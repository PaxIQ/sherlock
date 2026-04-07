# Screenpipe Wayland Flash Fix

## Problem
On Linux Wayland (especially GNOME), every call to `xcap::Monitor::capture_image()` triggers the xdg-desktop-portal Screenshot API, which flashes the screen.

## Solution
Use xcap's `VideoRecorder` API instead, which uses the ScreenCast portal. This:
1. Shows a permission dialog ONCE at startup
2. Creates a continuous PipeWire video stream
3. Allows grabbing frames without any flash

This mirrors the approach already used on Windows with `PersistentCapture` to avoid the orange border flash.

## Files to Modify

### `crates/screenpipe-screen/src/monitor.rs`

Add these fields to `SafeMonitor` (around line 65, in the `#[cfg(not(target_os = "macos"))]` section):

```rust
    /// Persistent PipeWire video recorder for Linux Wayland to avoid screen flash.
    /// Lazy-initialized on first capture_image() call when running under Wayland.
    #[cfg(target_os = "linux")]
    persistent_recorder: Arc<std::sync::Mutex<Option<LinuxPersistentCapture>>>,
    #[cfg(target_os = "linux")]
    is_wayland: bool,
```

Add a new struct for Linux persistent capture (add near the top of the file):

```rust
#[cfg(target_os = "linux")]
pub struct LinuxPersistentCapture {
    _recorder: xcap::VideoRecorder,
    frame_receiver: std::sync::mpsc::Receiver<xcap::video_recorder::Frame>,
    latest_frame: Arc<std::sync::Mutex<Option<image::RgbaImage>>>,
    _capture_thread: std::thread::JoinHandle<()>,
}

#[cfg(target_os = "linux")]
impl LinuxPersistentCapture {
    pub fn new(monitor: &XcapMonitor) -> Result<Self> {
        let (recorder, frame_receiver) = monitor.video_recorder()
            .map_err(|e| anyhow::anyhow!("Failed to create video recorder: {}", e))?;
        
        recorder.start()
            .map_err(|e| anyhow::anyhow!("Failed to start video recorder: {}", e))?;
        
        let latest_frame: Arc<std::sync::Mutex<Option<image::RgbaImage>>> = 
            Arc::new(std::sync::Mutex::new(None));
        let latest_frame_clone = latest_frame.clone();
        
        // Spawn thread to continuously receive frames and keep latest
        let capture_thread = std::thread::spawn(move || {
            while let Ok(frame) = frame_receiver.recv() {
                if let Some(img) = image::RgbaImage::from_raw(
                    frame.width,
                    frame.height,
                    frame.raw,
                ) {
                    if let Ok(mut guard) = latest_frame_clone.lock() {
                        *guard = Some(img);
                    }
                }
            }
        });
        
        // Wait a moment for first frame
        std::thread::sleep(std::time::Duration::from_millis(500));
        
        Ok(Self {
            _recorder: recorder,
            frame_receiver: std::sync::mpsc::channel().1, // dummy, real one moved to thread
            latest_frame,
            _capture_thread: capture_thread,
        })
    }
    
    pub fn get_latest_image(&self) -> Result<image::DynamicImage> {
        let guard = self.latest_frame.lock()
            .map_err(|e| anyhow::anyhow!("Frame mutex poisoned: {}", e))?;
        
        guard.clone()
            .map(image::DynamicImage::ImageRgba8)
            .ok_or_else(|| anyhow::anyhow!("No frame available yet"))
    }
}
```

Modify the Linux `capture_image()` implementation (around line 385):

```rust
    #[cfg(target_os = "linux")]
    pub async fn capture_image(&self) -> Result<DynamicImage> {
        let monitor_id = self.monitor_id;
        let is_wayland = self.is_wayland;
        
        // On Wayland, use persistent PipeWire capture to avoid flash
        if is_wayland {
            let persistent = self.persistent_recorder.clone();
            let cached_idx = self.cached_monitor_index.clone();
            
            let result = tokio::task::spawn_blocking(move || -> Result<DynamicImage> {
                // Try existing persistent session
                {
                    let guard = persistent.lock()
                        .map_err(|e| anyhow::anyhow!("persistent recorder mutex poisoned: {}", e))?;
                    if let Some(ref capture) = *guard {
                        match capture.get_latest_image() {
                            Ok(img) => return Ok(img),
                            Err(e) => {
                                tracing::debug!(
                                    "persistent capture failed for monitor {}, will reinit: {}",
                                    monitor_id, e
                                );
                            }
                        }
                    }
                }
                
                // Initialize new persistent session
                let monitors = XcapMonitor::all().map_err(anyhow::Error::from)?;
                let monitor = monitors.iter()
                    .find(|m| m.id().unwrap_or(0) == monitor_id)
                    .ok_or_else(|| anyhow::anyhow!("Monitor not found"))?;
                
                match LinuxPersistentCapture::new(monitor) {
                    Ok(capture) => {
                        match capture.get_latest_image() {
                            Ok(img) => {
                                let mut guard = persistent.lock()
                                    .map_err(|e| anyhow::anyhow!("mutex poisoned: {}", e))?;
                                *guard = Some(capture);
                                return Ok(img);
                            }
                            Err(e) => {
                                tracing::warn!("PipeWire capture failed, falling back to portal: {}", e);
                            }
                        }
                    }
                    Err(e) => {
                        tracing::warn!("Failed to init PipeWire capture, falling back to portal: {}", e);
                    }
                }
                
                // Fallback to per-frame capture (will flash, but at least works)
                Self::per_frame_capture_with_cache(monitor_id, cached_idx)
            })
            .await
            .map_err(|e| anyhow::anyhow!("capture task panicked: {}", e))??;
            
            return Ok(result);
        }
        
        // X11 path - per-frame capture is fine, no flash
        let cached_idx = self.cached_monitor_index.clone();
        let image = tokio::task::spawn_blocking(move || -> Result<DynamicImage> {
            Self::per_frame_capture_with_cache(monitor_id, cached_idx)
        })
        .await
        .map_err(|e| anyhow::anyhow!("capture task panicked: {}", e))??;
        Ok(image)
    }
```

Add Wayland detection helper (add to utils or monitor.rs):

```rust
#[cfg(target_os = "linux")]
fn is_wayland_session() -> bool {
    std::env::var("XDG_SESSION_TYPE")
        .map(|v| v == "wayland")
        .unwrap_or(false)
}
```

Update `SafeMonitor::new()` for Linux to initialize the new fields:

```rust
#[cfg(target_os = "linux")]
pub fn new(monitor: XcapMonitor) -> Self {
    let monitor_id = monitor.id().unwrap_or(0);
    let monitor_data = Arc::new(MonitorData {
        // ... existing fields ...
    });

    Self {
        monitor_id,
        monitor_data,
        cached_monitor_index: Arc::new(std::sync::Mutex::new(None)),
        persistent_recorder: Arc::new(std::sync::Mutex::new(None)),
        is_wayland: is_wayland_session(),
    }
}
```

## Testing

1. Build with changes: `cargo build --release`
2. On Wayland: Run `./target/release/screenpipe record` 
3. You should see ONE permission dialog asking to share screen
4. After granting, capture should work WITHOUT flashing

## Notes

- The ScreenCast portal remembers permission, so subsequent runs won't prompt again
- If PipeWire capture fails, it falls back to the old portal-based capture (will flash)
- X11 sessions are unaffected - they use the existing per-frame capture which doesn't flash
