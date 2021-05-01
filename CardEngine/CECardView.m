// =====================================================================================================================
//  CECardView.m
// =====================================================================================================================


#import <AssertMacros.h>
#import "CECard.h"
#import "CECardView.h"


UIImage		*gCardBack = nil;


static CGPDFDocumentRef	gCardPDFDocument = nil;


@implementation CECardView
// ========================================================================================================== CECardView
// ---------------------------------------------------------------------------------------------------------- synthesize

@synthesize highlightColor = _highlightColor;
@synthesize hasShadow = _hasShadow;

// ------------------------------------------------------------------------------------------------------------ cardSize

+ (CGSize) cardSize: (CECardSize) size
{
	if (size == kCardSizeMini)
		return CGSizeMake (46.0, 64.0);
	else if (size == kCardSizeSmall)
		return CGSizeMake (56.0, 78.0);
	else if (size == kCardSizeMedium)
		return CGSizeMake (64.0, 90.0);
	else if (size == kCardSizeLarge)
		return CGSizeMake (80.0, 112.0);
	else if (size == kCardSizeExtraLarge)
		return CGSizeMake (92.0, 128.0);
	else
		return CGSizeMake (0.0, 0.0);
}

// --------------------------------------------------------------------------------------------- playingCardCornerRadius

+ (CGFloat) playingCardCornerRadius: (CECardSize) size
{
	if (size == kCardSizeMini)
		return 2.0;
	else if (size == kCardSizeSmall)
		return 3.0;
	else if (size == kCardSizeMedium)
		return 4.0;
	else if (size == kCardSizeLarge)
		return 5.0;
	else if (size == kCardSizeExtraLarge)
		return 6.0;
	else
		return 0.0;
}

// ------------------------------------------------------------------------------------------- playingCardVerticalReveal

+ (CGFloat) playingCardVerticalReveal: (CECardSize) size
{
	if (size == kCardSizeMini)
		return 26.0;
	else if (size == kCardSizeSmall)
		return 29.0;
	else if (size == kCardSizeMedium)
		return 34.0;
	else if (size == kCardSizeLarge)
		return 40.0;
	else if (size == kCardSizeExtraLarge)
		return 52.0;
	else
		return 0.0;
}

// ------------------------------------------------------------------------------------------------------- initWithFrame

- (id) initWithFrame: (CGRect) frame
{
	id		myself;
	
	// Super.
	myself = [super initWithFrame: frame];
	require (myself, bail);
	
	// Initialize instance variables.
	_card = nil;
	_highlightColor = [[UIColor alloc] initWithRed: 0.0 green: 0.0 blue: 0.0 alpha: 0.25];
	
	_cardSize = kCardSizeMini;
	if (frame.size.width > 46.0)
		_cardSize = kCardSizeSmall;
	if (frame.size.width > 56.0)
		_cardSize = kCardSizeMedium;
	if (frame.size.width > 64.0)
		_cardSize = kCardSizeLarge;
	if (frame.size.width > 80.0)
		_cardSize = kCardSizeExtraLarge;
	
bail:
	
	return self;
}

// ------------------------------------------------------------------------------------------------------------- dealloc

- (void) dealloc
{
	// Release instance var.
	[_card release];
	[_highlightColor release];
	
	// Super.
	[super dealloc];
}

// ------------------------------------------------------------------------------------------------------------ isOpaque

- (BOOL) isOpaque
{
	return NO;
}

#pragma mark ------ accessors
// ------------------------------------------------------------------------------------------------------------- setCard

- (void) setCard: (CECard *) card
{
	// NOP.
	if (_card == card)
		return;
	
	// Release, retain, redraw.
	[_card release];
	_card = [card retain];
	
	[self setNeedsDisplay];
}

// ---------------------------------------------------------------------------------------------------------------- card

- (CECard *) card
{
	// Return.
	return _card;
}

// ------------------------------------------------------------------------------------------------------------ setLabel

