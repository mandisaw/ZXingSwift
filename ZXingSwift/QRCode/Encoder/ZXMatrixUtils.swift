//
//  ZXMatrixUtils.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 7/26/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

extension ZXByteMatrix {
	
	private static let TimingPatternCoordinateIndex : Int = 6;
	
	private static let VersionInfoMaxBitWidth : Int = 18;
	private static let FormatInfoMaxBitWidth : Int = 15;
	
	private static let SeparatorPatternDimensions_Horizontal : (width: Int, height: Int) = (8, 1);
	private static let SeparatorPatternDimensions_Vertical : (width: Int, height: Int) = (1, 7);
	
	private var DarkModulePosition : (column: Int, row: Int) {
		return (8, height - 8);
	}
	
	/** Builds QR Code 2D matrix out of given parameters */
	mutating func build (data: ZXBitMatrix, 
		errorCorrectionLevel ecLevel: ZXErrorCorrectionLevel, 
		version: ZXVersion, 
		maskPattern: Int) throws {
		
		clear();
		
		try encodeFinderPatterns();
		try encodeDarkModule();
		
		try encodePositionAlignmentPatterns (version: version);
		try encodeTimingPatterns();
		
		try encodeFormatInformation (errorCorrectionLevel: ecLevel, maskPattern: maskPattern);
		try encodeVersionInformation (version: version);
		
		try encodeData (data: data, maskPattern: maskPattern);
	}
	
	/** Encodes Finder Patterns, including separators.
	
	 Refer to QR Code specification, ISO 18004:2006, sections 5.3.2 - 5.3.3 
	 for Finder Pattern and Separator placement details. */
	private mutating func encodeFinderPatterns() throws {
		let patternDimensions = ZXByteMatrix.FinderPatternDimensions;
		
		// Top-left corner
		var origin : (x: Int, y: Int) = (0, 0);
		try encodeFinderPattern (columnStart: origin.x, rowStart: origin.y);
		try encodeSeparatorPattern (columnStart: origin.x, rowStart: origin.y + patternDimensions.height, isHorizontal: true); // Horizontal, below pattern
		try encodeSeparatorPattern (columnStart: origin.x + patternDimensions.width, rowStart: origin.y, isHorizontal: false); // Vertical, right of pattern
		
		// Top-right corner
		origin = (width - patternDimensions.width, 0);
		try encodeFinderPattern (columnStart: origin.x, rowStart: origin.y);
		try encodeSeparatorPattern (columnStart: origin.x - 1, rowStart: origin.y + patternDimensions.height, isHorizontal: true); // Horizontal, below pattern
		try encodeSeparatorPattern (columnStart: origin.x - 1, rowStart: origin.y, isHorizontal: false); // Vertical, left of pattern
		
		// Bottom-left corner
		origin = (0, height - patternDimensions.height);
		try encodeFinderPattern (columnStart: origin.x, rowStart: origin.y);
		try encodeSeparatorPattern (columnStart: origin.x, rowStart: origin.y - 1, isHorizontal: true); // Horizontal, above pattern
		try encodeSeparatorPattern (columnStart: origin.x + patternDimensions.width, rowStart: origin.y, isHorizontal: false); // Vertical, right of pattern
	}
	
	private mutating func encodeFinderPattern (columnStart: Int, rowStart: Int) throws {
		let FinderPattern : [Array<Int>] = ZXByteMatrix.FinderPattern;
		
		var column : Int;
		var row : Int;
		
		for (rowOffset, patternRow) in FinderPattern.enumerated() {
			for (colOffset, curr_bit) in patternRow.enumerated() {
				
				column = columnStart + colOffset;
				row = rowStart + rowOffset;
				
				if (isEmpty (column: column, row: row) == false) {
					throw ZXWriterError.Unspecified (
						"Conflicting encoding instructions at position (\(column), \(row)): Finder Pattern");
				}
				
				setValue ((curr_bit != 0), column: column, row: row);
			}
		}
	}
	
