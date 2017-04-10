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
	
	/** 
	 - Returns: The bit at the requested position, where True = Black/On
	 */
	public func value (row: Int, column: Int) -> Bool {
		let index = (row * rowSpan) + column;
		if ((index < 0) || (index >= bits.count)) { return false; }
		
		return bits [index];
	}
	
	public func rowValues (row: Int, callback: (Int, ArraySlice<Bool>) -> Void) {
		if ((row < 0) || (row >= height)) { return; }
		
		let start = (row * rowSpan);
		let end = start + rowSpan;
		
		let result = bits [start..<end];
		callback (row, result);
	}
	
	/** Sets the bit value at the given position, where True = Black/On */
	public func setValue (value newValue: Bool, row: Int, column: Int) {
		let index = (row * rowSpan) + column;
		if ((index < 0) || (index >= bits.count)) { return; }
		
		self.bits [index] = newValue;
	}
	
	/** Convenience method for setting values for a set of positions, where True = Black/On */
	public func setRegion (value newValue: Bool, minX: Int, maxX: Int, minY: Int, maxY: Int) {
		if ((minX < 0) || (minY < 0)) { return; }
		
		let regionWidth : Int = maxX - minX;
		let regionHeight : Int = maxY - minY;
		
		if ((regionWidth <= 0) || (regionHeight <= 0)) { return; }
		if ((regionWidth > self.width) || (regionHeight > self.height)) { return; }
		
		var index : Int;
		var rowOffset : Int;
		
		for row in minY..<maxY {
			rowOffset = (row * rowSpan);
			
			for column in minX..<maxX {
				index = rowOffset + column;
				bits [index] = newValue;
			}
		}
	}
	
	/** Convenience method for setting values for a set of positions, where True = Black/On */
	public func setRegion (value newValue: Bool, left: Int, top: Int, width regionWidth: Int, height regionHeight: Int) {
		setRegion (value: newValue, minX: left, maxX: left + regionWidth, minY: top, maxY: top + regionHeight);
	}
	
	public func reset (value newValue: Bool = false) {
		for index in 0..<bits.count {
			bits [index] = newValue;
		}
	}
	
	public override var debugDescription: String {
		var result : String = "";
		
		let onRowReceived = {(rowIndex: Int, rowBits: ArraySlice<Bool>) -> Void in 
			var curr_row : String = ((rowIndex > 0) ? "\r\n" : "");
			
			rowBits.forEach ({
				curr_row.append ($0 ? "1 " : "0 ");
			});
			
			result.append (curr_row);
		}
		
		for row in 0..<height {
			rowValues (row: row, callback: onRowReceived);
		}
		
		return result;
	}
}
