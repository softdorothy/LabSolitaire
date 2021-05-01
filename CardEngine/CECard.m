// =====================================================================================================================
//  CECard.m
// =====================================================================================================================


#import <AssertMacros.h>
#import "CECard.h"


#define RANDOM_ROTATION		0


static void AddRoundedRectToPath (CGContextRef context, CGRect rect, CGFloat ovalW, CGFloat ovalH);
static void RandomizeSeed (void);


static bool	_randomizedSeed = false;


@implementation CECard
// ============================================================================================================== CECard
// ---------------------------------------------------------------------------------------------------------- synthesize

@synthesize faceUp = _faceUp;
@synthesize transform = _transform;
@synthesize reversed = _reversed;
@synthesize alpha = _alpha;

#pragma mark ------ Class Methods
// ----------------------------------------------------------------------------------------------- indexWithRank:andSuit

+ (NSUInteger) indexWithRank: (CERank) rank andSuit: (CESuit) suit
{
	NSUInteger		index = 0;
	
	// Param check.
	require ((rank >= kCERankAce) && (rank <= kCERankKing), bail);
	require ((suit >= kCESuitDiamonds) && (suit <= kCESuitClubs), bail);
	
	// Compute index.
	index = (suit * 13) + rank;
	
bail:
	
	return index;
}

// ------------------------------------------------------------------------------------------------------- rankFromIndex

+ (CERank) rankFromIndex: (NSUInteger) index
{
	CERank		rank = 0;
	
	// Param check.
	require ((index >= 1) && (index <= 52), bail);
	
	// Modulo 13.
	rank = ((index - 1) % 13) + 1;
	
bail:
	
	return rank;
}

// ------------------------------------------------------------------------------------------------------- suitFromIndex

+ (CESuit) suitFromIndex: (NSUInteger) index
{
	CESuit		suit = 0;
	
	// Param check.
	require ((index >= 1) && (index <= 52), bail);
	
	// Divide by 13.
	suit = (index - 1) / 13;
	
bail:
	
	return suit;
}

// ------------------------------------------------------------------------------------------------------- stringForRank

+ (NSString *) stringForRank: (CERank) rank
{
	if (rank == kCERankAce)
		return @"A";
	else if ((rank >= kCERankTwo) && (rank <= kCERankTen))
		return [NSString stringWithFormat: @"%d", rank];
	else if (rank == kCERankJack)
		return @"J";
	else if (rank == kCERankQueen)
		return @"Q";
	else if (rank == kCERankKing)
		return @"K";
	else
		return nil;
}

// --------------------------------------------------------------------------------------------------- longStringForRank

+ (NSString *) longStringForRank: (CERank) rank
{
	if (rank == kCERankAce)
		return @"Ace";
	else if ((rank >= kCERankTwo) && (rank <= kCERankTen))
		return [NSString stringWithFormat: @"%d", rank];
	else if (rank == kCERankJack)
		return @"Jack";
	else if (rank == kCERankQueen)
		return @"Queen";
	else if (rank == kCERankKing)
		return @"King";
	else
		return nil;
}

// ------------------------------------------------------------------------------------------------------- stringForSuit

+ (NSString *) stringForSuit: (CESuit) suit
{
	if (suit == kCESuitDiamonds)
		return [NSString stringWithFormat: @"%C", (unichar) 0x2666];
	else if (suit == kCESuitClubs)
		return [NSString stringWithFormat: @"%C", (unichar) 0x2663];
	else if (suit == kCESuitHearts)
		return [NSString stringWithFormat: @"%C", (unichar) 0x2665];
	else if (suit == kCESuitSpades)
		return [NSString stringWithFormat: @"%C", (unichar) 0x2660];
	else
		return nil;
}

// -------------------------------------------------------------------------------------------------- asciiStringForSuit

+ (NSString *) asciiStringForSuit: (CESuit) suit
{
	if (suit == kCESuitDiamonds)
		return @"D";
	else if (suit == kCESuitClubs)
		return @"C";
	else if (suit == kCESuitHearts)
		return @"H";
	else if (suit == kCESuitSpades)
		return @"S";
	else
		return nil;
}

// ---------------------------------------------------------------------------------------------- longAsciiStringForSuit

+ (NSString *) longAsciiStringForSuit: (CESuit) suit
{
	if (suit == kCESuitDiamonds)
		return @"Diamonds";
	else if (suit == kCESuitClubs)
		return @"Clubs";
	else if (suit == kCESuitHearts)
		return @"Hearts";
	else if (suit == kCESuitSpades)
		return @"Spades";
	else
		return nil;
}

// ----------------------------------------------------------------------------------------------- stringForRank:andSuit

+ (NSString *) stringForRank: (CERank) rank andSuit: (CESuit) suit
{
	return [NSString stringWithFormat: @"%@%@", [CECard stringForRank: rank], [CECard stringForSuit: suit]];
}

#pragma mark ------ Methods
// ---------------------------------------------------------------------------------------------------------------- init

- (id) init
{
	// Call through below with zero index (random card).
	return ([self initWithIndex: 0]);
}

// ------------------------------------------------------------------------------------------------------- initWithIndex

- (id) initWithIndex: (NSUInteger) index
{
	id		myself;
	
	// Super.
	myself = [super init];
	require (myself, bail);
	
	// Assign instance variable.
	if (index == 0)
		index = (rand () % 52) + 1;
	_index = index;
	_faceUp = NO;
	_transform = CGAffineTransformIdentity;
	_reversed = (CERandomInt (2) == 0);
	_alpha = 1.0;
	
bail:
	
	return myself;
}