	private mutating func encodeSeparatorPattern (columnStart: Int, rowStart: Int, isHorizontal: Bool) throws {
		let separatorDimensions = (isHorizontal ? 
			ZXByteMatrix.SeparatorPatternDimensions_Horizontal : 
			ZXByteMatrix.SeparatorPatternDimensions_Vertical);
		
		var column : Int;
		var row : Int;
		
		for rowOffset in 0..<separatorDimensions.height {
			for colOffset in 0..<separatorDimensions.width {
				
				column = columnStart + colOffset;
				row = rowStart + rowOffset;
				
				if (isEmpty (column: column, row: row) == false) {
					throw ZXWriterError.Unspecified (
						"Conflicting encoding instructions at position (\(column), \(row)): Separator");
				}
				
				setValue (false, column: column, row: row);
			}
		}
	}
	
	/** Encodes always-Black/On/True module at bottom-left, used as offset/filler above Format Information position.
	 
	 Refer to QR Code specification, ISO 18004:2006, section 6.9  
	 (or original standard JIS X0510:2004, section 8.9) for Format Information placement details. */
	private mutating func encodeDarkModule() throws {
		let column : Int = DarkModulePosition.column;
		let row : Int = DarkModulePosition.row;
		
		if (isEmpty (column: column, row: row) == false) {
			throw ZXWriterError.Unspecified (
				"Conflicting encoding instructions at position (\(column), \(row)): Dark Module");
		}
		
		setValue (true, column: column, row: row);
	}
	
	/** Encodes Position Alignment patterns.
	
	 Refer to QR Code specification, ISO 18004:2006, Annex E for Position Alignment Pattern placement details.
	
	 Note that versions prior to 2 do not support position alignment patterns. */
	private mutating func encodePositionAlignmentPatterns (version: ZXVersion) throws {
		if (version.supportsPositionAlignment == false) { return; }
		
		guard let patternPositions = ZXByteMatrix.PositionAlignmentPatternPositions [version.versionNumber] else {
			throw ZXWriterError.Unspecified (
				"No Position Alignment Patterns found for version: \(version.versionNumber)");
		}
		
		for row in patternPositions {
			for column in patternPositions {
				// Exclude any positions that overlap Finder Patterns
				if (isEmpty (column: column, row: row) == false) { continue; }
				
				try encodePositionAlignmentPattern (columnCenter: column, rowCenter: row);
			}
		}
	}
	
	private mutating func encodePositionAlignmentPattern (columnCenter: Int, rowCenter: Int) throws {
		let PositionAlignmentPattern : [Array<Int>] = ZXByteMatrix.PositionAlignmentPattern;
		
		// Offset from to center point
		let columnStart : Int = columnCenter - (PositionAlignmentPattern [0].count / 2);
		let rowStart : Int = rowCenter - (PositionAlignmentPattern.count / 2);
		
		var column : Int;
		var row : Int;
		
		for (rowOffset, patternRow) in PositionAlignmentPattern.enumerated() {
			for (colOffset, curr_bit) in patternRow.enumerated() {
				
				column = columnStart + colOffset;
				row = rowStart + rowOffset;
				
				if (isEmpty (column: column, row: row) == false) {
					throw ZXWriterError.Unspecified (
						"Conflicting encoding instructions at position (\(column), \(row)): Position Alignment Pattern");
				}
				
				setValue ((curr_bit != 0), column: column, row: row);
			}
		}
	}
	
