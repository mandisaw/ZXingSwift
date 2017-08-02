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
	static var DefaultMargin : Int = 4;
	
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
		
		let sourceSize : (width: Int, height: Int) = (source.width, source.height);
		let qrSize : (width: Int, height: Int) = (sourceSize.width + (margin * 2), sourceSize.height + (margin * 2));
		let targetSize : (width: Int, height: Int) = (Swift.max (width, qrSize.width), Swift.max (height, qrSize.height));
		
		let multiple : Int = Swift.min (targetSize.width / qrSize.width, targetSize.height / qrSize.height);
		
		/* Padding includes both the quiet zone and the extra white pixels to accommodate the requested dimensions.
		 If, for example, the source code size is 25 x 25, the resulting QR code will be 33 x 33, including the quiet zone.
		 If the requested size is 200 x 160, the multiple will be 4, for a QR code of 132 x 132. 
		 This implementation adds additional padding to go from the raw QR code size of 132 x 132, up to the target size of 200 x 160.
		*/
		let leftPadding : Int = (targetSize.width - (sourceSize.width * multiple)) / 2;
		let topPadding : Int = (targetSize.height - (sourceSize.height * multiple)) / 2;
		
		let result = ZXBitMatrix (width: targetSize.width, height: targetSize.height, value: White);
		
		let inputWidth = sourceSize.width;
		let inputHeight = sourceSize.height;
		
		var outputX : Int = leftPadding;
		var outputY : Int = topPadding;
		
		for inputY in 0..<inputHeight {
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
