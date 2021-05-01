// =====================================================================================================================
//  CEStack.m
// =====================================================================================================================


#import <AssertMacros.h>
#import "CEStackPrivate.h"
#import "CECard.h"


#define kCardIsFaceUpFlag		0x1000
#define kCardIndexMask			0X0FFF


@interface CardData : NSObject
{
	CECard	*_card;
	BOOL	_promised;
}
@property(nonatomic,retain)				CECard		*card;
@property(nonatomic,getter=isPromised)	BOOL		promised;
@end


static int16_t winRand (void);
static void winSRand (int32_t seed);

static int32_t gWinRandState = 0;


@implementation CEStack
// ============================================================================================================= CEStack
// --------------------------------------------------------------------------------------------------------- deckOfCards

+ (id) deckOfCards
{
	NSUInteger	i;
	id			deck;
	
	deck = [[[CEStack alloc] init] autorelease];
	require (deck, bail);
	
	// Add deck of cards.
	for (i = 1; i <= 52; i++)
	{
		CECard		*card;
		
		// Add card.
		card = [[CECard alloc] initWithIndex: i];
		[deck addCardWithoutNotification: card];
		[card release];
	}
	
bail:
	
	return deck;
}

// ---------------------------------------------------------------------------------------------------------------- init

- (id) init
{
	id		myself;
	
	// Super.
	myself = [super init];
	require (myself, bail);
	
	// Initialize instance variables.
	_cards = nil;
	
bail:
	
	return myself;
}

// ------------------------------------------------------------------------------------------------------------- dealloc

- (void) dealloc
{
	// Release instance variables.
	[_cards release];
	
	// Super.
	[super dealloc];
}

#pragma mark ------ card accessors
// ------------------------------------------------------------------------------------------------------- numberOfCards

- (NSUInteger) numberOfCards
{
	if (_cards)
		return [_cards count];
	else
		return 0;
}

// ---------------------------------------------------------------------------------------------------------------- seed

- (NSUInteger) seed
{
	return _seedUsed;
}

// --------------------------------------------------------------------------------------------------------- cardAtIndex

- (CECard *) cardAtIndex: (NSUInteger) index
{
	CECard	*card = nil;
	
	// NOP.
	require (_cards, bail);
	require (index < [_cards count], bail);
	
	// Return the object in our array at index.
	card = [(CardData *)[_cards objectAtIndex: index] card];
	
bail:
	
	return card;
}

// -------------------------------------------------------------------------------------------------------- indexForCard

- (NSUInteger) indexForCard: (CECard *) card
{
	NSUInteger	count, i;
	NSUInteger	index = NSNotFound;
	
	// NOP.
	require (card, bail);
	
	// Return the index of the object in our array.
	count = [self numberOfCards];
	for (i = 0; i < count; i++)
	{
		if ([(CardData *)[_cards objectAtIndex: i] card] == card)
		{
			index = i;
			break;
		}
	}
	
bail:
	
	return index;
}

// --------------------------------------------------------------------------------------------------- stackContainsCard

- (BOOL) stackContainsCard: (CECard *) card
{
	NSUInteger	count, i;
	BOOL		contains = NO;
	
	// Param check.
	require (card, bail);
	
	// Is the card in our array?
	count = [self numberOfCards];
	for (i = 0; i < count; i++)
	{
		if ([(CardData *)[_cards objectAtIndex: i] card] == card)
		{
			contains = YES;
			break;
		}
	}
	
bail:
	
	return contains;
}

// ------------------------------------------------------------------------------------------------------------- topCard

- (CECard *) topCard
{
	CECard	*card = nil;
	
	// NOP.
	require (_cards, bail);
	require ([_cards count] > 0, bail);
	
	// Return the last object in our array.
	card = [(CardData *)[_cards lastObject] card];
	
bail:
	
	return card;
}

// --------------------------------------------------------------------------------------------- cardArrayRepresentation

- (NSArray *) cardArrayRepresentation
{
	NSMutableArray	*array;
	NSUInteger		count, i;
	
	// Create empty array.
	array = [[[NSMutableArray alloc] initWithCapacity: 3] autorelease];
	
	// For each card, add an NSNumber representing the value of the card to array.
	count = [self numberOfCards];
	for (i = 0; i < count; i++)
	{
		CECard      *card;
		NSUInteger  cardIndex;
		
		// One card.
		card = [self cardAtIndex: i];
		
		// Get card index - apply face-up mask.
		cardIndex = [card index];
		if ([card isFaceUp])
			cardIndex = cardIndex | kCardIsFaceUpFlag;
		
		// Add to array.
		[array addObject: [NSNumber numberWithUnsignedInteger: cardIndex]];
	}
	
	return array;
}

