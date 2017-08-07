//
//  ZXBitMatrix.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 4/7/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

/** Represents a 2D matrix of bits */
public final class ZXBitMatrix : NSObject {
	
	private static let EmptySlice = ArraySlice<Bool>();
	
	public private (set) var width: Int = 1;
	public private (set) var height: Int = 1;
	
	private var rowSpan: Int {
		return width;
	}
	
	private var bits: [Bool];
	
	public init (width inputWidth: Int, height inputHeight: Int, value defaultValue: Bool = false) {
		if (inputWidth >= 1) {
			self.width = inputWidth;
		}
		
		if (inputHeight >= 1) {
			self.height = inputHeight;
		}
		
		self.bits = Array<Bool> (repeating: defaultValue, count: width * height);
		
		super.init();
	}
	
	public var size : Int {
		return bits.count;
	}
	
	public func getValues<T> (transform: (Bool) throws -> T) rethrows -> [T] {
		return try bits.map (transform);
	}
	
	/** 
	 - Returns: The bit at the requested position, where True = Black/On
	 */
	public func value (row: Int, column: Int) -> Bool {
		let index = (row * rowSpan) + column;
		if ((index < 0) || (index >= bits.count)) { return false; }
		
		return bits [index];
	}
	
	/** 
	 - Returns: The bit at the requested index, where True = Black/On. 
	 This variant is useful for formats that require a continuous bit stream.
	 */
	public func value (index: Int) -> Bool {
		return bits [index];
	}
	
	public func rowValues (row: Int) -> (row: Int, bits: ArraySlice<Bool>) {
		if ((row < 0) || (row >= height)) {
			return (row, ZXBitMatrix.EmptySlice);
		}
		
		let start = (row * rowSpan);
		let end = start + rowSpan;
		
		return (row, bits [start..<end]);
	}
	
	public func coordinates (index: Int) -> (row: Int, column: Int)? {
		if ((index < 0) || (index >= bits.count)) { return nil; }
		
		let row : Int = index / rowSpan;
		let column : Int = row % rowSpan;
		
		return (row: row, column: column);
	}
	
	/** Sets the bit value at the given position, where True = Black/On */
	public func setValue (value newValue: Bool, row: Int, column: Int) {
		let index = (row * rowSpan) + column;
		if ((index < 0) || (index >= bits.count)) { return; }
		
		self.bits [index] = newValue;
	}
	
	/** Convenience method for setting values for a set of positions, where True = Black/On */
	public func setRegion (value newValue: Bool, minX: Int, maxX: Int, minY: Int, maxY: Int) {
		setRegion (value: newValue, left: minX, top: minY, width: maxX - minX, height: maxY - minY);
	}
	
	/** Convenience method for setting values for a set of positions, where True = Black/On */
	public func setRegion (value newValue: Bool, left: Int, top: Int, width regionWidth: Int, height regionHeight: Int) {
		if ((left < 0) || (top < 0)) { return; }
		if ((regionWidth < 1) || (regionHeight < 1)) { return; }
		
		let right = left + regionWidth;
		let bottom = top + regionHeight;
		
		if ((right > self.width) || (bottom > self.height)) { return; }
		
		var index : Int;
		var rowOffset : Int;
		
		for row in top..<bottom {
			rowOffset = (row * rowSpan);
			
			for column in left..<right {
				index = rowOffset + column;
				bits [index] = newValue;
			}
		}
	}
	
	public func reset (value newValue: Bool = false) {
		for index in 0..<bits.count {
			bits [index] = newValue;
		}
	}
	
	/** Looks for top-left Black/On/True bit, used in detecting corners of "pure" 2D barcodes. */
	public func findTopLeftOnBit() -> (row: Int, column: Int)? {
		var bitsOffset : Int = -1;
		
		for (idx, bitValue) in bits.enumerated() {
			if (bitValue) {
				bitsOffset = idx;
				break;
			}
		}
		
		if (bitsOffset < 0) { return nil; }
		
		return coordinates (index: bitsOffset);
	}
	
	/** Looks for bottom-right Black/On/True bit, used in detecting corners of "pure" 2D barcodes. */
	public func findBottomRightOnBit() -> (row: Int, column: Int)? {
		var bitsOffset : Int = -1;
		
		for (idx, bitValue) in bits.enumerated().reversed() {
			if (bitValue) {
				bitsOffset = idx;
				break;
			}
		}
		
		if (bitsOffset < 0) { return nil; }
		
		return coordinates (index: bitsOffset);
	}
	
	public override var debugDescription: String {
		var result : String = "";
		
		for (idx, curr_bit) in bits.enumerated() {
			if (idx % rowSpan == 0) { result.append ("\r\n"); }
			
			result.append (curr_bit ? "1 " : "0 ");
		}
		
		return result;
	}
}
