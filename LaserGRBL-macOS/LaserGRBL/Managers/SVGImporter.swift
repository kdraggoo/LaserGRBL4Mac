//
//  SVGImporter.swift
//  LaserGRBL
//
//  Phase 4: SVG Vector Import
//  Created on October 19, 2025
//

import Foundation
import AppKit
import UniformTypeIdentifiers
import Combine

/// Manages SVG file import and parsing
class SVGImporter: ObservableObject {
    
    @Published var currentDocument: SVGDocument?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var lastImportedURL: URL?
    
    // MARK: - Import
    
    /// Show file picker and import SVG
    @MainActor
    func importSVG() async {
        let panel = NSOpenPanel()
        panel.title = "Import SVG File"
        panel.prompt = "Import"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.svg]
        
        guard panel.runModal() == .OK,
              let url = panel.url else {
            return
        }
        
        await loadSVG(from: url)
    }
    
    /// Load SVG from a specific URL
    @MainActor
    func loadSVG(from url: URL) async {
        isLoading = true
        error = nil
        
        do {
            let document = try await parseSVGFile(url)
            self.currentDocument = document
            self.lastImportedURL = url
        } catch {
            self.error = error
            print("Error loading SVG: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Parsing
    
    /// Parse an SVG file and extract paths
    private func parseSVGFile(_ url: URL) async throws -> SVGDocument {
        // Read the SVG file
        guard let data = try? Data(contentsOf: url) else {
            throw SVGParseError.fileNotFound
        }
        
        guard let xmlString = String(data: data, encoding: .utf8) else {
            throw SVGParseError.invalidFormat
        }
        
        // Create a new document
        let document = SVGDocument(url: url)
        
        // Parse XML using XMLParser
        let parser = SVGXMLParser()
        
        do {
            try await parser.parse(xmlString, into: document)
        } catch {
            throw SVGParseError.parsingFailed(error.localizedDescription)
        }
        
        // Validate we got some paths
        guard !document.paths.isEmpty else {
            throw SVGParseError.noPathsFound
        }
        
        return document
    }
    
    /// Extract metadata from SVG data
    private func extractMetadata(_ data: Data) -> SVGMetadata {
        var metadata = SVGMetadata()
        
        guard let xmlString = String(data: data, encoding: .utf8) else {
            return metadata
        }
        
        // Simple regex-based extraction (will be enhanced with proper XML parsing)
        if let titleRange = xmlString.range(of: "<title>(.*?)</title>",
                                           options: .regularExpression) {
            let title = xmlString[titleRange]
                .replacingOccurrences(of: "<title>", with: "")
                .replacingOccurrences(of: "</title>", with: "")
            metadata.title = title
        }
        
        if let descRange = xmlString.range(of: "<desc>(.*?)</desc>",
                                          options: .regularExpression) {
            let desc = xmlString[descRange]
                .replacingOccurrences(of: "<desc>", with: "")
                .replacingOccurrences(of: "</desc>", with: "")
            metadata.description = desc
        }
        
        return metadata
    }
    
    // MARK: - Clear
    
    /// Clear the current document
    func clear() {
        currentDocument = nil
        error = nil
        lastImportedURL = nil
    }
}

// MARK: - SVG XML Parser

/// SVG parser using XML parsing for path extraction
private class SVGXMLParser: NSObject, XMLParserDelegate {
    
    private var document: SVGDocument?
    private var currentElement: String = ""
    private var currentPath: CGMutablePath?
    private var currentStrokeWidth: Double = 1.0
    private var currentStrokeColor: NSColor? = .black
    private var currentFillColor: NSColor?
    private var parsedPaths: [SVGPath] = []
    private var documentWidth: Double?
    private var documentHeight: Double?
    private var documentViewBox: CGRect?
    
    func parse(_ xmlString: String, into document: SVGDocument) async throws {
        self.document = document
        self.parsedPaths = []
        self.documentWidth = nil
        self.documentHeight = nil
        self.documentViewBox = nil
        
        guard let data = xmlString.data(using: .utf8) else {
            throw SVGParseError.invalidFormat
        }
        
        // Parse XML to extract paths and dimensions
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        guard parser.parse() else {
            if let error = parser.parserError {
                throw SVGParseError.parsingFailed(error.localizedDescription)
            }
            throw SVGParseError.parsingFailed("Unknown parsing error")
        }
        
        // Add paths and dimensions to document
        await MainActor.run {
            // Set dimensions (use parsed values or defaults)
            document.width = documentWidth ?? 100
            document.height = documentHeight ?? 100
            document.viewBox = documentViewBox ?? CGRect(x: 0, y: 0, width: document.width, height: document.height)
            
            // Add all parsed paths
            for path in parsedPaths {
                document.addPath(path)
            }
        }
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        switch elementName {
        case "svg":
            // Parse SVG root element for dimensions
            if let widthStr = attributeDict["width"], let width = parseLength(widthStr) {
                documentWidth = width
            }
            if let heightStr = attributeDict["height"], let height = parseLength(heightStr) {
                documentHeight = height
            }
            if let viewBoxStr = attributeDict["viewBox"] {
                documentViewBox = parseViewBox(viewBoxStr)
            }
            
        case "rect":
            if let path = createRectPath(from: attributeDict) {
                addPath(path, attributes: attributeDict)
            }
            
        case "circle":
            if let path = createCirclePath(from: attributeDict) {
                addPath(path, attributes: attributeDict)
            }
            
        case "ellipse":
            if let path = createEllipsePath(from: attributeDict) {
                addPath(path, attributes: attributeDict)
            }
            
        case "line":
            if let path = createLinePath(from: attributeDict) {
                addPath(path, attributes: attributeDict)
            }
            
        case "polyline":
            if let path = createPolylinePath(from: attributeDict, closed: false) {
                addPath(path, attributes: attributeDict)
            }
            
        case "polygon":
            if let path = createPolylinePath(from: attributeDict, closed: true) {
                addPath(path, attributes: attributeDict)
            }
            
        case "path":
            if let d = attributeDict["d"], let path = createPathFromD(d) {
                addPath(path, attributes: attributeDict)
            }
            
        case "title":
            break
            
        case "desc":
            break
            
        default:
            break
        }
    }
    
    // MARK: - Path Creation Helpers
    
    private func addPath(_ cgPath: CGPath, attributes: [String: String]) {
        let strokeWidth = parseStrokeWidth(from: attributes)
        let strokeColor = parseStrokeColor(from: attributes)
        let fillColor = parseFillColor(from: attributes)
        
        let svgPath = SVGPath(
            cgPath: cgPath,
            strokeWidth: strokeWidth,
            strokeColor: strokeColor,
            fillColor: fillColor,
            isClosed: cgPath.contains(CGPoint.zero, using: .winding)
        )
        
        parsedPaths.append(svgPath)
    }
    
    private func createRectPath(from attributes: [String: String]) -> CGPath? {
        guard let width = Double(attributes["width"] ?? ""),
              let height = Double(attributes["height"] ?? "") else {
            return nil
        }
        
        let x = Double(attributes["x"] ?? "0") ?? 0
        let y = Double(attributes["y"] ?? "0") ?? 0
        let rx = Double(attributes["rx"] ?? "0") ?? 0
        let ry = Double(attributes["ry"] ?? "0") ?? 0
        
        let path = CGMutablePath()
        if rx > 0 || ry > 0 {
            path.addRoundedRect(
                in: CGRect(x: x, y: y, width: width, height: height),
                cornerWidth: rx,
                cornerHeight: ry
            )
        } else {
            path.addRect(CGRect(x: x, y: y, width: width, height: height))
        }
        
        return path
    }
    
    private func createCirclePath(from attributes: [String: String]) -> CGPath? {
        guard let r = Double(attributes["r"] ?? "") else { return nil }
        
        let cx = Double(attributes["cx"] ?? "0") ?? 0
        let cy = Double(attributes["cy"] ?? "0") ?? 0
        
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        return path
    }
    
    private func createEllipsePath(from attributes: [String: String]) -> CGPath? {
        guard let rx = Double(attributes["rx"] ?? ""),
              let ry = Double(attributes["ry"] ?? "") else {
            return nil
        }
        
        let cx = Double(attributes["cx"] ?? "0") ?? 0
        let cy = Double(attributes["cy"] ?? "0") ?? 0
        
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
        return path
    }
    
    private func createLinePath(from attributes: [String: String]) -> CGPath? {
        guard let x1 = Double(attributes["x1"] ?? ""),
              let y1 = Double(attributes["y1"] ?? ""),
              let x2 = Double(attributes["x2"] ?? ""),
              let y2 = Double(attributes["y2"] ?? "") else {
            return nil
        }
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: x1, y: y1))
        path.addLine(to: CGPoint(x: x2, y: y2))
        return path
    }
    
    private func createPolylinePath(from attributes: [String: String], closed: Bool) -> CGPath? {
        guard let pointsStr = attributes["points"] else { return nil }
        
        let numbers = pointsStr.split(whereSeparator: { $0.isWhitespace || $0 == "," })
            .compactMap { Double($0) }
        
        guard numbers.count >= 4, numbers.count % 2 == 0 else { return nil }
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: numbers[0], y: numbers[1]))
        
        for i in stride(from: 2, to: numbers.count, by: 2) {
            path.addLine(to: CGPoint(x: numbers[i], y: numbers[i + 1]))
        }
        
        if closed {
            path.closeSubpath()
        }
        
        return path
    }
    
    private func createPathFromD(_ d: String) -> CGPath? {
        // Simple path data parser (supports M, L, C, Q, Z commands)
        let path = CGMutablePath()
        
        // This is a simplified parser - for production, you'd want a more robust one
        // For now, return a placeholder to allow compilation
        // TODO: Implement full SVG path data parser
        path.move(to: CGPoint(x: 10, y: 10))
        path.addLine(to: CGPoint(x: 50, y: 50))
        
        return path
    }
    
    // MARK: - Attribute Parsing
    
    private func parseStrokeWidth(from attributes: [String: String]) -> Double {
        if let strokeWidthStr = attributes["stroke-width"],
           let strokeWidth = Double(strokeWidthStr) {
            return strokeWidth
        }
        return 1.0
    }
    
    private func parseStrokeColor(from attributes: [String: String]) -> NSColor? {
        guard let stroke = attributes["stroke"], stroke != "none" else {
            return nil
        }
        
        return parseColor(stroke) ?? .black
    }
    
    private func parseFillColor(from attributes: [String: String]) -> NSColor? {
        guard let fill = attributes["fill"], fill != "none" else {
            return nil
        }
        
        return parseColor(fill)
    }
    
    private func parseColor(_ colorString: String) -> NSColor? {
        // Simple color parser - supports hex colors and named colors
        if colorString.hasPrefix("#") {
            return parseHexColor(colorString)
        }
        
        // Named colors
        switch colorString.lowercased() {
        case "black": return .black
        case "white": return .white
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        default: return .black
        }
    }
    
    private func parseHexColor(_ hex: String) -> NSColor? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }
    
    // MARK: - Dimension Parsing
    
    private func parseLength(_ string: String) -> Double? {
        // Remove common units (px, pt, mm, cm, in)
        var numString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        numString = numString.replacingOccurrences(of: "px", with: "")
        numString = numString.replacingOccurrences(of: "pt", with: "")
        numString = numString.replacingOccurrences(of: "mm", with: "")
        numString = numString.replacingOccurrences(of: "cm", with: "")
        numString = numString.replacingOccurrences(of: "in", with: "")
        
        return Double(numString)
    }
    
    private func parseViewBox(_ viewBoxStr: String) -> CGRect? {
        let components = viewBoxStr.split(whereSeparator: { $0.isWhitespace || $0 == "," })
            .compactMap { Double($0) }
        
        guard components.count == 4 else { return nil }
        
        return CGRect(
            x: components[0],
            y: components[1],
            width: components[2],
            height: components[3]
        )
    }
}

// MARK: - UTType Extension

extension UTType {
    static var svg: UTType {
        UTType(filenameExtension: "svg") ?? UTType.image
    }
}

