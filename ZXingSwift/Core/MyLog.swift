//
//  MyLog.swift
//  BCNavigatorStudent
//
//  Created by Mandisa Washington on 3/11/16.
//  Copyright © 2016 CUNY Brooklyn College. All rights reserved.
//

import Foundation

internal class MyLog : NSObject {
	
	static var logLevel : DebugLevel = DebugLevel.defaultLevel;
	
	static var DefaultDelimiter: String = "";
	
	private static var createLogMessage = {(arguments: [String]) -> String in 
		if (arguments.count == 1) {
			return arguments [0];
		} else {
			return arguments.joined (separator: DefaultDelimiter);
		}
	};
	
	private static func displayLog (level: DebugLevel, template: String, arguments: [String]) {
		let message = createLogMessage (arguments);
		
		if (DebugLevel.shouldDisplay (input: level, baseLevel: logLevel)) {
			NSLog (template, message);
		}
	}
	
	static func d (_ tag: String, _ arguments: String...) {
		let level = DebugLevel.Verbose;
		displayLog (level: level, template: tag, arguments: arguments);
	}
	
	static func i (_ tag: String, _ arguments: String...) {
		let level = DebugLevel.Informational;
		displayLog (level: level, template: tag, arguments: arguments);
	}
	
	static func w (_ tag: String, _ arguments: String...) {
		let level = DebugLevel.Warning;
		displayLog (level: level, template: tag, arguments: arguments);
	}
	
	static func e (_ tag: String, _ arguments: String...) {
		let level = DebugLevel.Error;
		displayLog (level: level, template: tag, arguments: arguments);
	}
	
	static func wtf (_ tag: String, _ arguments: String...) {
		let level = DebugLevel.FatalError;
		displayLog (level: level, template: tag, arguments: arguments);
	}
	
	static func d<C> (_ tag: String, _ arguments: C) 
		where C: Collection, C.Iterator.Element == String {
		
		let level = DebugLevel.Verbose;
		displayLog (level: level, template: tag, arguments: arguments.asArray());
	}
	
	static func i<C> (_ tag: String, _ arguments: C) 
		where C: Collection, C.Iterator.Element == String {
		
		let level = DebugLevel.Informational;
		displayLog (level: level, template: tag, arguments: arguments.asArray());
	}
	
	static func w<C> (_ tag: String, _ arguments: C) 
		where C: Collection, C.Iterator.Element == String {
		
		let level = DebugLevel.Warning;
		displayLog (level: level, template: tag, arguments: arguments.asArray());
	}
	
	static func e<C> (_ tag: String, _ arguments: C) 
		where C: Collection, C.Iterator.Element == String {
		
		let level = DebugLevel.Error;
		displayLog (level: level, template: tag, arguments: arguments.asArray());
	}
	
	static func wtf<C> (_ tag: String, _ arguments: C) 
		where C: Collection, C.Iterator.Element == String {
		
		let level = DebugLevel.FatalError;
		displayLog (level: level, template: tag, arguments: arguments.asArray());
	}
}

internal enum DebugLevel : Int {
	case Verbose = 0;
	case Informational = 1;
	case Warning = 2;
	case Error = 3;
	case FatalError = 4;
	
	static var defaultLevel : DebugLevel = DebugLevel.Verbose;
	
	static func shouldDisplay (input: DebugLevel, baseLevel: DebugLevel) -> Bool {
		return (input.rawValue >= baseLevel.rawValue);
	}
}

extension Collection {
	internal func asArray() -> [Self.Iterator.Element] {
		return (self as? [Self.Iterator.Element]) ?? 
			self.map ({ return $0; });
	}
}
