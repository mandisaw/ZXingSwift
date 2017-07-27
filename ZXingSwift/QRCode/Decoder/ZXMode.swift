//
//  ZXMode.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 7/19/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation


/** Encapsulates the various modes in which data can be encoded to bits, as defined by the QR Code standard. 
 See ISO 18004:2006, 6.4.1, Tables 2 and 3 for details. */
public enum ZXMode : Int, CustomDebugStringConvertible {
	/** Not exactly a mode, but included for completeness */
	case Terminator = 0x00;
	
	case Numeric = 0x01;
	case Alphanumeric = 0x02;
	case Byte = 0x04;
	
	/** Character counts do not apply in ECI mode */
	case ECI = 0x07;
	
	/** Not supported */
	case StructuredAppend = 0x03;
	
	case Kanji = 0x08;
	
	/** See GBT 18284-2000 - "Hanzi" is a transliteration of this mode name. 
	 This mode may not be defined for all countries. */
	case Hanzi = 0x0D;
	
	case FNC1_FirstPosition = 0x05;
	case FNC1_SecondPosition = 0x09;
	
	var bits : Int {
		return rawValue;
	}
	
	public var debugDescription: String {
		switch (self) {
		case .Terminator: return "Terminator";
			
		case .Numeric: return "Numeric";
		case .Alphanumeric: return "Alphanumeric";
		case .Byte: return "Byte";
		
		case .ECI: return "ECI";
		case .StructuredAppend: return "Structured Append";
			
		case .Kanji: return "Kanji";
		case .Hanzi: return "Hanzi";
			
		case .FNC1_FirstPosition: return "FNC1 First";
		case .FNC1_SecondPosition: return "FNC1 Second";
		}
	}
	
	private var CharacterCountBits : [Int] {
		switch (self) {
		case .Numeric:
			return [10, 12, 14];
			
		case .Alphanumeric:
			return [9, 11, 13];
			
		case .Byte:
			return [8, 16, 16];
			
		case .Terminator, 
			 .ECI, 
			 .StructuredAppend, 
			 .FNC1_FirstPosition, 
			 .FNC1_SecondPosition:
			return [0, 0, 0];
			
		case .Kanji, 
		     .Hanzi:
			return [8, 10, 12];
		}
	}
	
	func characterCountBits (version: ZXVersion) -> Int {
		let number : Int = version.versionNumber;
		let offset : Int;
		
		if (number <= 9) {
			offset = 0;
		} else if (number <= 26) {
			offset = 1;
		} else {
			offset = 2;
		}
		
		return CharacterCountBits [offset];
	}
	
	private static let NumericSupportedCharacterSet : CharacterSet = CharacterSet (charactersIn: "0"..."9");
	
	private static let AlphanumericSupportedCharacterSet : CharacterSet = {
		var result = CharacterSet();
		
		result.insert (charactersIn: "0"..."9");
		result.insert (charactersIn: "A"..."Z");
		result.insert (charactersIn: "\u{20}\u{24}\u{25}\u{2A}\u{2B}\u{2D}\u{2E}\u{2F}\u{3A}"); // (space), plus $%*+-./:
		
		return result;
	}();
	
	func supportsContent (_ text: String) -> Bool {
		switch (self) {
		case .Kanji:
			// Kanji mode supports only 16-bit characters that may be safely encoded using Shift-JIS 
			let encoding = String.Encoding.shiftJIS;
			
			if (text.canBeConverted (to: encoding) && 
				(text.lengthOfBytes (using: encoding) % 2 == 0)) {
				
				return (text.unicodeScalars.count == text.utf16.count);
			} else {
				return false;
			}
			
		case .Numeric:
			let charSet = ZXMode.NumericSupportedCharacterSet;
			
			for char in text.unicodeScalars {
				if (charSet.contains (char) == false) {
					return false;
				}
			}
			
			return true;
			
		case .Alphanumeric:
			let charSet = ZXMode.AlphanumericSupportedCharacterSet;
			
			for char in text.unicodeScalars {
				if (charSet.contains (char) == false) {
					return false;
				}
			}
			
			return true;
			
		case .Byte:
			return true;
			
		default:
			return false;
		}
	}
	
	/** - parameters: 
	   - lookupBits: Integer containing the four bits encoding a QR Code's data mode
	
	 - returns: the encoded mode */
	static func lookup (for lookupBits: Int) -> ZXMode? {
		return ZXMode (rawValue: lookupBits);
	}
}
