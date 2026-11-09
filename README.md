# TikGrab

No-watermark TikTok downloader for iPhone.

Paste any TikTok link (full `tiktok.com` link or `vm.tiktok.com` / `vt.tiktok.com` short link), tap **GET VIDEO**, preview it, then download:

- **HD • No Watermark** (primary)
- **SD • No Watermark**
- **MP3 Audio**
- **With Watermark**

Videos save to Photos (add-only permission). MP3s save to Documents and open the share sheet. History is kept on-device in UserDefaults so you can re-open past grabs.

Backend: `https://www.tikwm.com/api/?url=<encoded>&hd=1` — no API key.

## Honest quality note

You get the original quality the creator uploaded — most TikToks are 1080p max. No fake 4K upscale.

## Install (Sideloadly)

The IPA from GitHub Actions is **unsigned** — re-sign it to install:

1. Download `TikGrab-ipa` from the latest Actions run, unzip to get `TikGrab.ipa`.
2. Copy the IPA to Desktop/Downloads first (not from Messages Attachments).
3. Open Sideloadly on your iMac, pick the IPA, sign with your Apple ID, install.
4. On iPhone: Settings → General → VPN & Device Management → trust your profile.

- Bundle ID: `com.tikgrab.app`
- iOS 16+, SwiftUI, no external packages
- Project generated with XcodeGen from `project.yml`