#pragma mark ------ adding cards
// ------------------------------------------------------------------------------------------------------------- addCard

- (void) addCard: (CECard *) card
{
	// Param check.
	require (card, bail);
	
	// Add the card.
	[self addCardWithoutNotification: card];
	
	// Notify observers that the card stack was changed.
	[[NSNotificationCenter defaultCenter] postNotificationName: @"StackDidChangeCount" object: self userInfo: nil];
	
bail:
	
	return;
}

// ------------------------------------------------------------------------------------------- addCardsFromStack:inRange

- (void) addCardsFromStack: (CEStack *) stack inRange: (NSRange) range
{
	NSUInteger	i;
	
	// Param check.
	require (stack, bail);
	require ([stack numberOfCards] >= NSMaxRange (range), bail);
	
	// Add the cards one at a time.
	for (i = range.location; i < NSMaxRange (range); i++)
		[self addCardWithoutNotification: [stack cardAtIndex: i]];
	
	// Notify observers that the card stack was changed.
	[[NSNotificationCenter defaultCenter] postNotificationName: @"StackDidChangeCount" object: self userInfo: nil];
	
bail:
	
	return;
}

// ------------------------------------------------------------------------------------------------ addAllCardsFromStack

- (void) addAllCardsFromStack: (CEStack *) stack faceUp: (BOOL) faceUpOrDown
{
	NSUInteger		count, i;
	
	// Param check.
	require (stack, bail);
	
	// How many cards are in stack passed in?
	count = [stack numberOfCards];
	require_quiet (count > 0, bail);
	
	// Add the cards one at a time.
	for (i = 0; i < count; i++)
	{
		CECard	*card;
		
		card = [stack cardAtIndex: count - i - 1];
		[card setFaceUp: faceUpOrDown];
		[self addCardWithoutNotification: card];
	}
	
	// Notify observers that the card stack was changed.
	[[NSNotificationCenter defaultCenter] postNotificationName: @"StackDidChangeCount" object: self userInfo: nil];
	
bail:
	
	return;
}

// -------------------------------------------------------------------------------------------------- insertCard:atIndex

- (void) insertCard: (CECard *) card atIndex: (NSUInteger) index
{
	CardData	*cardData;
	
	// Param check.
	require (card, bail);
	
	// Create lazily.
	if (_cards == nil)
		_cards = [[NSMutableArray alloc] initWithCapacity: 3];
	
	// Param error (should we raise?).
	if (index > [_cards count])
		return;
	
	// Insert card as card data.
	cardData = [[CardData alloc] init];
	[cardData setCard: card];
	[_cards insertObject: cardData atIndex: index];
	[cardData release];
	
	// Notify observers that the card stack was changed.
	[[NSNotificationCenter defaultCenter] postNotificationName: @"StackDidChangeCount" object: self userInfo: nil];
	
bail:
	
	return;
}

// ------------------------------------------------------------------------------------------ addDeckWithRandomTransform

- (void) addDeckWithRandomTransform: (BOOL) random
{
	NSUInteger	i;
	
	// Add deck of cards.
	for (i = 1; i <= 52; i++)
	{
		CECard		*card;
		
		// Add card.
		card = [[CECard alloc] initWithIndex: i];
		if (random)
			[card randomizeTransform];
		[self addCardWithoutNotification: card];
		[card release];
	}
	
	// Notify observers that the card stack was changed.
	[[NSNotificationCenter defaultCenter] postNotificationName: @"StackDidChangeCount" object: self userInfo: nil];
	
bail:
	
	return;
}

// ----------------------------------------------------------------------- addCardsFromCardArrayRepresentation:randomize

