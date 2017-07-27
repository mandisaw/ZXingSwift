//
//  ZXMaskUtils.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 7/25/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

public final class ZXMaskUtils : NSObject {
	
	/** Weight/Penalty Constants - Refer to QR Code specification, ISO 18004:2006, section 6.8.2.1.  */
	private struct PenaltyConstants {
		static let N1 : Int = 3;
		static let N2 : Int = 3;
		static let N3 : Int = 40;
		static let N4 : Int = 10;
	}
	
	private override init() {
		super.init();
	}
	
	/** Mask Penalty Rule 1: Find repetitive cells with the same color/value, in either horizontal or vertical orientation, 
	 and assign a penalty/weight to them. */
	static let PenaltyRule1 = {(matrix: ZXByteMatrix) -> Int in 
		return createPenaltyRule1 (isHorizontal: true) (matrix) + 
			createPenaltyRule1 (isHorizontal: false) (matrix);
	};
	
	private static func createPenaltyRule1 (isHorizontal: Bool) -> (ZXByteMatrix) -> Int {
		return {(matrix: ZXByteMatrix) -> Int in 
			let rowCount = (isHorizontal ? matrix.height : matrix.width);
			let colCount = (isHorizontal ? matrix.width : matrix.height);
			
			var penalty : Int = 0;
			
			let updatePenalty = {(runCount: Int) in 
				penalty += PenaltyConstants.N1 + (runCount - 5);
			};
			
			var cellRunCount : Int;
			var prevBit : UInt8;
			var currBit : UInt8;
			
			for row in 0..<rowCount {
				cellRunCount = 0;
				prevBit = UInt8.max;
				
				for col in 0..<colCount {
					currBit = (isHorizontal ? matrix.value (column: col, row: row) : 
						matrix.value (column: row, row: col));
					
					if (currBit == prevBit) {
						cellRunCount += 1;
						
					} else {
						if (cellRunCount >= 5) {
							updatePenalty (cellRunCount);
						}
						
						cellRunCount = 1; // Include the current cell
						prevBit = currBit;
					}
				}
				
				if (cellRunCount >= 5) {
					updatePenalty (cellRunCount);
				}
			}
			
			return penalty;
		};
	}
	
	/** Mask Penalty Rule 2: Find 2x2 blocks with the same color/value, and assign a penalty/weight to them.
	 
	 Note that this implementation is equivalent to the specification rule, which is to find MxN blocks 
	 and assign them a penalty/weight proportional to `(M-1) x (N-1)`. This approach returns the number of 
	 2x2 blocks inside such a block. */
	static let PenaltyRule2 = {(matrix: ZXByteMatrix) -> Int in 
		let rowCount = matrix.height - 1;
		let colCount = matrix.width - 1;
		
		var penalty : Int = 0;
		
		var currBit : UInt8;
		
		for row in 0..<rowCount {
			for col in 0..<colCount {
				currBit = matrix.value (column: col, row: row);
				
				if ((currBit == matrix.value (column: col + 1, row: row)) && 
					(currBit == matrix.value (column: col, row: row + 1)) && 
					(currBit == matrix.value (column: col + 1, row: row + 1))) {
					
					penalty += 1;
				}
			}
		}
		
		return PenaltyConstants.N2 * penalty;
	};
	
	/** Mask Penalty Rule 3: Find consecutive runs of 1:1:3:1:1:4 starting with black/On/True, 
	 or 4:1:1:3:1:1 starting with white/Off/False. 
	 
	 Palindromic runs of 4:1:1:3:1:1:4 are only recognized once. */
	static let PenaltyRule3 = {(matrix: ZXByteMatrix) -> Int in 
		let rowCount = matrix.height;
		let colCount = matrix.width;
		
		var penalty : Int = 0;
		
		let testBytes : [UInt8] = [1, 0, 1, 1, 1, 0, 1];
		
		for row in 0..<rowCount {
			for col in 0..<colCount {
				
				if (col + 6 < colCount) {
					let rowBytes = matrix.rawBytes [row];
					
					if (rowBytes [col...col + 6].elementsEqual (testBytes) && 
						(isValidRun (rowBytes, from: col-4, to: col) || 
							isValidRun (rowBytes, from: col+7, to: col+11))) {
						
						penalty += 1;
					}
				}
				
				if (row + 6 < rowCount) {
					let colBytes = matrix.rawBytes.map ({
						$0 [col];
					});
					
					if (colBytes [row...row + 6].elementsEqual (testBytes) && 
						(isValidRun (colBytes, from: row-4, to: row) || 
							isValidRun (colBytes, from: row+7, to: row+11))) {
						
						penalty += 1;
					}
				}
			}
		}
		
		return PenaltyConstants.N3 * penalty;
	};
		
	private static func isValidRun (_ bytes: [UInt8], from: Int, to: Int) -> Bool {
		let startIndex = max (bytes.startIndex, from);
		let endIndex = min (to, bytes.endIndex);
		
		return (bytes [startIndex..<endIndex].contains (1) == false);
	}
	
	/** Mask Penalty Rule 4: Calculate the ratio of black/On/True cells, and 
	 aply a penalty/weight if the ratio is far from 50%. 
	 This implemenation applies a +10 penalty for every additional 5% deviation. */
	static let PenaltyRule4 = {(matrix: ZXByteMatrix) -> Int in 
		let totalCellCount : Int = matrix.width * matrix.height;
		var darkCellCount : Int = 0;
		
		for row in matrix.rawBytes {
			row.forEach ({
				if ($0 == 1) {
					darkCellCount += 1;
				}
			});
		}
		
		let penalty : Int = abs(darkCellCount * 2 - totalCellCount) * 10 / totalCellCount;
		
		return PenaltyConstants.N4 * penalty;
	};
	
	static func getDataMaskBit (maskPattern: Int, column x: Int, row y: Int) throws -> Bool {
		let intermediate : Int;
		let temp = y * x;
		
		switch (maskPattern) {
		case 0:
			intermediate = (y + x) & 0x1;
			break;
			
		case 1:
			intermediate = y & 0x1;
			break;
			
		case 2:
			intermediate = x % 3;
			break;
			
		case 3:
			intermediate = (y + x) % 3;
			break;
			
		case 4:
			intermediate = ((y / 2) + (x / 3)) & 0x1;
			break;
			
		case 5:
			intermediate = (temp & 0x1) + (temp % 3);
			break;
			
		case 6:
			intermediate = ((temp & 0x1) + (temp % 3)) & 0x1;
			break;
			
		case 7:
			intermediate = ((temp % 3) + ((y + x) & 0x1)) & 0x1;
			break;
			
		default:
			throw ZXWriterError.IllegalArgument (
				"Invalid mask pattern: \(maskPattern)");
		}
		
		return (intermediate == 0);
	}
}
