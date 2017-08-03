//
//  TextUtils.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 7/27/17.
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

internal class TextUtils : NSObject {
	
	private override init() {
		super.init();
	}
	
	static var DefaultLocale : Locale = Locale (identifier: "en_US_POSIX");
	
	static func isTextEqual (_ input1: String, _ input2: String, 
		locale optLocale: Locale? = nil) -> Bool {
		
		let locale = optLocale ?? DefaultLocale;
		
		let localizedInput1 = input1.lowercased (with: locale);
		let localizedInput2 = input2.lowercased (with: locale);
		
		return (localizedInput1 == localizedInput2);
	}
	
}
