//
//  ZXCharacterSetECI.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 7/19/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

/** Encapsulates a Character Set ECI, according to "Extended Channel Interpretations" 5.3.1.1 of ISO 18004 */
public enum ZXCharacterSetECI : CustomDebugStringConvertible {
	case ASCII;
	case Cp437;
	
	case ISO8859_1;
	case ISO8859_2;
	case ISO8859_3;
	case ISO8859_4;
	case ISO8859_5;
	case ISO8859_6;
	case ISO8859_7;
	case ISO8859_8;
	case ISO8859_9;
	case ISO8859_10;
	case ISO8859_11;
	case ISO8859_13;
	case ISO8859_14;
	case ISO8859_15;
	case ISO8859_16;
	
	case Cp1250;
	case Cp1251;
	case Cp1252;
	case Cp1256;
	
	case UnicodeBig_Unmarked;
	case UTF8;
	
	case Big5;
	case SJIS;
	case GB18030;
	case EUC_KR;
	
	static let defaultCharacterSet : ZXCharacterSetECI = ZXCharacterSetECI.ISO8859_1;
	
	static let values : [ZXCharacterSetECI] = [
		.ASCII,
		.Cp437,
		
		.ISO8859_1,
		.ISO8859_2,
		.ISO8859_3,
		.ISO8859_4,
		.ISO8859_5,
		.ISO8859_6,
		.ISO8859_7,
		.ISO8859_8,
		.ISO8859_9,
		.ISO8859_10,
		.ISO8859_11,
		.ISO8859_13,
		.ISO8859_14,
		.ISO8859_15,
		.ISO8859_16,
		
		.Cp1250,
		.Cp1251,
		.Cp1252,
		.Cp1256,
		
		.UnicodeBig_Unmarked,
		.UTF8,
		
		.Big5,
		.SJIS,
		.GB18030,
		.EUC_KR,
	];
	
	var name : String {
		switch (self) {
		case .ASCII: return "US-ASCII";
		case .Cp437: return "Cp437";
		
		case .ISO8859_1: return "ISO-8859-1";
		case .ISO8859_2: return "ISO-8859-2";
		case .ISO8859_3: return "ISO-8859-3";
		case .ISO8859_4: return "ISO-8859-4";
		case .ISO8859_5: return "ISO-8859-5";
		case .ISO8859_6: return "ISO-8859-6";
		case .ISO8859_7: return "ISO-8859-7";
		case .ISO8859_8: return "ISO-8859-8";
		case .ISO8859_9: return "ISO-8859-9";
		case .ISO8859_10: return "ISO-8859-10";
		case .ISO8859_11: return "ISO-8859-11";
		case .ISO8859_13: return "ISO-8859-13";
		case .ISO8859_14: return "ISO-8859-14";
		case .ISO8859_15: return "ISO-8859-15";
		case .ISO8859_16: return "ISO-8859-16";
		
		case .Cp1250: return "windows-1250";
		case .Cp1251: return "windows-1251";
		case .Cp1252: return "windows-1252";
		case .Cp1256: return "windows-1256";
		
		case .UnicodeBig_Unmarked: return "UnicodeBig";
		case .UTF8: return "UTF-8";
			
		case .SJIS: return "Shift_JIS";
		case .Big5: return "Big-5";
		case .GB18030: return "GB2312";
		case .EUC_KR: return "EUC-KR";
		}
	}
	
	var aliases : [String]? {
		switch (self) {
		case .UnicodeBig_Unmarked:
			return ["UTF-16BE"];
			
		case .GB18030:
			return ["EUC_CN", "GBK"];
			
		default:
			return nil;
		}
	}
	
	var value : Int? {
		return lookupIds.first;
	}
	
	var lookupIds : [Int] {
		switch (self) {
		case .ASCII: return [27, 170];
		case .Cp437: return [0, 2];
		
		case .ISO8859_1: return [1, 3];
		case .ISO8859_2: return [4];
		case .ISO8859_3: return [5];
		case .ISO8859_4: return [6];
		case .ISO8859_5: return [7];
		case .ISO8859_6: return [8];
		case .ISO8859_7: return [9];
		case .ISO8859_8: return [10];
		case .ISO8859_9: return [11];
		case .ISO8859_10: return [12];
		case .ISO8859_11: return [13];
		case .ISO8859_13: return [15];
		case .ISO8859_14: return [16];
		case .ISO8859_15: return [17];
		case .ISO8859_16: return [18];
		
		case .Cp1250: return [21];
		case .Cp1251: return [22];
		case .Cp1252: return [23];
		case .Cp1256: return [24];
		
		case .UnicodeBig_Unmarked: return [25];
		case .UTF8: return [26];
			
		case .SJIS: return [20];
		case .Big5: return [28];
		case .GB18030: return [29];
		case .EUC_KR: return [30];
		}
	}
	
	var encoding : String.Encoding? {
		switch (self) {
		case .ASCII: return String.Encoding.ascii;
		
		case .ISO8859_1: return String.Encoding.isoLatin1;
		case .ISO8859_2: return String.Encoding.isoLatin2;
		
		case .SJIS: return String.Encoding.shiftJIS;
		
		case .Cp1250: return String.Encoding.windowsCP1250;
		case .Cp1251: return String.Encoding.windowsCP1251;
		case .Cp1252: return String.Encoding.windowsCP1252;
		
		case .UnicodeBig_Unmarked: return String.Encoding.utf16;
		case .UTF8: return String.Encoding.utf8;
		
		default: return nil;
		}
	}
	
	static var supportedEncodings : [String.Encoding] {
		var result : [String.Encoding] = Array<String.Encoding>();
		
		values.forEach ({
			if let encoding = $0.encoding {
				result.append (encoding);
			}
		});
		
		return result;
	}
	
	public var debugDescription: String {
		return name;
	}
	
	func matches (lookupId test: Int) -> Bool {
		return self.lookupIds.contains (test);
	}
	
	func matches (name test: String) -> Bool {
		var result = TextUtils.isTextEqual (name, test);
		
		if (result == false), 
			let aliases = aliases {
			
			result = aliases.contains (where: {
				TextUtils.isTextEqual ($0, test);
			});
		}
		
		return result;
	}
	
	func matches (encoding test: String.Encoding) -> Bool {
		if let encoding = encoding {
			return (test == encoding);
		} else {
			return false;
		}
	}
	
	static func lookup (lookupId test: Int) throws -> ZXCharacterSetECI? {
		if ((test < 0) || (test >= 900)) {
			throw ZXWriterError.InvalidFormat(
				"Error parsing barcode: Invalid Character Set ECI value");
		}
		
		return ZXCharacterSetECI.values.first (where: {
			$0.matches (lookupId: test);
		});
	}
	
	static func lookup (name test: String) -> ZXCharacterSetECI? {
		return ZXCharacterSetECI.values.first (where: {
			$0.matches (name: test);
		});
	}
	
	static func lookup (encoding test: String.Encoding) -> ZXCharacterSetECI? {
		return ZXCharacterSetECI.values.first (where: {
			$0.matches (encoding: test);
		});
	}
}
