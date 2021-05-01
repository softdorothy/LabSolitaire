// =====================================================================================================================
//  CEStackPrivate.h
// =====================================================================================================================


#import <UIKit/UIKit.h>
#import "CEStack.h"


@class CECard, CardData;


@interface CEStack (CEStackPriv)

+ (void) debugRandomFunction: (NSUInteger) seed;
- (void) shuffleDeckWithSeed: (NSUInteger) seed;
- (void) addCardWithoutNotification: (CECard *) card;
- (void) promiseCard: (CECard *) card;
- (void) promiseKeptForCard: (CECard *) card;
- (BOOL) isCardPromised;
- (NSUInteger) numberOfCardsExcludingPromised;
- (NSArray *) cardsExcludingPromised;
- (CardData *) cardDataAtIndex: (NSUInteger) index;
- (void) replaceCardAtIndex: (NSUInteger) destIndex withCardAtIndex: (NSUInteger) srcIndex;
- (void) exchangeCardAtIndex: (NSUInteger) destIndex withCardAtIndex: (NSUInteger) srcIndex;

@end