// ------------------------------------------------------------------------------------------------------------- dealloc

- (void) dealloc
{
	// Super.
	[super dealloc];
}

// ---------------------------------------------------------------------------------------------------------------- suit

- (CESuit) suit
{
	// Return.
	return [CECard suitFromIndex: _index];
}

// ---------------------------------------------------------------------------------------------------------------- rank

- (CERank) rank
{
	// Return.
	return [CECard rankFromIndex: _index];
}

// --------------------------------------------------------------------------------------------------------------- index

- (NSUInteger) index
{
	// Return.
	return _index;
}

// -------------------------------------------------------------------------------------------------- randomizeTransform

- (void) randomizeTransform
{
	_transform = CGAffineTransformMakeTranslation (round (CERandomFloat (5.0) - 2.0), round (CERandomFloat (5.0) - 2.0));
	
#if RANDOM_ROTATION
	_transform = CGAffineTransformRotate (_transform, (CERandomFloat (11.0) - 5.0) / 150.0);
#endif	// RANDOM_ROTATION
}

// ------------------------------------------------------------------------------------------------- cardIsOppositeColor

- (BOOL) cardIsOppositeColor: (CECard *) cardTesting
{
	return ((CESuitIsRed (self.suit) && CESuitIsBlack (cardTesting.suit)) || 
			(CESuitIsBlack (self.suit) && CESuitIsRed (cardTesting.suit)));
}

// ------------------------------------------------------------------------------------------------ cardRankIsOneGreater

- (BOOL) cardRankIsOneGreater: (CECard *) cardTesting
{
	return (([self rank] + 1) == [cardTesting rank]);
}

// ------------------------------------------------------------------------------------------------ cardRankIsOneGreater

- (NSString *) description
{
	return ([NSString stringWithFormat: @"%@-%@", [CECard stringForRank: [CECard rankFromIndex: _index]], 
			[CECard longAsciiStringForSuit: [CECard suitFromIndex: _index]]]);
}

@end


#pragma mark ------ Functions
// =========================================================================================================== Functions
// --------------------------------------------------------------------------------------------------- CEFillRoundedRect

void CEFillRoundedRect (CGContextRef context, CGRect rect, CGFloat radius)
{
	// Created rounded rect.
	AddRoundedRectToPath (context, rect, radius, radius);
	
	// Fill.
	CGContextFillPath (context);
}

// ------------------------------------------------------------------------------------------ CEStrokeRoundedRectOfWidth

void CEStrokeRoundedRectOfWidth (CGContextRef context, CGRect rect, CGFloat radius, CGFloat width)
{
	// Created rounded rect.
	AddRoundedRectToPath (context, CGRectInset (rect, width / 2., width / 2.), radius, radius);
	
	// Set line width.
	CGContextSetLineWidth(context, width);
	
	// Stroke.
	CGContextStrokePath (context);
}

// --------------------------------------------------------------------------------------------------------- CERandomInt

int CERandomInt (int range)
{
	// Make sure we set the random seed to a unique value.
	if (_randomizedSeed == false)
		RandomizeSeed();
	
	return (rand () % range);
}

// ------------------------------------------------------------------------------------------------------- CERandomFloat

CGFloat CERandomFloat (CGFloat range)
{
	// Make sure we set the random seed to a unique value.
	if (_randomizedSeed == false)
		RandomizeSeed();
	
	return rand () / (((CGFloat) RAND_MAX + 1) / range);
}

// ------------------------------------------------------------------------------------------------ AddRoundedRectToPath

static void AddRoundedRectToPath (CGContextRef context, CGRect rect, CGFloat ovalW, CGFloat ovalH)
{
	CGFloat		fw, fh;
	
	// Begin path.
	CGContextBeginPath (context);
	
	// If the width or height of the corner oval is zero, then it reduces to a standard rectangle.
	if ((ovalW == 0) || (ovalH == 0))
	{
		CGContextAddRect (context, rect);
		return;
	}
	
	// Save.
	CGContextSaveGState (context);
	
	// Translate the origin of the contex to the lower left corner of the rectangle.
	CGContextTranslateCTM (context, CGRectGetMinX (rect), CGRectGetMinY (rect));
	
	// Normalize the scale of the context so that the width and height of the arcs are 1.0
	CGContextScaleCTM (context, ovalW, ovalH);
	
	// Calculate the width and height of the rectangle in the new coordinate system.
	fw = CGRectGetWidth (rect) / ovalW;
	fh = CGRectGetHeight (rect) / ovalH;
	
	// CGContextAddArcToPoint adds an arc of a circle to the context's path (creating the rounded
	// corners). It also adds a line from the path's last point to the begining of the arc, making
	// the sides of the rectangle.
	CGContextMoveToPoint (context, fw, fh / 2.0);					// Start at lower right corner
	CGContextAddArcToPoint (context, fw, fh, fw / 2.0, fh, 1.0);	// Top right corner
	CGContextAddArcToPoint (context, 0.0, fh, 0.0, fh / 2.0, 1.0);	// Top left corner
	CGContextAddArcToPoint (context, 0.0, 0.0, fw / 2.0, 0.0, 1.0);	// Lower left corner
	CGContextAddArcToPoint (context, fw, 0.0, fw, fh / 2.0, 1.0);	// Back to lower right
	
	// Restore.
	CGContextRestoreGState (context);
	
	// Close the path
	CGContextClosePath (context);
}

// ------------------------------------------------------------------------------------------------------- RandomizeSeed

static void RandomizeSeed (void)
{
	// Randomize random number seed.
	srand ((unsigned) time (nil));
	_randomizedSeed = true;
}

