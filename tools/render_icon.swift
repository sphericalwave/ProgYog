//
//  render_icon.swift
//
//  Generates AppIcon.png (1024×1024) for Progressive Yoga.
//  Run: swift tools/render_icon.swift <output_path>
//

import SwiftUI
import AppKit

@available(macOS 13.0, *)
struct AppIconView: View {
    static let size: CGFloat = 1024

    var body: some View {
        ZStack {
            Color(red: 0.855, green: 0.435, blue: 0.184) // #DA6F2F

            TensegrityFrame()
                .stroke(
                    Color.white.opacity(0.92),
                    style: StrokeStyle(lineWidth: 24, lineCap: .round, lineJoin: .round)
                )
                .padding(140)

            Image(systemName: "figure.yoga")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(260)
                .foregroundStyle(.white)
        }
        .frame(width: Self.size, height: Self.size)
    }
}

struct TensegrityFrame: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let topA = CGPoint(x: rect.midX,             y: rect.minY)
        let topB = CGPoint(x: rect.maxX,             y: rect.minY + rect.height * 0.35)
        let topC = CGPoint(x: rect.minX,             y: rect.minY + rect.height * 0.35)
        let botA = CGPoint(x: rect.minX,             y: rect.maxY)
        let botB = CGPoint(x: rect.maxX,             y: rect.maxY)
        let botC = CGPoint(x: rect.midX,             y: rect.maxY - rect.height * 0.35)

        // Struts (rods)
        p.move(to: topA); p.addLine(to: botB)
        p.move(to: topB); p.addLine(to: botC)
        p.move(to: topC); p.addLine(to: botA)

        // Top triangle (cables)
        p.move(to: topA); p.addLine(to: topB)
        p.addLine(to: topC); p.addLine(to: topA)

        // Bottom triangle (cables)
        p.move(to: botA); p.addLine(to: botB)
        p.addLine(to: botC); p.addLine(to: botA)
        return p
    }
}

@available(macOS 13.0, *)
@MainActor
func render(to path: String) throws {
    let renderer = ImageRenderer(content: AppIconView())
    renderer.scale = 1.0
    guard let cgImage = renderer.cgImage else {
        FileHandle.standardError.write("Render failed\n".data(using: .utf8)!)
        exit(1)
    }
    let rep = NSBitmapImageRep(cgImage: cgImage)
    guard let png = rep.representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write("PNG encode failed\n".data(using: .utf8)!)
        exit(1)
    }
    let url = URL(fileURLWithPath: path)
    try png.write(to: url)
    print("Wrote \(url.path)  (\(cgImage.width)×\(cgImage.height))")
}

guard #available(macOS 13.0, *) else {
    FileHandle.standardError.write("Requires macOS 13+\n".data(using: .utf8)!)
    exit(1)
}

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"
try MainActor.assumeIsolated { try render(to: out) }
