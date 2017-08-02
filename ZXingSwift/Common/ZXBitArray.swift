//
//  ZXBitArray.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 7/27/17.
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

typealias ZXBitArray = [Bool];

/** Generates an array of least-significant bits from the given value, in most-significant-first order. */
internal func makeBitArray <T> (value: T, length: Int) -> [Bool] where T: FixedWidthIntegerCompat {
	let source = value.toBitArray (msbFirst: true);
	let sourceSize : Int = source.count;
	
	if (length < sourceSize) {
		return Array (source.suffix (length));
		
	} else if (length > sourceSize) {
		let padding = Array (repeating: false, count: length - sourceSize);
		return padding + source;
		
	} else {
		return source;
	}
}

extension Array where Element == Bool {
	
	/** Reads from this BitArray into a new byte array of the given target size, starting at the optional offset */
	internal func makeByteArray (offset: Int = 0, targetSize sizeInBytes: Int) -> [UInt8] {
		var result : [UInt8] = Array<UInt8>();
		
		var start = Swift.max (offset, startIndex);
		var curr_byte : Int;
		
		for _ in 0..<sizeInBytes {
			curr_byte = 0;
			
			for bitIdx in 0..<8 {
				if (self [start + bitIdx]) {
					curr_byte |= (1 << (7 - bitIdx));
				}
			}
			
			result.append (UInt8 (curr_byte));
			start += 8;
		}
		
		return result;
	}
}
