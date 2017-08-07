//
//  ZXQRCode.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 7/25/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

public final class ZXQRCode : NSObject {
	
	static let MaskPatternsCount : Int = 8;
	static let InvalidMaskPattern : Int = -1;
	
	var mode : ZXMode? = nil;
	var errorCorrectionLevel : ZXErrorCorrectionLevel? = nil;
	var version : ZXVersion? = nil;
	
	var maskPattern : Int = -1;
	
	var matrix : ZXByteMatrix? = nil;
	
	init (mode: ZXMode? = nil, version: ZXVersion? = nil, errorCorrectionLevel ecLevel: ZXErrorCorrectionLevel? = nil) {
		super.init();
		
		self.mode = mode;
		self.version = version;
		self.errorCorrectionLevel = ecLevel;
	}
	
	static func isValid (maskPattern: Int) -> Bool {
		return ((maskPattern >= 0) && 
			(maskPattern < MaskPatternsCount));
	}
	
	public override var debugDescription: String {
		var result = String();
		
		result.append("<<");
		result.append (EOL + "mode: \(mode as Optional)");
		result.append (EOL + "error correction level: \(errorCorrectionLevel as Optional)");
		result.append (EOL + "version: \(version?.versionNumber as Optional)");
		result.append (EOL + "mask pattern: \(maskPattern)");
		
		result.append (EOL + "matrix: \(matrix?.debugDescription ?? "nil")");
		
		result.append(EOL + ">>");
		
		return result;
	}
}
