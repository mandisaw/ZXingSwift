//
//  ZXBarcodeFormat.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 4/7/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

/** Enumerates barcode formats known to this package. */
public enum ZXBarcodeFormat : String, CustomDebugStringConvertible {
	
	/** Aztec 2D barcode format */
	case Aztec = "Aztec";
	
	/** CODABAR 1D barcode format */
	case Codabar = "Codabar";
	
	/** Code 39 1D barcode format */
	case Code39 = "Code 39";
	
	/** Code 93 1D barcode format */
	case Code93 = "Code 93";
	
	/** Code 128 1D barcode format */
	case Code128 = "Code 128";
	
	/** Data Matrix 2D barcode format */
	case DataMatrix = "DataMatrix";
	
	/** EAN-8 1D barcode format */
	case EAN8 = "EAN-8";
	
	/** EAN-13 1D barcode format */
	case EAN13 = "EAN-13";
	
	/** ITF (Interleaved Two of Five) 1D barcode format */
	case ITF = "ITF";
	
	/** MaxiCode 2D barcode format */
	case MaxiCode = "MaxiCode";
	
	/** PDF417 barcode format */
	case PDF417 = "PDF417";
	
	/** QR Code 2D barcode format */
	case QR_Code = "QR Code";
	
	/** RSS 14 barcode format */
	case RSS14 = "RSS 14";
	
	/** RSS Expanded barcode format */
	case RSS_Expanded = "RSS Expanded";
	
	/** UPC-A 1D barcode format */
	case UPC_A = "UPC-A'";
	
	/** UPC-E 1D barcode format */
	case UPC_E = "UPC-E";
	
	/** UPC/EAN extension - Not a standalone barcode format. */
	case UPC_EAN_Extension = "UPC/EAN Extension";
	
	public var debugDescription: String {
		return rawValue;
	}
}