- (void) setLabel: (NSString *) label
{
	// NOP.
	if (label == _label)
		return;
	
	// Release, retain, assign.
	[_label release];
	_label = [label retain];
	
	// Redraw.
	[self setNeedsDisplay];
}

// --------------------------------------------------------------------------------------------------------------- label

- (NSString *) label
{
	// Return value.
	return _label;
}

// -------------------------------------------------------------------------------------------------------- setHighlight

- (void) setHighlight: (BOOL) highlight
{
	// NOP.
	if (_highlight == highlight)
		return;
	
	// Assign.
	_highlight = highlight;
	
	// Redraw.
	[self setNeedsDisplay];
}

// ----------------------------------------------------------------------------------------------------------- highlight

- (BOOL) highlight
{
	// Return value.
	return _highlight;
}

// -------------------------------------------------------------------------------------------------------- setHasShadow

- (void) setHasShadow: (BOOL) shadow
{
	// NOP.
	if (shadow == _hasShadow)
		return;
	
	// Assign.
	_hasShadow = shadow;
	
	// Redraw.
	[self setNeedsDisplay];
}

// ----------------------------------------------------------------------------------------------------------- hasShadow

- (BOOL) hasShadow
{
	// Return value.
	return _hasShadow;
}

#pragma mark ------ drawing methods
// ------------------------------------------------------------------------------------------------------- fontForCorner

- (UIFont *) fontForCorner
{
	if (_cardSize == kCardSizeMini)
		return [UIFont fontWithName: @"Arial" size: 16];
	else if (_cardSize == kCardSizeSmall)
		return [UIFont fontWithName: @"Arial" size: 17];
	else if (_cardSize == kCardSizeMedium)
		return [UIFont fontWithName: @"Arial" size: 19];
	else if (_cardSize == kCardSizeLarge)
		return [UIFont fontWithName: @"Arial" size: 24];
	else if (_cardSize == kCardSizeExtraLarge)
		return [UIFont fontWithName: @"Arial" size: 26];
	else
		return nil;
}

// ------------------------------------------------------------------------------------------------------------ drawRect

- (void) drawRect: (CGRect) rect
{
	// Skip out if we don't have a card to display.
	if (_card == nil)
		return;
		
	// Call subclass-able methods for drawing card shadow, face or back.
	if (_hasShadow)
		[self drawShadow];
	if ([_card isFaceUp])
		[self drawCardFace];
	else
		[self drawCardBack];
	
	// Draw label.
	if (_label)
	{
		UIFont		*font;
		CGRect		box;
		CGRect		bounds;
		
		font = [self fontForCorner];
		box.size = [_label sizeWithAttributes: [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, nil]];
		box.size.width = box.size.width + 6.0;
		bounds = [self bounds];
		box.origin.x = floor((bounds.size.width - box.size.width) / 2.0);
		box.origin.y = floor((bounds.size.height - box.size.height) / 2.0);
		[[UIColor whiteColor] set];
		UIRectFill (box);
		[[UIColor blackColor] set];
		UIRectFrame (box);
		NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
		style.lineBreakMode = NSLineBreakByWordWrapping;
		style.alignment = NSTextAlignmentCenter;
		[_label drawInRect: box withAttributes: [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, 
				style, NSParagraphStyleAttributeName, nil]];
		[style release];
	}
}

// ---------------------------------------------------------------------------------------------------------- drawShadow

- (void) drawShadow
{
}

// -------------------------------------------------------------------------------------------------------- drawCardFace

