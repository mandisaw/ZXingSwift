//
//  ZXQRCodeWriter.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 8/2/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

public class ZXQRCodeWriter : NSObject, ZXWriter {
	
	static var DefaultErrorCorrectionLevel = ZXErrorCorrectionLevel.L;
	static var DefaultMargin : Int = 0;
	
	let Black : Bool = true;
	let White : Bool = false;
	
	override init() {
		super.init();
	}
	
	func encode (contents: String, 
		format: ZXBarcodeFormat, 
		width: Int, height: Int, 
		options: ZXEncodingHints?) throws -> ZXBitMatrix {
		
		if (contents.isEmpty) {
			throw ZXWriterError.Unspecified ("Empty contents found!");
		}
		
		if (format != ZXBarcodeFormat.QR_Code) {
			throw ZXWriterError.InvalidFormat ("Only QR Code format is supported");
		}
		
		if ((width <= 0) || (height <= 0)) {
			throw ZXWriterError.Unspecified ("Negative width or height are not allowed");
		}
		
		let errorCorrectionLevel = (options?.errorCorrection as? ZXErrorCorrectionLevel) ?? 
			ZXQRCodeWriter.DefaultErrorCorrectionLevel;
		
		let margin : Int = ZXQRCodeWriter.DefaultMargin;
		
		let qrCode : ZXQRCode = try ZXEncoder.encode (content: contents, 
			errorCorrectionLevel: errorCorrectionLevel, options: options);
		
		return try render (barcode: qrCode, width: width, height: height, margin: margin);
	}
	
	/** - Returns: A BitMatrix representing the given QR barcode, including the provided margins 
	 where True = Black, False = White
	 */
	internal func render (barcode: ZXQRCode, 
		width: Int, height: Int, 
		margin: Int
		) throws -> ZXBitMatrix {
		
		guard let source : ZXByteMatrix = barcode.matrix else {
			throw ZXWriterError.IllegalArgument (
				"Error rendering barcode: Missing QR Code matrix information, did you forget to encode?");
		}
		
		let inputWidth : Int = source.width;
		let inputHeight : Int = source.height;
		
		let qrWidth : Int = inputWidth + (margin * 2);
		let qrHeight : Int = inputHeight + (margin * 2);
		
		let outputWidth : Int = max (width, qrWidth);
		let outputHeight : Int = max (height, qrHeight);
		
		let multiple : Int = min (outputWidth / qrWidth, outputHeight / qrHeight);
		
		/* Padding includes both the quiet zone and the extra white pixels to accommodate the requested dimensions.
		 If, for example, the source code size is 25 x 25, the resulting QR code will be 33 x 33, including the quiet zone.
		 If the requested size is 200 x 160, the multiple will be 4, for a QR code of 132 x 132. 
		 This implementation adds additional padding to go from the raw QR code size of 132 x 132, up to the target size of 200 x 160.
		*/
		let leftPadding : Int = (outputWidth - (inputWidth * multiple)) / 2;
		let topPadding : Int = (outputHeight - (inputHeight * multiple)) / 2;
		
		let result = ZXBitMatrix (width: outputWidth, height: outputHeight, value: White);
		
		var outputX : Int = leftPadding;
		var outputY : Int = topPadding;
		
		for inputY in 0..<inputHeight {
			outputX = leftPadding;
			
			for inputX in 0..<inputWidth {
				if (source.value (column: inputX, row: inputY) == 1) {
					result.setRegion (value: Black, left: outputX, top: outputY, width: multiple, height: multiple);
				}
				
				outputX += multiple;
			}
			
			outputY += multiple;
		}
		
		return result;
	}		
}
