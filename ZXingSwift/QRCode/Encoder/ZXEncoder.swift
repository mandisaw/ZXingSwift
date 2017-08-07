//
//  ZXEncoder.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 7/27/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

/** Unified QR Code encoder, largely references QR Code specification, ISO 18004:2006, Chapter 6 Encode Procedure, 
 however various constituent portions may be found in other parts of the specification. */
public final class ZXEncoder : NSObject {
	
	private static let TAG = String (describing: ZXEncoder.self) + ": %@";
	
	static var DefaultMode : ZXMode = ZXMode.Byte;
	
	static let SupportedModes : [ZXMode] = [
		.Kanji, 
		.Numeric, 
		.Alphanumeric, 
		.Byte
	];
	
	static var DefaultECICharacterSet : ZXCharacterSetECI = ZXCharacterSetECI.ISO8859_1;
	static var DefaultErrorCorrectionLevel : ZXErrorCorrectionLevel = ZXErrorCorrectionLevel.L;
	
	private static let PadCodewords : [Int] = [
		0xEC, // 0b11101100 
		0x11  // 0b00010001
	];
	
	private static let QRReedSolomonField : ZXGenericGF = ZXGenericGF.QRCode_Field256;
	
	private static let Instance = ZXEncoder();
	
	private override init() {
		super.init();
	}
	
	public static func encode (content: String, 
		 errorCorrectionLevel optECLevel: ZXErrorCorrectionLevel? = nil, 
		 eciCharacterSet optECI: ZXCharacterSetECI? = nil, 
		 requestedVersion optVersion: Int? = nil, 
		 options: ZXEncodingHints? = nil
		) throws -> ZXQRCode {
		
		let ecLevel : ZXErrorCorrectionLevel = parseOptions (errorCorrectionLevel: optECLevel, options: options);
		let eciCharacterSet : ZXCharacterSetECI? = parseOptions (eciCharacterSet: optECI, options: options);
		let requestedVersion : ZXVersion? = try parseOptions (version: optVersion, options: options);
		let characterEncoding : String.Encoding? = eciCharacterSet?.encoding;
		
		let mode : ZXMode = selectEncodingMode (content: content, encoding: characterEncoding);
		
		// Encoded header information, including mode and optional ECI segment
		let headerBits : ZXBitArray = createHeaderSegment (mode: mode, eciCharacterSet: eciCharacterSet);
		
		let dataBits : ZXBitArray = try createDataPayload (content: content, mode: mode, 
			encoding: characterEncoding);
		
		let version : ZXVersion;
		
		if let requestedVersion = requestedVersion, 
			(requestedVersion.willSupportEncoding (mode: mode, errorCorrectionLevel: ecLevel, 
				header: headerBits, data: dataBits)) {
			
			version = requestedVersion;
			
		} else if let calculatedVersion = ZXVersion.lookupSupportedVersion (
				requestedVersion: requestedVersion, mode: mode, errorCorrectionLevel: ecLevel, 
				header: headerBits, data: dataBits) {
			
			version = calculatedVersion;
			
		} else {
			throw ZXWriterError.InvalidFormat (
				"Error encoding barcode - Version could not be determined for given content and parameters");
		}
		
		let characterCountBits : ZXBitArray = try createCharacterCountSegment (mode: mode, version: version, 
			content: content, data: dataBits, encoding: characterEncoding);
		
		var encodedBits : ZXBitArray = ZXBitArray();
		encodedBits.append (contentsOf: headerBits);
		encodedBits.append (contentsOf: characterCountBits);
		encodedBits.append (contentsOf: dataBits);
		
		try terminateCode (version: version, errorCorrectionLevel: ecLevel, data: &encodedBits);
		
		let errorCorrectedBits : ZXBitArray = try applyErrorCorrection (version: version, 
			errorCorrectionLevel: ecLevel, data: encodedBits);
		
		let qrCode = ZXQRCode (mode: mode, version: version, errorCorrectionLevel: ecLevel);
		
		qrCode.maskPattern = try ZXByteMatrix.lookupMaskPattern (ecData: errorCorrectedBits, 
			errorCorrectionLevel: ecLevel, version: version);
		
		qrCode.matrix = try ZXByteMatrix (data: errorCorrectedBits, errorCorrectionLevel: ecLevel, 
			version: version, maskPattern: qrCode.maskPattern);
		
//		MyLog.d(TAG, "QR Code: content: \(content), encoding: \(characterEncoding as Optional), " + EOL + 
//			"\(qrCode.debugDescription)");
		
		return qrCode;
	}
	
