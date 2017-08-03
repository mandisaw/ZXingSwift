//
//  ZXEncodingHints.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 4/7/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

/** Optional encoding hints to be passed to Writers */
public class ZXEncodingHints : NSObject {
	
	public override init() {
		super.init();
	}
	
	/** Specifies what degree of error correction to use, in formats that support it, for example, QR Code.
	 Type of correction is encoder-dependent. Most encoders support String type-specification, with additional
	 specifiers possible.
	 - QR Code: Use QRCode.ErrorCorrectionLevel
	 - Aztec: Use Integer, representing the minimal percentage of error-correction words (minimum 25% EC words)
	 - PDF417: Use Integer, valid values in the range 0-8
	 */
	public var errorCorrection : Any? = nil;
	
	/** Specifies character encoding to use, where applicable. */
	public var characterEncoding : String.Encoding? = nil;
	
	/** DataMatrix-only: Specifies the matrix shape to use */
//	public var dataMatrixShape : DataMatrix.SymbolShapeHint? = nil;
	
	/** DataMatrix-only: Specifies a maximum barcode size to use */
	public var dataMatrixMaxSize : CGSize? = nil;
	
	/** Specifies margin, in pixels, to use when generating a barcode. The meaning is encoder-dependent.
	 - 1D formats: Typically interpreted as left/right margin
	*/
	public var margin : Int? = nil;
	
	/** PDF 417-only: Flag specifying use of Compact Mode */
	public var PDF417_useCompactMode : Bool? = nil;
	
	/** PDF 417-only: Specifies type of compaction mode to use */
//	public var PDF417_compactionMode : PDF417.Compaction? = nil;
	
	/** PDF 417-only: Specifies the minimum and maximum number of rows and columns */
//	public var PDF417_dimensions : PDF417.Dimensions? = nil;
	
	/** Aztec-only: Specifies the required number of layers.
	 - Negative: Use a compact Aztec code.
	 - 0 (default): Use the minimum number of layers
	 - Positive: Use a normal (not compact) Aztec code.
	 */
	public var aztecLayers : Int? = nil;
	
	/** QR Code-only: Specifies the version of QR Code to be encoded */
	public var qrVersion : Int? = nil;
}
