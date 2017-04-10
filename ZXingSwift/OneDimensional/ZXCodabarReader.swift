//
//  ZXCodabarReader.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 4/10/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

/** Decoder for Codabar barcode format */
public class ZXCodabarReader : NSObject {
	
	/** These represent the encodings of allowed characters, as patterns of wide and narrow bars.
	 The 7 least-significant bits of each int correspond to the pattern of wide and narrow, with 
	 1s representing "wide" and 0s representing narrow.
	 */
	static let AlphabetEncodingMap : [UnicodeScalar : Int] = [
		"0" : 0x003, 
		"1" : 0x006, 
		"2" : 0x009, 
		"3" : 0x060, 
		"4" : 0x012, 
		"5" : 0x042, 
		"6" : 0x021, 
		"7" : 0x024, 
		"8" : 0x030, 
		"9" : 0x048, 
		"-" : 0x00C, 
		"$" : 0x018, 
		":" : 0x045, 
		"/" : 0x051, 
		"." : 0x054, 
		"+" : 0x015, 
		"A" : 0x01A, 
		"B" : 0x029, 
		"C" : 0x00B, 
		"D" : 0x00E, 
	];
	
	static let GuardCharacters : [UnicodeScalar] = [
		"A", 
		"B", 
		"C", 
		"D"
	];
	
	static let AlternateGuardCharacters : [String : String] = [
		"T" : "A", 
		"N" : "B", 
		"*" : "C", 
		"E" : "D", 
	];
	
	static let GuardCharacterSet : CharacterSet = {
		let source = ZXCodabarReader.GuardCharacters;
		
		if #available(iOS 10.3, *) {
			return CharacterSet (source);
			
		} else {
			var result = CharacterSet();
			
			for curr_character in source {
				result.insert (curr_character);
			}
			
			return result;
		}
	}();
	
	static func transformAlternateGuardCharacters (_ input: String) -> String {
		var result : String = String (input);
		
		for (source, target) in ZXCodabarReader.AlternateGuardCharacters {
			result = result.replacingOccurrences (of: source, with: target);
		}
		
		return result;
	}
	
	static func encodedCharacterLength (_ input: UnicodeScalar) throws -> Int {
		switch (input) {
		case "0"..."9":
			return 9;
		
		case "-", "$":
			return 9;
			
		case "/", ":", "+", ".":
			return 10;
			
		default:
			break;
		}
		
		if (GuardCharacters.contains (input)) {
			return 10;
		}
		
		let strInput = String (input);
		if (AlternateGuardCharacters.keys.contains (strInput)) {
			return 10;
		}
		
		throw ZXWriterError.InvalidFormat ("Invalid character found: \(input)");
	}
}
