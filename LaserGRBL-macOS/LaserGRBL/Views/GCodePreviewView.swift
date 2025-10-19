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

    // Preview options for debugging
    @State private var showLaserOn = true
    @State private var showLaserOff = true
    @State private var showFirstMovement = true

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

                // Debug toggles
                Toggle(isOn: $showFirstMovement) {
                    Text("1st")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .help("Show First Movement (Blue)")

                Toggle(isOn: $showLaserOn) {
                    Text("On")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .help("Show Laser On (Red)")

                Toggle(isOn: $showLaserOff) {
                    Text("Off")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .help("Show Laser Off (Orange)")

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
                Canvas { context, size in
                    // Draw grid
                    if showGrid {
                        drawGrid(context: context, size: size)
                    }

                    // Draw G-code
                    drawGCode(context: context, size: size)
                }
                .background(Color(NSColor.windowBackgroundColor))
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            zoom *= value
                        }
                        .simultaneously(with:
                            DragGesture()
                                .onChanged { value in
                                    offset = value.translation
                                }
                        )
                )
            }
        }
    }

    private func drawGrid(context: GraphicsContext, size: CGSize) {
        let gridSpacing: CGFloat = 20
        let gridColor = Color.gray.opacity(0.3)

        // Vertical lines
        for x in stride(from: 0, through: size.width, by: gridSpacing) {
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                },
                with: .color(gridColor),
                lineWidth: 0.5
            )
        }

        // Horizontal lines
        for y in stride(from: 0, through: size.height, by: gridSpacing) {
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                },
                with: .color(gridColor),
                lineWidth: 0.5
            )
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

        // Draw toolpath using color-coded approach like original PC version
        var currentX: Double = 0
        var currentY: Double = 0
        var laserOn = false
        var motionCount = 0
        var laserMotionCount = 0
        var firstLine = true

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
                motionCount += 1

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

                // Determine if this is an arc command
                let isArc = command.command == .motion(.arcCW) || command.command == .motion(.arcCCW)
                let isClockwise = command.command == .motion(.arcCW)

                // Color coding like original PC version with toggle options
                let shouldDraw: Bool
                let lineColor: Color
                let lineWidth: CGFloat
                let lineStyle: StrokeStyle

                if firstLine && showFirstMovement {
                    // First movement - blue
                    shouldDraw = true
                    lineColor = .blue
                    lineWidth = 1.5
                    lineStyle = StrokeStyle(lineWidth: lineWidth)
                    firstLine = false
                } else if laserOn && showLaserOn {
                    // Laser on - red (engraving)
                    shouldDraw = true
                    lineColor = .red
                    lineWidth = 0.5  // Thinner for dense raster
                    lineStyle = StrokeStyle(lineWidth: lineWidth)
                    laserMotionCount += 1
                } else if !laserOn && showLaserOff {
                    // Laser off - orange (travel)
                    shouldDraw = true
                    lineColor = .orange
                    lineWidth = 0.3
                    lineStyle = StrokeStyle(lineWidth: lineWidth, dash: [2, 2])
                } else {
                    shouldDraw = false
                    lineColor = .clear
                    lineWidth = 0
                    lineStyle = StrokeStyle()
                }

                // Draw the segment if enabled
                if shouldDraw {
                    if isArc, let i = command.i, let j = command.j {
                        // Draw arc using I, J parameters
                        let arcPath = createArcPath(
                            from: startPoint,
                            to: endPoint,
                            i: CGFloat(i) * scale,
                            j: CGFloat(j) * scale,
                            clockwise: isClockwise
                        )
                        context.stroke(arcPath, with: .color(lineColor), style: lineStyle)
                        
                        // Debug output for arcs
                        print("🎯 Arc: \(command.command) from (\(currentX), \(currentY)) to (\(newX), \(newY)) I:\(i) J:\(j)")
                    } else {
                        // Draw linear segment
                        var segmentPath = Path()
                        segmentPath.move(to: startPoint)
                        segmentPath.addLine(to: endPoint)
                        context.stroke(segmentPath, with: .color(lineColor), style: lineStyle)
                    }
                }
            }

            currentX = newX
            currentY = newY
        }

        // Debug output
        print("🎨 Preview Debug:")
        print("   Total commands: \(file.commands.count)")
        print("   Motion commands: \(motionCount)")
        print("   Laser motion commands: \(laserMotionCount)")
        print("   Bounding box: \(bbox)")
        print("   Scale: \(scale)")
        print("   Show options - First: \(showFirstMovement), LaserOn: \(showLaserOn), LaserOff: \(showLaserOff)")

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
    
    private func createArcPath(from startPoint: CGPoint, to endPoint: CGPoint, i: CGFloat, j: CGFloat, clockwise: Bool) -> Path {
        var path = Path()
        
        // Calculate arc center (I, J are relative to start point)
        // Note: J needs to be flipped because G-code Y+ is up, but screen Y+ is down
        let centerX = startPoint.x + i
        let centerY = startPoint.y - j  // Flip J for screen coordinates
        
        // Calculate radius
        let radius = sqrt(i * i + j * j)
        
        // Calculate start and end angles
        let startAngle = atan2(startPoint.y - centerY, startPoint.x - centerX)
        let endAngle = atan2(endPoint.y - centerY, endPoint.x - centerX)
        
        // Calculate the angular span from start to end
        var angularSpan = endAngle - startAngle
        
        // Normalize the angular span based on direction
        if clockwise {
            // For clockwise arcs, ensure we go the shorter way around in negative direction
            while angularSpan > .pi {
                angularSpan -= 2 * .pi
            }
            while angularSpan >= 0 {
                angularSpan -= 2 * .pi
            }
        } else {
            // For counter-clockwise arcs, ensure we go the shorter way around in positive direction
            while angularSpan < -.pi {
                angularSpan += 2 * .pi
            }
            while angularSpan <= 0 {
                angularSpan += 2 * .pi
            }
        }
        
        // Create arc path - move to start point first
        path.move(to: startPoint)
        path.addArc(
            center: CGPoint(x: centerX, y: centerY),
            radius: radius,
            startAngle: Angle(radians: startAngle),
            endAngle: Angle(radians: startAngle + angularSpan),
            clockwise: clockwise
        )
        
        return path
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
        for x in stride(from: 0, through: rect.width, by: spacing) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }

        // Horizontal lines
        for y in stride(from: 0, through: rect.height, by: spacing) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }

        return path
    }
}

#Preview {
    GCodePreviewView(file: GCodeFile(), selectedCommandId: .constant(nil))
        .frame(width: 400, height: 300)
}
