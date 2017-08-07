//
//  ZXGenericGFPoly.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 7/19/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

/** Reed-Solomon implementation:
 Represents a polynomial whose coefficients are elements of a Galois Field (GF). 
 Instances of this class are immutable.
 
 Portions of this algorithm were originally developed by William Rucklidge, as part of his C++ 
 Reed-Solomon implementation.
 
 Note that in this implementation, elements of the Galois Fields are represented as an Int
 for convenience and speed, at the potential expense of memory.
 
 - authors: 
   M. Washington (Swift port),
   
   Sean Owen & David Olivier (Java),
   
   William Rucklidge (C++ source)
*/

public struct ZXGenericGFPoly : CustomDebugStringConvertible {
	
	private static let ZeroCoefficients = [0];
	
	let field: ZXGenericGF;
	let coefficients : [Int];
	
	/** 
	 - Parameters:
	   - field: The ZXGenericGF instance representing the field to use to perform calculations
	   - coeffs: coefficients as Integers representing elements of GF(size), arranged from 
	 most-significant coefficient (highest-power term) to least-significant (lowest-power term)
	 - Throws: If coeffs is empty, or if leading coefficient is 0 and this is not a constant polynomial
	 (that is, not the monomial '0')
	*/
	init (field: ZXGenericGF, coefficients coeffs: [Int]) {
//		if (coeffs.isEmpty) {
//			throw ZXWriterError.IllegalArgument(
//				"Coefficients array cannot be empty");
//		}
		
		self.field = field;
		
		if ((coeffs.count > 1) && (coeffs [0] == 0)) {
			// Leading term must be non-zero, for anything except the constant monomial '0'
			let firstTermOffset = coeffs.suffix (from: 1).first (where: {(value) in 
				(value != 0);
			});
			
			if let offset = firstTermOffset {
				self.coefficients = Array (coeffs.suffix (from: offset));
			} else {
				self.coefficients = ZXGenericGFPoly.ZeroCoefficients;
			}
		
		} else if (coeffs.isEmpty == false) {
			self.coefficients = coeffs;
			
		} else {
			self.coefficients = ZXGenericGFPoly.ZeroCoefficients;
		}
	}
	
	/** - returns: Degree of this polynomial */
	var degree : Int {
		return coefficients.count - 1;
	}
	
	/** - returns: True, if this polynomial is the constant monomial '0' */
	var isZero : Bool {
		return coefficients [0] == 0;
	}
	
	/** - returns: Coefficient of x^degree term in this polynomial */
	func coefficient (degree: Int) -> Int {
		let index = coefficients.count - 1 - degree;
		return coefficients [index];
	}
	
	/** - returns: Evaluation of this polynomial for the given value */
	func evaluate (at value: Int) -> Int {
		var result : Int;
		
		switch (value) {
		case 0:
			// Just return the x^0 coefficient
			result = coefficient (degree: 0);
			break;
			
		case 1:
			// Return the sum of the coefficients
			result = 0;
			
			coefficients.forEach ({
				result = ZXGenericGF.add (result, $0);
			});
			break;
			
		default:
			result = coefficients [0];
			
			coefficients.suffix (from: 1).forEach ({
				result = ZXGenericGF.add (field.multiply(value, result), $0);
			});
			break;
		}
		
		return result;
	}
	
	func add (other: ZXGenericGFPoly) throws -> ZXGenericGFPoly {
		if (field.isEqual (other.field) == false) {
			throw ZXWriterError.IllegalArgument(
				"GF Polynomials must have the same GF field");
		}
		
		if (isZero) {
			return other;
		}
		
		if (other.isZero) {
			return self;
		}
		
		let isSelfLarger = (self.coefficients.count > other.coefficients.count);
		let smallerCoeffs = (isSelfLarger ? other.coefficients : self.coefficients);
		let largerCoeffs = (isSelfLarger ? self.coefficients : other.coefficients);
		
		// Copy higher-order terms only found in the higher-degree polynomial
		let highOrderOffset = largerCoeffs.count - smallerCoeffs.count;
		var newCoefficients = Array (largerCoeffs.prefix (highOrderOffset));
		var value : Int;
		
		for (idx, baseValue) in largerCoeffs.enumerated() {
			if (idx < highOrderOffset) { continue; }
			
			value = ZXGenericGF.add (smallerCoeffs [idx - highOrderOffset], baseValue);
			newCoefficients.append (value);
		}
		
		return ZXGenericGFPoly (field: self.field, coefficients: newCoefficients);
	}
	