- (void) addCardsFromCardArrayRepresentation: (NSArray *) array randomize: (BOOL) randomize
{
	NSUInteger	count, i;
	
	// Param check.
	require (array, bail);
	
	// See if there are any cards here.
	count = [array count];
	require_quiet (count > 0, bail);
	
	// For each card, add an NSNumber representing the value of the card to array.
	for (i = 0; i < count; i++)
	{
		int				cardIndex;
		CECard		*card;
		
		// Get raw card index from array.
		cardIndex = [[array objectAtIndex: i] intValue];
		
		// Create card - pay special attention to face-up flag.
		card = [[CECard  alloc] initWithIndex: cardIndex & kCardIndexMask];
		if ((cardIndex & kCardIsFaceUpFlag) == kCardIsFaceUpFlag)
			[card setFaceUp: YES];
		
		// BUG: Randomizing the transform needs to be done *before* the card is added to the stack for some reason.
		if (randomize)
			[card randomizeTransform];
		
		// Add card.
		[self addCardWithoutNotification: card];
		[card release];
	}
	
	// Notify observers that the card stack was changed.
	[[NSNotificationCenter defaultCenter] postNotificationName: @"StackDidChangeCount" object: self userInfo: nil];
	
bail:
	
	return;
}

#pragma mark ------ removing cards
// ---------------------------------------------------------------------------------------------------------- removeCard

- (void) removeCard: (CECard *) card
{
	NSUInteger	index;
	
	// Param check.
	require (card, bail);
	require (_cards, bail);
	
	// Skip out if this is not our card.
	if ([self stackContainsCard: card] == NO)
		goto bail;
	
	// Get index for card we are going to remove.
	index = [self indexForCard: card];
	require (index != NSNotFound, bail);
	
	// Remove card data object.
	[_cards removeObjectAtIndex: index];
	
	// Notify observers that the card stack was changed.
	[[NSNotificationCenter defaultCenter] postNotificationName: @"StackDidChangeCount" object: self userInfo: nil];
	
bail:
	
	return;
}

// -------------------------------------------------------------------------------------------------- removeCardsInRange

- (void) removeCardsInRange: (NSRange) range
{
	require (_cards, bail);
	require (NSMaxRange (range) <= [_cards count], bail);
	
	// Remove the card data objects.
	[_cards removeObjectsInRange: range];
	
	// Notify observers that the card stack was changed.
	[[NSNotificationCenter defaultCenter] postNotificationName: @"StackDidChangeCount" object: self userInfo: nil];
	
bail:
	
	return;
}

// ------------------------------------------------------------------------------------------------------ removeAllCards

- (void) removeAllCards
{
	// Param check.
	require (_cards, bail);
	require ([_cards count] > 0, bail);
	
	// Remove all cards (empty the array).
	[_cards removeAllObjects];
	
	// Notify observers that the card stack was changed.
	[[NSNotificationCenter defaultCenter] postNotificationName: @"StackDidChangeCount" object: self userInfo: nil];
	
bail:
	
	return;
}

#pragma mark ------ card flipping
// ----------------------------------------------------------------------------------------------------- flipCard:faceUp

- (void) flipCard: (CECard *) card faceUp: (BOOL) faceUpOrDown
{
	// Param check.
	require (card, bail);
	require (_cards, bail);
	
	// Skip out if this is not our card.
	if ([self stackContainsCard: card] == NO)
		goto bail;
	
	// NOP.
	if ([card isFaceUp] == faceUpOrDown)
		return;
	
	// Face up.
	[card setFaceUp: faceUpOrDown];
	
	// Notify observers that a card was flipped. We indicate which card so listener need only invalidate one card view.
	[[NSNotificationCenter defaultCenter] postNotificationName: @"StackDidFlipCard" object: self 
			userInfo: [NSDictionary dictionaryWithObjectsAndKeys: card, @"card", nil]];
	
bail:
	
	return;
}

// ------------------------------------------------------------------------------------------------------ revealAllCards

