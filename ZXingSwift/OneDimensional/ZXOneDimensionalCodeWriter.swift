//
//  ZXOneDimensionalCodeWriter.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 4/7/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

/** Encapsulates functionality common to 1D formats */
public class ZXOneDimensionalCodeWriter : NSObject, ZXWriter {
	
	static var DefaultMargin : Int = 10;
	
	let Black : Bool = true;
	let White : Bool = false;
	
	override init() {
		super.init();
	}
	
	/** Encodes the given contents to a boolean array expressing a one-dimensional barcode.
	 Start and end codes should be included in result, but margins should not be considered.
	Subclasses should override with format-specific behavior. */
	internal func encode (contents: String) throws -> [Bool] {
		return [];
	}
	
	func encode (contents: String, 
		format: ZXBarcodeFormat, 
		width: Int, height: Int, 
		options: ZXEncodingHints?) throws -> ZXBitMatrix {
		
		if (contents.isEmpty) {
			throw ZXWriterError.Unspecified ("Empty contents found!");
		}
		
		if ((width <= 0) || (height <= 0)) {
			throw ZXWriterError.Unspecified ("Negative width or height are not allowed");
		}
		
		var sideMargin = ZXOneDimensionalCodeWriter.DefaultMargin;
		hints?.forEach ({
			switch ($0) {
			case .Margin (let margin):
				sideMargin = margin;
				break;
				
			default:
				break;
			}
		});
		
		let rawBarcode = try encode (contents: contents);
		return render (barcode: rawBarcode, width: width, height: height, margin: sideMargin);
	}
	
	/** - Returns: A BitMatrix representing the given raw barcode, including the provided margins, 
	 where True = Black, False = White
	 */
	internal func render (barcode: [Bool], 
		width: Int, height: Int, 
		margin: Int
		) -> ZXBitMatrix {
		
		let inputWidth = barcode.count;
		let fullWidth = inputWidth + margin;
		
		let outputWidth = max (width, fullWidth);
		let outputHeight = max (1, height);
		
		let multiple = outputWidth / fullWidth;
		let leftPadding = (outputWidth - (inputWidth * multiple)) / 2;
		
		let result = ZXBitMatrix (width: outputWidth, height: outputHeight, value: White);
		
		var outputX = leftPadding;
		
		for inputX in 0..<inputWidth {
			if (barcode [inputX]) {
				result.setRegion (value: Black, left: outputX, top: 0, width: multiple, height: outputHeight);
			}
			
			outputX += multiple;
		}
		
		return result;
	}
}
