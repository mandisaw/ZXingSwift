//
//  ZXVersion.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 7/20/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

/** Encapsulates a QR Code's Version information. Refer to QR Code specification, ISO 18004:2006, Annex D. */
public final class ZXVersion : NSObject {
	
	private static let ValidVersionNumbers : ClosedRange<Int> = 1...40;
	
	/** Hamming distance of the version codes is 7, by construction.
	So a weight/distance under 3 bits corresponds to a match. */
	private static let VersionInfoDecodeTolerance = 3;
	
	let versionNumber : Int;
	let alignmentPatternCenters : [Int];
	
	let errorCorrectionBlocks : [ZXErrorCorrectionLevel : ECBlocks];
	let totalCodewords : Int;
	
	private init (versionNumber: Int, alignmentCenters: [Int], _ ecBlocks: [ZXErrorCorrectionLevel : ECBlocks]) {
		self.versionNumber = versionNumber;
		self.alignmentPatternCenters = alignmentCenters;
		self.errorCorrectionBlocks = ecBlocks;
		
		var tempTotalCodewords = 0;
		
		if let firstBlock = ecBlocks.first {
			let ecCodewordsPerBlock = firstBlock.value.ecCodewordsPerBlock;
			
			for curr_block in firstBlock.value.ecBlocks {
				tempTotalCodewords += (curr_block.blockCount * 
					(curr_block.dataCodewords + ecCodewordsPerBlock));
			};
		}
		
		self.totalCodewords = tempTotalCodewords;
		
		super.init();
	}
	
	/** Note that only Version numbers 7 and up support encoded version information */
	var supportsEncoding : Bool {
		return (versionNumber >= 7);
	}
	
	/** Note that only Version numbers 2 and up support encoded position alignment patterns */
	var supportsPositionAlignment : Bool {
		return (versionNumber >= 2);
	}
	
	func getDimension() -> Int {
		return 17 + (4 * versionNumber);
	}
	
	func errorCorrectionBlocks (ecLevel: ZXErrorCorrectionLevel) -> ECBlocks {
		return errorCorrectionBlocks [ecLevel]!;
	}
	
	/** Deduces version information purely from QR Code dimensions
	 - parameters: 
	   - dimension: Barcode dimension, in modules 
	 - returns: Version for a QR Code of the given dimension
	 - throws: ZXWriterError, if given dimension is not a multiple of 4, plus 1
	*/
	static func getProvisionalVersion (dimension: Int) throws -> ZXVersion {
		if ((dimension % 4) != 1) {
			throw ZXWriterError.InvalidFormat(
				"Dimension (in modules) must be a multiple of 4, plus 1");
		}
		
		do {
			let versionNumber : Int = (dimension - 17) / 4;
			return try lookupVersion (versionNumber: versionNumber);
			
		} catch {
			throw ZXWriterError.InvalidFormat(
				"Could not detect version from dimension: \(error.localizedDescription)");
		}
	}
	
	static func lookupVersion (versionNumber: Int) throws -> ZXVersion {
		if (ValidVersionNumbers.contains (versionNumber) == false) {
			throw ZXWriterError.IllegalArgument(
				"Version number must fall between 1 and 40, inclusive");
		}
		
		return Versions [versionNumber - 1];
	}
	
	static func decode (versionInfo: Int) throws -> ZXVersion? {
		var result : (lookupId: Int, rawVersionNumber: Int)? = nil;
		
		var bestMatch : (weight: Int, entry: (Int, Int)) = (Int.max, (0, 0));
		var curr_weight : Int;
		
		for curr_entry in VersionDecodeTable {
			let lookupId = curr_entry.lookupId;
			
			// Check for an exact match
			if (lookupId == versionInfo) {
				result = curr_entry;
				break;
			}
			
			// Check input for a corrupted match
			curr_weight = ZXFormatInformation.differentBitCount (versionInfo, lookupId);
			if (curr_weight < bestMatch.weight) {
				bestMatch = (curr_weight, curr_entry);
			}
		}
		
		if ((result == nil) && 
			(bestMatch.weight <= VersionInfoDecodeTolerance)) {
			
			result = bestMatch.entry;
		}
		
		if let result = result {
			let versionNumber = result.rawVersionNumber + 7;
			return try lookupVersion (versionNumber: versionNumber);
			
		} else {
			return nil;
		}
	}
	
