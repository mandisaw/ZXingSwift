//
//  ZXMultiFormatWriter.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 4/7/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

/** Factory class linking requested BarcodeFormat with an appropriate Writer */
public final class ZXMultiFormatWriter : NSObject {
	
	public static func encode (contents: String, 
		format: ZXBarcodeFormat, 
		width: Int, height: Int, 
		options: ZXEncodingHints? = nil
		) throws -> ZXBitMatrix {
		
		var writer : ZXWriter? = nil;
		
		switch (format) {
/*		case .Aztec:
			writer = ZXAztecWriter();
			break;
			
		case .Code39:
			writer = ZXCode39Writer();
			break;
			
		case .Code93:
			writer = ZXCode93Writer();
			break;
		
		case .Code128:
			writer = ZXCode128Writer();
			break;
			
		case .DataMatrix:
			writer = ZXDataMatrixWriter();
			break;
			
		case .EAN8:
			writer = ZXEAN8Writer();
			break;
			
		case .EAN13:
			writer = ZXEAN13Writer();
			break;
		
		case .ITF:
			writer = ZXITFWriter();
			break;
			
		case .MaxiCode:
			writer = ZXMaxiCodeWriter();
			break;
			
		case .PDF417:
			writer = ZXPDF417Writer();
			break;
			
		case .QR_Code:
			writer = ZXQRCodeWriter();
			break;
			
		case .RSS14:
			writer = ZXRSS14Writer();
			break;
			
		case .RSS_Expanded:
			writer = ZXRSSExpandedWriter();
			break;
			
		case .UPC_A:
			writer = ZXUPCAWriter();
			break;
			
		case .UPC_E:
			writer = ZXUPCEWriter();
			break;
*/			
		case .Codabar:
			writer = ZXCodabarWriter();
			break;
			
		default:
			break;
		}
		
		if let writer = writer {
			return try writer.encode (contents: contents, format: format, 
				width: width, height: height, options: options);
			
		} else {
			throw ZXWriterError.InvalidFormat ("No encoder available for format: \(format.debugDescription)");
		}
	}
}