- (void) drawCardFace
{
	CGRect				bounds;
	CGPDFPageRef		cardPage;
	CGContextRef		context;
	CGAffineTransform	transform;
	CFURLRef			base = nil;
	CFURLRef			url = nil;
	
	// Get our bounds and context.
	bounds = [self bounds];
	context = UIGraphicsGetCurrentContext ();
	
	if (gCardPDFDocument == nil)
	{
		CFBundleRef			bundle = nil;
		
		// Get image URL from bundle.
		bundle = CFBundleGetMainBundle ();
		require (bundle, bail);
		
		base = CFBundleCopyResourcesDirectoryURL (bundle);
		require (base, bail);
		
		url = CFURLCreateWithFileSystemPathRelativeToBase (kCFAllocatorDefault, CFSTR ("Cards.pdf"), 
				kCFURLPOSIXPathStyle, false, base); 
		require (url, bail);
		
		// Get PDF document.
		gCardPDFDocument = CGPDFDocumentCreateWithURL (url);
	}
	
	// Must have a PDF document by now.
	require (gCardPDFDocument, bail);
	
	// Get the page of the PDF that corresponds to our card index.
	cardPage = CGPDFDocumentGetPage (gCardPDFDocument, [_card index]);
	require (cardPage, bail);
	
	transform = CGPDFPageGetDrawingTransform (cardPage, kCGPDFCropBox, bounds, 0, true);
	
	CGContextSaveGState (context);
	CGContextSetInterpolationQuality (context, kCGInterpolationHigh);
	CGContextScaleCTM (context, 1.0, -1.0);
	CGContextTranslateCTM (context, 0.0, -bounds.size.height);
	CGContextConcatCTM (context, transform);
	CGContextDrawPDFPage (context, cardPage);
	CGContextRestoreGState (context);	
	
bail:
	
	// Highlight.
	if ((_highlight) && (_highlightColor))
	{
		[_highlightColor set];
		CEFillRoundedRect (context, bounds, [CECardView playingCardCornerRadius: _cardSize]);
	}
	
	// Clean up.
	if (base)
		CFRelease (base);
	if (url)
		CFRelease (url);
}

// -------------------------------------------------------------------------------------------------------- drawCardBack

- (void) drawCardBack
{
	CGRect				bounds;
	CGPDFPageRef		cardPage;
	CGContextRef		context;
	CGAffineTransform	transform;
	CFURLRef			base = nil;
	CFURLRef			url = nil;
	
	// Get our bounds and context.
	bounds = [self bounds];
	context = UIGraphicsGetCurrentContext ();
	
	if (gCardPDFDocument == nil)
	{
		CFBundleRef	bundle = nil;
		
		// Get image URL from bundle.
		bundle = CFBundleGetMainBundle ();
		require (bundle, bail);
		
		base = CFBundleCopyResourcesDirectoryURL (bundle);
		require (base, bail);
		
		url = CFURLCreateWithFileSystemPathRelativeToBase (kCFAllocatorDefault, CFSTR ("Cards.pdf"), 
				kCFURLPOSIXPathStyle, false, base); 
		require (url, bail);
		
		// Get PDF document.
		gCardPDFDocument = CGPDFDocumentCreateWithURL (url);
	}
	
	// Must have a PDF document by now.
	require (gCardPDFDocument, bail);
	
	// Get the page of the PDF that corresponds to our card index.
	cardPage = CGPDFDocumentGetPage (gCardPDFDocument, 53);
	require (cardPage, bail);
	
	transform = CGPDFPageGetDrawingTransform (cardPage, kCGPDFCropBox, bounds, 0, true);
	
	CGContextSaveGState (context);
	CGContextSetInterpolationQuality (context, kCGInterpolationHigh);
	CGContextScaleCTM (context, 1.0, -1.0);
	CGContextTranslateCTM (context, 0.0, -bounds.size.height);
	CGContextConcatCTM (context, transform);
	CGContextDrawPDFPage (context, cardPage);
	CGContextRestoreGState (context);	
	
bail:
	
	// Highlight.
	if ((_highlight) && (_highlightColor))
	{
		[_highlightColor set];
		CEFillRoundedRect (context, bounds, [CECardView playingCardCornerRadius: _cardSize]);
	}
	
	// Clean up.
	if (base)
		CFRelease (base);
	if (url)
		CFRelease (url);
}

@end
