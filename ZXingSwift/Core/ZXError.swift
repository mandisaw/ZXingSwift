//
//  ZXError.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 4/7/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

public enum ZXWriterError : Error {
	case InvalidFormat (String);
	case IllegalArgument (String);
	case Unspecified (String);
	
	public var localizedDescription: String {
		switch (self) {
		case 
			.InvalidFormat (let message), 
			.IllegalArgument (let message), 
		     .Unspecified (let message):
			
			return message;
			
//		default:
//			return "Unknown";
		}
	}
}

public enum ZXReaderError : Error {
	case Unspecified (String);
	
	public var localizedDescription: String {
		switch (self) {
		case 
		     .Unspecified (let message):
			
			return message;
			
//		default:
//			return "Unknown";
		}
	}
}
