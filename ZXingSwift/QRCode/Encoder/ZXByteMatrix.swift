//
//  ZXByteMatrix.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 7/25/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

internal let EOL : String = "\r\n";

public struct ZXByteMatrix : CustomDebugStringConvertible {
	
	static let InvalidByteValue : UInt8 = UInt8.max;
	
	private var bytes : Array<[UInt8]>;
	private let dimensions : (width: Int, height: Int);
	
	// TODO 7/25/17 Should we check for invalid dimensions?
	init (width: Int, height: Int) {
		self.dimensions = (width, height);
		
		var tempBytes = Array<[UInt8]>();
		var row : [UInt8];
		
		for _ in 0..<height {
			row = Array<UInt8> (repeating: 0, count: width);
			tempBytes.append (row);
		}
		
		self.bytes = tempBytes;
	}
	
	var width : Int {
		return dimensions.width;
	}
	
	var height : Int {
		return dimensions.height;
	}
	
	var rawBytes : Array<[UInt8]> {
		return bytes;
	}
	
	func value (column x: Int, row y: Int) -> UInt8 {
		return bytes [y][x];
	}
	
	func isEmpty (column x: Int, row y: Int) -> Bool {
		return (value (column: x, row: y) == ZXByteMatrix.InvalidByteValue);
	}
	
	mutating func setValue (_ newValue: UInt8, column x: Int, row y: Int) {
		self.bytes [y][x] = newValue;
	}
	
	mutating func setValue (_ newValue: Int, column x: Int, row y: Int) {
		setValue (UInt8 (newValue), column: x, row: y);
	}
	
	mutating func setValue (_ newValue: Bool, column x: Int, row y: Int) {
		setValue ((newValue ? 1 : 0), column: x, row: y);
	}
	
	mutating func clear (value: UInt8 = ZXByteMatrix.InvalidByteValue) {
		for row in 0..<height {
			for col in 0..<width {
				setValue (value, column: col, row: row);
			}
		}
	}
	
	public var debugDescription: String {
		var result = String();
		
		for row in 0..<height {
			result.append (EOL);
			
			for col in 0..<width {
				switch (value (column: col, row: row)) {
				case 0:
					result.append(" 0");
					break;
					
				case 1:
					result.append(" 1");
					break;
					
				default:
					result.append("  ");
					break;
				}
			}
		}
		
		return result;
	}
}
