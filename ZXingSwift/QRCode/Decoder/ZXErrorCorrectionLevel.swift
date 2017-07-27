//
//  ZXErrorCorrectionLevel.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 7/19/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

/** Encapsulates the four error-correcion levels defined by the QR Code standard. 
 See ISO 18004:2006, 6.5.1 for details.

 The following Comparison of Levels is taken from [QRStuff - QR Code Error Correction](https://blog.qrstuff.com/2011/12/14/qr-code-error-correction)
   - The lower the error correction level, the less dense the QR code image is, which improves minimum printing/display size.

   - The higher the error correction level, the more damage it can sustain before it becomes unreadable.

   - Level L or Level M represent the best compromise between density and ruggedness for general marketing use.

   - Level Q and Level H are generally recommended for industrial environments where keeping the QR code clean 
   or undamaged will be a challenge.
*/
public enum ZXErrorCorrectionLevel : Int, CustomDebugStringConvertible {
	
	/** L: ~7% correction */
	case L = 0x01;
	
	/** M: ~15% correction */
	case M = 0x00;
	
	/** Q: ~25% correction */
	case Q = 0x03;
	
	/** H: ~30% correction */
	case H = 0x02;
	
	static let defaultLevel : ZXErrorCorrectionLevel = ZXErrorCorrectionLevel.L;
	
	static let values : [ZXErrorCorrectionLevel] = [
		.L, 
		.M, 
		.Q, 
		.H, 
	];
	
	var bits : Int {
		return rawValue;
	}
	
	var ordinal : Int {
		return ZXErrorCorrectionLevel.values.index (of: self) ?? -1;
	}
	
	public var debugDescription: String {
		switch (self) {
		case .L: return "L (7% correction)";
		case .M: return "M (15% correction)";
		case .Q: return "Q (25% correction)";
		case .H: return "H (30% correction)";
		}
	}
	
	/** - parameters: 
	   - lookupBits: Integer containing the two bits encoding a QR Code's error correction level
	
	 - returns: the encoded error correction level */
	static func lookup (for lookupBits: Int) -> ZXErrorCorrectionLevel? {
		return ZXErrorCorrectionLevel (rawValue: lookupBits);
	}
}
