//
//  VectorPreviewCanvas.swift
//  LaserGRBL
//
//  Phase 4: SVG Vector Import
//  Created on October 19, 2025
//

import SwiftUI

/// Canvas view for previewing SVG paths
struct VectorPreviewCanvas: View {
    @EnvironmentObject var svgImporter: SVGImporter
    
    @State private var zoom: Double = 1.0
    @State private var offset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var showGrid = true
    @State private var showBounds = true
    @State private var showOrigin = true
    
    var body: some View {
        ZStack {
            // Background
            Color(NSColor.textBackgroundColor)
            
            // Canvas
            if let document = svgImporter.currentDocument {
                GeometryReader { geometry in
                    Canvas { context, size in
                        // Calculate transform
                        let transform = calculateTransform(
                            canvasSize: size,
                            documentBounds: document.boundingBox
                        )
                        
                        // Draw grid
                        if showGrid {
                            drawGrid(context: context, size: size, transform: transform)
                        }
                        
                        // Draw origin
                        if showOrigin {
                            drawOrigin(context: context, size: size, transform: transform)
                        }
                        
                        // Draw paths
                        for path in document.visiblePaths {
                            drawPath(path, context: context, transform: transform)
                        }
                        
                        // Draw bounding box
                        if showBounds {
                            drawBounds(context: context, bounds: document.boundingBox, transform: transform)
                        }
                    }
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                zoom = max(0.1, min(10.0, value))
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                offset.width += value.translation.width
                                offset.height += value.translation.height
                                dragOffset = .zero
                            }
                    )
                }
            }
            
            // Controls overlay
            VStack {
                HStack {
                    Spacer()
                    controlsPanel
                }
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - Controls Panel
    
    private var controlsPanel: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // Zoom controls
            HStack(spacing: 4) {
                Button {
                    withAnimation {
                        zoom = max(0.1, zoom - 0.1)
                    }
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                }
                .buttonStyle(.bordered)
                .help("Zoom Out")
                
                Text(String(format: "%.0f%%", zoom * 100))
                    .font(.caption)
                    .frame(width: 50)
                
                Button {
                    withAnimation {
                        zoom = min(10.0, zoom + 0.1)
                    }
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                }
                .buttonStyle(.bordered)
                .help("Zoom In")
                
                Button {
                    withAnimation {
                        zoom = 1.0
                        offset = .zero
                        dragOffset = .zero
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
                .help("Reset View")
            }
            
            Divider()
                .frame(width: 200)
            
            // Display toggles
            Toggle("Grid", isOn: $showGrid)
                .toggleStyle(.switch)
                .controlSize(.small)
            
            Toggle("Bounds", isOn: $showBounds)
                .toggleStyle(.switch)
                .controlSize(.small)
            
            Toggle("Origin", isOn: $showOrigin)
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .shadow(radius: 2)
    }
    
    // MARK: - Drawing Functions
    
    private func calculateTransform(canvasSize: CGSize, documentBounds: CGRect) -> CGAffineTransform {
        // Center the content
        let padding: CGFloat = 50
        let availableWidth = canvasSize.width - padding * 2
        let availableHeight = canvasSize.height - padding * 2
        
        // Calculate scale to fit
        let scaleX = availableWidth / documentBounds.width
        let scaleY = availableHeight / documentBounds.height
        let fitScale = min(scaleX, scaleY) * 0.9
        
        // Apply user zoom
        let finalScale = fitScale * zoom
        
        // Calculate translation to center
        let centerX = canvasSize.width / 2
        let centerY = canvasSize.height / 2
        let boundsCenter = CGPoint(
            x: documentBounds.midX,
            y: documentBounds.midY
        )
        
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(
            x: centerX + offset.width + dragOffset.width,
            y: centerY + offset.height + dragOffset.height
        )
        transform = transform.scaledBy(x: finalScale, y: finalScale)
        transform = transform.translatedBy(x: -boundsCenter.x, y: -boundsCenter.y)
        
        return transform
    }
    
    private func drawGrid(context: GraphicsContext, size: CGSize, transform: CGAffineTransform) {
        var gridContext = context
        gridContext.opacity = 0.2
        
        let gridSpacing: CGFloat = 10 // 10mm grid
        let transformedSpacing = gridSpacing * abs(transform.a)
        
        // Vertical lines
        var x: CGFloat = 0
        while x < size.width {
            let path = Path { p in
                p.move(to: CGPoint(x: x, y: 0))
                p.addLine(to: CGPoint(x: x, y: size.height))
            }
            gridContext.stroke(path, with: .color(.gray), lineWidth: 0.5)
            x += transformedSpacing
        }
        
        // Horizontal lines
        var y: CGFloat = 0
        while y < size.height {
            let path = Path { p in
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: size.width, y: y))
            }
            gridContext.stroke(path, with: .color(.gray), lineWidth: 0.5)
            y += transformedSpacing
        }
    }
    
