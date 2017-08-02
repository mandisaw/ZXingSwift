//
//  IntegerUtils.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 7/26/17.
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

internal protocol FixedWidthIntegerCompat {
	var nonzeroBitCount : Int { get }
	var bitWidth : Int { get }
	
	static var max : Self { get }
	static var min : Self { get }
	
	func toBitArray (msbFirst: Bool) -> [Bool];
}

extension Int : FixedWidthIntegerCompat {
	
	// TODO 7/20/17 Replace with equivalent built-in property currently in XCode 9 beta
	var nonzeroBitCount : Int {
		var result : Int = 0;
		var value = self;
		
		while (value > 0) {
			if ((value & 0x1) == 1) {
				result += 1;
			}
			
			value >>= 1;
		}
		
		return result;
	}
	
	// TODO 7/26/17 Replace with equivalent built-in property currently in XCode 9 beta
	var bitWidth : Int {
		var result : Int = 0;
		var value = self;
		
		while (value > 0) {
			result += 1;
			value >>= 1;
		}
		
		return result;
	}
	
	/** Generates an array of individual bit values, 
	 in order from least-significant to most-significant, unless stipulated otherwise */
	func toBitArray (msbFirst: Bool = false) -> [Bool] {
		var result : [Bool] = Array<Bool>();
		var value = self;
		
		while (value > 0) {
			result.append ((value & 0x1) == 1);
			value >>= 1;
		}
		
		if (msbFirst) {
			result.reverse();
		}
		
		return result;
	}
}

extension UInt8 : FixedWidthIntegerCompat {
	
	// TODO 7/20/17 Replace with equivalent built-in property currently in XCode 9 beta
	var nonzeroBitCount : Int {
		var result : Int = 0;
		var value = self;
		
		while (value > 0) {
			if ((value & 0x1) == 1) {
				result += 1;
			}
			
			value >>= 1;
		}
		
		return result;
	}
	
	// TODO 7/26/17 Replace with equivalent built-in property currently in XCode 9 beta
	var bitWidth : Int {
		var result : Int = 0;
		var value = self;
		
		while (value > 0) {
			result += 1;
			value >>= 1;
		}
		
		return result;
	}
	
	/** Generates an array of individual bit values, 
	 in order from least-significant to most-significant, unless stipulated otherwise */
	func toBitArray (msbFirst: Bool = false) -> [Bool] {
		var result : [Bool] = Array<Bool>();
		var value = self;
		
		while (value > 0) {
			result.append ((value & 0x1) == 1);
			value >>= 1;
		}
		
		if (msbFirst) {
			result.reverse();
		}
		
		return result;
	}
}

extension UInt32 : FixedWidthIntegerCompat {
	
	// TODO 7/20/17 Replace with equivalent built-in property currently in XCode 9 beta
	var nonzeroBitCount : Int {
		var result : Int = 0;
		var value = self;
		
		while (value > 0) {
			if ((value & 0x1) == 1) {
				result += 1;
			}
			
			value >>= 1;
		}
		
		return result;
	}
	
	// TODO 7/26/17 Replace with equivalent built-in property currently in XCode 9 beta
	var bitWidth : Int {
		var result : Int = 0;
		var value = self;
		
		while (value > 0) {
			result += 1;
			value >>= 1;
		}
		
		return result;
	}
	
	/** Generates an array of individual bit values, 
	 in order from least-significant to most-significant, unless stipulated otherwise */
	func toBitArray (msbFirst: Bool = false) -> [Bool] {
		var result : [Bool] = Array<Bool>();
		var value = self;
		
		while (value > 0) {
			result.append ((value & 0x1) == 1);
			value >>= 1;
		}
		
		if (msbFirst) {
			result.reverse();
		}
		
		return result;
	}
}

extension Bool {
	
	internal static func ^ (lhs: Bool, rhs: Bool) -> Bool {
		return ((lhs ? 1 : 0) ^ (rhs ? 1 : 0)) != 0;
	}
	
	internal static func ^= (lhs: inout Bool, rhs: Bool) {
		lhs = lhs ^ rhs;
	}
}
