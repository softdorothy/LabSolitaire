// =====================================================================================================================
//  CEStack.h
// =====================================================================================================================


#import <UIKit/UIKit.h>


@class CECard;


@interface CEStack : NSObject
{
	NSMutableArray	*_cards;
	BOOL			_cardPromised;
	NSUInteger		_seedUsed;
}

@property(nonatomic,readonly) NSUInteger	numberOfCards;		// Number of PlayingCard objects associated with the card stack.
@property(nonatomic,readonly) NSUInteger	seed;				// Seed used to shuffle the deck. Undefined if deck has not been shuffled.

// Returns aan autoreleased deck of cards in order.
+ (id) deckOfCards;

// Returns the card at the specified index.  Returns nil if the index is out of range.
- (CECard *) cardAtIndex: (NSUInteger) index;

// Returns the index of the specified card.  Returns NSNotFound if the card is not in the stack.
- (NSUInteger) indexForCard: (CECard *) card;

// Returns YES if the specified card is in the stack, NO otherwise.
- (BOOL) stackContainsCard: (CECard *) card;

// Returns the top card of the stack. By convention, the top card will be the last card in the 'cards' array.
// Equivalent to calling: [[stack cards] lastObject] or [stack cardAtIndex: [stack numberOfCards] - 1].
// Returns nil if there are no cards in the stack.
- (CECard *) topCard;

// For archiving purposes.  Returns an array of NSNumber objects that represent the card indicees in the stack.
// Use -[addCardsFromCardArrayRepresentation:randomize:] below to restore a stack from the card array.
- (NSArray *) cardArrayRepresentation;

// Add a card to the top of the stack. By convention, the top card will be the last card in the 'cards' array.
- (void) addCard: (CECard *) card;

// For passing more than one card from a stack, you can specify the range from within the stack to add.
// Note: the cards in the stack passed in are not removed.
- (void) addCardsFromStack: (CEStack *) stack inRange: (NSRange) range;

// For passing all the cards from a stack to target. Cards are added one at a time from top of stack passed in.
// Note: the cards in stack passed in are not removed.
- (void) addAllCardsFromStack: (CEStack *) stack faceUp: (BOOL) faceUpOrDown;

// The following calls alter the stack of cards in various ways.  When you use the following calls the stack will 
// communicate with any and all StackView objects that are backed by this stack. In this way, changes will 
// percolate up and be revealed to the user as the StackView updates its layout.

// Inserts a playing card at the specified index. Does nothing if the index is out of range.
- (void) insertCard: (CECard *) card atIndex: (NSUInteger) index;

// Convenience method to add a deck of cards (the standard set of 52 cards).
// They are not shuffled and are added to top of the stack (if other cards already exist).
// If random, the cards are given a slight random rotation.
- (void) addDeckWithRandomTransform: (BOOL) random;

// Using an array obtained from a call to -[cardArrayRepresentation] (above), restores the stack to the contents of 
// the array. This and -[cardArrayRepresentation] are convenience methods for saving and restoring game state.
- (void) addCardsFromCardArrayRepresentation: (NSArray *) array randomize: (BOOL) randomize;

// Removes a specific card from the stack.  Does nothing if the card is not in the current stack.
- (void) removeCard: (CECard *) card;

// Removes cards within the specified range from the stack.
- (void) removeCardsInRange: (NSRange) range;

// Convenience method to remove (release) all cards in the stack.  Handy when a 'hand' in a game is cleared.
- (void) removeAllCards;

// Flips the specified card face up or face down. Does nothing if the card is not in the stack or if the card 
// specified does not need to be flipped to 'faceUpOrDown'. You should call this method on the stack rather than 
// manipulating the card directly if there is a StackView backed by this stack. Otherwise the change in the card's 
// state will not be displayed.
- (void) flipCard: (CECard *) card faceUp: (BOOL) faceUpOrDown;

// Convenience method to flip all cards in a stack face up. Does nothing if all cards are already face up.
- (void) revealAllCards;

// Shuffles all the cards in a stack.
- (void) shuffle;

// Shuffles all the cards in a stack but using a specific seed. This allows specifc games to be re-played.
- (void) shuffleWithSeed: (NSUInteger) seed;

// NEED SORT METHOD

@end
