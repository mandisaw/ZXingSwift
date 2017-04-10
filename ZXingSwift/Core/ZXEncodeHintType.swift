//
//  ZXEncodeHintType.swift
//  ZXingSwift
//
//  Created by Mandisa Washington on 4/7/17.
//  Based on ZXing project by Daniel Switkin.
//
//  Copyright © 2017 ZXingSwift Project. All rights reserved.
//

import Foundation

/** Optional encoding hints to be passed to Writers */
public enum ZXEncodeHintType {
	
	/** Specifies what degree of error correction to use, in formats that support it, for example, QR Code.
	 Type of correction is encoder-dependent. Most encoders support String type-specification, with additional
	 specifiers possible.
	 - QR Code: Use QRCode.ErrorCorrectionLevel
	 - Aztec: Use Integer, representing the minimal percentage of error-correction words (minimum 25% EC words)
	 - PDF417: Use Integer, valid values in the range 0-8
	 */
	case ErrorCorrection (Any);
	
	/** Specifies character encoding to use, where applicable. */
	case CharacterSet (String.Encoding);
	
	/** DataMatrix-only: Specifies the matrix shape to use */
//	case DataMatrixShape (DataMatrix.SymbolShapeHint);
	
	/** DataMatrix-only: Specifies a maximum barcode size to use */
	case DataMatrixMaxSize (CGSize);
	
	/** Specifies margin, in pixels, to use when generating a barcode. The meaning is encoder-dependent.
	 - 1D formats: Typically interpreted as left/right margin
	*/
	case Margin (Int);
	
	/** PDF 417-only: Flag specifying use of Compact Mode */
	case PDF417_UseCompactMode (Bool);
	
	/** PDF 417-only: Specifies type of compaction mode to use */
//	case PDF417_CompactionMode (PDF417.Compaction);
	
	/** PDF 417-only: Specifies the minimum and maximum number of rows and columns */
//	case PDF417_Dimensions (PDF417.Dimensions);
	
	/** Aztec-only: Specifies the required number of layers.
	 - Negative: Use a compact Aztec code.
	 - 0 (default): Use the minimum number of layers
	 - Positive: Use a normal (not compact) Aztec code.
	 */
	case AztecLayers (Int);
	
	/** QR Code-only: Specifies the version of QR Code to be encoded */
	case QR_Version (Int);
}