    private func drawOrigin(context: GraphicsContext, size: CGSize, transform: CGAffineTransform) {
        let origin = CGPoint.zero.applying(transform)
        
        // Draw crosshair
        var originContext = context
        originContext.opacity = 0.5
        
        let crossSize: CGFloat = 10
        
        // Horizontal line
        let hPath = Path { p in
            p.move(to: CGPoint(x: origin.x - crossSize, y: origin.y))
            p.addLine(to: CGPoint(x: origin.x + crossSize, y: origin.y))
        }
        originContext.stroke(hPath, with: .color(.red), lineWidth: 2)
        
        // Vertical line
        let vPath = Path { p in
            p.move(to: CGPoint(x: origin.x, y: origin.y - crossSize))
            p.addLine(to: CGPoint(x: origin.x, y: origin.y + crossSize))
        }
        originContext.stroke(vPath, with: .color(.red), lineWidth: 2)
        
        // Label
        let text = Text("(0,0)")
            .font(.caption)
            .foregroundColor(.red)
        originContext.draw(text, at: CGPoint(x: origin.x + 15, y: origin.y - 15))
    }
    
    private func drawPath(_ svgPath: SVGPath, context: GraphicsContext, transform: CGAffineTransform) {
        var transformedPath = Path(svgPath.cgPath)
        transformedPath = transformedPath.applying(transform)
        
        var pathContext = context
        
        // Draw fill if present
        if let fillColor = svgPath.fillColor {
            pathContext.fill(transformedPath, with: .color(Color(fillColor)))
        }
        
        // Draw stroke if present
        if let strokeColor = svgPath.strokeColor {
            let strokeWidth = max(0.5, svgPath.strokeWidth * abs(transform.a))
            pathContext.stroke(
                transformedPath,
                with: .color(Color(strokeColor)),
                lineWidth: strokeWidth
            )
        }
    }
    
    private func drawBounds(context: GraphicsContext, bounds: CGRect, transform: CGAffineTransform) {
        let transformedRect = bounds.applying(transform)
        let path = Path(transformedRect)
        
        var boundsContext = context
        boundsContext.opacity = 0.5
        boundsContext.stroke(
            path,
            with: .color(.blue),
            style: StrokeStyle(lineWidth: 1, dash: [5, 5])
        )
        
        // Draw dimensions
        let text = Text(String(format: "%.1f × %.1f mm", bounds.width, bounds.height))
            .font(.caption)
            .foregroundColor(.blue)
        boundsContext.draw(
            text,
            at: CGPoint(
                x: transformedRect.midX,
                y: transformedRect.maxY + 15
            )
        )
    }
}

// MARK: - Preview

#Preview {
    VectorPreviewCanvas()
        .environmentObject({
            let importer = SVGImporter()
            // Create a sample document for preview
            let document = SVGDocument()
            document.width = 100
            document.height = 100
            document.viewBox = CGRect(x: 0, y: 0, width: 100, height: 100)
            
            // Add a sample path
            let path = CGMutablePath()
            path.addRect(CGRect(x: 10, y: 10, width: 80, height: 80))
            
            let svgPath = SVGPath(
                cgPath: path,
                strokeWidth: 2.0,
                strokeColor: .black,
                fillColor: nil,
                isClosed: true
            )
            
            document.addPath(svgPath)
            importer.currentDocument = document
            
            return importer
        }())
        .frame(width: 800, height: 600)
}

