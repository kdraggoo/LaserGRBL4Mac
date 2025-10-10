//
//  GCodePreviewView.swift
//  LaserGRBL for macOS
//
//  2D preview canvas for G-code visualization
//

import SwiftUI

struct GCodePreviewView: View {
    @ObservedObject var file: GCodeFile
    @Binding var selectedCommandId: UUID?
    @State private var zoom: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var showGrid = true
    @State private var showBounds = true

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Preview")
                    .font(.headline)

                Spacer()

                Toggle(isOn: $showGrid) {
                    Image(systemName: "grid")
                }
                .help("Show Grid")

                Toggle(isOn: $showBounds) {
                    Image(systemName: "rectangle.dashed")
                }
                .help("Show Bounds")

                Divider()
                    .frame(height: 20)

                Button(action: { resetView() }) {
                    Image(systemName: "arrow.counterclockwise")
                }
                .help("Reset View")

                Button(action: { zoomToFit() }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
                .help("Zoom to Fit")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Canvas
            GeometryReader { _ in
                ZStack {
                    // Background
                    Color(NSColor.textBackgroundColor)

                    // Grid
                    if showGrid {
                        GridPattern(spacing: 10 * zoom)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                    }

                    // G-Code visualization
                    Canvas { context, size in
                        drawGCode(context: context, size: size)
                    }
                    .offset(offset)
                }
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            zoom = max(0.1, min(value, 10.0))
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = value.translation
                        }
                )
            }

            // Status bar
            HStack {
                if let bbox = file.boundingBox {
                    Text(String(format: "Size: %.1f × %.1f mm", bbox.width, bbox.height))
                        .font(.caption)

                    Divider()
                        .frame(height: 12)
                }

                Text("Zoom: \(Int(zoom * 100))%")
                    .font(.caption)

                Spacer()

                Text("\(file.commands.filter { !$0.isEmpty }.count) commands")
                    .font(.caption)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor))
        }
    }

    private func drawGCode(context: GraphicsContext, size: CGSize) {
        print("🎨 Canvas render called with size: \(size)")
        print("🎨 Drawing G-Code - File has \(file.commands.count) commands")

        guard let bbox = file.boundingBox else {
            print("❌ No bounding box available")
            return
        }
        print("📦 Bounding box: \(bbox)")

        let centerX = size.width / 2
        let centerY = size.height / 2

        // Calculate scale to fit
        let scaleX = (size.width * 0.8) / CGFloat(bbox.width)
        let scaleY = (size.height * 0.8) / CGFloat(bbox.height)
        let scale = min(scaleX, scaleY) * zoom

        // Draw bounding box
        if showBounds {
            let rectWidth = CGFloat(bbox.width) * scale
            let rectHeight = CGFloat(bbox.height) * scale
            let rect = CGRect(
                x: centerX - rectWidth / 2,
                y: centerY - rectHeight / 2,
                width: rectWidth,
                height: rectHeight
            )

            context.stroke(
                Path(rect),
                with: .color(.blue.opacity(0.5)),
                style: StrokeStyle(lineWidth: 1, dash: [5, 5])
            )
        }

        // Draw toolpath
        var currentX: Double = 0
        var currentY: Double = 0
        var laserOn = false
        var path = Path()

        for command in file.commands {
            let newX = command.x ?? currentX
            let newY = command.y ?? currentY

            // Update laser state
            switch command.command {
            case .laser(.on), .laser(.onDynamic):
                laserOn = true
            case .laser(.off):
                laserOn = false
            default:
                break
            }

            // Draw motion
            if command.isMotion {
                let startPoint = transformPoint(
                    x: currentX - bbox.centerX,
                    y: currentY - bbox.centerY,
                    centerX: centerX,
                    centerY: centerY,
                    scale: scale
                )

                let endPoint = transformPoint(
                    x: newX - bbox.centerX,
                    y: newY - bbox.centerY,
                    centerX: centerX,
                    centerY: centerY,
                    scale: scale
                )

                if laserOn {
                    // Cutting/engraving move (laser on)
                    // Only move to start point if this is the first command or if we're starting a new path
                    if path.isEmpty {
                        path.move(to: startPoint)
                    }

                    // Handle different motion types
                    switch command.command {
                    case .motion(.linear), .motion(.rapid):
                        // Straight line
                        path.addLine(to: endPoint)

                    case .motion(.arcCW), .motion(.arcCCW):
                        // Arc motion - draw as line segments for now
                        print("🔵 ARC COMMAND: \(command.rawLine)")
                        if let i = command.i, let j = command.j {
                            // Calculate arc center (I,J are offsets from current position)
                            let arcCenterX = currentX + i
                            let arcCenterY = currentY + j

                            // Calculate radius
                            let radius = sqrt(i * i + j * j)

                            // Calculate start and end angles
                            let startAngle = atan2(currentY - arcCenterY, currentX - arcCenterX)
                            let endAngle = atan2(newY - arcCenterY, newX - arcCenterX)

                            // Handle the angle difference properly for arcs
                            var angleDiff = endAngle - startAngle

                            // Normalize angle difference for clockwise/counterclockwise
                            let clockwise = command.command == .motion(.arcCW)

                            // Ensure we take the correct direction for the arc
                            if clockwise {
                                // For clockwise arcs (G2), if angleDiff > 0, we should go the long way
                                if angleDiff > 0 {
                                    angleDiff -= 2 * .pi
                                }
                            } else {
                                // For counter-clockwise arcs (G3), if angleDiff < 0, we should go the long way
                                if angleDiff < 0 {
                                    angleDiff += 2 * .pi
                                }
                            }

                            // Draw arc using line segments
                            let numSegments = max(10, Int(abs(angleDiff) * 10))

                            for i in 0..<numSegments {
                                let t = Double(i) / Double(numSegments - 1)
                                let currentAngle = startAngle + angleDiff * t

                                let arcX = arcCenterX + radius * cos(currentAngle)
                                let arcY = arcCenterY + radius * sin(currentAngle)

                                let arcPoint = transformPoint(
                                    x: arcX - bbox.centerX,
                                    y: arcY - bbox.centerY,
                                    centerX: centerX,
                                    centerY: centerY,
                                    scale: scale
                                )

                                if i == 0 && path.isEmpty {
                                    path.move(to: arcPoint)
                                } else {
                                    path.addLine(to: arcPoint)
                                }
                            }
                        } else {
                            // Fallback to straight line if no I,J parameters
                            path.addLine(to: endPoint)
                        }

                    default:
                        // Default to straight line
                        path.addLine(to: endPoint)
                    }
                }
            }

            currentX = newX
            currentY = newY
        }

        // Draw the path
        context.stroke(
            path,
            with: .color(.red),
            lineWidth: 1.5
        )

        // Draw origin
        let origin = transformPoint(
            x: -bbox.centerX,
            y: -bbox.centerY,
            centerX: centerX,
            centerY: centerY,
            scale: scale
        )

        let crossSize: CGFloat = 10
        var crossPath = Path()
        crossPath.move(to: CGPoint(x: origin.x - crossSize, y: origin.y))
        crossPath.addLine(to: CGPoint(x: origin.x + crossSize, y: origin.y))
        crossPath.move(to: CGPoint(x: origin.x, y: origin.y - crossSize))
        crossPath.addLine(to: CGPoint(x: origin.x, y: origin.y + crossSize))

        context.stroke(crossPath, with: .color(.green), lineWidth: 2)
    }

    private func transformPoint(x: Double, y: Double, centerX: CGFloat, centerY: CGFloat, scale: CGFloat) -> CGPoint {
        // Convert G-code coordinates to screen coordinates
        // Note: Flip Y axis (G-code Y+ is up, screen Y+ is down)
        CGPoint(
            x: centerX + CGFloat(x) * scale,
            y: centerY - CGFloat(y) * scale
        )
    }

    private func resetView() {
        zoom = 1.0
        offset = .zero
    }

    private func zoomToFit() {
        // TODO: Calculate optimal zoom based on bounding box
        zoom = 1.0
        offset = .zero
    }
}

// MARK: - Grid Pattern

struct GridPattern: Shape {
    let spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Vertical lines
        var x = rect.minX
        while x <= rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += spacing
        }

        // Horizontal lines
        var y = rect.minY
        while y <= rect.maxY {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += spacing
        }

        return path
    }
}

#Preview {
    let file = GCodeFile()
    file.commands = [
        GCodeCommand(rawLine: "G21", lineNumber: 1),
        GCodeCommand(rawLine: "G90", lineNumber: 2),
        GCodeCommand(rawLine: "G0 X0 Y0", lineNumber: 3),
        GCodeCommand(rawLine: "M3 S500", lineNumber: 4),
        GCodeCommand(rawLine: "G1 X50 Y0 F1000", lineNumber: 5),
        GCodeCommand(rawLine: "G1 X50 Y50", lineNumber: 6),
        GCodeCommand(rawLine: "G1 X0 Y50", lineNumber: 7),
        GCodeCommand(rawLine: "G1 X0 Y0", lineNumber: 8),
        GCodeCommand(rawLine: "M5", lineNumber: 9)
    ]
    file.analyze()

    return GCodePreviewView(file: file, selectedCommandId: .constant(nil))
        .frame(width: 500, height: 600)
}