- (void) revealAllCards
{
	NSUInteger	count, i;
	CECard	*cardFlipped;
	BOOL		flippedACard = NO;
	
	// Param check.
	require (_cards, bail);
	
	// How many cards?
	count = [_cards count];
	require (count > 0, bail);
	
	// Set face up.
	for (i = 0; i < count; i++)
	{
		CECard	*card;
		
		card = [self cardAtIndex: i];
		if ([card isFaceUp] == NO)
		{
			[card setFaceUp: YES];
			if (flippedACard )
			{
				// If more than one card is revealed, we won't try to optimize the redraw.
				cardFlipped = nil;
			}
			else
			{
				// One card flipped - indicate it.
				cardFlipped = card;
				flippedACard = YES;
			}
		}
	}
	
	// Skip down to end if we have nothing to report.
	if (flippedACard == NO)
		goto bail;
	
	// Notify observers that some cards were flipped.
	if (cardFlipped)
	{
		// Indicate which card was flipped so listener need only invalidate one card view.
		[[NSNotificationCenter defaultCenter] postNotificationName: @"StackDidFlipCard" object: self 
				userInfo: [NSDictionary dictionaryWithObjectsAndKeys: cardFlipped, @"card", nil]];
	}
	else
	{
		// We don't specify which card (it is more than one) - listener will have to invalidate all card views.
		[[NSNotificationCenter defaultCenter] postNotificationName: @"StackDidFlipCard" object: self userInfo: nil];
	}
	
bail:
	
	return;
}

#pragma mark ------ actions
// ------------------------------------------------------------------------------------------------------------- shuffle

- (void) shuffle
{
	[self shuffleWithSeed: time (nil)];
}

// ----------------------------------------------------------------------------------------------------- shuffleWithSeed

- (void) shuffleWithSeed: (NSUInteger) seed
{
	NSUInteger	count, i;
	
	// NOP.
	require (_cards, bail);
	
	// Seed the psuedo-random number generator.
	_seedUsed = seed;
	srand ((unsigned) seed);
	
	// Swap each card with a random card.
	count = [_cards count];
	require (count > 1, bail);
	
	// New shuffle algorithm: Fisher and Yates (also called the Knuth Shuffle).
	for (i = count - 1; i > 0; i--)
		[_cards exchangeObjectAtIndex: i withObjectAtIndex: (rand () % (i + 1))];
	
	// Notify observers that the card stack order was changed.
	[[NSNotificationCenter defaultCenter] postNotificationName: @"StackDidChangeOrder" object: self userInfo: nil];
	
bail:
	
	return;
}

@end


@implementation CEStack (StackPriv)
// ================================================================================================= CEStack (StackPriv)
// ------------------------------------------------------------------------------------------------- debugRandomFunction

+ (void) debugRandomFunction: (NSUInteger) seed
{
	int			i;
	
	// Random seed.
	winSRand ((unsigned) seed);
	printf ("Random Number Seed = %lu\n", (unsigned long) seed);
	for (i = 0; i < 52; i++)
		printf ("Random Number = %d\n", winRand () % 52);
}

// ------------------------------------------------------------------------------------------------- shuffleDeckWithSeed

- (void) shuffleDeckWithSeed: (NSUInteger) seed
{
	NSUInteger	count, i;
	NSUInteger	wLeft;
	CEStack		*tempDeck;
	
	// NOP.
	require (_cards, bail);
	
	// Swap each card with a random card.
	count = [_cards count];
	wLeft = count;
	
	// A current restriction is that the stack has exactly 52 cards.
	require (count == 52, bail);
	
	// Random seed.
	winSRand ((unsigned) seed);
	
	// Card source.
	tempDeck = [CEStack deckOfCards];
	
	// The attempt below is to produce a deck of cards identical to ones Microsoft FreeCell would deal.
	// So far, either because my shuffle aglorithm is incorrect or because rand() gives different results from the 
	// Windows compiler, I have not been able to get Microsoft deals. I leave this code here though as an exercise.
	// Perhaps I can get it to work someday.
	for (i = 0; i < count; i++)
	{
		NSUInteger	j;
		
		j = winRand ();
		j = j % wLeft;
		[_cards replaceObjectAtIndex: i withObject: [tempDeck cardDataAtIndex: j]];
		[tempDeck exchangeCardAtIndex: j withCardAtIndex: --wLeft];
	}
	
	// Notify observers that the card stack order was changed.
	[[NSNotificationCenter defaultCenter] postNotificationName: @"StackDidChangeOrder" object: self userInfo: nil];
	
bail:
	
	return;
}

// ------------------------------------------------------------------------------------------ addAllCardsFromStackFaceUp

- (void) addAllCardsFromStackFaceUp: (CEStack *) stack
{
	[self addAllCardsFromStack: stack faceUp: YES];
}

// ------------------------------------------------------------------------------------------ addCardWithoutNotification

