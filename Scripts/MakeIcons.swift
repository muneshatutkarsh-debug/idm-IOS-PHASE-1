#!/usr/bin/env swift
//
//  MakeIcons.swift
//  Generates the app icon set and the in-app logo glyph image from the
//  base64-encoded master artwork in Assets/glyph.png.b64.
//
//  Usage: swift Scripts/MakeIcons.swift <repo-root>
//
//  The artwork itself is never redrawn or recoloured - it is only decoded,
//  scaled and (for the app icon) placed on the white brand tile.
//

import Foundation

#if canImport(AppKit)
import AppKit

let root = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : FileManager.default.currentDirectoryPath

let fm = FileManager.default
let rootURL = URL(fileURLWithPath: root, isDirectory: true)
let b64URL = rootURL.appendingPathComponent("Assets/glyph.png.b64")
let assetsURL = rootURL.appendingPathComponent("Resources/Assets.xcassets")
let appIconSet = assetsURL.appendingPathComponent("AppIcon.appiconset")
let glyphSet = assetsURL.appendingPathComponent("LogoGlyph.imageset")

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data(("MakeIcons: " + message + "\n").utf8))
    exit(1)
}

guard let encoded = try? String(contentsOf: b64URL, encoding: .utf8) else {
    fail("could not read \(b64URL.path)")
}

let cleaned = encoded.components(separatedBy: .whitespacesAndNewlines).joined()
guard let pngData = Data(base64Encoded: cleaned),
      let glyph = NSImage(data: pngData) else {
    fail("could not decode master artwork")
}

try? fm.createDirectory(at: appIconSet, withIntermediateDirectories: true)
try? fm.createDirectory(at: glyphSet, withIntermediateDirectories: true)

// The glyph keeps its transparency for in-app use.
try? pngData.write(to: glyphSet.appendingPathComponent("glyph.png"))

/// Draws the glyph centred on an opaque white tile and returns PNG data.
func renderIcon(pixels: Int, glyphFraction: CGFloat) -> Data {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 3,
        hasAlpha: false,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { fail("could not create bitmap") }

    rep.size = NSSize(width: pixels, height: pixels)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high

    NSColor.white.setFill()
    NSRect(x: 0, y: 0, width: CGFloat(pixels), height: CGFloat(pixels)).fill()

    let side = CGFloat(pixels) * glyphFraction
    let origin = (CGFloat(pixels) - side) / 2
    glyph.draw(
        in: NSRect(x: origin, y: origin, width: side, height: side),
        from: .zero,
        operation: .sourceOver,
        fraction: 1.0
    )

    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        fail("could not encode png")
    }
    return data
}

for size in [120, 180, 1024] {
    let data = renderIcon(pixels: size, glyphFraction: 0.68)
    let url = appIconSet.appendingPathComponent("AppIcon-\(size).png")
    do {
        try data.write(to: url)
        print("MakeIcons: wrote \(url.lastPathComponent) (\(data.count) bytes)")
    } catch {
        fail("could not write \(url.path): \(error)")
    }
}

print("MakeIcons: done")

#else
FileHandle.standardError.write(Data("MakeIcons: AppKit is required (run on macOS)\n".utf8))
exit(1)
#endif
