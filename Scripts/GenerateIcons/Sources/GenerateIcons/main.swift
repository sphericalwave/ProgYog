import AppKit
import BrandGenCore

// MARK: - Brand

let brandHex    = "193BE8"   // royal blue (light mode icon bg + launch bg)
let darkHex     = "7B9EF5"   // lighter blue (dark mode accent)
let brandColor  = NSColor(srgbRed: 0x19/255, green: 0x3B/255, blue: 0xE8/255, alpha: 1)

// MARK: - Paths (run from project root: progYog/)

let cwd     = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets  = cwd.appendingPathComponent("ProgYog/Assets.xcassets")
let iconDir = assets.appendingPathComponent("AppIcon.appiconset")
let logoDir = assets.appendingPathComponent("LaunchLogo.imageset")
let accentDir  = assets.appendingPathComponent("AccentColor.colorset")
let bgDir      = assets.appendingPathComponent("LaunchBackground.colorset")

// MARK: - SF Symbol glyph drawer

func yogaGlyph() -> GlyphDrawer {
    return { rect, cg in
        let pt  = rect.width * 0.55
        let cfg = NSImage.SymbolConfiguration(pointSize: pt, weight: .regular)
        guard let raw = NSImage(systemSymbolName: "figure.yoga", accessibilityDescription: nil),
              let sym = raw.withSymbolConfiguration(cfg) else {
            print("warning: figure.yoga SF symbol not found")
            return
        }
        let s  = sym.size
        let tw = Int(ceil(s.width)), th = Int(ceil(s.height))
        let tmp = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: tw, pixelsHigh: th,
            bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        let prevCtx = NSGraphicsContext.current
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: tmp)
        NSGraphicsContext.current!.cgContext.clear(CGRect(x: 0, y: 0, width: s.width, height: s.height))
        sym.draw(in: NSRect(x: 0, y: 0, width: s.width, height: s.height))
        NSGraphicsContext.current!.cgContext.setBlendMode(.sourceAtop)
        NSGraphicsContext.current!.cgContext.setFillColor(NSColor.white.cgColor)
        NSGraphicsContext.current!.cgContext.fill(CGRect(x: 0, y: 0, width: s.width, height: s.height))
        NSGraphicsContext.current = prevCtx
        guard let cgImg = tmp.cgImage else { return }
        let dx = rect.midX - s.width / 2, dy = rect.midY - s.height / 2
        cg.draw(cgImg, in: CGRect(x: dx, y: dy, width: s.width, height: s.height))
    }
}

// MARK: - Helpers

let fm = FileManager.default
func mkdirs(_ url: URL) { try? fm.createDirectory(at: url, withIntermediateDirectories: true) }
func writeJSON(_ json: String, to dir: URL, name: String = "Contents.json") {
    mkdirs(dir)
    try! json.write(to: dir.appendingPathComponent(name), atomically: true, encoding: .utf8)
    print("wrote \(dir.appendingPathComponent(name).path)")
}

// MARK: - Generate

// AppIcon (opaque, brand bg)
write(render(size: 1024, background: brandColor, glyphDrawer: yogaGlyph()),
      to: iconDir, name: "icon-1024.png")

// LaunchLogo @1x/2x/3x (transparent bg)
write(renderLaunchLogo(circleSize: 170, appName: "ProgYog", glyphDrawer: yogaGlyph()),
      to: logoDir, name: "LaunchLogo.png")
write(renderLaunchLogo(circleSize: 340, appName: "ProgYog", glyphDrawer: yogaGlyph()),
      to: logoDir, name: "LaunchLogo@2x.png")
write(renderLaunchLogo(circleSize: 512, appName: "ProgYog", glyphDrawer: yogaGlyph()),
      to: logoDir, name: "LaunchLogo@3x.png")

writeJSON(appIconContentsJSON,                        to: iconDir)
writeJSON(launchLogoContentsJSON,                     to: logoDir)
writeJSON(colorsetJSON(lightHex: brandHex, darkHex: darkHex), to: accentDir)
writeJSON(colorsetJSON(lightHex: brandHex),           to: bgDir)

print("\nDone. Cmd+Shift+K in Xcode to flush the launch screen cache.")
