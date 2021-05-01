// =====================================================================================================================
//  CECard.h
// =====================================================================================================================


#import <UIKit/UIKit.h>


// Card rank.
typedef int CERank;
enum
{
	kCERankAce = 1, 
	kCERankTwo = 2, 
	kCERankThree = 3, 
	kCERankFour = 4, 
	kCERankFive = 5, 
	kCERankSix = 6, 
	kCERankSeven = 7, 
	kCERankEight = 8, 
	kCERankNine = 9, 
	kCERankTen = 10, 
	kCERankJack = 11, 
	kCERankQueen = 12, 
	kCERankKing = 13
};

#define CERankIsFaceCard(rank) ((rank) >= kCERankJack && (rank) <= kCERankKing)

typedef NSUInteger CESuit;
enum
{
	kCESuitDiamonds = 0, 
	kCESuitClubs = 1,
	kCESuitHearts = 2, 
	kCESuitSpades = 3
};

#define CESuitIsRed(suit) ((suit) == kCESuitDiamonds || (suit) == kCESuitHearts)
#define CESuitIsBlack(suit) ((suit) == kCESuitSpades || (suit) == kCESuitClubs)


@interface CECard : NSObject
{
	NSUInteger          _index;
	BOOL				_faceUp;
	CGAffineTransform	_transform;
	BOOL				_reversed;
	CGFloat				_alpha;
}

@property(nonatomic,readonly)			CERank				rank;			// The rank of a card (Ace, Two, Three, etc.).
@property(nonatomic,readonly)			CESuit				suit;			// The suit of a card (Diamonds, Spades, etc.).
@property(nonatomic,readonly)			NSUInteger          index;			// Value is a combination of rank and suit (values run from 1 to 52).
@property(nonatomic,getter=isFaceUp)	BOOL				faceUp;			// Indicates if the card is face up or down.
@property(nonatomic)					CGAffineTransform	transform;		// Identity by default, a transform to give a card a rotation or offset.
@property(nonatomic)					BOOL				reversed;		// Indicates if the card is right-side up or not.
@property(nonatomic)					CGFloat				alpha;			// Opacity of card (default = 1).

// Class methods for converting between the more familiar rank/suit and 'index' used in this API.
+ (NSUInteger) indexWithRank: (CERank) rank andSuit: (CESuit) suit;
+ (CERank) rankFromIndex: (NSUInteger) index;
+ (CESuit) suitFromIndex: (NSUInteger) index;

// Class methods return a string representation for rank and suit.
+ (NSString *) stringForRank: (CERank) rank;
+ (NSString *) longStringForRank: (CERank) rank;
+ (NSString *) stringForSuit: (CESuit) suit;
+ (NSString *) asciiStringForSuit: (CESuit) suit;
+ (NSString *) longAsciiStringForSuit: (CESuit) suit;
+ (NSString *) stringForRank: (CERank) rank andSuit: (CESuit) suit;

// Designated initializer.
- (id) initWithIndex: (NSUInteger) index;

// Give the card a random rotation, offset.
- (void) randomizeTransform;

// Returns YES if cardTesting is the opposite color of self (black vs. red).
- (BOOL) cardIsOppositeColor: (CECard *) cardTesting;

// Returns YES if the rank of cardTesting is one greater than card (self).
- (BOOL) cardRankIsOneGreater: (CECard *) cardTesting;

@end

// Some drawing functions used internally and useful for subclassers that want to draw the cards with a highlight, etc.
void CEFillRoundedRect (CGContextRef context, CGRect rect, CGFloat radius);
void CEStrokeRoundedRectOfWidth (CGContextRef context, CGRect rect, CGFloat radius, CGFloat width);
int CERandomInt (int range);
CGFloat CERandomFloat (CGFloat range);