	/** Encodes Timing Patterns.
	
	 Refer to QR Code specification, ISO 18004:2006, section 5.3.4 for Timing Pattern placement details. */
	private mutating func encodeTimingPatterns() throws {
		let TimingCoordinateIndex : Int = ZXByteMatrix.TimingPatternCoordinateIndex;
		
		// Skip positions corresponding to Finder Patterns, including separators
		let startIndex = ZXByteMatrix.FinderPatternDimensions.width + 
			ZXByteMatrix.SeparatorPatternDimensions_Vertical.width;
		
		let endIndex = width - startIndex;
		
		var column : Int;
		var row : Int;
		
		var curr_bit : Bool;
		
		// Timing patterns start with a dark/True/On module, and alternate on/off
		for idx in startIndex..<endIndex {
			curr_bit = (((idx + 1) % 2) != 0);
			
			// Horizontal line
			column = idx;
			row = TimingCoordinateIndex;
			
			if (isEmpty (column: column, row: row)) {
				setValue (curr_bit, column: column, row: row);
			}
			
			// Vertical line
			column = TimingCoordinateIndex;
			row = idx;
			
			if (isEmpty (column: column, row: row)) {
				setValue (curr_bit, column: column, row: row);
			}
		}
	}
	
	/** Encodes data bitstream using the given mask pattern.
	
	 Refer to QR Code specification, ISO 18004:2006, section 6.7.3  
	 (or original standard JIS X0510:2004, section 8.7) for Symbol Character placement details. */
	private mutating func encodeData (data: ZXBitMatrix, maskPattern: Int, 
		shouldSkipMasking: Bool = false) throws {
		
		let colRange = 0..<width;
		let rowRange = 0..<height;
		
		// Starting from bottom-right cell, scan pairs vertically, right to left.
		var colIdx : Int = width - 1;
		var rowIdx : Int = height - 1;
		
		var scanDirection : Bool = true;
		
		let dataBitCount : Int = data.size;
		var dataBitIndex : Int = 0;
		var dataBit : Bool;
		
		while (colRange.contains (colIdx)) {
			// Skip vertical timing pattern
			if (colIdx == ZXByteMatrix.TimingPatternCoordinateIndex) {
				colIdx -= 1;
			}
			
			while (rowRange.contains (rowIdx)) {
				for colIdx in colIdx ... colIdx+1 {
					// Skip this cell if it's already populated
					if (isEmpty (column: colIdx, row: rowIdx) == false) {
						continue;
					}
					
					if (dataBitIndex < dataBitCount) {
						dataBit = data.value (index: dataBitIndex);
						dataBitIndex += 1;
					} else {
						// If no data remains, we pad with False/Zero/Off, as described in the spec
						dataBit = false;
					}
					
					// For debugging purposes, masking may be skipped
					if (try !shouldSkipMasking && 
						ZXMaskUtils.getDataMaskBit (maskPattern: maskPattern, column: colIdx, row: rowIdx)) {
						
						dataBit = !dataBit;
					}
					
					setValue (dataBit, column: colIdx, row: rowIdx);
				}
				
				rowIdx += (scanDirection ? -1 : 1);
			}
			
			// Reverse vertical-scan direction and continue horizontal-scan to the left
			scanDirection = !scanDirection;
			colIdx -= 2;
		}
		
		// Check to ensure that all data has been consumed
		if (dataBitIndex != dataBitCount) {
			throw ZXWriterError.Unspecified (
				"Data bits remaining during encoding: \(dataBitIndex) / \(dataBitCount) consumed");
		}
	}
	