	private static func parseOptions (errorCorrectionLevel ecLevel: ZXErrorCorrectionLevel?, 
		options: ZXEncodingHints?
		) -> ZXErrorCorrectionLevel {
		
		return ecLevel ?? 
			(options?.errorCorrection as? ZXErrorCorrectionLevel) ?? 
			DefaultErrorCorrectionLevel;
	}
	
	private static func parseOptions (eciCharacterSet charSetECI: ZXCharacterSetECI?, 
		options: ZXEncodingHints?
		) -> ZXCharacterSetECI? {
		
		var result : ZXCharacterSetECI? = charSetECI;
		
		if (result == nil), 
			let optEncoding = options?.characterEncoding {
			
			result = ZXCharacterSetECI.lookup (encoding: optEncoding);
		}
		
		return result;
	}
	
	private static func parseOptions (version versionNumber: Int?, 
		options: ZXEncodingHints?
		) throws -> ZXVersion? {
		
		var result : ZXVersion? = nil;
		
		if let versionNumber = versionNumber ?? options?.qrVersion {
			result = try ZXVersion.lookupVersion (versionNumber: versionNumber);
		}
		
		return result;
	}
	
	/** Attempts to match an encoding Mode to the given content, with the encoding used as a hint.
	 Note that this could be improved to use multiple modes/segments, as that could be more efficient. */
	private static func selectEncodingMode (content: String, 
		encoding: String.Encoding? = nil
		) -> ZXMode {
		
		var result : ZXMode? = nil;
		
		result = SupportedModes.first (where: {(mode) in 
			switch (mode) {
			case .Kanji:
				if (encoding == String.Encoding.shiftJIS) {
					return ZXMode.Kanji.supportsContent (content);
				} else {
					return false;
				}
				
			default:
				return mode.supportsContent (content);
			}
		});
		
		return result ?? DefaultMode;
	}
	
	/** Header includes optional ECI segment, and Mode information */
	private static func createHeaderSegment (mode: ZXMode, eciCharacterSet: ZXCharacterSetECI?) -> ZXBitArray {
		var bits : ZXBitArray = ZXBitArray();
		
		// Append ECI header segment, if applicable
		if (mode == ZXMode.Byte),  
			let eciCharacterSet = eciCharacterSet, 
			(eciCharacterSet != DefaultECICharacterSet) {
			
			bits.append (contentsOf: makeBitArray (value: ZXMode.ECI.bits, length: 4));
			
			if let eciValue = eciCharacterSet.value {
				// This is correct for values up to 127, which is all we need for now
				bits.append (contentsOf: makeBitArray (value: eciValue, length: 8));
			}
		}
		
		// Append Mode info
		bits.append (contentsOf: makeBitArray (value: mode.bits, length: 4));
		
		return bits;
	}
	
	private static func createCharacterCountSegment (mode: ZXMode, version: ZXVersion, 
		content: String, data: ZXBitArray? = nil, encoding: String.Encoding? = nil) throws -> ZXBitArray {
		
		let contentLength : Int = try mode.calculateCharacterCount (content: content, data: data, encoding: encoding);
		let maxBitsCount = mode.characterCountBits (version: version);
		
		if (contentLength.bitWidth > maxBitsCount) {
			throw ZXWriterError.InvalidFormat (
				"Error encoding barcode: Character count exceeds maximum for this mode and version");
		}
		
		return makeBitArray (value: contentLength, length: maxBitsCount);
	}
	
	/** Refer to QR Code specification, ISO 18004:2006, sections 6.4.10 for details 
	 on bit stream to codeword conversion, incl. Terminator encoding */
	private static func terminateCode (version: ZXVersion, 
		errorCorrectionLevel ecLevel: ZXErrorCorrectionLevel, 
		data: inout ZXBitArray) throws {
		
		let bytesCapacity : Int = version.maxDataBytesSupported (errorCorrectionLevel: ecLevel);
		let bitsCapacity = bytesCapacity * 8;
		
		if (data.count > bitsCapacity) {
			throw ZXWriterError.InvalidFormat (
				"Error encoding barcode: Encoded content size (\(data.count)) exceeds capacity (\(bitsCapacity)) for the given parameters");
		}
		
		for _ in 0..<4 {
			if (data.count >= bitsCapacity) { break; }
			
			data.append (false);
		}
		
		// Add padding bits to ensure that sequence is codeword-aligned (8 bits)
		// TODO 8/1/2017 Using modulo here for clarity, dropping original likely-unneeded optimization
		let partialByteSize = data.count % 8;
		if (partialByteSize > 0) {
			for _ in partialByteSize..<8 {
				data.append (false);
			}
		}
		
		// Add Pad Codewords alternately, to fill capacity specified by version
		let dataBytes = (data.count + 7) / 8;
		var curr_padWord : Int;
		
		for idx in dataBytes..<bytesCapacity {
			curr_padWord = PadCodewords [(idx & 0x1)];
			
			data.append (contentsOf: makeBitArray (value: curr_padWord, length: 8));
		}
		
		if (data.count != bitsCapacity) {
			throw ZXWriterError.InvalidFormat (
				"Error encoding barcode: Final code size (\(data.count)) does not match capacity (\(bitsCapacity)) for the given parameters");
		}
	}
	