	func subtract (other: ZXGenericGFPoly) throws -> ZXGenericGFPoly {
		return try add (other: other);
	}
	
	func multiply (other: ZXGenericGFPoly) throws -> ZXGenericGFPoly {
		if (field.isEqual (other.field) == false) {
			throw ZXWriterError.IllegalArgument(
				"GF Polynomials must have the same GF field");
		}
		
		if (isZero || other.isZero) {
			return field.Zero;
		}
		
		let coeffsA = self.coefficients;
		let coeffsB = other.coefficients;
		
		var newCoefficients = Array (repeating: 0, count: coeffsA.count + coeffsB.count - 1);
		var value : Int;
		
		for (idxA, coeffA) in coeffsA.enumerated() {
			for (idxB, coeffB) in coeffsB.enumerated() {
				value = newCoefficients [idxA + idxB];
				
				newCoefficients [idxA + idxB] = ZXGenericGF.add (value, 
					field.multiply (coeffA, coeffB));
			}
		}
		
		return ZXGenericGFPoly (field: self.field, coefficients: newCoefficients);
	}
	
	func multiply (value: Int) -> ZXGenericGFPoly {
		switch (value) {
		case 0:
			return field.Zero;
			
		case 1:
			return self;
			
		default:
			let newCoefficients = coefficients.map ({
				field.multiply ($0, value);
			});
			
			return ZXGenericGFPoly (field: self.field, coefficients: newCoefficients);
		}
	}
	
	func multiply (degree: Int, coefficient: Int) throws -> ZXGenericGFPoly {
		if (degree < 0) {
			throw ZXWriterError.IllegalArgument(
				"Degree must be zero or positive");
		}
		
		if (coefficient == 0) {
			return field.Zero;
		}
		
		let newCoefficients = coefficients.map ({
			field.multiply ($0, coefficient);
		});
		
		return ZXGenericGFPoly (field: self.field, coefficients: newCoefficients);
	}
	
	func divide (other: ZXGenericGFPoly) throws -> (quotient: ZXGenericGFPoly, remainder: ZXGenericGFPoly) {
		if (field.isEqual (other.field) == false) {
			throw ZXWriterError.IllegalArgument(
				"GF Polynomials must have the same GF field");
		}
		
		if (other.isZero) {
			throw ZXWriterError.IllegalArgument(
				"Cannot divide by zero");
		}
		
		var quotient : ZXGenericGFPoly = field.Zero;
		var remainder : ZXGenericGFPoly = self;
		
		let leadingTerm = other.coefficient (degree: other.degree);
		let inverseLeadingTerm = try field.multInverse (value: leadingTerm);
		
		var degreeDifference : Int;
		var scale : Int;
		
		var curr_term : ZXGenericGFPoly;
		var curr_quotient : ZXGenericGFPoly;
		
		while ((remainder.degree >= other.degree) && !remainder.isZero) {
			degreeDifference = remainder.degree - other.degree;
			
			scale = field.multiply (remainder.coefficient (degree: remainder.degree), 
				inverseLeadingTerm);
			
			curr_term = try other.multiply (degree: degreeDifference, coefficient: scale);
			curr_quotient = try field.buildMonomial (degree: degreeDifference, coefficient: scale);
			
			quotient = try quotient.add (other: curr_quotient);
			remainder = try remainder.add (other: curr_term);
		}
		
		return (quotient, remainder);
	}
	
	public var debugDescription: String {
		var result = String();
		
		var curr_coeff : Int;
		
		for curr_degree in (0...degree).reversed() {
			curr_coeff = coefficient (degree: curr_degree);
			
			if (curr_coeff == 0) { continue; }
			
			// Operator
			if (curr_coeff < 0) {
				result.append (" - ");
				curr_coeff = -curr_coeff;
			
			} else {
				if (!result.isEmpty) {
					result.append (" + ");
				}
			}
			
			if ((curr_degree == 0) || (curr_coeff != 1)), 
				let alphaPower = try? field.log (value: curr_coeff) {
				
				switch (alphaPower) {
				case 0:
					result.append ("1");
					break;
					
				case 1:
					result.append ("a");
					break;
					
				default:
					result.append ("a^\(alphaPower)");
					break;
				}
			}
			
			if (curr_degree != 0) {
				if (curr_degree == 1) {
					result.append ("x");
				} else {
					result.append ("x^\(curr_degree)");
				}
			}
		}
		
		return result;
	}
}
