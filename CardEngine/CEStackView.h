// =====================================================================================================================
//  CEStackView.h
// =====================================================================================================================


#import <UIKit/UIKit.h>
#import "CECardView.h"


@class CEStack, CECard, CECardView;


@protocol CEStackViewDelegate;


typedef int CEStackViewLayout;
enum
{
	kCEStackViewLayoutStacked = 0, 
	kCEStackViewLayoutStandardSpread = 1, 
	kCEStackViewLayoutReverseSpread = 2, 
	kCEStackViewLayoutBiasedColumn = 3, 
	kCEStackViewLayoutColumn = 4 
};

typedef int CEStackDragPermissions;
enum
{
	kStackDragAllDraggingPermitted = 0, 
	kStackNoDraggingPermitted = 1, 
	kStackDragSourceOnlyPermitted = 2, 
	kStackDragDestinationOnlyPermitted = 3
};

enum
{
	kStackViewTouchStateIdle = 0, 
	kStackViewTouchStateRevealing = 1, 
	kStackViewTouchStateMoving = 2
};


@interface CEStackView : UIView
{
	CEStack						*_stack;					// View's underlying stack of cards.
	UIColor						*_borderColor;
	UIColor						*_fillColor;
	UIColor						*_highlightColor;			// Fill color when view is highlighted.
	NSString					*_label;					// Optional label to display in view. If nil, no label.
	UIFont						*_labelFont;				// Label font used to display label.
	UIColor						*_labelColor;				// Can be nil to turn off label.
	CEStackViewLayout			_layout;					// Layout of cards.
	NSMutableArray				*_cardViews;				// Array of CECardViews stack view we manage.
	CECardSize					_cardSize;					// Size of the playing card views created.
	CGRect						_cardBoundingRect;			// Union of all card view bounds (may be zero rect if no cards).
	CGFloat						_hOffset;					// Vertical offset from left of view.
	CGFloat						_vOffset;					// Vertical offset from top of view.
	CGFloat						_cornerRadius;				// Radius used for stack view corners.
	CGFloat						_cornerRadiusInternal;		// Radius used for stack view corners.
	CGFloat						_cardSeparation;			// Ideal separation for spread layout.
	CGFloat						_cardBiasSeparation;		// Ideal separation for face-down cards in biased column layout.
	BOOL						_displaysCount;
	BOOL						_highlight;					// Highlight state
	NSInteger					_highlightedViewIndex;		// If our own stack is highlighted, the card view highlighted.
	CEStackDragPermissions		_dragPermissions;			// Simple drag permissions.  More complex rules done via delegate.
	BOOL						_allowsReordering;			// Whether cards within a stack can be re-ordered by the user.
	id <CEStackViewDelegate>	_delegate;
	id <CEStackViewDelegate>	_privateDelegate;
	int							_touchState;				// State of the touch event.
	NSUInteger					_cardIndexRevealed;			// Index of the card that is being revealed.
	NSRange						_cardRangeDragged;			// Range of cards being dragged (can be a single card).
//	BOOL						_animationInProgress;		// Flag indicating an animation has not yet completed.
	NSInteger					_animationRefCount;
	NSMutableArray				*_draggedCardViews;			// Temporary card views being dragged.
	CGPoint						_touchBeganLocation;		// Location of initial touch.
	CGFloat						_cardYDragOffset;			// Drag offset to prevent finger from obscuring top of card.
	CEStackView					*_highlightedStack;			// Highlighted stack user is dragging over.
	NSString					*_identifier;
	NSString					*_archiveIdentifier;
	BOOL						_orderly;
	BOOL						_enableUndoGrouping;
}

@property(nonatomic,retain)				CEStack						*stack;					// The card stack associated with the view.
@property(nonatomic)					CEStackViewLayout			layout;					// This property determines the layout of the cards displayed.
@property(nonatomic)					CECardSize					cardSize;				// Specifies the size of PlayingCardView created.
@property(nonatomic)					CEStackDragPermissions		dragPermissions;		// Indicates if cards can be dragged to or from stack.
@property(nonatomic)					BOOL						allowsReordering;		// Enables reordering of cards by user.  Default = NO.
@property(nonatomic,retain)				UIColor						*borderColor;			// Can be nil to turn off border.
@property(nonatomic,retain)				UIColor						*fillColor;				// Can be nil to turn off rounded-rect fill.
@property(nonatomic,retain)				UIColor						*highlightColor;		// Can be nil to turn off highlighting (not recommended).
@property(nonatomic,retain)				NSString					*label;					// Can be nil to turn off label.
@property(nonatomic,retain)				UIFont						*labelFont;				// Can be nil to turn off label.
@property(nonatomic,retain)				UIColor						*labelColor;			// Can be nil to turn off label.
@property(nonatomic)					CGFloat						cornerRadius;			// Set to -1 for automatic. Default is automatic.
@property(nonatomic)					BOOL						displaysCount;			// Display count of cards (only for kCEStackViewLayoutStacked). Default = NO.
@property(nonatomic)					BOOL						highlight;				// During a live drag, view highlights when dragged into and allowed.
@property(nonatomic,assign)				id <CEStackViewDelegate>	delegate;				// Optional delegate for the view.
@property(nonatomic,retain)				NSString					*identifier;			// An identifier you can choose to associate a StackView with.
@property(nonatomic,retain)				NSString					*archiveIdentifier;		// An identifier used to archive the state of a stack. Default is nil.
@property(nonatomic,getter=isOrderly)	BOOL						orderly;				// If not orderly cards may have a random rotation or offset applied.
@property(nonatomic)					BOOL						enableUndoGrouping;		// Whether to wrap moving multiple cards in an undo group. Default = YES.
@property(nonatomic,readonly)			BOOL						animationInProgress;	// Returns YES if there is an animation in progress.
@property(nonatomic,readonly)			int							touchState;				// Returns state if card in stack is being touched.

