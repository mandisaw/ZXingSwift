//
//  ZXReedSolomonEncoder.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 7/19/17.
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

/** Implementation of Reed-Solomon error-correction (encoding).
 
 Portions of this algorithm were originally developed by William Rucklidge, as part of his C++ 
 Reed-Solomon implementation.

 Note that in this implementation, elements of the Galois Fields are represented as an Int
 for convenience and speed, at the potential expense of memory.
 
 - authors: 
   M. Washington (Swift port),
   
   Sean Owen & David Olivier (Java),
   
   William Rucklidge (C++ source)
*/
public final class ZXReedSolomonEncoder : NSObject {
	
	let field : ZXGenericGF;
	
	var cachedGenerators : [ZXGenericGFPoly] = Array();
	
	private init (field: ZXGenericGF) {
		self.field = field;
		
		super.init();
		
		self.cachedGenerators.append (
			ZXGenericGFPoly (field: field, coefficients: [1]));
	}
	
	static func encode (toEncode target: inout [Int], field: ZXGenericGF, errorCorrectionBytes ecBytes: Int) throws {
		if (ecBytes == 0) {
			throw ZXWriterError.IllegalArgument(
				"No error correction bytes provided!");
		}
		
		let dataBytesOffset : Int = target.count - ecBytes;
		
		if (dataBytesOffset <= 0) {
			throw ZXWriterError.IllegalArgument(
				"No data bytes provided!");
		}
		
		let encoder = ZXReedSolomonEncoder (field: field);
		
		let generator : ZXGenericGFPoly = try encoder.buildGenerator (degree: ecBytes);
		let infoCoeffs : [Int] = Array (target.prefix (dataBytesOffset));
		
		var info : ZXGenericGFPoly = ZXGenericGFPoly (field: field, coefficients: infoCoeffs);
		info = try info.multiply (degree: ecBytes, coefficient: 1);
		
		let remainder : ZXGenericGFPoly = try info.divide (other: generator).remainder;
		let coefficients = remainder.coefficients;
		
		let zeroCoeffsOffset = ecBytes - coefficients.count;
		
		for idx in 0..<zeroCoeffsOffset {
			target [dataBytesOffset + idx] = 0;
		}
		
		for (idx, curr_coeff) in coefficients.enumerated() {
			target [dataBytesOffset + zeroCoeffsOffset + idx] = curr_coeff;
		}
	}
	
	private func buildGenerator (degree: Int) throws -> ZXGenericGFPoly {
		if (degree >= cachedGenerators.count) {
			var lastGen : ZXGenericGFPoly? = cachedGenerators.last;
			var nextCoeffs : [Int];
			
			let genExpansion = cachedGenerators.count...degree;
			for curr_degree in genExpansion {
				nextCoeffs = [ 1, 
					field.exp (value: curr_degree - 1 + field.generatorBase)
				];
				
				if let nextGen = try lastGen?.multiply (other: 
					ZXGenericGFPoly (field: field, coefficients: nextCoeffs)) {
					
					self.cachedGenerators.append (nextGen);
					lastGen = nextGen;
				}
			}
		}
		
		return cachedGenerators [degree];
	}
}