	/** Refer to QR Code specification, ISO 18004:2006, sections 6.4.3-6.4.6 for details on Data encoding */
	private static func createDataPayload (content: String, mode: ZXMode, 
		encoding: String.Encoding? = nil) throws -> ZXBitArray {
		
		switch (mode) {
		case .Numeric:
			return createNumericPayload (content: content);
		case .Alphanumeric:
			return try createAlphanumericPayload (content: content);
		case .Kanji:
			return try createKanjiPayload (content: content);
		case .Byte:
			return try createGenericPayload (content: content, encoding: encoding);
			
		default:
			throw ZXWriterError.IllegalArgument (
				"Error encoding barcode: Invalid mode specified");
		}
	}
	
	private static func createGenericPayload (content: String, 
		encoding optEncoding: String.Encoding? = nil) throws -> ZXBitArray {
		
		let encoding = optEncoding ?? DefaultECICharacterSet.encoding;
		
		if let encoding = encoding, 
			(content.canBeConverted (to: encoding)) {
			
			guard let encodedString : Data = content.data (using: encoding, allowLossyConversion: false) else {
				throw ZXWriterError.IllegalArgument (
					"Error encoding barcode: Could not encode content to desired encoding: \(encoding)");
			}
			
			var bits : ZXBitArray = ZXBitArray();
			
			encodedString.forEach ({ (byte: UInt8) in 
				bits.append (contentsOf: makeBitArray (value: byte, length: 8));
			});
			
			return bits;
		
		} else {
			throw ZXWriterError.IllegalArgument (
				"Error encoding barcode: Invalid encoding specified");
		}
	}
	
	private static func createAlphanumericPayload (content: String) throws -> ZXBitArray {
		var bits : ZXBitArray = ZXBitArray();
		
		let characters = content.unicodeScalars;
		let startIndex = characters.startIndex;
		let len = characters.count;
		
		let charAt = {(offset: Int) -> UnicodeScalar in 
			let idx = characters.index (startIndex, offsetBy: offset);
			return characters [idx];
		};
		
		var charIdx : Int = 0;
		
		var encodeValue : Int;
		var encodeBitWidth : Int;
		
		while (charIdx < len) {
			if (charIdx + 1 < len), 
				let code1 = AlphanumericLookupTable [charAt (charIdx)], 
				let code2 = AlphanumericLookupTable [charAt (charIdx + 1)] {
				
				// Encode a sequence of 2 characters in 11 bits
				encodeBitWidth = 11;
				encodeValue = (
					(code1 * 45) + 
					code2
				);
				
				charIdx += 2;
				
			} else if let code1 = AlphanumericLookupTable [charAt (charIdx)] {
				// Encode single character in 6 bits
				encodeBitWidth = 6;
				encodeValue = code1;
				
				charIdx += 1;
			
			} else {
				throw ZXWriterError.IllegalArgument(
					"Error encoding barcode: Illegal characters in content");
			}
			
			bits.append (contentsOf: makeBitArray (value: encodeValue, length: encodeBitWidth));
		}
		
		return bits;
 	}
	
