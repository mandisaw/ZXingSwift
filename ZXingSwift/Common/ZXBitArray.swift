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
public func makeBitArray (value: Int, length: Int) -> [Bool] {
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