	/** Encodes version information for the given version.
	
	 Refer to QR Code specification, ISO 18004:2006, section 6.10  
	 (or original standard JIS X0510:2004, section 8.10) for Version Information placement details.
	
	 Note that versions prior to 7 do not support embedded version information. */
	private mutating func encodeVersionInformation (version: ZXVersion) throws {
		if (version.supportsEncoding == false) { return; }
		
		var versionInfoBits : ZXBitArray = makeBitArray (value: version.versionNumber, length: 6);
		
		let bchCode : Int = try calculateBCHCode (input: version.versionNumber, 
			poly: ZXByteMatrix.VersionInfoPoly);
		
		versionInfoBits.append (contentsOf: makeBitArray (value: bchCode, length: 12));
		
		let maxBitWidth = ZXByteMatrix.VersionInfoMaxBitWidth;
		
		// Version Info bits should be a standard length
		if (versionInfoBits.count != maxBitWidth) {
			throw ZXWriterError.Unspecified (
				"Error encoding version information: \(versionInfoBits.count) should be 18");
		}
		
		// Encode bits in least-significant-first (i.e. reverse) order
		var bitIndex : Int = versionInfoBits.count - 1;
		var curr_bit : Bool;
		
		for idx in 0..<6 {
			for jdx in 0..<3 {
				curr_bit = versionInfoBits [bitIndex];
				bitIndex -= 1;
				
				// Bottom-left corner
				setValue (curr_bit, column: idx, row: height - 11 + jdx);
				
				// Top-right corner
				setValue (curr_bit, column: width - 11 + jdx, row: idx);
			}
		}
	}
	
	/** Encodes format/type information for the given version.
	
	 Refer to QR Code specification, ISO 18004:2006, section 6.9  
	 (or original standard JIS X0510:2004, section 8.9) for Format Information placement details. */
	private mutating func encodeFormatInformation (
		errorCorrectionLevel ecLevel: ZXErrorCorrectionLevel, maskPattern: Int) throws {
		
		if (ZXQRCode.isValid (maskPattern: maskPattern) == false) {
			throw ZXWriterError.Unspecified (
				"Error encoding type information: Invalid mask pattern");
		}
		
		let formatInfo : Int = (ecLevel.bits << 3) | maskPattern;
		var formatInfoBits : ZXBitArray = makeBitArray (value: formatInfo, length: 5);
		
		let bchCode : Int = try calculateBCHCode (input: formatInfo, 
			poly: ZXByteMatrix.FormatInfoPoly);
		
		formatInfoBits.append (contentsOf: makeBitArray (value: bchCode, length: 10));
		
		let maxBitWidth = ZXByteMatrix.FormatInfoMaxBitWidth;
		
		// Type Info bits should be a standard length
		if (formatInfoBits.count != maxBitWidth) {
			throw ZXWriterError.Unspecified (
				"Error encoding type information: \(formatInfoBits.count) should be 15");
		}
		
		let maskBits : ZXBitArray = makeBitArray (value: ZXByteMatrix.FormatInfoMaskPattern, length: 15);
		
		if (maskBits.count != formatInfoBits.count) {
			throw ZXWriterError.Unspecified (
				"Error encoding type information: Incorrect Mask size, must match Type size");
		}
		
		for (idx, curr_maskBit) in maskBits.enumerated() {
			formatInfoBits [idx] ^= curr_maskBit;
		}
		
		// Encode bits in least-significant-first (i.e. reverse) order
		var bitIndex : Int = formatInfoBits.count - 1;
		var curr_bit : Bool;
		
		let BasePositions = ZXByteMatrix.FormatInfoCoordinates;
		var curr_position : (x: Int, y: Int);
		
		for idx in 0..<15 {
			curr_bit = formatInfoBits [bitIndex];
			bitIndex -= 1;
			
			// Top-left corner
			curr_position = BasePositions [idx];
			setValue (curr_bit, column: curr_position.x, row: curr_position.y);
			
			if (idx < 8) {
				// Top-right corner
				curr_position = (width - 1 - idx, 8);
				setValue (curr_bit, column: curr_position.x, row: curr_position.y);
				
				// Bottom-left corner
				curr_position = (8, height - 7 + (idx - 8));
				setValue (curr_bit, column: curr_position.x, row: curr_position.y);
			}
		}
	}
	
