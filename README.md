# mDownloader — iOS (Glass Rebuild)

A full, from-scratch SwiftUI rebuild of **mDownloader** with a frosted-glass visual
language over a soft blue gradient. Background downloads, live progress in the
Dynamic Island and on the Lock Screen, an in-app files library, a floating glass
tab dock, an animated first-launch welcome screen, and a
"Download with mDownloader" share extension.

---

## What's inside

```
App/              mDownloaderApp.swift, RootView.swift (glass dock + deep links),
                  WelcomeView.swift, SettingsStore.swift
DesignSystem/     Theme.swift (colour tokens, Original + Basic themes),
                  Components.swift (glass surfaces, rows, progress bar, buttons)
Screens/          DownloadsView, FilesView, SettingsView, DownloadDetailView,
                  PreviewSupport (QuickLook + share sheet)
Models/           DownloadItem, StoredFile, FileKind, Formatters,
                  DownloadActivityAttributes
Services/         DownloadManager (background URLSession), FileLibrary,
                  LiveActivityController, SampleData
Widget/           DownloadLiveActivityWidget (Dynamic Island + Lock Screen)
ShareExtension/   ShareViewController
Scripts/          MakeIcons.swift (generates the app icon + logo asset at build time)
Assets/           glyph.png.b64 (the mDownloader glyph, base64)
```

Three targets, wired up by [XcodeGen](https://github.com/yonaskolb/XcodeGen)
from `project.yml`:

| Target | Bundle ID | Purpose |
| --- | --- | --- |
| `mDownloader` | `com.mdownloader.app` | The app |
| `mDownloaderWidget` | `com.mdownloader.app.widget` | Live Activity |
| `mDownloaderShare` | `com.mdownloader.app.share` | Share extension |

Deployment target: **iOS 16.1** (ActivityKit APIs above 16.1 are availability gated).

---

## Design tokens

Every surface is a blurred translucent material tinted with the card colour,
a 1pt translucent stroke, a soft outer shadow, a brighter top-edge highlight and
a corner radius of 18.

| Token | Light | Dark |
| --- | --- | --- |
| Background top | `#F1F5FE` | `#101A3E` |
| Background bottom | `#E7EEFB` | `#090E24` |
| Card | `#FFFFFF` | `#151E3B` |
| Card raised | `#F4F8FF` | `#1D2748` |
| Ink | `#0C1430` | `#FFFFFF` |
| Secondary | `#5C6474` | `#9AA2B4` |
| Accent | `#34549A` | `#6E90E6` |
| Tile | `#E3EAF9` | `#1D2748` |
| Track | `rgba(12,20,48,.12)` | `rgba(255,255,255,.16)` |
| Hairline | `rgba(18,28,60,.10)` | `rgba(255,255,255,.08)` |

Brand constants in both modes: gradient top `#4F72BE`, gradient bottom `#2E4088`,
arrow red `#EC445B` (used only for the progress ball).

The **Basic** theme swaps the same token set for a clean system look; the theme
choice also flows into the Live Activity.

---

## Building

### On a Mac

```bash
brew install xcodegen
swift Scripts/MakeIcons.swift "$PWD"   # renders the icon + logo asset
xcodegen generate --spec project.yml
open mDownloader.xcodeproj
```

The generated `mDownloader.xcodeproj` is intentionally **not** committed — it is
regenerated from `project.yml` so the repo stays clean.

### Unsigned IPA via GitHub Actions

Push to `main` (or run the workflow manually) and
`.github/workflows/ios-build.yml` will:

1. spin up a macOS runner and install XcodeGen,
2. generate the icons and the Xcode project,
3. `xcodebuild` the Release configuration with code signing disabled
   (`CODE_SIGNING_ALLOWED=NO`),
4. package `mDownloader.app` into `Payload/` and zip it as
   **`mDownloader-unsigned.ipa`**,
5. upload it as the `mDownloader-unsigned-ipa` artifact **and** attach it to a
   GitHub release tagged `build-<run number>`.

If the build fails, the workflow opens an issue containing the compiler errors
and the tail of the build log.

### Sideloading

The IPA is unsigned, so install it with **AltStore**, **SideStore** or
**Sideloadly** (they re-sign with your own Apple ID). Live Activities and the
share extension work on a sideloaded build; a free Apple ID certificate expires
after 7 days.

---

## Notes

- Sample rows from the mockups are shown until the first real download / file
  exists, so a fresh install looks exactly like the design.
- Pausing uses `cancel(byProducingResumeData:)`, so resuming continues from the
  byte it stopped at.
- The Welcome screen respects **Reduce Motion** (fades only, no drift or sheen).
- The app icon is composited at build time from the supplied glyph on a white
  tile. Drop a 1024×1024 master into
  `Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` (plus the
  120/180 variants) if you'd rather ship the original artwork untouched.
"# mDowloader-IOS" 
"# mDowloader-IOS" 