	/** Builds a function pattern used in decoding operations.
	 Refer to QR Code specification, ISO 18004:2006, Annex E. */
	func buildFunctionPattern() -> ZXBitMatrix {
		let dimension = getDimension();
		let bitMatrix = ZXBitMatrix (width: dimension, height: dimension);
		
		// Finder patterns (including separator & format)
		bitMatrix.setRegion (value: true, left: 0, top: 0, width: 9, height: 9); // Top-left
		bitMatrix.setRegion (value: true, left: dimension - 8, top: 0, width: 8, height: 9); // Top-right
		bitMatrix.setRegion (value: true, left: 0, top: dimension - 8, width: 9, height: 8); // Bottom-left
		
		// Alignment patterns
		let maxX = alignmentPatternCenters.count;
		let maxY = maxX;
		var top : Int;
		var left : Int;
		
		for row in 0..<maxY {
			top = alignmentPatternCenters [row] - 2;
			
			for col in 0..<maxX {
				// No alignment patterns near the three finder patterns
				if ((row == 0) && ((col == 0) || (col == maxX - 1))) { continue; }
				if ((row == maxY - 1) && (col == 0)) { continue; }
				
				left = alignmentPatternCenters [col] - 2;
				bitMatrix.setRegion (value: true, left: left, top: top, width: 5, height: 5);
			}
		}
		
		// Timing patterns
		bitMatrix.setRegion (value: true, left: 6, top: 9, width: 1, height: dimension - 17); // Vertical
		bitMatrix.setRegion (value: true, left: 9, top: 6, width: dimension - 17, height: 1); // Horizontal
		
		// Version info, for those versions that support it
		if (versionNumber > 6) {
			bitMatrix.setRegion (value: true, left: dimension - 11, top: 0, width: 3, height: 6); // Top-right
			bitMatrix.setRegion (value: true, left: 0, top: dimension - 11, width: 6, height: 3); // Bottom-left
		}
		
		return bitMatrix;
	}
	
	func maxDataBytesSupported (errorCorrectionLevel ecLevel: ZXErrorCorrectionLevel) -> Int {
		let numECBytes = errorCorrectionBlocks (ecLevel: ecLevel).totalECCodewords;
		return totalCodewords - numECBytes;
	}
	
	func maxDataBitsSupported (errorCorrectionLevel ecLevel: ZXErrorCorrectionLevel) -> Int {
		return maxDataBytesSupported (errorCorrectionLevel: ecLevel) * 8;
	}
	
	/** - Return: True, if this version supports encoding the given content, using this mode and error correction level */
	func willSupportEncoding (mode: ZXMode, errorCorrectionLevel ecLevel: ZXErrorCorrectionLevel, 
		header: ZXBitArray, data: ZXBitArray) -> Bool {
		
		let numBitsNeeded = mode.characterCountBits (version: self) + header.count + data.count;
		return (numBitsNeeded + 7) <= maxDataBitsSupported (errorCorrectionLevel: ecLevel);
	}
	
	/** Searches for the lowest version (smallest size, in modules) of QR Code 
	 that can support encoding the given content, using this mode and error correction level.
	 - parameters:
	   - requestedVersion:		If provided, search will begin at the requested version
	
	 - returns: Nil, if no suitable version could be found with the given parameters
	*/
	static func lookupSupportedVersion (requestedVersion: ZXVersion? = nil, 
		mode: ZXMode, errorCorrectionLevel ecLevel: ZXErrorCorrectionLevel, 
		header: ZXBitArray, data: ZXBitArray) -> ZXVersion? {
		
		let minVersionNumber : Int = requestedVersion?.versionNumber ?? 0;
		
		return Versions.suffix (from: minVersionNumber).first (where: {
			return $0.willSupportEncoding (mode: mode, errorCorrectionLevel: ecLevel, 
				header: header, data: data);
		});
	}
	