// Default returns [PlayingCardView class]. Subclassers can override in order to have their own class istantiated.
- (Class) cardViewClass;

// Moves the top card to the destination stack view. Specify if it is to land face up. A duration > 0 will animate.
- (void) dealTopCardToStackView: (CEStackView *) destStack faceUp: (BOOL) faceUp duration: (NSTimeInterval) duration;

// Moves the card to the destination stack view. Specify if it is to land face up. A duration > 0 will animate.
- (void) dealCard: (CECard *) card toStackView: (CEStackView *) stack faceUp: (BOOL) faceUp duration: (NSTimeInterval) duration;

// Flips the specified card to faceUp. If this would not change the card, does nothing. A duration > 0 will animate.
- (void) flipCard: (CECard *) card faceUp: (BOOL) faceUp duration: (NSTimeInterval) duration;

// MAYBE NEED:
//- (void) moveAllCardsToStackView: (StackView *) destStack faceUp: (BOOL) faceUp animate: (BOOL) animate;

// Returns YES if the underlying stack has been proimised a card. A card is promised foer the duration of an animation.
- (BOOL) isCardPromised;

@end

extern NSString *const StackViewWillDragCardToStackNotification;

// Notification sent as a result of a completed user-initiated drag of a card to another StackView.
// The object for the notification is self (StackView).
// The userInfo dictionary contains a "cards" key for an array of PlayingCard objects dragged by the user and a 
// "destinationStack" key for the StackView object where the card was dragged to.
extern NSString *const StackViewDidDragCardToStackNotification;

// Notification sent when a user has picked up a card (initiated a drag). This is a good opportunity to play a sound
// for the card pick-up for example.
extern NSString *const StackViewCardPickedUpNotification;

// Notification sent when a user has released a card (completed or abandoned a drag). This is a good opportunity to 
// play a sound for the card release for example.
extern NSString *const StackViewCardReleasedNotification;


@protocol CEStackViewDelegate<NSObject>

@optional

// Called from touchEnded in the stack view if there was no drag. Card passed may be nil (if no card was touched).
// Will not be called if touch was ended outside of stack view bounds (user changed their mind).
- (void) stackView: (CEStackView *) view cardWasTouched: (CECard *) card;

// Called when the stack view is double tapped. Card passed may be nil (if touch was inside view but not on a card).
- (void) stackView: (CEStackView *) view cardWasDoubleTapped: (CECard *) card;

// Delegate can return NO to disallow the dragging of a specific card. You can disallow dragging for all but the top 
// card for a stack view for example if you don't want to allow the dragging of multiple cards from a stack.
- (BOOL) stackView: (CEStackView *) view allowDragCard: (CECard *) card;

// Delegate is passed the proposed range of cards to drag and can return a different range. This allows the delegate to 
// disallow the dragging of multiple cards (or to allow it) or to drag from the first face up card, etc. Returning an 
// invalid range (outside range of number of cards) or range.length equal to zero will cancel the drag.
- (NSRange) stackView: (CEStackView *) view rangeOfCardsToDrag: (NSRange) range;

// Delegate can indicate whether or not to allow a drag of a card to a specific stack view.
- (BOOL) stackView: (CEStackView *) view allowDragCard: (CECard *) card toStackView: (CEStackView *) dest;

// Called when animation begins - for dealCard:, dealTopCard: from above.
- (void) stackView: (CEStackView *) view beginAnimatingCardMove: (CECard *) card;

// Called when animation begins - for flipCard: from above.
- (void) stackView: (CEStackView *) view beginAnimatingCardFlip: (CECard *) card;

// Called when animation completes - for dealCard:, dealTopCard: from above.
- (void) stackView: (CEStackView *) view finishedAnimatingCardMove: (CECard *) card;

// Called when animation completes - for flipCard: from above.
- (void) stackView: (CEStackView *) view finishedAnimatingCardFlip: (CECard *) card;

// Delegate can customize card layout by indicating the ideal separation between cards. It is called 'ideal' because 
// this separation is used only when the cards willfit within the stack bounds - otherwise they are squeezed together.
// Returning a negative value indicates you want the stack view to use the standard value.
- (CGFloat) idealCardSeparationForStackView: (CEStackView *) view;

// Delegate can customize card layout by indicating the ideal separation between face-down cards for biased columns.
// Returning a negative value indicates you want the stack view to use the standard value.
- (CGFloat) idealCardBiasSeparationForStackView: (CEStackView *) view;

// If implemented by delegate, returns UIVIew that all anaimted cards are to be added below. If not implemented 
// (or if nil is returned) daragged card views will be simply added to the CEStackView's superview (on top of subviews).
- (UIView *) stackViewOverlayingView: (CEStackView *) view;

@end
