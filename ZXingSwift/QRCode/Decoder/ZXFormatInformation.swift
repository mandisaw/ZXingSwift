//
//  ZXFormatInformation.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 7/20/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

/** Encapsulates a QR Code's format information, including the data mask used, and error correction level. */
public struct ZXFormatInformation {
	
	private static let FormatInfoMaskQR = 0x5412;
	
	/** Hamming distance of the masked codes is 7, by construction.
	 So a weight/distance under 3 bits corresponds to a match. */
	private static let FormatInfoDecodeTolerance = 3;
	
	let errorCorrectionLevel : ZXErrorCorrectionLevel;
	let dataMask : UInt8;
	
	/** Attempts to match the given format data against a known table of format codes, accounting for 
	 potential data-corruption.
	
	 Note that some QR Codes do not actually mask format information, contrary to standard behavior, 
	 so this also attempts to mask the given pattern, in the event of a failed-match.
	
	 - parameters:
	   - infoA: Format data, with mask still applied
	   - infoB: Second copy of format data, both are checked simultaneously
	
	 - returns: Format information for this QR Code, or nil if data does not seem to match any known pattern 
	 - throws: ZXWriterError if error-correction level could not be parsed correctly */
	init? (formatInfoA infoA: Int, formatInfoB infoB: Int) throws {
		if let maskedResult = try ZXFormatInformation.decode (formatInfoA: infoA, formatInfoB: infoB) {
			self = maskedResult;
			
		} else if let result = try ZXFormatInformation.decode (formatInfoA: infoA, formatInfoB: infoB, applyMask: true) {
			self = result;
		
		} else {
			return nil;
		}
	}
	
	private init? (formatInfo: Int) throws {
		// Bits 3, 4
		var maskedBits : Int = (formatInfo >> 3) & 0x03;
		guard let tempECLevel = ZXErrorCorrectionLevel.lookup (for: maskedBits) else {
			throw ZXWriterError.IllegalArgument (
				"Failed to parse Error Correction Level");
		}
		
		self.errorCorrectionLevel = tempECLevel;
		
		// Lower 3 bits
		maskedBits = (formatInfo & 0x07);
		self.dataMask = UInt8 (maskedBits);
	}
	
	internal static func differentBitCount (_ a: Int, _ b: Int) -> Int {
		return (a ^ b).nonzeroBitCount;
	}
	
	/** Find the lookup table entry with the fewest bits differing (Hamming weight < tolerance) */
	private static func decode (formatInfoA: Int, formatInfoB: Int, 
		applyMask: Bool = false
		) throws -> ZXFormatInformation? {
		
		let infoA = (applyMask ? (formatInfoA ^ FormatInfoMaskQR) : formatInfoA);
		let infoB = (applyMask ? (formatInfoB ^ FormatInfoMaskQR) : formatInfoB);
		
		var result : (lookupId: Int, formatInfo: Int)? = nil;
		
		var bestMatch : (weight: Int, entry: (Int, Int)) = (Int.max, (0, 0));
		var curr_weight : Int;
		
		for curr_entry in FormatInfoDecodeTable {
			let lookupId = curr_entry.lookupId;
			
			// Check for an exact match
			if ((lookupId == infoA) || 
				(lookupId == infoB)) {
				
				result = curr_entry;
				break;
			}
			
			// Check input for a corrupted match
			curr_weight = differentBitCount (infoA, lookupId);
			if (curr_weight < bestMatch.weight) {
				bestMatch = (curr_weight, curr_entry);
			}
			
			// Check other input for a corrupted match
			if (infoA != infoB) {
				curr_weight = differentBitCount (infoB, lookupId);
				if (curr_weight < bestMatch.weight) {
					bestMatch = (curr_weight, curr_entry);
				}
			}
		}
		
		if ((result == nil) && 
			(bestMatch.weight <= FormatInfoDecodeTolerance)) {
			
			result = bestMatch.entry;
		}
		
		if let result = result {
			return try ZXFormatInformation (formatInfo: result.formatInfo);
		} else {
			return nil;
		}
	}
	
	/** Refer to QR Code specification, ISO 18004:2006, Annex C, Table C.1 */
	private static let FormatInfoDecodeTable : [(lookupId: Int, formatInfo: Int)] = [
		(0x5412, 0x00),
		(0x5125, 0x01),
		(0x5E7C, 0x02),
		(0x5B4B, 0x03),
		(0x45F9, 0x04),
		(0x40CE, 0x05),
		(0x4F97, 0x06),
		(0x4AA0, 0x07),
		(0x77C4, 0x08),
		(0x72F3, 0x09),
		(0x7DAA, 0x0A),
		(0x789D, 0x0B),
		(0x662F, 0x0C),
		(0x6318, 0x0D),
		(0x6C41, 0x0E),
		(0x6976, 0x0F),
		(0x1689, 0x10),
		(0x13BE, 0x11),
		(0x1CE7, 0x12),
		(0x19D0, 0x13),
		(0x0762, 0x14),
		(0x0255, 0x15),
		(0x0D0C, 0x16),
		(0x083B, 0x17),
		(0x355F, 0x18),
		(0x3068, 0x19),
		(0x3F31, 0x1A),
		(0x3A06, 0x1B),
		(0x24B4, 0x1C),
		(0x2183, 0x1D),
		(0x2EDA, 0x1E),
		(0x2BED, 0x1F),
	];
}