	/** Calculate BCH (Bose-Chaudhuri-Hocquenghem) code for "value" using polynomial "poly". 
	 The BCH code is used for encoding type information and version information.
	
	 Example: Calculation of version information of 7.
	 f(x) is created from 7.
	   - 7 = 000111 in 6 bits
	   - f(x) = x^2 + x^1 + x^0
	
	 g(x) is given by the standard (p. 67)
	   - g(x) = x^12 + x^11 + x^10 + x^9 + x^8 + x^5 + x^2 + 1
	
	 Multiply f(x) by x^(18 - 6)
	   - f'(x) = f(x) * x^(18 - 6)
	   - f'(x) = x^14 + x^13 + x^12
	
	 Calculate the remainder of f'(x) / g(x)
	         x^2
	         __________________________________________________
	   g(x) )x^14 + x^13 + x^12
	         x^14 + x^13 + x^12 + x^11 + x^10 + x^7 + x^4 + x^2
	         --------------------------------------------------
	                              x^11 + x^10 + x^7 + x^4 + x^2
	
	 The remainder is x^11 + x^10 + x^7 + x^4 + x^2
	 Encode it in binary: 110010010100
	 The return value is 0xc94 (1100 1001 0100)
	
	 Since all coefficients in the polynomials are 1 or 0, we can do the calculation by bit
	 operations. We don't care if coefficients are positive or negative.
	*/
	private func calculateBCHCode (input: Int, poly: Int) throws -> Int {
		if (poly == 0) {
			throw ZXWriterError.IllegalArgument (
				"BCH Polynomial cannot be 0");
		}
		
		let polyMSB : Int = poly.bitWidth;
		
		var remainder : Int = input << polyMSB - 1;
		
		// Do the division using exclusive-or operations
		while (remainder.bitWidth >= polyMSB) {
			remainder ^= poly << (remainder.bitWidth - polyMSB);
		}
		
		return remainder;
	}
	
	// MARK: Patterns
	
	/** From Appendix D in JISX0510:2004 (p. 67) */
	fileprivate static let VersionInfoPoly = 0x1f25; // 1 1111 0010 0101
	
	/** From Appendix C in JISX0510:2004 (p.65) */
	fileprivate static let FormatInfoPoly = 0x537;
	fileprivate static let FormatInfoMaskPattern = 0x5412;
	
	/** Coordinates of Format/Type information (top-left corner)
	 
	 Note that column and row index 6 are skipped due to being used for the Timing Pattern */
	fileprivate static let FormatInfoCoordinates : [(x: Int, y: Int)] = [
		( 8, 0 ),
		( 8, 1 ),
		( 8, 2 ),
		( 8, 3 ),
		( 8, 4 ),
		( 8, 5 ),
		( 8, 7 ),
		( 8, 8 ),
		( 7, 8 ),
		( 5, 8 ),
		( 4, 8 ),
		( 3, 8 ),
		( 2, 8 ),
		( 1, 8 ),
		( 0, 8 ),
	];
	
	fileprivate static let FinderPatternDimensions : (width: Int, height: Int) = 
		(ZXByteMatrix.FinderPattern [0].count, ZXByteMatrix.FinderPattern.count);
	
	fileprivate static let FinderPattern : [Array<Int>] = [
		[ 1, 1, 1, 1, 1, 1, 1 ],
		[ 1, 0, 0, 0, 0, 0, 1 ],
		[ 1, 0, 1, 1, 1, 0, 1 ],
		[ 1, 0, 1, 1, 1, 0, 1 ],
		[ 1, 0, 1, 1, 1, 0, 1 ],
		[ 1, 0, 0, 0, 0, 0, 1 ],
		[ 1, 1, 1, 1, 1, 1, 1 ],
	];
	
	fileprivate static let PositionAlignmentPattern : [Array<Int>] = [
		[ 1, 1, 1, 1, 1 ],
		[ 1, 0, 0, 0, 1 ],
		[ 1, 0, 1, 0, 1 ],
		[ 1, 0, 0, 0, 1 ],
		[ 1, 1, 1, 1, 1 ],
	];
	
