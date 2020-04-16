//
//  ZXCodabarWriter.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 4/7/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

/** Encoder for Codabar barcode format */
public class ZXCodabarWriter : ZXOneDimensionalCodeWriter {
	
	var DefaultGuard : String { return String (ZXCodabarReader.GuardCharacters.first ?? "A"); }
	var DefaultLocale : Locale { return ZXCodabarWriter.Locale_US; }
	
	override func encode (contents: String) throws -> [Bool] {
		var source = contents.uppercased (with: DefaultLocale);
		
		if (contents.count < 2) {
			// Missing guard characters, so tentatively add default guards
			source = DefaultGuard + source + DefaultGuard;
		
		} else {
			// Verify input and transform/add guard characters as needed
			source = try verifyGuardCharacters (source);
		}
		
		let encodedLength = try calculateEncodedLength (source);
		let CodabarEncoding = getCodabarEncoding (source);
		
		var result = Array<Bool> (repeating: White, count: encodedLength);
		
		var globalPosition : Int = 0;
		var localPosition : Int;
		var curr_bit : Int;
		var color : Bool;
		
		for (characterIndex, characterCode) in CodabarEncoding.enumerated() {
			// Each character is encoded by a 7-bit sequence
			
			localPosition = 0;
			curr_bit = 0;
			color = Black;
			
			while (curr_bit < 7) {
				result [globalPosition] = color;
				globalPosition += 1;
				
				// Check for color-flip
				if ((((characterCode >> (6 - curr_bit)) & 1) == 0) || 
					(localPosition == 1)) {
					
					color = !color;
					curr_bit += 1;
					
					localPosition = 0;
				
				} else {
					localPosition += 1;
				}
			}
			
			if (characterIndex < CodabarEncoding.count - 1) {
				result [globalPosition] = White;
				globalPosition += 1;
			}
		}
		
		return result;
	}
	
	private func verifyGuardCharacters (_ input: String) throws -> String {
		let GuardCharacterSet = ZXCodabarReader.GuardCharacterSet;
		var source = ZXCodabarReader.transformAlternateGuardCharacters (input);
		
		if let firstCharacter = source.unicodeScalars.first, 
			let lastCharacter = source.unicodeScalars.last {
			
			let isValidStart = GuardCharacterSet.contains (firstCharacter);
			let isValidEnd = GuardCharacterSet.contains (lastCharacter);
			
			if ((isValidStart && !isValidEnd) || 
				(!isValidStart && isValidEnd)) {
				
				// Mismatched, or missing one guard character
				throw ZXWriterError.InvalidFormat("Invalid guard characters!: \(input)");
			
			} else if (!isValidStart && !isValidEnd) {
				// Missing both guard characters
				source = DefaultGuard + source + DefaultGuard;
			}
		}
		
		return source;
	}
	
	private func calculateEncodedLength (_ input: String) throws -> Int {
		var result : Int = 0;
		
		try input.unicodeScalars.forEach ({
			let length = try ZXCodabarReader.encodedCharacterLength ($0);
			result += length;
		});
		
		// Blanks are placed between each character
		result += input.count - 1;
		
		return result;
	}
	
	private func getCodabarEncoding (_ input: String) -> [Int] {
		var result = Array<Int>();
		
		let EncodingMap = ZXCodabarReader.AlphabetEncodingMap;
		
		input.unicodeScalars.forEach ({
			if let currEncoding = EncodingMap [$0] {
				result.append (currEncoding);
			}
		});
		
		return result;
	}
}
