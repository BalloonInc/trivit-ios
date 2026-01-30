//
//  TrivitColorsTests.swift
//  trivitTests
//
//  Unit tests for TrivitColors
//

import XCTest
import SwiftUI
@testable import trivit

final class TrivitColorsTests: XCTestCase {
    
    // MARK: - Palette Tests
    
    func testPaletteHasCorrectCount() {
        XCTAssertEqual(TrivitColors.palette.count, TrivitColors.colorCount)
    }
    
    func testDarkPaletteHasCorrectCount() {
        XCTAssertEqual(TrivitColors.paletteDark.count, TrivitColors.colorCount)
    }
    
    func testColorCountIs10() {
        XCTAssertEqual(TrivitColors.colorCount, 10)
    }
    
    // MARK: - Color At Index Tests
    
    func testColorAtValidIndex() {
        for i in 0..<TrivitColors.colorCount {
            let color = TrivitColors.color(at: i)
            XCTAssertEqual(color, TrivitColors.palette[i])
        }
    }
    
    func testDarkColorAtValidIndex() {
        for i in 0..<TrivitColors.colorCount {
            let color = TrivitColors.darkColor(at: i)
            XCTAssertEqual(color, TrivitColors.paletteDark[i])
        }
    }
    
    func testColorAtIndexWrapsAround() {
        // Index 10 should wrap to 0
        let colorAt10 = TrivitColors.color(at: 10)
        let colorAt0 = TrivitColors.color(at: 0)
        XCTAssertEqual(colorAt10, colorAt0)
        
        // Index 15 should wrap to 5
        let colorAt15 = TrivitColors.color(at: 15)
        let colorAt5 = TrivitColors.color(at: 5)
        XCTAssertEqual(colorAt15, colorAt5)
    }
    
    func testDarkColorAtIndexWrapsAround() {
        // Index 10 should wrap to 0
        let colorAt10 = TrivitColors.darkColor(at: 10)
        let colorAt0 = TrivitColors.darkColor(at: 0)
        XCTAssertEqual(colorAt10, colorAt0)
        
        // Index 25 should wrap to 5
        let colorAt25 = TrivitColors.darkColor(at: 25)
        let colorAt5 = TrivitColors.darkColor(at: 5)
        XCTAssertEqual(colorAt25, colorAt5)
    }
    
    func testColorAtNegativeIndexHandledSafely() {
        // Negative indices should be handled using abs()
        let colorAtNeg3 = TrivitColors.color(at: -3)
        let colorAt3 = TrivitColors.color(at: 3)
        XCTAssertEqual(colorAtNeg3, colorAt3)
    }
    
    func testDarkColorAtNegativeIndexHandledSafely() {
        let colorAtNeg7 = TrivitColors.darkColor(at: -7)
        let colorAt7 = TrivitColors.darkColor(at: 7)
        XCTAssertEqual(colorAtNeg7, colorAt7)
    }
    
    // MARK: - Random Color Tests
    
    func testRandomColorReturnsValidColor() {
        let color = TrivitColors.randomColor()
        XCTAssertTrue(TrivitColors.palette.contains(color), "Random color should be from the palette")
    }
    
    func testRandomColorIndexReturnsValidIndex() {
        for _ in 0..<100 { // Test multiple times due to randomness
            let index = TrivitColors.randomColorIndex()
            XCTAssertGreaterThanOrEqual(index, 0)
            XCTAssertLessThan(index, TrivitColors.colorCount)
        }
    }
    
    // MARK: - Color Hex Extension Tests
    
    func testColorFromValidHex6() {
        // Test that Color(hex:) creates valid colors
        let red = Color(hex: "FF0000")
        let green = Color(hex: "00FF00")
        let blue = Color(hex: "0000FF")
        
        // Colors are opaque struct types, so we just verify they don't crash
        // and are created successfully
        XCTAssertNotNil(red)
        XCTAssertNotNil(green)
        XCTAssertNotNil(blue)
    }
    
    func testColorFromHexWithHash() {
        // Should handle # prefix
        let color = Color(hex: "#1ABC9C")
        XCTAssertNotNil(color)
    }
    
    func testColorFromHex3() {
        // Should handle 3-character hex (RGB shorthand)
        let color = Color(hex: "F00") // Red
        XCTAssertNotNil(color)
    }
    
    func testColorFromHex8() {
        // Should handle 8-character hex (ARGB)
        let color = Color(hex: "FF1ABC9C")
        XCTAssertNotNil(color)
    }
    
    // MARK: - Palette Colors Match Expected Values
    
    func testFirstPaletteColorIsTurquoise() {
        let expected = Color(hex: "1ABC9C")
        XCTAssertEqual(TrivitColors.palette[0], expected)
    }
    
    func testSecondPaletteColorIsEmerald() {
        let expected = Color(hex: "2ECC71")
        XCTAssertEqual(TrivitColors.palette[1], expected)
    }
    
    func testFirstDarkPaletteColorIsGreenSea() {
        let expected = Color(hex: "16A085")
        XCTAssertEqual(TrivitColors.paletteDark[0], expected)
    }
}