	/** Center coordinates of Position Alignment Patterns, indexed by version number. 
	
	 Patterns are to be arranged with center points at each position indicated by an NxN matrix, made up of the given 
	 row/column coordinates.
	
	 **Example:** Version 7 indicates a 3x3 arrangement of potential patterns, with center coordinate values 6, 22, 38:
	````
	---------------------------------------
	|  (6, 6)   |  (22,  6)  |  (38,  6) |
	---------------------------------------
	|  (6, 22)  |  (22, 22)  |  (38, 22) |
	---------------------------------------
	|  (6, 38)  |  (22, 38)  |  (38, 38) |
	---------------------------------------
	````
	After discarding any positions that would conflict with Finder Patterns, the final pattern arrangement:
	````
	--------------------------------------
	|  ------  |  (22,  6)  |   ------  |
	--------------------------------------
	| (6, 22)  |  (22, 22)  |  (38, 22) |
	--------------------------------------
	|  ------  |  (22, 38)  |  (38, 38) |
	--------------------------------------
	````
	
	 Note that Position Alignment patterns are only supported in version 2+.
	 Refer to QR Code specification, ISO 18004:2006, Annex E for Position Alignment Pattern placement details. */
	fileprivate static let PositionAlignmentPatternPositions : Dictionary<Int, Array<Int>> = [
		 1: [ ],  // Version 1 - Position Alignment not supported
		 2: [  6, 18 ],  // Version 2
		 3: [  6, 22 ],  // Version 3
		 4: [  6, 26 ],  // Version 4
		 5: [  6, 30 ],  // Version 5
		 6: [  6, 34 ],  // Version 6
		 7: [  6, 22, 38 ],  // Version 7
		 8: [  6, 24, 42 ],  // Version 8
		 9: [  6, 26, 46 ],  // Version 9
		10: [  6, 28, 50 ],  // Version 10
		11: [  6, 30, 54 ],  // Version 11
		12: [  6, 32, 58 ],  // Version 12
		13: [  6, 34, 62 ],  // Version 13
		14: [  6, 26, 46, 66 ],  // Version 14
		15: [  6, 26, 48, 70 ],  // Version 15
		16: [  6, 26, 50, 74 ],  // Version 16
		17: [  6, 30, 54, 78 ],  // Version 17
		18: [  6, 30, 56, 82 ],  // Version 18
		19: [  6, 30, 58, 86 ],  // Version 19
		20: [  6, 34, 62, 90 ],  // Version 20
		21: [  6, 28, 50, 72,  94 ],  // Version 21
		22: [  6, 26, 50, 74,  98 ],  // Version 22
		23: [  6, 30, 54, 78, 102 ],  // Version 23
		24: [  6, 28, 54, 80, 106 ],  // Version 24
		25: [  6, 32, 58, 84, 110 ],  // Version 25
		26: [  6, 30, 58, 86, 114 ],  // Version 26
		27: [  6, 34, 62, 90, 118 ],  // Version 27
		28: [  6, 26, 50, 74,  98, 122 ],  // Version 28
		29: [  6, 30, 54, 78, 102, 126 ],  // Version 29
		30: [  6, 26, 52, 78, 104, 130 ],  // Version 30
		31: [  6, 30, 56, 82, 108, 134 ],  // Version 31
		32: [  6, 34, 60, 86, 112, 138 ],  // Version 32
		33: [  6, 30, 58, 86, 114, 142 ],  // Version 33
		34: [  6, 34, 62, 90, 118, 146 ],  // Version 34
		35: [  6, 30, 54, 78, 102, 126, 150 ],  // Version 35
		36: [  6, 24, 50, 76, 102, 128, 154 ],  // Version 36
		37: [  6, 28, 54, 80, 106, 132, 158 ],  // Version 37
		38: [  6, 32, 58, 84, 110, 136, 162 ],  // Version 38
		39: [  6, 26, 54, 82, 110, 138, 166 ],  // Version 39
		40: [  6, 30, 58, 86, 114, 142, 170 ],  // Version 40
	];
}
