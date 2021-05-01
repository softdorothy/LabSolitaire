// =====================================================================================================================
//  CEStackViewPrivate.h
// =====================================================================================================================


#import "CEStackView.h"


@class CEStack, CECardView, CETableView;


@interface CEStackView (CEStackViewPriv)

- (CETableView *) enclosingCETableView;

- (void) setPrivateDelegate: (id) delegate;

- (void) handleTouchesBegan: (UITouch *) touch;
- (void) touchesMovedForStackLayout: (UITouch *) touch;
- (void) touchesMovedForSpreadLayout: (UITouch *) touch;
- (void) touchesMovedForColumnLayout: (UITouch *) touch;
- (void) handleTouchesEnded: (UITouch *) touch cancelled: (BOOL) cancelled;

- (void) createDraggedCardViews: (CGPoint) offset;
- (void) dragDraggedCardViews: (CGPoint) offset;
- (void) returnDraggedCardsWithAnimation;
- (void) draggedCardsReturned: (NSString *) animationID finished: (NSNumber *) finished context: (void *) context;
- (void) destroyDraggedCardViews;

- (void) beginCardDrag: (UITouch *) touch;
- (void) handleMoveCard: (UITouch *) touch;
- (void) handleRevealCard: (UITouch *) touch;
- (int) determineDragGesture: (UITouch *) touch;
- (void) setRevealCard: (BOOL) reveal;

- (CEStackView *) stackViewAtLocation: (CGPoint) location;

// ------ undo support
- (void) registerDealCard: (CECard *) card stackView: (CEStackView *) stack duration: (NSTimeInterval) duration;
- (void) registerFlipCard: (CECard *) card duration: (NSTimeInterval) duration;

- (void) calculateLayoutOffsets;
- (BOOL) shouldRevealCardOnTouch: (UITouch *) touch;
- (NSUInteger) cardIndexToRevealAtLocation: (CGPoint) location;
- (NSUInteger) cardIndexAtLocation: (CGPoint) location;
- (CECardView *) cardViewForCardIndex: (NSUInteger) index;
- (CECardView *) cardViewForCard: (CECard *) card;
- (CGRect) boundsForCardAtIndex: (NSUInteger) index forCount: (NSUInteger) count;
- (void) layoutCards;																// <--- MAKE PUBLIC FOR SUBCLASSERS
- (void) layoutForStack;
- (void) layoutForSpread;
- (void) layoutForColumn;

// ------ animation
- (void) handleAnimation: (NSMutableDictionary *) dictionary;
- (void) animateWithDictionary: (NSDictionary *) dictionary;
- (void) animationStopped: (NSString *) animationID finished: (NSNumber *) finished context: (void *) context;

@end
