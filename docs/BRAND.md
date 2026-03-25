# Recap — Brand Guidelines

## App Overview
Recap is a macOS meeting recorder that captures screen, audio, and timestamps from your calls — then organizes everything so nothing important gets lost.

---

## Icon Concept

**Visual:** A circular "rec" button / red dot combined with a timeline bar — suggesting recording in time.
- A rounded square icon
- A stylized red circle (recording dot) at the top left
- Below it, a horizontal timeline/waveform strip in gradient from red to blue
- Sizes: 16, 32, 64, 128, 256, 512, 1024

**Alternative concept:** A clock face with a red recording dot, and subtle timestamp markers around the edge.

---

## Color Palette

| Role | Hex | Usage |
|------|-----|-------|
| Primary Red | `#DC2626` | Recording indicator, active record button |
| Deep Red | `#B91C1C` | Pressed states |
| Recording Pulse | `#EF4444` | Pulsing recording dot animation |
| Timeline Gradient Start | `#EF4444` | Waveform start (red = recorded) |
| Timeline Gradient End | `#3B82F6` | Waveform end (blue = playback) |
| Background Light | `#F9FAFB` | Main background (light) |
| Background Dark | `#111827` | Main background (dark) |
| Surface Light | `#FFFFFF` | Cards, panels (light) |
| Surface Dark | `#1F2937` | Cards, panels (dark) |
| Text Primary Light | `#111827` | Headings (light) |
| Text Primary Dark | `#F9FAFB` | Headings (dark) |
| Text Secondary | `#6B7280` | Timestamps, metadata |
| Success Green | `#10B981` | Export complete, saved |
| Warning Amber | `#F59E0B` | Low disk space, auto-save |
| Destructive | `#DC2626` | Delete recording |
| Timestamp Marker | `#8B5CF6` | Key moment marker (purple) |

---

## Typography

- **Display / Recording Title:** SF Pro Display, Bold — 18px
- **Section Headings:** SF Pro Text, Semibold — 14px
- **Timestamp Labels:** SF Mono, Regular — 12px (monospace for time precision)
- **Body:** SF Pro Text, Regular — 13px
- **Caption / Metadata:** SF Pro Text, Regular — 11px, secondary color

**Font Stack:**
```
font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Mono", monospace;
```

---

## Visual Motif

**Theme:** "Precision in Motion" — the app lives at the intersection of time and content. The visual language should feel clinical yet warm — precise enough for professionals, approachable enough to not feel intimidating.

- **Recording indicator:** Always-visible red pulsing dot in the toolbar when active
- **Waveform:** Horizontal audio waveform visualization, red during recording, blue during playback
- **Timestamp markers:** Small purple diamond/chevron on the timeline — clickable to jump to key moments
- **Countdown overlay:** Large centered countdown (3, 2, 1) before recording starts
- **Recordings library:** Card grid with thumbnail, title, date, duration — like video thumbnails
- **Empty state:** A microphone icon inside a circle, with a subtle "Your recordings will appear here"

**Spatial rhythm:** 8pt grid. Toolbar 44px. Timeline area 80px. Card grid 3-column on full window.

---

## macOS-Specific Behavior

- **Window:** `NSWindow` with toolbar. Minimum 800×600. Full-screen recording mode available.
- **Menu Bar:** Optional menu bar icon showing recording status + quick record toggle.
- **Display selection:** Multi-display support — user picks which screen/window to record.
- **Auto-save:** Recordings saved locally in `~/Library/Application Support/Recap/`.
- **Dark Mode:** Full support.
- **Keyboard shortcuts:** `⌘⇧R` start/stop recording, `⌘⇧S` screenshot during recording, `Space` play/pause.

---

## Sizes & Behavior

| Element | Default | Minimized (Mini) |
|---------|---------|------------------|
| Toolbar height | 44px | 28px |
| Timeline height | 80px | 40px |
| Recording card | 240×160px | 160×100px |
| Thumbnail | 120×68px (16:9) | 80×45px |
| Waveform height | 48px | 24px |

Window resizable. Mini player mode: floating 300×200 window.
