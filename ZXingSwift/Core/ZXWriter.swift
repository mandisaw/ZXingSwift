//
//  ZXWriter.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 4/7/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

/**
 The base protocol for all objects which encode/generate a barcode image.
 */
protocol ZXWriter {
	
	/** Encode a barcode using the default settings.
	 - parameter contents: The contents to encode in the barcode
	 - parameter format: The barcode format to generate
	 - parameter width: Preferred width in pixels
	 - parameter height: Preferred height in pixels
	 - parameter options: Additional parameters to supply to the encoder (optional)
	
	 - Throws: WriterError if contents cannot be encoded legally in a format
	
	 - Returns: BitMatrix representing encoded barcode image
	*/
	func encode (contents: String, 
	             format: ZXBarcodeFormat, 
	             width: Int, 
	             height: Int, 
	             options hints: ZXEncodingHints?
		) throws -> ZXBitMatrix;
}

extension ZXWriter {
	static var Locale_US : Locale { return Locale (identifier: "en_US_POSIX"); }
}
