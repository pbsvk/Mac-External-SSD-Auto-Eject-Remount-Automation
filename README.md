# Mac External SSD Auto Eject & Remount Automation

This is a simple **Hammerspoon** script to automatically unmount your external SSD after your Mac has been locked for 30 minutes and then remount it when you unlock or wake your Mac.

## Why?

Thunderbolt 4 NVMe SSDs often don't sleep automatically to save power. This script helps:

- Reduce wear and power consumption by unmounting SSD after idle lock
- Automatically remount SSD when you unlock or wake your Mac
- Receive notifications on unmount and remount events

## Requirements

- macOS
- [Hammerspoon](https://www.hammerspoon.org/) installed and accessibility permissions enabled
- External SSD disk identifier (run `diskutil list` in Terminal to find yours)

## Usage

1. Edit `ssd_auto_eject.lua` and replace `ssdVolume` and `ssdDiskID` with your SSD's volume path and disk identifier.
2. Place the script content in your `~/.hammerspoon/init.lua` file (or require it from there).
3. Reload Hammerspoon config (`Hammerspoon menu → Reload Config`).
4. Lock your Mac and wait 30 minutes; the SSD will auto unmount.
5. Unlock or wake your Mac; the SSD will auto remount.

## Quick Test

To test immediately without waiting 30 minutes, change the `delaySeconds` value to something smaller (e.g., 10 seconds).

## License

MIT License © Bhaskara Sai Vamsi Krishna Padala