	/** Generates error-correction capacity information for the given block ID and error-correction level.
	 Refer to QR Code specification, ISO 18004:2006, section 6.5.1, Table 9 for details on bit stream error correction */
	func getErrorCorrectionCapacity (blockId: Int, 
		errorCorrectionLevel ecLevel: ZXErrorCorrectionLevel) 
		throws -> (dataBytesCapacity: Int, ecBytesCapacity: Int) {
		
		let numTotalBytes = totalCodewords;
		let numDataBytes = maxDataBytesSupported (errorCorrectionLevel: ecLevel);
		let numReedSolomonBlocks = errorCorrectionBlocks (ecLevel: ecLevel).totalBlockCount;
		
		if ((blockId < 0) || (blockId >= numReedSolomonBlocks)) {
			throw ZXWriterError.IllegalArgument (
				"Error generating error-correction: Block ID out of bounds");
		}
		
		// Two parallel attempts at generating capacity info are made, and then the results selected based on block ID
		let numRSBlocks_group2 = numTotalBytes % numReedSolomonBlocks;
		let numRSBlocks_group1 = numReedSolomonBlocks - numRSBlocks_group2;
		
		let numTotalBytes_group1 = numTotalBytes / numReedSolomonBlocks;
		let numTotalBytes_group2 = numTotalBytes_group1 + 1;
		
		let numDataBytes_group1 = numDataBytes / numReedSolomonBlocks;
		let numDataBytes_group2 = numDataBytes_group1 + 1;
		
		let numECBytes_group1 = numTotalBytes_group1 - numDataBytes_group1;
		let numECBytes_group2 = numTotalBytes_group2 - numDataBytes_group2;
		
		// Perform sanity checks
		if (numECBytes_group1 != numECBytes_group2) {
			throw ZXWriterError.Unspecified (
				"Error generating error-correction: Mismatched error-correction bytes \(numECBytes_group1) vs \(numECBytes_group2)");
		}
		
		if (numReedSolomonBlocks != numRSBlocks_group1 + numRSBlocks_group2) {
			throw ZXWriterError.Unspecified (
				"Error generating error-correction: Mismatched Reed-Solomon blocks \(numRSBlocks_group1) vs \(numRSBlocks_group2)");
		}
		
		let calculatedTotalBytes = 
			((numDataBytes_group1 + numECBytes_group1) * numRSBlocks_group1) + 
				((numDataBytes_group2 + numECBytes_group2) * numRSBlocks_group2);
		
		if (numTotalBytes != calculatedTotalBytes) {
			throw ZXWriterError.Unspecified (
				"Error generating error-correction: Mismatched total bytes \(calculatedTotalBytes) vs \(numTotalBytes)");
		}
		
		if (blockId < numRSBlocks_group1) {
			return (numDataBytes_group1, numECBytes_group1);
		} else {
			return (numDataBytes_group2, numECBytes_group2);
		}
	}
	
	// MARK: Helpers
	
	/** Encapsulates the parameters for one error-correction block in one symbol version.
	 
	 This includes the number of data codewords, and the number of times a block with these parameters 
	 is used consecutively in the QR Code version's format. */
	struct ECB {
		let blockCount : Int;
		let dataCodewords : Int;
		
		init (count: Int, words: Int) {
			self.blockCount = count;
			self.dataCodewords = words;
		}
	}
	
	/** Encapsulates a set of error-correction blocks in one symbol version.
	 
	 Most versions will use blocks of differing sizes within one version, so this encapsulates 
	 the parameters for each set of blocks. 
	
	 It also holds the number of error-correction codewords per-block, since it will be the same
	 across all blocks within a version. */
	struct ECBlocks {
		let ecCodewordsPerBlock : Int;
		let ecBlocks : [ECB];
		
		init (wordsPerBlock: Int, blocks: ECB...) {
			self.ecCodewordsPerBlock = wordsPerBlock;
			self.ecBlocks = blocks;
		}
		
		var totalBlockCount : Int {
			var total : Int = 0;
			
			ecBlocks.forEach ({
				total += $0.blockCount;
			});
			
			return total;
		}
		
		var totalECCodewords : Int {
			return ecCodewordsPerBlock * totalBlockCount;
		}
	}
	