	private static func createNumericPayload (content: String) -> ZXBitArray {
		var bits : ZXBitArray = ZXBitArray();
		
		let characters = content.unicodeScalars;
		let startIndex = characters.startIndex;
		let len = characters.count;
		
		let zero = UnicodeScalar ("0")!.value; // Unicode value of 0
		
		let charAt = {(offset: Int) -> UnicodeScalar in 
			let idx = characters.index (startIndex, offsetBy: offset);
			return characters [idx];
		};
		
		var charIdx : Int = 0;
		
		var encodeValue : UInt32;
		var encodeBitWidth : Int;
		
		while (charIdx < len) {
			if (charIdx + 2 < len) {
				// Encode a sequence of 3 characters in 10 bits
				encodeBitWidth = 10;
				encodeValue = (
					((charAt (charIdx).value - zero) * 100) + 
					((charAt (charIdx + 1).value - zero) * 10) + 
					(charAt (charIdx + 2).value - zero)
				);
				
				charIdx += 3;
			
			} else if (charIdx + 1 < len) {
				// Encode a sequence of 2 characters in 7 bits
				encodeBitWidth = 7;
				encodeValue = (
					((charAt (charIdx).value - zero) * 10) + 
					(charAt (charIdx + 1).value - zero)
				);
				
				charIdx += 2;
			
			} else {
				// Encode single character in 4 bits
				encodeBitWidth = 4;
				encodeValue = charAt (charIdx).value - zero;
				
				charIdx += 1;
			}
			
			bits.append (contentsOf: makeBitArray (value: encodeValue, length: encodeBitWidth));
		}
		
		return bits;
	}
	
	private static func createKanjiPayload (content: String) throws -> ZXBitArray {
		let encoding = String.Encoding.shiftJIS;
		
		if (content.canBeConverted (to: encoding)) {
			
			guard let encodedString : Data = content.data (using: encoding, allowLossyConversion: false) else {
				throw ZXWriterError.IllegalArgument (
					"Error encoding barcode: Could not encode content to desired encoding: \(encoding)");
			}
			
			var bits : ZXBitArray = ZXBitArray();
			
			var byteIdx : Int = 0;
			let len = encodedString.count;
			let encodeBitWidth : Int = 13;
			
			var upperByte : UInt8;
			var lowerByte : UInt8;
			
			var rawCode : Int;
			var codeOffset : Int;
			var codeValue : Int;
			
			while (byteIdx < len) {
				upperByte = encodedString [byteIdx] & 0xFF;
				lowerByte = encodedString [byteIdx + 1] & 0xFF;
				
				rawCode = Int ((upperByte << 8) | lowerByte);
				
				if (KanjiLowerReferenceRange.range.contains (rawCode)) {
					codeOffset = KanjiLowerReferenceRange.offset;
					
				} else if (KanjiUpperReferenceRange.range.contains (rawCode)) {
					codeOffset = KanjiUpperReferenceRange.offset;
				
				} else {
					throw ZXWriterError.IllegalArgument(
						"Error encoding barcode: Could not encode content to Kanji mode");
				}
				
				rawCode -= codeOffset;
				codeValue = ((rawCode >> 8) * 0xC0) + (rawCode & 0xFF);
				
				bits.append (contentsOf: makeBitArray (value: codeValue, length: encodeBitWidth));
				
				byteIdx += 2;
			}
			
			return bits;
		
		} else {
			throw ZXWriterError.IllegalArgument (
				"Error encoding barcode: Invalid encoding specified");
		}
	}
	
