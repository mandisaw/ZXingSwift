//
//  ZXGenericGF.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 7/19/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

/** Reed-Solomon implementation:
 Utility methods for performing mathematical operations over the Galois Fields (GF). 
 Operations use a given primitive polynomial in calculations.
 
 Portions of this algorithm were originally developed by William Rucklidge, as part of his C++ 
 Reed-Solomon implementation.

 Note that in this implementation, elements of the Galois Fields are represented as an Int
 for convenience and speed, at the potential expense of memory.
 
 - authors: 
   M. Washington (Swift port),
   
   Sean Owen & David Olivier (Java),
   
   William Rucklidge (C++ source)
*/
public final class ZXGenericGF : NSObject {
	
	static let TAG = String (describing: ZXGenericGF.self) + ": %@";
	
	var exponentTable : [Int];
	var logarithmTable : [Int];
	
	let size : Int;
	let primitive : Int;
	let generatorBase : Int;
	
	private var _zero : ZXGenericGFPoly? = nil;
	private var _one : ZXGenericGFPoly? = nil;
	
	/** Creates a representation of GF(size) using the given primitive polynomial.
	 - parameters: 
	   - primitive: Irreducible polynomial whose coefficients are represented by the bits of an Int, 
	 where the least-significant bit represents the constant coefficient
	   - size: The size of the field
	   - base: The factor b in the generator polynomial can be 0- or 1-based, as
	 `g(x) = (x + a^b)(x + a^(b+1))...(x + a^(b+2t-1))`. 
	 In most cases, it should be 1, but for QR code it is 0. 
	 */
	init (primitive: Int, size: Int, base: Int = 1) {
		self.primitive = primitive;
		self.size = size;
		self.generatorBase = base;
		
		self.exponentTable = Array (repeating: 0, count: size);
		self.logarithmTable = Array (repeating: 0, count: size);
		
		var x : Int = 1;
		
		for idx in 0..<size {
			exponentTable [idx] = x;
			
			// We are assuming here that the generator alpha is 2
			x *= 2;
			
			if (x >= size) {
				x ^= primitive;
				x &= size - 1;
			}
		}
		
		for idx in 0..<(size-1) {
			logarithmTable [exponentTable [idx]] = idx;
		}
		// logTable [0] == 0, but this should never be used
	}
	
	var Zero : ZXGenericGFPoly {
		let result = _zero ?? 
			ZXGenericGFPoly (field: self, coefficients: [0]);
		
		self._zero = result;
		return result;
	}
	
	var One : ZXGenericGFPoly {
		let result = _one ?? 
			ZXGenericGFPoly (field: self, coefficients: [1]);
		
		self._one = result;
		return result;
	}
	
	/** - returns: The monomial representing coefficent * x^degree */
	func buildMonomial (degree: Int, coefficient: Int) throws -> ZXGenericGFPoly {
		if (degree < 0) {
			throw ZXWriterError.IllegalArgument (
				"Degree must be zero or positive");
		}
		
		if (coefficient == 0) {
			return Zero;
		}
		
		var coefficients : [Int] = Array (repeating: 0, count: degree + 1);
		coefficients [0] = coefficient;
		
		return ZXGenericGFPoly (field: self, coefficients: coefficients);
	}
	
	/** Note that addition and subtraction have the same value in GF(size).
	 - returns: sum of given parameters in GF(size) */
	static func add (_ itemA: Int, _ itemB: Int) -> Int {
		return itemA ^ itemB;
	}
	
	/** Note that addition and subtraction have the same value in GF(size).
	 - returns: difference of given parameters in GF(size) */
	static func subtract (_ itemA: Int, _ itemB: Int) -> Int {
		return add (itemA, itemB);
	}
	
	/** - returns: 2 raised to the power of value in GF(size) */
	func exp (value: Int) -> Int {
		return exponentTable [value];
	}
	
	/** - returns: base 2 logarithm of the given value in GF(size) */
	func log (value: Int) throws -> Int {
		if (value == 0) {
			throw ZXWriterError.IllegalArgument (
				"Log function is undefined at 0");
		}
		
		return logarithmTable [value];
	}
	
	/** - returns: multiplicative inverse of the given value */
	func multInverse (value: Int) throws -> Int {
		if (value == 0) {
			throw ZXWriterError.IllegalArgument(
				"Inverse function is undefined at 0");
		}
		
		let index = size - logarithmTable [value] - 1;
		return exponentTable [index];
	}
	
	/** - returns: product of given parameters */
	func multiply (_ itemA: Int, _ itemB: Int) -> Int {
		if ((itemA == 0) || (itemB == 0)) {
			return 0;
		}
		
		let index = (logarithmTable [itemA] + logarithmTable [itemB]) % (size - 1);
		return exponentTable [index];
	}
	
	public override var debugDescription: String {
		return "GF (0x" + String (format: "%02X", primitive) + ", \(size))";
	}
	
	// MARK: Reference functions
		
	/** Aztec barcode format, Data12 variant: `x^12 + x^6 + x^5 + x^3 + 1` */
	static let Aztec_Data12 = ZXGenericGF (primitive: 0x1069, size: 4096, base: 1);
	
	/** Aztec barcode format, Data10 variant: `x^10 + x^3 + 1` */
	static let Aztec_Data10 = ZXGenericGF (primitive: 0x409, size: 1024, base: 1);
	
	/** Aztec barcode format, Data6 variant: `x^6 + x + 1` */
	static let Aztec_Data6 = ZXGenericGF (primitive: 0x43, size: 64, base: 1);
	
	/** Parameter used by Aztec barcode format: `x^4 + x + 1` */
	static let Aztec_Parameter = ZXGenericGF (primitive: 0x13, size: 16, base: 1);
	
	/** QR barcode format, 256-bit field variant: `x^8 + x^4 + x^3 + x^2 + 1` */
	static let QRCode_Field256 = ZXGenericGF (primitive: 0x011D, size: 256, base: 0);
	
	/** DataMatrix barcode format, 256-bit field variant: `x^8 + x^5 + x^3 + x^2 + 1` */
	static let DataMatrix_Field256 = ZXGenericGF (primitive: 0x012D, size: 256, base: 1);
	
	/** Aztec barcode format, Data8 variant: `x^8 + x^5 + x^3 + x^2 + 1` 
	 (same as DataMatrix, 256-bit field variant) */
	static let Aztec_Data8 = ZXGenericGF.DataMatrix_Field256;
	
	/** MaxiCode barcode format, 64-bit field variant: `x^6 + x + 1` */
	static let MaxiCode_Field64 = ZXGenericGF.Aztec_Data6;
	
}