	/** Each entry corresponds to the raw version bits, where version = index + 7.
	
	 Note that only Version numbers 7 through 40 support version information, 
	 so decoding bits are only provided for that range. 
	
	 (Reference: QR Code specification, ISO 18004:2006, 6.10, Version Information.) */
	private static let VersionDecodeTable : [(lookupId: Int, rawVersionNumber: Int)] = [
		(0x07C94, 0x00), 
		(0x085BC, 0x01), 
		(0x09A99, 0x02), 
		(0x0A4D3, 0x03), 
		(0x0BBF6, 0x04), 
		(0x0C762, 0x05), 
		(0x0D847, 0x06), 
		(0x0E60D, 0x07), 
		(0x0F928, 0x08), 
		(0x10B78, 0x09), 
		(0x1145D, 0x0A), 
		(0x12A17, 0x0B), 
		(0x13532, 0x0C), 
		(0x149A6, 0x0D), 
		(0x15683, 0x0E), 
		(0x168C9, 0x0F), 
		(0x177EC, 0x10), 
		(0x18EC4, 0x11), 
		(0x191E1, 0x12), 
		(0x1AFAB, 0x13), 
		(0x1B08E, 0x14), 
		(0x1CC1A, 0x15), 
		(0x1D33F, 0x16), 
		(0x1ED75, 0x17), 
		(0x1F250, 0x18), 
		(0x209D5, 0x19), 
		(0x216F0, 0x1A), 
		(0x228BA, 0x1B), 
		(0x2379F, 0x1C), 
		(0x24B0B, 0x1D), 
		(0x2542E, 0x1E), 
		(0x26A64, 0x1F), 
		(0x27541, 0x20), 
		(0x28C69, 0x21), 
	];
	