	/** Applies Reed-Solomon error-correction to given data stream.
	 Refer to QR Code specification, ISO 18004:2006, section 6.5 for details on bit stream error correction */
	private static func applyErrorCorrection (version: ZXVersion, 
		errorCorrectionLevel ecLevel: ZXErrorCorrectionLevel, 
		data: ZXBitArray) throws -> ZXBitArray {
		
		let numDataBytes : Int = version.maxDataBytesSupported (errorCorrectionLevel: ecLevel);
		let testDataBytesCount = (data.count + 7) / 8;
		
		if (testDataBytesCount != numDataBytes) {
			throw ZXWriterError.InvalidFormat (
				"Error encoding barcode: Final code size (\(testDataBytesCount)) does not match capacity (\(numDataBytes)) for the given parameters");
		}
		
		let numTotalBytes : Int = version.totalCodewords;
		let numReedSolomonBlocks : Int = version.errorCorrectionBlocks (ecLevel: ecLevel).totalBlockCount;
		
		// Divide data bytes into blocks, generating error correction bytes for each block, and interleaving both
		
		var dataBytesOffset : Int = 0;
		var maxDataBytesCount : Int = 0;
		var maxECBytesCount : Int = 0;
		
		var blocks : [ZXBlockPair] = Array<ZXBlockPair>();
		blocks.reserveCapacity (numReedSolomonBlocks);
		
		var curr_capacityInfo : (dataBytesCapacity: Int, ecBytesCapacity: Int);
		var curr_dataBytesCount : Int;
		var curr_dataBytes : [UInt8];
		var curr_ecBytes : [UInt8];
		var curr_block : ZXBlockPair;
		
		for blockIdx in 0..<numReedSolomonBlocks {
			curr_capacityInfo = try version.getErrorCorrectionCapacity (blockId: blockIdx, errorCorrectionLevel: ecLevel);
			curr_dataBytesCount = curr_capacityInfo.dataBytesCapacity;
			
			curr_dataBytes = data.makeByteArray (offset: dataBytesOffset * 8, targetSize: curr_dataBytesCount);
			curr_ecBytes = try generateECBytes (data: curr_dataBytes, capacity: curr_capacityInfo.ecBytesCapacity);
			
			curr_block = ZXBlockPair (dataBytes: curr_dataBytes, errorCorrectionBytes: curr_ecBytes);
			blocks.append (curr_block);
			
			maxDataBytesCount = Swift.max (maxDataBytesCount, curr_capacityInfo.dataBytesCapacity);
			maxECBytesCount = Swift.max (maxECBytesCount, curr_ecBytes.count);
			
			dataBytesOffset += curr_dataBytesCount;
		}
		
		if (numDataBytes != dataBytesOffset) {
			throw ZXWriterError.InvalidFormat (
				"Error encoding barcode: Error-corrected data size (\(dataBytesOffset)) does not match expectation (\(numDataBytes))");
		}
		
		// Return interleaved data and error-correction blocks
		var result : ZXBitArray = ZXBitArray();
		
		for idx in 0..<maxDataBytesCount {
			for block in blocks {
				curr_dataBytes = block.dataBytes;
				
				if (idx < curr_dataBytes.count) {
					result.append (contentsOf: makeBitArray (value: curr_dataBytes [idx], length: 8));
				}
			}
		}
		
		for idx in 0..<maxECBytesCount {
			for block in blocks {
				curr_ecBytes = block.errorCorrectionBytes;
				
				if (idx < curr_ecBytes.count) {
					result.append (contentsOf: makeBitArray (value: curr_ecBytes [idx], length: 8));
				}
			}
		}
		
		let resultBytesCount : Int = (result.count + 7) / 8;
		if (numTotalBytes != resultBytesCount) {
			throw ZXWriterError.InvalidFormat (
				"Error encoding barcode: Interleaved error-corrected data size (\(resultBytesCount)) does not match expectation (\(numTotalBytes))");
		}
		
		return result;
	}
	
	private static func generateECBytes (data: [UInt8], capacity: Int) throws -> [UInt8] {
		let numDataBytes : Int = data.count;
		
		var source : [Int] = Array (repeating: 0, count: numDataBytes + capacity);
		for (idx, byte) in data.enumerated() {
			source [idx] = Int (byte & 0xFF);
		}
		
		try ZXReedSolomonEncoder.encode (toEncode: &source, field: QRReedSolomonField, errorCorrectionBytes: capacity);
		
		var result : [UInt8] = Array (repeating: 0, count: capacity);
		for idx in 0..<capacity {
			result [idx] = UInt8 (source [numDataBytes + idx]);
		}
		
		return result;
	}
	
	// MARK: Helpers
	
	private static let KanjiLowerReferenceRange : (range: CountableClosedRange<Int>, offset: Int) = (0x8140...0x9FFC, 0x8140);
	private static let KanjiUpperReferenceRange : (range: CountableClosedRange<Int>, offset: Int) = (0xE040...0xEBBF, 0xC140);
	
	/** Encoding/decoding table for Alphanumeric mode
	 Refer to QR Code specification, ISO 18004:2006, section 6.4.4, Table 5 for details. */
	private static let AlphanumericLookupTable : [UnicodeScalar : Int] = {
		var result = Dictionary<UnicodeScalar, Int>();
		
		var startIndex = result.count;
		var range : ClosedRange<UnicodeScalar> = "0"..."9";
		
		for (idx, charValue) in (range.lowerBound.value ... range.upperBound.value).enumerated() {
			if let char = UnicodeScalar (charValue) {
				result.updateValue (startIndex + idx, forKey: char);
			}
		}
		
		startIndex = result.count;
		range = "A"..."Z";
		
		for (idx, charValue) in (range.lowerBound.value ... range.upperBound.value).enumerated() {
			if let char = UnicodeScalar (charValue) {
				result.updateValue (startIndex + idx, forKey: char);
			}
		}
		
		let symbols = "\u{20}\u{24}\u{25}\u{2A}\u{2B}\u{2D}\u{2E}\u{2F}\u{3A}".unicodeScalars; // (space), plus $%*+-./:
		
		startIndex = result.count;
		for (idx, char) in symbols.enumerated() {
			result.updateValue (startIndex + idx, forKey: char);
		}
		
		return result;
	}();
}
