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
	
	var mode : ZXMode? = nil;
	var errorCorrectionLevel : ZXErrorCorrectionLevel? = nil;
	var version : ZXVersion? = nil;
	
	var maskPattern : Int = -1;
	
	var matrix : ZXByteMatrix? = nil;
	
	public override init() {
		super.init();
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
		result.append (EOL + "version: \(version as Optional)");
		result.append (EOL + "mask pattern: \(maskPattern)");
		
		result.append (EOL + "matrix: \(matrix?.debugDescription as Optional)");
		
		result.append(EOL + ">>");
		
		return result;
	}
}