	/** QR Code version information
	 (Reference: QR Code specification, ISO 18004:2006, 6.5.1, Table 9) */
	private static let Versions : [ZXVersion] = [
		ZXVersion (versionNumber: 1, alignmentCenters: [ ], [
			.L : ECBlocks (wordsPerBlock: 7, blocks: ECB (count: 1, words: 19)),
			.M : ECBlocks (wordsPerBlock: 10, blocks: ECB (count: 1, words: 16)),
			.Q : ECBlocks (wordsPerBlock: 13, blocks: ECB (count: 1, words: 13)),
			.H : ECBlocks (wordsPerBlock: 17, blocks: ECB (count: 1, words: 9))
		]),
		ZXVersion (versionNumber: 2, alignmentCenters: [ 6, 18 ], [
			.L : ECBlocks (wordsPerBlock: 10, blocks: ECB (count: 1, words: 34)),
			.M : ECBlocks (wordsPerBlock: 16, blocks: ECB (count: 1, words: 28)),
			.Q : ECBlocks (wordsPerBlock: 22, blocks: ECB (count: 1, words: 22)),
			.H : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 1, words: 16))
		]),
		ZXVersion (versionNumber: 3, alignmentCenters: [ 6, 22 ], [
			.L : ECBlocks (wordsPerBlock: 15, blocks: ECB (count: 1, words: 55)),
			.M : ECBlocks (wordsPerBlock: 26, blocks: ECB (count: 1, words: 44)),
			.Q : ECBlocks (wordsPerBlock: 18, blocks: ECB (count: 2, words: 17)),
			.H : ECBlocks (wordsPerBlock: 22, blocks: ECB (count: 2, words: 13))
		]),
		ZXVersion (versionNumber: 4, alignmentCenters: [ 6, 26 ], [
			.L : ECBlocks (wordsPerBlock: 20, blocks: ECB (count: 1, words: 80)),
			.M : ECBlocks (wordsPerBlock: 18, blocks: ECB (count: 2, words: 32)),
			.Q : ECBlocks (wordsPerBlock: 26, blocks: ECB (count: 2, words: 24)),
			.H : ECBlocks (wordsPerBlock: 16, blocks: ECB (count: 4, words: 9))
		]),
		ZXVersion (versionNumber: 5, alignmentCenters: [ 6, 30 ], [
			.L : ECBlocks (wordsPerBlock: 26, blocks: ECB (count: 1, words: 108)),
			.M : ECBlocks (wordsPerBlock: 24, blocks: ECB (count: 2, words: 43)),
			.Q : ECBlocks (wordsPerBlock: 18, blocks: ECB (count: 2, words: 15), ECB (count: 2, words: 16)),
			.H : ECBlocks (wordsPerBlock: 22, blocks: ECB (count: 2, words: 11), ECB (count: 2, words: 12))
		]),
		ZXVersion (versionNumber: 6, alignmentCenters: [ 6, 34 ], [
			.L : ECBlocks (wordsPerBlock: 18, blocks: ECB (count: 2, words: 68)),
			.M : ECBlocks (wordsPerBlock: 16, blocks: ECB (count: 4, words: 27)),
			.Q : ECBlocks (wordsPerBlock: 24, blocks: ECB (count: 4, words: 19)),
			.H : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 4, words: 15))
		]),
		ZXVersion (versionNumber: 7, alignmentCenters: [ 6, 22, 38 ], [
			.L : ECBlocks (wordsPerBlock: 20, blocks: ECB (count: 2, words: 78)),
			.M : ECBlocks (wordsPerBlock: 18, blocks: ECB (count: 4, words: 31)),
			.Q : ECBlocks (wordsPerBlock: 18, blocks: ECB (count: 2, words: 14), ECB (count: 4, words: 15)),
			.H : ECBlocks (wordsPerBlock: 26, blocks: ECB (count: 4, words: 13), ECB (count: 1, words: 14))
		]),
		ZXVersion (versionNumber: 8, alignmentCenters: [ 6, 24, 42 ], [
			.L : ECBlocks (wordsPerBlock: 24, blocks: ECB (count: 2, words: 97)),
			.M : ECBlocks (wordsPerBlock: 22, blocks: ECB (count: 2, words: 38), ECB (count: 2, words: 39)),
			.Q : ECBlocks (wordsPerBlock: 22, blocks: ECB (count: 4, words: 18), ECB (count: 2, words: 19)),
			.H : ECBlocks (wordsPerBlock: 26, blocks: ECB (count: 4, words: 14), ECB (count: 2, words: 15))
		]),
		ZXVersion (versionNumber: 9, alignmentCenters: [ 6, 26, 46 ], [
			.L : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 2, words: 116)),
			.M : ECBlocks (wordsPerBlock: 22, blocks: ECB (count: 3, words: 36), ECB (count: 2, words: 37)),
			.Q : ECBlocks (wordsPerBlock: 20, blocks: ECB (count: 4, words: 16), ECB (count: 4, words: 17)),
			.H : ECBlocks (wordsPerBlock: 24, blocks: ECB (count: 4, words: 12), ECB (count: 4, words: 13))
		]),
		ZXVersion (versionNumber: 10, alignmentCenters: [ 6, 28, 50 ], [
			.L : ECBlocks (wordsPerBlock: 18, blocks: ECB (count: 2, words: 68), ECB (count: 2, words: 69)),
			.M : ECBlocks (wordsPerBlock: 26, blocks: ECB (count: 4, words: 43), ECB (count: 1, words: 44)),
			.Q : ECBlocks (wordsPerBlock: 24, blocks: ECB (count: 6, words: 19), ECB (count: 2, words: 20)),
			.H : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 6, words: 15), ECB (count: 2, words: 16))
		]),
		ZXVersion (versionNumber: 11, alignmentCenters: [ 6, 30, 54 ], [
			.L : ECBlocks (wordsPerBlock: 20, blocks: ECB (count: 4, words: 81)),
			.M : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 1, words: 50), ECB (count: 4, words: 51)),
			.Q : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 4, words: 22), ECB (count: 4, words: 23)),
			.H : ECBlocks (wordsPerBlock: 24, blocks: ECB (count: 3, words: 12), ECB (count: 8, words: 13))
		]),
		ZXVersion (versionNumber: 12, alignmentCenters: [ 6, 32, 58 ], [
			.L : ECBlocks (wordsPerBlock: 24, blocks: ECB (count: 2, words: 92), ECB (count: 2, words: 93)),
			.M : ECBlocks (wordsPerBlock: 22, blocks: ECB (count: 6, words: 36), ECB (count: 2, words: 37)),
			.Q : ECBlocks (wordsPerBlock: 26, blocks: ECB (count: 4, words: 20), ECB (count: 6, words: 21)),
			.H : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 7, words: 14), ECB (count: 4, words: 15))
		]),
		ZXVersion (versionNumber: 13, alignmentCenters: [ 6, 34, 62 ], [
			.L : ECBlocks (wordsPerBlock: 26, blocks: ECB (count: 4, words: 107)),
			.M : ECBlocks (wordsPerBlock: 22, blocks: ECB (count: 8, words: 37), ECB (count: 1, words: 38)),
			.Q : ECBlocks (wordsPerBlock: 24, blocks: ECB (count: 8, words: 20), ECB (count: 4, words: 21)),
			.H : ECBlocks (wordsPerBlock: 22, blocks: ECB (count: 12, words: 11), ECB (count: 4, words: 12))
		]),
		ZXVersion (versionNumber: 14, alignmentCenters: [ 6, 26, 46, 66 ], [
			.L : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 3, words: 115), ECB (count: 1, words: 116)),
			.M : ECBlocks (wordsPerBlock: 24, blocks: ECB (count: 4, words: 40), ECB (count: 5, words: 41)),
			.Q : ECBlocks (wordsPerBlock: 20, blocks: ECB (count: 11, words: 16), ECB (count: 5, words: 17)),
			.H : ECBlocks (wordsPerBlock: 24, blocks: ECB (count: 11, words: 12), ECB (count: 5, words: 13))
		]),
		ZXVersion (versionNumber: 15, alignmentCenters: [ 6, 26, 48, 70 ], [
			.L : ECBlocks (wordsPerBlock: 22, blocks: ECB (count: 5, words: 87), ECB (count: 1, words: 88)),
			.M : ECBlocks (wordsPerBlock: 24, blocks: ECB (count: 5, words: 41), ECB (count: 5, words: 42)),
			.Q : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 5, words: 24), ECB (count: 7, words: 25)),
			.H : ECBlocks (wordsPerBlock: 24, blocks: ECB (count: 11, words: 12), ECB (count: 7, words: 13))
		]),
		ZXVersion (versionNumber: 16, alignmentCenters: [ 6, 26, 50, 74 ], [
			.L : ECBlocks (wordsPerBlock: 24, blocks: ECB (count: 5, words: 98), ECB (count: 1, words: 99)),
			.M : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 7, words: 45), ECB (count: 3, words: 46)),
			.Q : ECBlocks (wordsPerBlock: 24, blocks: ECB (count: 15, words: 19), ECB (count: 2, words: 20)),
			.H : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 3, words: 15), ECB (count: 13, words: 16))
		]),
		ZXVersion (versionNumber: 17, alignmentCenters: [ 6, 30, 54, 78 ], [
			.L : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 1, words: 107), ECB (count: 5, words: 108)),
			.M : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 10, words: 46), ECB (count: 1, words: 47)),
			.Q : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 1, words: 22), ECB (count: 15, words: 23)),
			.H : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 2, words: 14), ECB (count: 17, words: 15))
		]),
		ZXVersion (versionNumber: 18, alignmentCenters: [ 6, 30, 56, 82 ], [
			.L : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 5, words: 120), ECB (count: 1, words: 121)),
			.M : ECBlocks (wordsPerBlock: 26, blocks: ECB (count: 9, words: 43), ECB (count: 4, words: 44)),
			.Q : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 17, words: 22), ECB (count: 1, words: 23)),
			.H : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 2, words: 14), ECB (count: 19, words: 15))
		]),
		ZXVersion (versionNumber: 19, alignmentCenters: [ 6, 30, 58, 86 ], [
			.L : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 3, words: 113), ECB (count: 4, words: 114)),
			.M : ECBlocks (wordsPerBlock: 26, blocks: ECB (count: 3, words: 44), ECB (count: 11, words: 45)),
			.Q : ECBlocks (wordsPerBlock: 26, blocks: ECB (count: 17, words: 21), ECB (count: 4, words: 22)),
			.H : ECBlocks (wordsPerBlock: 26, blocks: ECB (count: 9, words: 13), ECB (count: 16, words: 14))
		]),
		ZXVersion (versionNumber: 20, alignmentCenters: [ 6, 34, 62, 90 ], [
			.L : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 3, words: 107), ECB (count: 5, words: 108)),
			.M : ECBlocks (wordsPerBlock: 26, blocks: ECB (count: 3, words: 41), ECB (count: 13, words: 42)),
			.Q : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 15, words: 24), ECB (count: 5, words: 25)),
			.H : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 15, words: 15), ECB (count: 10, words: 16))
		]),
		ZXVersion (versionNumber: 21, alignmentCenters: [ 6, 28, 50, 72, 94 ], [
			.L : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 4, words: 116), ECB (count: 4, words: 117)),
			.M : ECBlocks (wordsPerBlock: 26, blocks: ECB (count: 17, words: 42)),
			.Q : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 17, words: 22), ECB (count: 6, words: 23)),
			.H : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 19, words: 16), ECB (count: 6, words: 17))
		]),
		ZXVersion (versionNumber: 22, alignmentCenters: [ 6, 26, 50, 74, 98 ], [
			.L : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 2, words: 111), ECB (count: 7, words: 112)),
			.M : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 17, words: 46)),
			.Q : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 7, words: 24), ECB (count: 16, words: 25)),
			.H : ECBlocks (wordsPerBlock: 24, blocks: ECB (count: 34, words: 13))
		]),
		ZXVersion (versionNumber: 23, alignmentCenters: [ 6, 30, 54, 78, 102 ], [
			.L : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 4, words: 121), ECB (count: 5, words: 122)),
			.M : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 4, words: 47), ECB (count: 14, words: 48)),
			.Q : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 11, words: 24), ECB (count: 14, words: 25)),
			.H : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 16, words: 15), ECB (count: 14, words: 16))
		]),
		ZXVersion (versionNumber: 24, alignmentCenters: [ 6, 28, 54, 80, 106 ], [
			.L : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 6, words: 117), ECB (count: 4, words: 118)),
			.M : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 6, words: 45), ECB (count: 14, words: 46)),
			.Q : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 11, words: 24), ECB (count: 16, words: 25)),
			.H : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 30, words: 16), ECB (count: 2, words: 17))
		]),
		ZXVersion (versionNumber: 25, alignmentCenters: [ 6, 32, 58, 84, 110 ], [
			.L : ECBlocks (wordsPerBlock: 26, blocks: ECB (count: 8, words: 106), ECB (count: 4, words: 107)),
			.M : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 8, words: 47), ECB (count: 13, words: 48)),
			.Q : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 7, words: 24), ECB (count: 22, words: 25)),
			.H : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 22, words: 15), ECB (count: 13, words: 16))
		]),
		ZXVersion (versionNumber: 26, alignmentCenters: [ 6, 30, 58, 86, 114 ], [
			.L : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 10, words: 114), ECB (count: 2, words: 115)),
			.M : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 19, words: 46), ECB (count: 4, words: 47)),
			.Q : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 28, words: 22), ECB (count: 6, words: 23)),
			.H : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 33, words: 16), ECB (count: 4, words: 17))
		]),
		ZXVersion (versionNumber: 27, alignmentCenters: [ 6, 34, 62, 90, 118 ], [
			.L : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 8, words: 122), ECB (count: 4, words: 123)),
			.M : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 22, words: 45), ECB (count: 3, words: 46)),
			.Q : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 8, words: 23), ECB (count: 26, words: 24)),
			.H : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 12, words: 15), ECB (count: 28, words: 16))
		]),
		ZXVersion (versionNumber: 28, alignmentCenters: [ 6, 26, 50, 74, 98, 122 ], [
			.L : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 3, words: 117), ECB (count: 10, words: 118)),
			.M : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 3, words: 45), ECB (count: 23, words: 46)),
			.Q : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 4, words: 24), ECB (count: 31, words: 25)),
			.H : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 11, words: 15), ECB (count: 31, words: 16))
		]),
		ZXVersion (versionNumber: 29, alignmentCenters: [ 6, 30, 54, 78, 102, 126 ], [
			.L : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 7, words: 116), ECB (count: 7, words: 117)),
			.M : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 21, words: 45), ECB (count: 7, words: 46)),
			.Q : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 1, words: 23), ECB (count: 37, words: 24)),
			.H : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 19, words: 15), ECB (count: 26, words: 16))
		]),
		ZXVersion (versionNumber: 30, alignmentCenters: [ 6, 26, 52, 78, 104, 130 ], [
			.L : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 5, words: 115), ECB (count: 10, words: 116)),
			.M : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 19, words: 47), ECB (count: 10, words: 48)),
			.Q : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 15, words: 24), ECB (count: 25, words: 25)),
			.H : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 23, words: 15), ECB (count: 25, words: 16))
		]),
		ZXVersion (versionNumber: 31, alignmentCenters: [ 6, 30, 56, 82, 108, 134 ], [
			.L : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 13, words: 115), ECB (count: 3, words: 116)),
			.M : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 2, words: 46), ECB (count: 29, words: 47)),
			.Q : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 42, words: 24), ECB (count: 1, words: 25)),
			.H : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 23, words: 15), ECB (count: 28, words: 16))
		]),
		ZXVersion (versionNumber: 32, alignmentCenters: [ 6, 34, 60, 86, 112, 138 ], [
			.L : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 17, words: 115)),
			.M : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 10, words: 46), ECB (count: 23, words: 47)),
			.Q : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 10, words: 24), ECB (count: 35, words: 25)),
			.H : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 19, words: 15), ECB (count: 35, words: 16))
		]),
		ZXVersion (versionNumber: 33, alignmentCenters: [ 6, 30, 58, 86, 114, 142 ], [
			.L : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 17, words: 115), ECB (count: 1, words: 116)),
			.M : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 14, words: 46), ECB (count: 21, words: 47)),
			.Q : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 29, words: 24), ECB (count: 19, words: 25)),
			.H : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 11, words: 15), ECB (count: 46, words: 16))
		]),
		ZXVersion (versionNumber: 34, alignmentCenters: [ 6, 34, 62, 90, 118, 146 ], [
			.L : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 13, words: 115), ECB (count: 6, words: 116)),
			.M : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 14, words: 46), ECB (count: 23, words: 47)),
			.Q : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 44, words: 24), ECB (count: 7, words: 25)),
			.H : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 59, words: 16), ECB (count: 1, words: 17))
		]),
		ZXVersion (versionNumber: 35, alignmentCenters: [ 6, 30, 54, 78, 102, 126, 150 ], [
			.L : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 12, words: 121), ECB (count: 7, words: 122)),
			.M : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 12, words: 47), ECB (count: 26, words: 48)),
			.Q : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 39, words: 24), ECB (count: 14, words: 25)),
			.H : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 22, words: 15), ECB (count: 41, words: 16))
		]),
		ZXVersion (versionNumber: 36, alignmentCenters: [ 6, 24, 50, 76, 102, 128, 154 ], [
			.L : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 6, words: 121), ECB (count: 14, words: 122)),
			.M : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 6, words: 47), ECB (count: 34, words: 48)),
			.Q : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 46, words: 24), ECB (count: 10, words: 25)),
			.H : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 2, words: 15), ECB (count: 64, words: 16))
		]),
		ZXVersion (versionNumber: 37, alignmentCenters: [ 6, 28, 54, 80, 106, 132, 158 ], [
			.L : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 17, words: 122), ECB (count: 4, words: 123)),
			.M : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 29, words: 46), ECB (count: 14, words: 47)),
			.Q : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 49, words: 24), ECB (count: 10, words: 25)),
			.H : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 24, words: 15), ECB (count: 46, words: 16))
		]),
		ZXVersion (versionNumber: 38, alignmentCenters: [ 6, 32, 58, 84, 110, 136, 162 ], [
			.L : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 4, words: 122), ECB (count: 18, words: 123)),
			.M : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 13, words: 46), ECB (count: 32, words: 47)),
			.Q : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 48, words: 24), ECB (count: 14, words: 25)),
			.H : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 42, words: 15), ECB (count: 32, words: 16))
		]),
		ZXVersion (versionNumber: 39, alignmentCenters: [ 6, 26, 54, 82, 110, 138, 166 ], [
			.L : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 20, words: 117), ECB (count: 4, words: 118)),
			.M : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 40, words: 47), ECB (count: 7, words: 48)),
			.Q : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 43, words: 24), ECB (count: 22, words: 25)),
			.H : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 10, words: 15), ECB (count: 67, words: 16))
		]),
		ZXVersion (versionNumber: 40, alignmentCenters: [ 6, 30, 58, 86, 114, 142, 170 ], [
			.L : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 19, words: 118), ECB (count: 6, words: 119)),
			.M : ECBlocks (wordsPerBlock: 28, blocks: ECB (count: 18, words: 47), ECB (count: 31, words: 48)),
			.Q : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 34, words: 24), ECB (count: 34, words: 25)),
			.H : ECBlocks (wordsPerBlock: 30, blocks: ECB (count: 20, words: 15), ECB (count: 61, words: 16))
		]),
	];
}