- (void) addCardWithoutNotification: (CECard *) card
{
	CardData	*cardData;
	
	// Param check.
	require (card, bail);
	
	// Create lazily.
	if (_cards == nil)
		_cards = [[NSMutableArray alloc] initWithCapacity: 5];
	
	// Add card as card data.
	cardData = [[CardData alloc] init];
	[cardData setCard: card];
	[_cards addObject: cardData];
	[cardData release];
	
bail:
	
	return;
}

// --------------------------------------------------------------------------------------------------------- promiseCard

- (void) promiseCard: (CECard *) card
{
	CardData	*cardData;
	
	// Param check.
	require (card, bail);
	
	// Create lazily.
	if (_cards == nil)
		_cards = [[NSMutableArray alloc] initWithCapacity: 5];
	
	// Add card as card data. Set promised flag to indicate it is not to be drawn yet.
	cardData = [[CardData alloc] init];
	[cardData setCard: card];
	[cardData setPromised: YES];
	[_cards addObject: cardData];
	[cardData release];
	
	_cardPromised = YES;
	
bail:
	
	return;
}

// -------------------------------------------------------------------------------------------------- promiseKeptForCard

- (void) promiseKeptForCard: (CECard *) card
{
	NSUInteger	index;
	
	// Get the card index.
	index = [self indexForCard: card];
	require (index != NSNotFound, bail);
	
	// Clear promised flag.
	[[_cards objectAtIndex: index] setPromised: NO];
	
	_cardPromised = NO;
	
	// Notify observers that the card stack was changed.
	[[NSNotificationCenter defaultCenter] postNotificationName: @"StackDidChangeCount" object: self userInfo: nil];
	
bail:
	
	return;
}

// ------------------------------------------------------------------------------------------------------ isCardPromised

- (BOOL) isCardPromised
{
	return _cardPromised;
}

// -------------------------------------------------------------------------------------- numberOfCardsExcludingPromised

- (NSUInteger) numberOfCardsExcludingPromised
{
	NSUInteger		count, i;
	NSUInteger		numCards = 0;
	
	// Walk our card data....
	count = [_cards count];
	for (i = 0; i < count; i++)
	{
		CardData	*oneCard;
		
		// Add 'not-promised' cards.
		oneCard = [_cards objectAtIndex: i];
		if ([oneCard isPromised] == NO)
			numCards = numCards + 1;
	}
	
	return numCards;
}
// ---------------------------------------------------------------------------------------------- cardsExcludingPromised

- (NSArray *) cardsExcludingPromised
{
	NSMutableArray	*cards;
	NSUInteger		count, i;
	
	// Create autorelease array.
	cards = [NSMutableArray arrayWithCapacity: 3];
	
	// Walk our card data....
	count = [_cards count];
	for (i = 0; i < count; i++)
	{
		CardData	*oneCard;
		
		// Add 'not-promised' cards.
		oneCard = [_cards objectAtIndex: i];
		if ([oneCard isPromised] == NO)
			[cards addObject: [oneCard card]];
	}
	
	return cards;
}

// ----------------------------------------------------------------------------------------------------- cardDataAtIndex

- (CardData *) cardDataAtIndex: (NSUInteger) index
{
	return [_cards objectAtIndex: index];
}

// ---------------------------------------------------------------------------------- replaceCardAtIndex:withCardAtIndex

- (void) replaceCardAtIndex: (NSUInteger) destIndex withCardAtIndex: (NSUInteger) srcIndex
{
	[_cards replaceObjectAtIndex: destIndex withObject: [_cards objectAtIndex: srcIndex]];
}

// --------------------------------------------------------------------------------- exchangeCardAtIndex:withCardAtIndex

- (void) exchangeCardAtIndex: (NSUInteger) destIndex withCardAtIndex: (NSUInteger) srcIndex
{
	[_cards exchangeObjectAtIndex: destIndex withObjectAtIndex: srcIndex];
}

@end


@implementation CardData
// ============================================================================================================ CardData
// ---------------------------------------------------------------------------------------------------------- synthesize

@synthesize card = _card;
@synthesize promised = _promised;

@end


// =========================================================================================================== Functions
// ------------------------------------------------------------------------------------------------------------- winRand

static int16_t winRand (void)
{
    gWinRandState = gWinRandState * 214013L + 2531011L;
    return (gWinRandState >> 16) & 0x7FFF;
}

// ------------------------------------------------------------------------------------------------------------ winSRand

static void winSRand (int32_t seed)
{
    gWinRandState = seed;
}
