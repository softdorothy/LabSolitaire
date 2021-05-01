// =====================================================================================================================
//  CEStackView.m
// =====================================================================================================================


#import <AssertMacros.h>
#import <QuartzCore/QuartzCore.h>
#import "CECard.h"
#import "CEStackPrivate.h"
#import "CEStackViewPrivate.h"
#import "CETableViewPrivate.h"


#define	BORDER_IS_ALWAYS_SIZE_OF_CARD			1	// Usually 1, set to 0 when wanting to see full bounds of stack view.
#define DISALLOW_TOUCHES_IF_ANIMATION_ON_TABLE	0

#define kCardMoveAnimationSeconds				0.2
#define kStackViewBorderWidth					3.0
#define kHorizontalSpreadSeparation				32
#define kVerticalFaceDownSeparation				6
#define kMaxShadowHeight						12.0
#define kCardEnlargeScale						1.03
#define kCardShadowOffset						6.0


enum
{
	kDragGestureNone = 0, 
	kDragGestureRevealing = 1, 
	kDragGestureMoving = 2
};


NSString *const StackViewWillDragCardToStackNotification = @"StackViewWillDragCardToStack";
NSString *const StackViewDidDragCardToStackNotification = @"StackViewDidDragCardToStack";
NSString *const StackViewCardPickedUpNotification = @"StackViewCardPickedUp";
NSString *const StackViewCardReleasedNotification = @"StackViewCardReleased";


@implementation CEStackView
// ========================================================================================================= CEStackView
// ---------------------------------------------------------------------------------------------------------- synthesize

@synthesize dragPermissions = _dragPermissions;
@synthesize highlightColor = _highlightColor;
@synthesize allowsReordering = _allowsReordering;
@synthesize enableUndoGrouping = _enableUndoGrouping;
@synthesize orderly = _orderly;
@synthesize identifier = _identifier;
@synthesize archiveIdentifier = _archiveIdentifier;
@synthesize touchState = _touchState;

// ------------------------------------------------------------------------------------------------------- initWithFrame

- (id) initWithFrame: (CGRect) frame
{
	id		myself;
	
	// Super.
	myself = [super initWithFrame: frame];
	require (myself, bail);
	
	// Default instance variable values.
	_borderColor = [[UIColor alloc] initWithRed: 1. green: 1. blue: 1. alpha: 0.5];
	_fillColor = [[UIColor alloc] initWithRed: 0.3 green: 0.8 blue: 0.3 alpha: 0.5];
	_highlightColor = [[UIColor alloc] initWithRed: 0.0 green: 0.0 blue: 0.0 alpha: 0.25];
	_labelFont = [[UIFont fontWithName: @"Arial" size: 32] retain];
	_labelColor = [[UIColor alloc] initWithRed: 0.07 green: 0.34 blue: 0.10 alpha: 1.];
	_layout = kCEStackViewLayoutStandardSpread;
	_cornerRadius = -1.0;
	_cardViews = [[NSMutableArray alloc] initWithCapacity: 3];
	_cardSize = kCardSizeLarge;
	_highlightedViewIndex = -1;
	_draggedCardViews = [[NSMutableArray alloc] initWithCapacity: 3];
	_animationRefCount = 0;
	_touchState = kStackViewTouchStateIdle;
	_cardIndexRevealed = NSNotFound;
	_cardRangeDragged = NSMakeRange (0, 0);
	_orderly = YES;
	_enableUndoGrouping = YES;
	[self calculateLayoutOffsets];
	
	self.exclusiveTouch = YES;	// <--- EXPERIMENT.
	
	// Add empty stack by default.
	[self setStack: [[[CEStack alloc] init] autorelease]];
	
bail:
	
	return self;
}

// ------------------------------------------------------------------------------------------------------------- dealloc

- (void) dealloc
{
	// Stop listening for notifications.
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	// Release instance vars.
	[_borderColor release];
	[_fillColor release];
	[_highlightColor release];
	[_label release];
	[_labelFont release];
	[_labelColor release];
	[_cardViews release];
	[_stack release];
	
	// Super.
	[super dealloc];
}

// ------------------------------------------------------------------------------------------------------------ isOpaque

- (BOOL) isOpaque
{
	return NO;
}

// ------------------------------------------------------------------------------------------------------------ setFrame

- (void) setFrame: (CGRect) frame
{
	// Super.
	[super setFrame: frame];
	
	// Cards need re-laying out.
	if (_stack)
	{
		[self calculateLayoutOffsets];
		[self layoutCards];
	}
}

#pragma mark ------ attributes
// ------------------------------------------------------------------------------------------------------------ setStack

- (void) setStack: (CEStack *) stack
{
	// NOP.
	if (stack == _stack)
		return;
	
	// Stop listening to changes made to the old stack.
	[[NSNotificationCenter defaultCenter] removeObserver: self name: @"StackDidChangeCount" object: _stack];
	[[NSNotificationCenter defaultCenter] removeObserver: self name: @"StackDidFlipCard" object: _stack];
	[[NSNotificationCenter defaultCenter] removeObserver: self name: @"StackDidChangeOrder" object: _stack];
	
	// Release, retain, assign.
	[_stack release];
	_stack = [stack retain];
	
	// Listen for changes in the stack.
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector (stackChangedCount:) 
			name: @"StackDidChangeCount" object: _stack];
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector (stackChangedCardFlipped:) 
			name: @"StackDidFlipCard" object: _stack];
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector (stackChangedOrder:) 
			name: @"StackDidChangeOrder" object: _stack];
	
	// Cards need laying out.
	[self layoutCards];
}

// --------------------------------------------------------------------------------------------------------------- stack

- (CEStack *) stack
{
	// Return value.
	return _stack;
}

// ----------------------------------------------------------------------------------------------------------- setLayout

- (void) setLayout: (CEStackViewLayout) layout
{
	// Assign.
	_layout = layout;
	
	// Cards need re-laying out.
	[self calculateLayoutOffsets];
	[self layoutCards];
}

// -------------------------------------------------------------------------------------------------------------- layout

- (CEStackViewLayout) layout
{
	// Return value.
	return _layout;
}

// --------------------------------------------------------------------------------------------------------- setCardSize

- (void) setCardSize: (CECardSize) size
{
	// Assign.
	_cardSize = size;
	
	// Cards need re-laying out.
	[self calculateLayoutOffsets];
	[self layoutCards];
}

// ------------------------------------------------------------------------------------------------------------ cardSize

- (CECardSize) cardSize
{
	// Return value.
	return _cardSize;
}

// ------------------------------------------------------------------------------------------------------ setBorderColor

- (void) setBorderColor: (UIColor *) color
{
	// NOP
	if (color == _borderColor)
		return;
	
	// Release, retain, assign.
	[_borderColor release];
	_borderColor = [color retain];
	
	// Redraw.
	[self setNeedsDisplay];
}

// --------------------------------------------------------------------------------------------------------- borderColor

- (UIColor *) borderColor
{
	// Return value.
	return _borderColor;
}

// -------------------------------------------------------------------------------------------------------- setFillColor

- (void) setFillColor: (UIColor *) color
{
	// NOP
	if (color == _fillColor)
		return;
	
	// Release, retain, assign.
	[_fillColor release];
	_fillColor = [color retain];
	
	// Redraw.
	[self setNeedsDisplay];
}

// ----------------------------------------------------------------------------------------------------------- fillColor

- (UIColor *) fillColor
{
	// Return value.
	return _fillColor;
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

// -------------------------------------------------------------------------------------------------------- setLabelFont

- (void) setLabelFont: (UIFont *) font
{
	// NOP.
	if (font == _labelFont)
		return;
	
	// Release, retain, assign.
	[_labelFont release];
	_labelFont = [font retain];
	
	// Redraw.
	[self setNeedsDisplay];
}

// ----------------------------------------------------------------------------------------------------------- labelFont

- (UIFont *) labelFont
{
	// Return value.
	return _labelFont;
}

// ------------------------------------------------------------------------------------------------------- setLabelColor

- (void) setLabelColor: (UIColor *) color
{
	// NOP.
	if (color == _labelColor)
		return;
	
	// Release, retain, assign.
	[_labelColor release];
	_labelColor = [color retain];
	
	// Redraw.
	[self setNeedsDisplay];
}

// ---------------------------------------------------------------------------------------------------------- labelColor

- (UIColor *) labelColor
{
	// Return value.
	return _labelColor;
}

// ----------------------------------------------------------------------------------------------------- setCornerRadius

- (void) setCornerRadius: (CGFloat) radius
{
	// NOP.
	if (radius == _cornerRadius)
		return;
	
	// Assign.
	_cornerRadius = radius;
	
	// Re-calculate.
	[self calculateLayoutOffsets];
}

// -------------------------------------------------------------------------------------------------------- cornerRadius

- (CGFloat) cornerRadius
{
	// Return value.
	return _cornerRadiusInternal;
}

// ---------------------------------------------------------------------------------------------------- setDisplaysCount

- (void) setDisplaysCount: (BOOL) displaysCount
{
	// NOP.
	if (_displaysCount == displaysCount)
		return;
	
	// Assign.
	_displaysCount = displaysCount;
	
	// Redraw entire view.
	if ((_layout == kCEStackViewLayoutStacked) && ([_stack numberOfCards] > 0))
		[self layoutCards];
}

// ------------------------------------------------------------------------------------------------------- displaysCount

- (BOOL) displaysCount
{
	// Return value.
	return _displaysCount;
}

// -------------------------------------------------------------------------------------------------------- setHighlight

- (void) setHighlight: (BOOL) highlight
{
	// NOP.
	if (_highlight == highlight)
		return;
	
	// Assign.
	_highlight = highlight;
	
	// We set the highlight state of our top card.
	if (highlight)
	{
		// Determine view to highlight.
		if ((_cardRangeDragged.length == 0) && (_cardViews) && ([_cardViews count] > 0))
			_highlightedViewIndex = [_cardViews count] - 1;
		else if ((_cardRangeDragged.location > 0) && (_cardViews) && ([_cardViews count] > (_cardRangeDragged.location - 1)))
			_highlightedViewIndex = _cardRangeDragged.location - 1;
		else
			_highlightedViewIndex = -1;
		
		if (_highlightedViewIndex >= 0)
		{
			[[_cardViews objectAtIndex: _highlightedViewIndex] setHighlight: YES];
			[[_cardViews objectAtIndex: _highlightedViewIndex] setNeedsDisplay];
		}
		else
		{
			// Redraw entire view.
			[self setNeedsDisplay];
		}
	}
	else
	{
		if (_highlightedViewIndex >= 0)
		{
			// Un-highlight view.
			if ((_cardViews) && (_highlightedViewIndex < [_cardViews count]))
			{
				[[_cardViews objectAtIndex: _highlightedViewIndex] setHighlight: NO];
				[[_cardViews objectAtIndex: _highlightedViewIndex] setNeedsDisplay];
			}
			else
			{
				printf("Serious error encountered in -[setHighlight:]");
			}
			
			_highlightedViewIndex = -1;
		}
		else
		{
			// Redraw entire view.
			[self setNeedsDisplay];
		}
	}
	
}

// ----------------------------------------------------------------------------------------------------------- highlight

- (BOOL) highlight
{
	// Return value.
	return _highlight;
}

// --------------------------------------------------------------------------------------------------------- setDelegate

- (void) setDelegate: (id <CEStackViewDelegate>) delegate
{
	// Assign.
	_delegate = delegate;
	
	// Delegate may respond to layout selectors.
	[self calculateLayoutOffsets];
}

// ------------------------------------------------------------------------------------------------------------ delegate

- (id <CEStackViewDelegate>) delegate
{
	// Return value.
	return _delegate;
}

// ------------------------------------------------------------------------------------------------------- cardViewClass

- (Class) cardViewClass
{
	return [CECardView class];
}

// ------------------------------------------------------------------------------------------------- animationInProgress

- (BOOL) animationInProgress
{
	return (_animationRefCount != 0);
}

#pragma mark ------ actions
// ------------------------------------------------------------------------------ dealTopCardToStackView:faceUp:duration

- (void) dealTopCardToStackView: (CEStackView *) destStack faceUp: (BOOL) faceUp duration: (NSTimeInterval) duration 
{
	// Call more general method below.
	[self dealCard: [_stack topCard] toStackView: destStack faceUp: faceUp duration: duration];
}

// -------------------------------------------------------------------------------- dealCard:toStackView:faceUp:duration

- (void) dealCard: (CECard *) card toStackView: (CEStackView *) stack faceUp: (BOOL) faceUp duration: (NSTimeInterval) duration
{
	// Param check.
	require (stack, bail);
	require (_stack, bail);
	require ([_stack stackContainsCard: card], bail);
	
	// Register for 'undo'.
	[self registerDealCard: card stackView: stack duration: duration];
	
	if (duration > 0.0)
	{
		NSMutableDictionary	*dictionary;
		CECardView			*sourceView;
		CGPoint				point;
		NSUInteger			destNumCards;
		CGRect				destRect;
		
		// Create animation dictionary. Animation completion will release dictionary.
		dictionary = [[NSMutableDictionary alloc] initWithCapacity: 3];
		
		// Add animation type key to dictionary.
		[dictionary setObject: @"moveCardFromPointToPoint" forKey: @"type"];
		
		// Add card, source and destination stack and faceup-edness to animation dictionary.
		[dictionary setObject: card forKey: @"card"];
		[dictionary setObject: [stack stack] forKey: @"destStack"];
		[dictionary setObject: [NSNumber numberWithBool: faceUp] forKey: @"faceUp"];
		[dictionary setObject: [NSNumber numberWithDouble: duration] forKey: @"totalDuration"];
		
		// Get card view that is going to animate.
		sourceView = [self cardViewForCard: card];
		require (sourceView, abortAnimation);
		
		// Determine the coordinate to move from.
		point = sourceView.center;
		point = [self convertPoint: point toView: [self superview]];
		
		// Add starting point to animation dictionary.
		[dictionary setObject: [NSValue valueWithCGPoint: point] forKey: @"startPt"];
		
		// Determine the coordinate to move to.
		// Get location for new card.
		destNumCards = [[stack stack] numberOfCards];
		destRect = [stack boundsForCardAtIndex: destNumCards forCount: destNumCards + 1];
		point.x = CGRectGetMidX (destRect);
		point.y = CGRectGetMidY (destRect);
		point = [stack convertPoint: point toView: [self superview]];
		
		// Add destination point to animation dictionary.
		[dictionary setObject: [NSValue valueWithCGPoint: point] forKey: @"endPt"];
		
		// Indicate stage 0.0
		[dictionary setObject: [NSNumber numberWithInt: 0] forKey: @"stage"];
		
		// Hide source view.
		[sourceView setHidden: YES];
		
		// Remove card from our own stack.
		[card retain];
		[_stack removeCard: card];
		
		// Promise a card.
		[[stack stack] promiseCard: card];
		
		// Call method that prepares the animation based on objects we put in the dictionary.
		[self handleAnimation: dictionary];
	}
	else
	{
abortAnimation:
		
		// Remove card from our own stack.
		[card retain];
		[_stack removeCard: card];
		
		// Flip and add card to destination stack.
		[card setFaceUp: faceUp];
		[[stack stack] addCard: card];
		[card release];
	}
	
	// Notify observers that a card is being dragged.
	[[NSNotificationCenter defaultCenter] postNotificationName: StackViewCardPickedUpNotification 
			object: self userInfo: nil];
	
bail:
	
	return;
}

// -------------------------------------------------------------------------------------------- flipCard:faceUp:duration

- (void) flipCard: (CECard *) card faceUp: (BOOL) faceUp duration: (NSTimeInterval) duration
{
	// Param check.
	require (card, bail);
	require (_stack, bail);
	
	// Skip out if this is not our card.
	if ([_stack stackContainsCard: card] == NO)
		goto bail;
	
	// NOP.
	if ([card isFaceUp] == faceUp)
		return;
	
	// Register for 'undo'.
	[self registerFlipCard: card duration: duration];
	
	// Optional animation.
	if (duration > 0.0)
	{
		NSMutableDictionary	*dictionary;
		CECardView			*sourceView;
		CGRect				frame;
		
		// Create animation dictionary. Animation completion will release dictionary.
		dictionary = [[NSMutableDictionary alloc] initWithCapacity: 3];
		
		// Add animation type key to dictionary.
		[dictionary setObject: @"flipCard" forKey: @"type"];
		
		// Add card, duration, face-upedness to animation dictionary.
		[dictionary setObject: card forKey: @"card"];
		[dictionary setObject: [NSNumber numberWithBool: faceUp] forKey: @"faceUp"];
		[dictionary setObject: [NSNumber numberWithDouble: duration] forKey: @"totalDuration"];
		
		// Get the bounds for the flipping card.
		sourceView = [self cardViewForCard: card];
		require (sourceView, abortAnimation);
		frame = [self convertRect: [sourceView frame] toView: [self superview]];
		
		// Add frame to animation dictionary.
		[dictionary setObject: [NSValue valueWithCGRect: frame] forKey: @"frame"];
		
		// Indicate stage 0.0
		[dictionary setObject: [NSNumber numberWithInt: 0] forKey: @"stage"];
		
		// Hide source view momentarily.
		[sourceView setHidden: YES];
		
		// Call method that prepares the animation based on objects we put in the dictionary.
		[self handleAnimation: dictionary];
	}
	else
	{
abortAnimation:
		
		// Face up.
		[card setFaceUp: faceUp];
		
		// Redraw.
		[[self cardViewForCard: card] setNeedsDisplay];
	}
	
bail:
	
	return;
}

// ------------------------------------------------------------------------------------------------------ isCardPromised

- (BOOL) isCardPromised
{
	return [_stack isCardPromised];
}

#pragma mark ------ drawing
// ------------------------------------------------------------------------------------------------------------ drawRect

- (void) drawRect: (CGRect) rect
{
	CGContextRef	context;
	CGRect			bounds;
	NSUInteger		numCards;
	
	context = UIGraphicsGetCurrentContext ();
	
	// Get our bounds.
	bounds = [self bounds];
#if BORDER_IS_ALWAYS_SIZE_OF_CARD
	bounds.size = [[self cardViewClass] cardSize: _cardSize];
#endif
	
	// Fill view.
	if (_fillColor)
	{
		[_fillColor set];
		CEFillRoundedRect (context, bounds, _cornerRadiusInternal);
	}
	
	// Highlight.
	if ((_highlight) && (_highlightColor) && (_highlightedViewIndex == -1))
	{
		[_highlightColor set];
		CEFillRoundedRect (context, [self boundsForCardAtIndex: 0 forCount: 1], [[self cardViewClass] playingCardCornerRadius: _cardSize]);
	}
	
	// Label.
	if ((_label) && (_labelFont) && (_labelColor))
	{
		CGSize		size;
		CGPoint		origin;
		
		[_labelColor set];
		
		size = [_label sizeWithAttributes: [NSDictionary dictionaryWithObjectsAndKeys: _labelFont, NSFontAttributeName, nil]];
		origin = CGPointMake (floor((bounds.size.width - size.width) / 2.), floor((bounds.size.height - size.height) / 2.));

		NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
		style.lineBreakMode = NSLineBreakByTruncatingMiddle;
		[_label drawAtPoint: origin withAttributes: [NSDictionary dictionaryWithObjectsAndKeys: _labelFont, NSFontAttributeName, 
				style, NSParagraphStyleAttributeName, nil]];
		[style release];
	}
	
	// Draw border.
	if (_borderColor)
	{
		[_borderColor set];
		CEStrokeRoundedRectOfWidth (context, bounds, _cornerRadiusInternal, kStackViewBorderWidth);
	}
	
	// Number of cards (not promised cards).
	numCards = [_stack numberOfCardsExcludingPromised];
	
	// Draw shadow of deck.
	if ((_layout == kCEStackViewLayoutStacked) && (_stack) && (numCards > 1))
	{
		CGRect			shadowBounds;
		CGFloat			shadowHeight;
		CGColorSpaceRef	colorSpace;
		CGFloat			color[4] = {0.0, 0.0, 0.0, 0.6};
		CGColorRef		shadowColor;
		
		CGContextSaveGState (context);
		shadowHeight = numCards * kMaxShadowHeight / 52.;
		if (shadowHeight > (_vOffset - 1.))
			shadowHeight = _vOffset - 1.;
		if (shadowHeight > kMaxShadowHeight)
			shadowHeight = kMaxShadowHeight;
		if (shadowHeight < 0.0)
			shadowHeight = 0.0;
		shadowBounds = [self boundsForCardAtIndex: 0 forCount: numCards];
		colorSpace = CGColorSpaceCreateDeviceRGB ();
		shadowColor = CGColorCreate (colorSpace, color);
		CGContextSetShadowWithColor (context, CGSizeMake (0.0, -shadowHeight), 1., shadowColor);
		CEFillRoundedRect (context, shadowBounds, [[self cardViewClass] playingCardCornerRadius: _cardSize]);
		CGColorRelease (shadowColor);
		CGColorSpaceRelease (colorSpace);
		CGContextRestoreGState (context);
	}
}

#pragma mark ------ touch event entry
// ---------------------------------------------------------------------------------------------- touchesBegan:withEvent

- (void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event
{
	UITouch		*touch;
	
	// An animation may be in progress.
	if (_animationRefCount > 0)
		return;
	
#if DISALLOW_TOUCHES_IF_ANIMATION_ON_TABLE
	CETableView	*cardTable;
	
	// Or an animation somewhere on the card table may be going on.
	cardTable = [self enclosingCETableView];
	if ((cardTable) && ([cardTable animationInProgress]))
		return;
#endif	// DISALLOW_TOUCHES_IF_ANIMATION_ON_TABLE
	
	// We may have been promised a card ... wait for it.
	// This bug could arise if a card was animating to this stack from another stack - while the animation is underway, 
	// if we attempt to drag a card in this stack an orphaned card view could be left on the table. Andrew Pangborn 
	// found this bug. This was the best fix I could find.
//	if ([_stack isCardPromised])
//		return;
	
	// Get the touch.
	touch = [[event allTouches] anyObject];
	
	// Call out "double-taps".
	if ([touch tapCount] == 2)
	{
		if ((_delegate) && ([_delegate respondsToSelector: @selector (stackView:cardWasDoubleTapped:)]))
		{
			NSUInteger	cardIndexTapped;
			
			// Locate card tapped.  May return nil.
			cardIndexTapped = [self cardIndexAtLocation: [touch locationInView: self]];
			if (cardIndexTapped != NSNotFound)
				[_delegate stackView: self cardWasDoubleTapped: [_stack cardAtIndex: cardIndexTapped]];
		}
		
		return;
	}
	
	// Skip out if dragging is not allowed.
	if ((_dragPermissions == kStackNoDraggingPermitted) || (_dragPermissions == kStackDragDestinationOnlyPermitted))
		return;
	
	// See if the touch was in one our subviews.
	if ([_cardViews containsObject: [touch view]])
		[self handleTouchesBegan: touch];
}

// ---------------------------------------------------------------------------------------------- touchesMoved:withEvent

- (void) touchesMoved: (NSSet *) touches withEvent: (UIEvent *) event
{
	UITouch		*touch;
	
	// An animation may be in progress.
	if (_animationRefCount > 0)
		return;
	
#if DISALLOW_TOUCHES_IF_ANIMATION_ON_TABLE
	CETableView	*cardTable;
	
	// Or an animation somewhere on the card table may be going on.
	cardTable = [self enclosingCETableView];
	if ((cardTable) && ([cardTable animationInProgress]))
		return;
#endif	// DISALLOW_TOUCHES_IF_ANIMATION_ON_TABLE
	
	// Get the touch.
	touch = [[event allTouches] anyObject];
	
	// Skip out if dragging is not allowed.
	if (_dragPermissions == kStackNoDraggingPermitted)
		return;
	
	if (_layout == kCEStackViewLayoutStacked)
		[self touchesMovedForStackLayout: touch];
	else if (_layout == kCEStackViewLayoutStandardSpread)
		[self touchesMovedForSpreadLayout: touch];
	else if ((_layout == kCEStackViewLayoutColumn) || (_layout == kCEStackViewLayoutBiasedColumn))
		[self touchesMovedForColumnLayout: touch];
}

// ---------------------------------------------------------------------------------------------- touchesEnded:withEvent

- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event
{
	UITouch		*touch;
	
	// Get the touch.
	touch = [[event allTouches] anyObject];
	
	// Handle touch ended.
	[self handleTouchesEnded: touch cancelled: NO];
	
	// We are no longer touching.
	_touchState = kStackViewTouchStateIdle;
}

// ------------------------------------------------------------------------------------------ touchesCancelled:withEvent

- (void) touchesCancelled: (NSSet *) touches withEvent: (UIEvent *) event
{
	UITouch		*touch;
	
	printf ("touchesCancelled\n");
	
	// Get the touch.
	touch = [[event allTouches] anyObject];
	
	// Treat as a touch ended.
	[self handleTouchesEnded: touch cancelled: YES];
	
	// We are no longer touching.
	_touchState = kStackViewTouchStateIdle;
}

@end


@implementation CEStackView (CEStackViewPriv)
// ======================================================================================= CEStackView (CEStackViewPriv)
// ------------------------------------------------------------------------------------------------ enclosingCETableView

- (CETableView *) enclosingCETableView
{
	CETableView	*table = nil;
	
	// Check superview to see if it is a CETableView.
	if ([[self superview] isKindOfClass: [CETableView class]])
		table = (CETableView *) [self superview];
	
	return table;
}

// -------------------------------------------------------------------------------------------------- setPrivateDelegate

- (void) setPrivateDelegate: (id) delegate
{
	_privateDelegate = delegate;
}

// -------------------------------------------------------------------------------------------------- handleTouchesBegan
#pragma mark ------ touch handling

- (void) handleTouchesBegan: (UITouch *) touch
{
	CGPoint		location;
	NSUInteger	cardIndex;
	BOOL		canDrag = YES;
	CECardView	*cardViewTouched;
	CGFloat		yLocationInCard;
	CGFloat		cardYOffsetTreshold;
	
	// Get location of touch.
	location = [touch locationInView: self];
	
	// Locate card we're over.
	cardIndex = [self cardIndexAtLocation: location];
	if (cardIndex == NSNotFound)
		return;
	
	// Ask delegate if we can drag this particular card.
	if ((_delegate) && ([_delegate respondsToSelector: @selector (stackView:allowDragCard:)]))
		canDrag = [_delegate stackView: self allowDragCard: [_stack cardAtIndex: cardIndex]];
	
	// If we were disallowed from dragging this card, return.
	if (canDrag == NO)
		return;
	
	// Note initial touch location.
	_touchBeganLocation = location;
	
	// SHOULD WE ALWAYS ALLOW A COLUMN DRAG? THE DELEGATE CAN DISALLOW IN THE CODE ABOVE, YES?
	if ((_layout == kCEStackViewLayoutBiasedColumn) || (_layout == kCEStackViewLayoutColumn))
		_cardRangeDragged = NSMakeRange (cardIndex, [_stack numberOfCards] - cardIndex);
	else
		_cardRangeDragged = NSMakeRange (cardIndex, 1);
	
	// Delegate gets a chance to modify the range of cards allowed.
	if ((_delegate) && ([_delegate respondsToSelector: @selector (stackView:rangeOfCardsToDrag:)]))
	{
		// Pass delegate range, delegate can return an adjusted range.
		_cardRangeDragged = [_delegate stackView: self rangeOfCardsToDrag: _cardRangeDragged];
		
		// Param check returned value. User can cancel drag by returning a length of zero.
		if ((NSMaxRange (_cardRangeDragged) > [_stack numberOfCards]) || (_cardRangeDragged.length == 0))	// Should it be '>=' instead of '>'?
		{
			_cardRangeDragged = NSMakeRange (0, 0);
		}
	}
	
	// Get the view corresponding to the touched card.
	cardViewTouched = [self cardViewForCardIndex: cardIndex];
	
	// See where within the card we touched — we'll adjust if the top of the card is obscured.
	yLocationInCard = [touch locationInView: cardViewTouched].y;
	cardYOffsetTreshold = 60.0;
	
	// For touch in top portion of card, move down — the user should be able to see card they're dragging.
	if (yLocationInCard < cardYOffsetTreshold)
		_cardYDragOffset = yLocationInCard - cardYOffsetTreshold;
	else
		_cardYDragOffset = 0.0;
	
	if ((_layout == kCEStackViewLayoutStandardSpread) && ([self shouldRevealCardOnTouch: touch]))
	{
		_touchState = kStackViewTouchStateRevealing;
		[self handleRevealCard: touch];
	}
}

// ------------------------------------------------------------------------------------------ touchesMovedForStackLayout

- (void) touchesMovedForStackLayout: (UITouch *) touch
{
	// Ignore moved touch if no card was initially selected.
	if (_cardRangeDragged.length != 1)
		return;
	
	if (_touchState == kStackViewTouchStateIdle)
	{
		// We transition to a drag state.
		[self beginCardDrag: touch];
	}
	else if (_touchState == kStackViewTouchStateMoving)
	{
		[self handleMoveCard: touch];
	}
}

// ----------------------------------------------------------------------------------------- touchesMovedForSpreadLayout

- (void) touchesMovedForSpreadLayout: (UITouch *) touch
{
	// Ignore moved touch if no card was initially selected.
	if (_cardRangeDragged.length == 0)
		return;
	
	if (_touchState == kStackViewTouchStateIdle)
	{
		// If the cards are such that they need revealing, transition then to reveal mode.
		if ([self shouldRevealCardOnTouch: touch])
		{
			int		gesture;
			
			// Determine if the touch is moving horizontally or vertically.
			gesture = [self determineDragGesture: touch];
			
			// Are we moving more vertical than horizontal?
			if (gesture == kDragGestureMoving)
			{
				// Note card index touched and create a range for it.
				_cardRangeDragged = NSMakeRange (_cardIndexRevealed, 1);
				
				// Reset touch began location.
				_touchBeganLocation.x = [touch locationInView: self].x;
				
				// Begin drag.
				[self beginCardDrag: touch];
			}
			else if (gesture == kDragGestureRevealing)
			{
				// We're moving horizontal, so go into reveal mode until we start to drag vertical.
				_touchState = kStackViewTouchStateRevealing;
				[self handleRevealCard: touch];
			}
		}
		else
		{
			// We transition to a drag state.
			[self beginCardDrag: touch];
		}
	}
	else if (_touchState == kStackViewTouchStateRevealing)
	{
		// The user presumed selecting a card still?
		// See if the touch was in one our subviews.
		if ([_cardViews containsObject: [touch view]])
		{
			int		gesture;
			
			// Determine if the touch is moving horizontally or vertically.
			gesture = [self determineDragGesture: touch];
			
			if (gesture == kDragGestureMoving)
			{
				// Note card index touched and create a range for it.
				_cardRangeDragged = NSMakeRange (_cardIndexRevealed, 1);
				
				// Reset touch began location.
				_touchBeganLocation.x = [touch locationInView: self].x;
				
				// Pop the previously revealed card back down.
				[self setRevealCard: NO];
				
				// We're moving horizontal, so transition to a drag state.
				[self beginCardDrag: touch];
			}
			else if (gesture == kDragGestureRevealing)
			{
				[self handleRevealCard: touch];
			}
		}
	}
	else if (_touchState == kStackViewTouchStateMoving)
	{
		[self handleMoveCard: touch];
	}
}

// ----------------------------------------------------------------------------------------- touchesMovedForColumnLayout

- (void) touchesMovedForColumnLayout: (UITouch *) touch
{
	// Ignore moved touch if no card was initially selected.
	if (_cardRangeDragged.length == 0)
		return;
	
	if (_touchState == kStackViewTouchStateIdle)
	{
		// If the cards are such that they need revealing, transition then to reveal mode.
		if ([self shouldRevealCardOnTouch: touch])
		{
			int		gesture;
			
			// Determine if the touch is moving horizontally or vertically.
			gesture = [self determineDragGesture: touch];
			
			// Are we moving more vertical than horizontal?
			if (gesture == kDragGestureMoving)
			{
				// We're moving horizontal, so transition to a drag state.
				[self beginCardDrag: touch];
			}
			else if (gesture == kDragGestureRevealing)
			{
				// We're moving horizontal, so go into reveal mode until we start to drag vertical.
				_touchState = kStackViewTouchStateRevealing;
				[self handleRevealCard: touch];
			}
		}
		else
		{
			// We transition to a drag state.
			[self beginCardDrag: touch];
		}
	}
	else if (_touchState == kStackViewTouchStateRevealing)
	{
		// The user presumed selecting a card still?
		// See if the touch was in one our subviews.
		if ([_cardViews containsObject: [touch view]])
		{
			int		gesture;
			
			// Determine if the touch is moving horizontally or vertically.
			gesture = [self determineDragGesture: touch];
			
			if (gesture == kDragGestureMoving)
			{
				// Pop the previously revealed card back down.
				[self setRevealCard: NO];
				
				// We're moving horizontal, so transition to a drag state.
				[self beginCardDrag: touch];
			}
			else if (gesture == kDragGestureRevealing)
			{
				[self handleRevealCard: touch];
			}
		}
	}
	else if (_touchState == kStackViewTouchStateMoving)
	{
		[self handleMoveCard: touch];
	}
}

// ---------------------------------------------------------------------------------------- handleTouchesEnded:cancelled

- (void) handleTouchesEnded: (UITouch *) touch cancelled: (BOOL) cancelled
{
	if (_touchState == kStackViewTouchStateRevealing)
	{
		// Pop the previously revealed card back down.
		[self setRevealCard: NO];
		
		// Card dragging complete.
		_cardRangeDragged = NSMakeRange (0, 0);
		
		// Notify observers that the card touched has been released.
		[[NSNotificationCenter defaultCenter] postNotificationName: StackViewCardReleasedNotification 
				object: self userInfo: nil];
	}
	else if (_touchState == kStackViewTouchStateMoving)
	{
		// Did we land on a stack after all?
		if ((_highlightedStack) && ((_highlightedStack != self) || (_allowsReordering)) && (cancelled == NO))
		{
			NSMutableArray	*cardArray;
			NSUInteger		i;
			
			// Create card array to pass to listeners.
			cardArray = [NSMutableArray arrayWithCapacity: _cardRangeDragged.length];
			for (i = _cardRangeDragged.location; i < NSMaxRange (_cardRangeDragged); i++)
			{
				// Sanity check.
				if ([_stack numberOfCards] > i)
				{
					[cardArray addObject: [_stack cardAtIndex: i]];
				}
				else
				{
					printf ("handleTouchesEnded - error, card index out range\n");
				}
			}
			
			// Notify observers that a card will be dragged.
			[[NSNotificationCenter defaultCenter] postNotificationName: StackViewWillDragCardToStackNotification 
					object: self userInfo: [NSDictionary dictionaryWithObjectsAndKeys: cardArray, @"cards", 
					_highlightedStack, @"destinationStack", nil]];
			
			// Undo.
			if (_enableUndoGrouping)
				[[CETableView sharedCardUndoManager] beginUndoGrouping];
			for (i = NSMaxRange (_cardRangeDragged); i > _cardRangeDragged.location; i--)
			{
				[[CETableView sharedCardUndoManager] registerUndoWithTarget: [_highlightedStack stack] selector: @selector (removeCard:) object: [_stack cardAtIndex: i - 1]];
				[[CETableView sharedCardUndoManager] registerUndoWithTarget: _stack selector: @selector (addCard:) object: [_stack cardAtIndex: i - 1]];
			}
			if (_enableUndoGrouping)
				[[CETableView sharedCardUndoManager] endUndoGrouping];
			
			// Move cards we were dragging from our stack to the stack dragged to.
			[[_highlightedStack stack] addCardsFromStack: _stack inRange: _cardRangeDragged];
			[_stack removeCardsInRange: _cardRangeDragged];
			
			// Destroy the dragged views.
			[self destroyDraggedCardViews];
			
			// Turn off highlight.
			[_highlightedStack setHighlight: NO];
			
			// Notify observers that a card was dragged.
			if (0)
			{
				[[NSNotificationCenter defaultCenter] postNotificationName: StackViewDidDragCardToStackNotification 
						object: self userInfo: [NSDictionary dictionaryWithObjectsAndKeys: cardArray, @"cards", 
						_highlightedStack, @"destinationStack", nil]];
			}
			else
			{
				[[NSNotificationQueue defaultQueue] enqueueNotification: 
						[NSNotification notificationWithName: StackViewDidDragCardToStackNotification object: self 
						userInfo: [NSDictionary dictionaryWithObjectsAndKeys: cardArray, @"cards", 
						_highlightedStack, @"destinationStack", nil]] 
						postingStyle: NSPostWhenIdle];
			}
			
			// Reset.
			_cardRangeDragged = NSMakeRange (0, 0);
			_highlightedStack = nil;
		}
		else
		{
			// Initiate animation - when it completes dragged cards are destroyed and views un-hidden.
			// When animation completes, _cardRangeDragged will be reset.
			if (_touchState == kStackViewTouchStateMoving)
				[self returnDraggedCardsWithAnimation];
		}
		
		// Notify observers that the card touched has been released.
		[[NSNotificationCenter defaultCenter] postNotificationName: StackViewCardReleasedNotification 
				object: self userInfo: nil];
	}
	else
	{
		// See if touch is still inside bounds.
		if ((cancelled == NO) && (touch) && (CGRectContainsPoint ([self bounds], [touch locationInView: self])))
		{
			if ((_delegate) && ([_delegate respondsToSelector: @selector (stackView:cardWasTouched:)]))
			{
				NSUInteger	cardIndexTapped;
				
				// Locate card tapped.  May return nil.
				cardIndexTapped = [self cardIndexAtLocation: [touch locationInView: self]];
				if (cardIndexTapped == NSNotFound)
					[_delegate stackView: self cardWasTouched: nil];
				else
					[_delegate stackView: self cardWasTouched: [_stack cardAtIndex: cardIndexTapped]];
			}
		}
		
		// Reset.
		_cardRangeDragged = NSMakeRange (0, 0);
	}
}

#pragma mark ------ dragged card views
// ----------------------------------------------------------------------------------------------- addSubviewToSuperview

- (void) addSubviewToSuperview: (UIView *) subview
{
	UIView	*overlayingView = nil;
	
	// Ask delegate for overlaying view (nil assumes no overlaying view).
	// OPTIMIZATION - STORE WHETHER DELEGATE RESPONDS TO METHOD AS INSTANCE VAR - ASK ONCE
	if ((_delegate) && ([_delegate respondsToSelector: @selector (stackViewOverlayingView:)]))
		overlayingView = [_delegate stackViewOverlayingView: self];
	
	if (overlayingView)
		[[self superview] insertSubview: subview belowSubview: overlayingView];
	else
		[[self superview] addSubview: subview];

}

// ---------------------------------------------------------------------------------------------- createDraggedCardViews

- (void) createDraggedCardViews: (CGPoint) offset
{
	NSUInteger	i;
	
	for (i = _cardRangeDragged.location; i < NSMaxRange (_cardRangeDragged); i++)
	{
		CECardView	*draggedCard;
		CGRect		frame;
		
		// Get frame from card-view touched - adjust position.
		frame = [[self cardViewForCardIndex: i] frame];
		frame.origin.x = frame.origin.x + offset.x;
		frame.origin.y = frame.origin.y + offset.y;
		frame.size.width = frame.size.width + kCardShadowOffset;
		frame.size.height = frame.size.height + kCardShadowOffset;
		
		// Create temporary card-view to drag.
		draggedCard = [[[self cardViewClass] alloc] initWithFrame: frame];
		[draggedCard setCard: [_stack cardAtIndex: i]];
		draggedCard.hasShadow = YES;
		
		// Add new card view to the our superview so that dragging is across other peer stack views.
		[self addSubviewToSuperview: draggedCard];
		
		// Add to our array.
		[_draggedCardViews addObject: draggedCard];
		[draggedCard release];
	}
	
bail:
	
	return;
}

// ------------------------------------------------------------------------------------------------ dragDraggedCardViews

- (void) dragDraggedCardViews: (CGPoint) offset
{
	NSUInteger	count, i;
	
	count = [_draggedCardViews count];
	for (i = 0; i < count; i++)
	{
		CGRect	frame;
		
		frame = [[_draggedCardViews objectAtIndex: i] frame];
		[[_draggedCardViews objectAtIndex: i] setFrame: CGRectOffset (frame, offset.x, offset.y)];
	}
}

// ------------------------------------------------------------------------------------- returnDraggedCardsWithAnimation

- (void) returnDraggedCardsWithAnimation
{
	NSUInteger	i;
	CECard		*card = nil;
	CETableView	*cardTable;
	
	// Indicate an animation is in progress.
	_animationRefCount += 1;
	
	[UIView beginAnimations: nil context: nil];
	[UIView setAnimationDelegate: self];
	[UIView setAnimationDidStopSelector: @selector (draggedCardsReturned:finished:context:)];
	[UIView setAnimationDuration: kCardMoveAnimationSeconds];
	
	// Loop over dragged cards - return to original location.
	for (i = _cardRangeDragged.location; i < NSMaxRange (_cardRangeDragged); i++)
	{
		CGRect		frame;
		
		// Get frame from card-view touched - adjust position.
		frame = [[self cardViewForCardIndex: i] frame];
		frame = [self convertRect: frame toView: [self superview]];
		
		// Sanity check.
		if ([_draggedCardViews count] > (i - _cardRangeDragged.location))
		{
			[[_draggedCardViews objectAtIndex: i - _cardRangeDragged.location] setFrame: frame];
		}
		else
		{
			printf ("returnDraggedCardsWithAnimation - error, card index out range\n");
		}
		
		// Pick first card as representational of stack (see delegate call below).
		if (card == nil)
			card = [_stack cardAtIndex: i];
	}
	
	[UIView commitAnimations];
	
	// Call delegate animation begin routine.
	if ((_delegate) && ([_delegate respondsToSelector: @selector (stackView:beginAnimatingCardMove:)]))
		[_delegate stackView: self beginAnimatingCardMove: card];
	
	// The enclosing card table keeps track of the animation count.
	cardTable = [self enclosingCETableView];
	if (cardTable)
		[cardTable stackView: self beginAnimatingCardMove: card];
}

// ------------------------------------------------------------------------------- draggedCardsReturned:finished:context

- (void) draggedCardsReturned: (NSString *) animationID finished: (NSNumber *) finished context: (void *) context
{
	NSUInteger	i;
	CECard		*card = nil;
	CETableView	*cardTable;
	
	// Destroy dragged cards.
	[self destroyDraggedCardViews];
	
	// Reveal previously hidden cards.
	for (i = _cardRangeDragged.location; i < NSMaxRange (_cardRangeDragged); i++)
	{
		[[self cardViewForCardIndex: i] setHidden: NO];
		
		// Pick first card as representational of stack (see delegate call below).
		if (card == nil)
			card = [_stack cardAtIndex: i];
	}
	
	// Card dragging complete.
	_cardRangeDragged = NSMakeRange (0, 0);
	
	// Un-highlight.
	if (_highlightedStack)
	{
		[_highlightedStack setHighlight: NO];
		_highlightedStack = nil;
	}
	
	// Call delegate animation completion routine.
	if ((_delegate) && ([_delegate respondsToSelector: @selector (stackView:finishedAnimatingCardMove:)]))
		[_delegate stackView: self finishedAnimatingCardMove: card];
	
	// The enclosing card table keeps track of the animation count.
	cardTable = [self enclosingCETableView];
	if (cardTable)
		[cardTable stackView: self finishedAnimatingCardMove: card];
	
	// Animation complete.
	_animationRefCount -= 1;
}

// --------------------------------------------------------------------------------------------- destroyDraggedCardViews

- (void) destroyDraggedCardViews
{
	NSUInteger	count, i;
	
	// Remove all temporary drag cards from the superview.
	count = [_draggedCardViews count];
	for (i = 0; i < count; i++)
		[[_draggedCardViews objectAtIndex: i] removeFromSuperview];
	
	// Release temporary card views.
	[_draggedCardViews removeAllObjects];
}

#pragma mark ------ card drag handling
// ------------------------------------------------------------------------------------------------------- beginCardDrag

- (void) beginCardDrag: (UITouch *) touch
{
	CGPoint		location;
	CGPoint		offset;
	NSUInteger	i;
	
	// When the touch moves, we are in a dragging state.
	_touchState = kStackViewTouchStateMoving;
	
	// Get location of touch.
	location = [touch locationInView: self];
	
	// Determine the offset to move card origin.
	offset.x = location.x - _touchBeganLocation.x;
	offset.y = location.y - _touchBeganLocation.y + _cardYDragOffset;
	offset = [self convertPoint: offset toView: [self superview]];
	
	// Create dragged card views.
	[self createDraggedCardViews: offset];
	
	// Hide views of cards we are about to drag clones of.
	for (i = _cardRangeDragged.location; i < NSMaxRange (_cardRangeDragged); i++)
		[[self cardViewForCardIndex: i] setHidden: YES];
	
	// The stack shadow has to be reckoned with.
	if (_layout == kCEStackViewLayoutStacked)
		[self setNeedsDisplay];
	
	// Notify observers that a card is being dragged.
	[[NSNotificationCenter defaultCenter] postNotificationName: StackViewCardPickedUpNotification object: self userInfo: nil];
}

// ------------------------------------------------------------------------------------------------------ handleMoveCard

- (void) handleMoveCard: (UITouch *) touch
{
	CGPoint		location;
	CEStackView	*stackOver;
	CGPoint		previousLocation;
	BOOL		canDragTo = NO;
	
	// Get location in superview coords.
	location = [touch locationInView: [self superview]];
	
	// Are we over a stack?
	stackOver = [self stackViewAtLocation: location];
	
	// Is there a previously highlighted stack we are no longer over?  Un-highlight it.
	if ((_highlightedStack) && (stackOver != _highlightedStack))
	{
		[_highlightedStack setHighlight: NO];
		_highlightedStack = nil;
	}
	
	// Are we over a stack other than our own?
	if (stackOver == self)
	{
		canDragTo = YES;
	}
	else if ((stackOver) && (stackOver != self))
	{
		int			dragPerms;
		
		// Check its drag permissions.
		dragPerms = [stackOver dragPermissions];
		canDragTo = ((dragPerms != kStackDragSourceOnlyPermitted) && (dragPerms != kStackNoDraggingPermitted));
		
		// Ask delegate.
		if ((_delegate) && ([_delegate respondsToSelector: @selector (stackView:allowDragCard:toStackView:)]))
		{
			CECard	*card;
			
			card = [_stack cardAtIndex: _cardRangeDragged.location];
			canDragTo = [_delegate stackView: self allowDragCard: card toStackView: stackOver];
		}
	}
	
	// If we can drag to it.....
	if (canDragTo)
	{
		// I've tried it both ways but I think I prefer it if we do NOT highlight our own stack when dragging a card around.
		if (stackOver != self)
		{
			_highlightedStack = stackOver;
			[_highlightedStack setHighlight: YES];
		}
		
		// If the destination stack allows specific insertion (limited to spread or columnar layouts)
		// determine where in the destination stack it would be inserted. We need to have a notion of a 
		// place-holder card that is accounted for in the layout but no view is instantiated for it.
		// xxxx
	}
	
	// Position (drag) card.
	previousLocation = [touch previousLocationInView: [self superview]];
	[self dragDraggedCardViews: CGPointMake (location.x - previousLocation.x, location.y - previousLocation.y)];
	
//	NSDate *now = [[NSDate alloc] init];
//	printf ("Time for handleMoveCard: = %.5f\n", [now timeIntervalSinceNow]);
//	[now release];
}

// ---------------------------------------------------------------------------------------------------- handleRevealCard

- (void) handleRevealCard: (UITouch *) touch
{
	NSUInteger	cardIndexOver;
	
	// Locate card view we're over.
	cardIndexOver = [self cardIndexToRevealAtLocation: [touch locationInView: self]];
	if (cardIndexOver != _cardIndexRevealed)
	{
		// Pop the previously revealed card back down.
		[self setRevealCard: NO];
		
		// Assign the new card we are revealing.
		_cardIndexRevealed = cardIndexOver;
		
		// Reveal the new card.
		[self setRevealCard: YES];
	}
}

// ------------------------------------------------------------------------------------------------ determineDragGesture

- (int) determineDragGesture: (UITouch *) touch
{
#if 0
	int			gesture = kDragGestureNone;
	CGPoint		location;
	CGPoint		wasLocation;
	CGPoint		dragDelta;
	
	// Determine if the touch is moving horizontally or vertically.
	location = [touch locationInView: self];
	wasLocation = [touch previousLocationInView: self];
	dragDelta = CGPointMake (location.x - wasLocation.x, location.y - wasLocation.y);
	
	if (abs(dragDelta.y) > (abs(dragDelta.x) + 2.))
		gesture = kDragGestureRevealing;
	else if (abs(dragDelta.x) > (abs(dragDelta.y) + 2.))
		gesture = kDragGestureMoving;
#else
	int			gesture = kDragGestureNone;
	CGPoint		location;
	CGPoint		dragDelta;
	
	// Determine if the touch is moving horizontally or vertically.
	location = [touch locationInView: self];
	dragDelta = CGPointMake (location.x - _touchBeganLocation.x, location.y - _touchBeganLocation.y);
	
	// If the drag is up or down by some threshold, we are now 'moving' the card and no longer 'selecting'.
	if ((dragDelta.y < -([[self cardViewClass] cardSize: _cardSize].height / 2.0)) || 
			(dragDelta.y > ([[self cardViewClass] cardSize: _cardSize].height / 2.0)))
	{
		gesture = kDragGestureMoving;
	}
	else if (fabs (dragDelta.x) > (fabs (dragDelta.y) + 2.0))
	{
		gesture = kDragGestureRevealing;
	}
#endif
	
	return gesture;
}

// ------------------------------------------------------------------------------------------------------- setRevealCard

- (void) setRevealCard: (BOOL) reveal
{
	CECardView	*cardView;
	CGRect		frame;
	
	if (_cardIndexRevealed == NSNotFound)
		return;
	
	// COULD ANIMATE ALL THIS.
	cardView = [self cardViewForCardIndex: _cardIndexRevealed];
	frame = [cardView frame];
	if (reveal)
		frame = CGRectOffset (frame, 0.0, -[[self cardViewClass] playingCardVerticalReveal: _cardSize]);
	else
		frame = CGRectOffset (frame, 0.0, [[self cardViewClass] playingCardVerticalReveal: _cardSize]);
	[cardView setFrame: frame];
	
	// Set to nil if reveal turned off.
	if (reveal == NO)
		_cardIndexRevealed = NSNotFound;
}

// ------------------------------------------------------------------------------------------------- stackViewAtLocation

- (CEStackView *) stackViewAtLocation: (CGPoint) location
{
	NSArray		*peerViews;
	NSUInteger	count;
	NSUInteger	i;
	CEStackView	*stackOver = nil;
	
	// Get peer views.
	peerViews = [[self superview] subviews];
	
	count = [peerViews count];
	for (i = 0; i < count; i++)
	{
		UIView		*view;
		
		view = [peerViews objectAtIndex: i];
//		if ([view isKindOfClass: [CEStackView class]])
		if (CGRectContainsPoint ([view frame], location))
		{
//			if (CGRectContainsPoint ([view frame], location))
			if ([view isKindOfClass: [CEStackView class]])
			{
				stackOver = (CEStackView *)view;
				break;
			}	
		}
	}
	
	return stackOver;
}

#pragma mark ------ undo support
// --------------------------------------------------------------------------------- registerDealCard:stackView:duration

- (void) registerDealCard: (CECard *) card stackView: (CEStackView *) stack duration: (NSTimeInterval) duration
{
	NSMutableDictionary	*dictionary;
	
	// Create undo dictionary. For purposes of 'undo' we package up the whole action in a dictionary.
	dictionary = [[NSMutableDictionary alloc] initWithCapacity: 3];
	
	// Store action attributes in undo dictionary.
	[dictionary setObject: card forKey: @"card"];
	[dictionary setObject: self forKey: @"stack"];
	[dictionary setObject: [NSNumber numberWithBool: card.faceUp] forKey: @"faceUp"];
	[dictionary setObject: [NSNumber numberWithDouble: duration] forKey: @"duration"];
	
	// Pass the whole dictionary to the undo manager.
	[[CETableView sharedCardUndoManager] registerUndoWithTarget: stack selector: @selector (undoDealCard:) object: dictionary];
	
	// Clean up.
	[dictionary release];
}

// ------------------------------------------------------------------------------------------- registerFlipCard:duration

- (void) registerFlipCard: (CECard *) card duration: (NSTimeInterval) duration
{
	NSMutableDictionary	*dictionary;
	
	// Create undo dictionary. For purposes of 'undo' we package up the whole action in a dictionary.
	dictionary = [[NSMutableDictionary alloc] initWithCapacity: 3];
	
	// Store action attributes in undo dictionary.
	[dictionary setObject: card forKey: @"card"];
	[dictionary setObject: [NSNumber numberWithBool: card.faceUp] forKey: @"faceUp"];
	[dictionary setObject: [NSNumber numberWithDouble: duration] forKey: @"duration"];
	
	// Pass the whole dictionary to the undo manager.
	[[CETableView sharedCardUndoManager] registerUndoWithTarget: self selector: @selector (undoFlipCard:) object: dictionary];
	
	// Clean up.
	[dictionary release];
}

// -------------------------------------------------------------------------------------------------------- undoDealCard

- (void) undoDealCard: (NSDictionary *) dictionary
{
	[self dealCard: [dictionary objectForKey: @"card"] 
			toStackView: [dictionary objectForKey: @"stack"] 
			faceUp: [[dictionary objectForKey: @"faceUp"] boolValue] 
//			duration: [[dictionary objectForKey: @"duration"] doubleValue]];
			duration: 0.0];
}

// -------------------------------------------------------------------------------------------------------- undoFlipCard

- (void) undoFlipCard: (NSDictionary *) dictionary
{
	[self flipCard: [dictionary objectForKey: @"card"] 
			faceUp: [[dictionary objectForKey: @"faceUp"] boolValue] 
//			duration: [[dictionary objectForKey: @"duration"] doubleValue]];
			duration: 0.0];
}

#pragma mark ------ layout engine
// ---------------------------------------------------------------------------------------------- calculateLayoutOffsets

- (void) calculateLayoutOffsets
{
	// Set to invalid value.
	_cardSeparation = -1.0;
	_cardBiasSeparation = -1.0;
	
	// See if delegate wants to provide the separation.
	if ((_delegate) && ([_delegate respondsToSelector: @selector (idealCardSeparationForStackView:)]))
		_cardSeparation = [_delegate idealCardSeparationForStackView: self];
	
	if (_cardSeparation < 0.0)
	{
		if (_layout == kCEStackViewLayoutStacked)
			_cardSeparation = 0.0;
		else if ((_layout == kCEStackViewLayoutStandardSpread) || (_layout == kCEStackViewLayoutReverseSpread))
			_cardSeparation = kHorizontalSpreadSeparation;
		else if ((_layout == kCEStackViewLayoutColumn) || (_layout == kCEStackViewLayoutBiasedColumn))
			_cardSeparation = [[self cardViewClass] playingCardVerticalReveal: _cardSize];
	}
	
	// See if delegate wants to provide the separation.
	if ((_delegate) && ([_delegate respondsToSelector: @selector (idealCardBiasSeparationForStackView:)]))
		_cardBiasSeparation = [_delegate idealCardBiasSeparationForStackView: self];
	if (_cardBiasSeparation < 0.0)
		_cardBiasSeparation = kVerticalFaceDownSeparation;
	
	// Calculate the horizontal offset.
	if ((_layout == kCEStackViewLayoutStandardSpread) || (_layout == kCEStackViewLayoutReverseSpread))
	{
		// Use vertical gap for horizontal offset.
		_hOffset = ceil(([self bounds].size.height - [[self cardViewClass] cardSize: _cardSize].height) / 2.0);
		if (_hOffset < 0.0)
			_hOffset = 0.0;
	}
	else
	{
		_hOffset = floor(([self bounds].size.width - [[self cardViewClass] cardSize: _cardSize].width) / 2.0);
		if (_hOffset < 0.0)
			_hOffset = 0.0;
	}
	
	// Calculate the vertical offset.
	if ((_layout == kCEStackViewLayoutColumn) || (_layout == kCEStackViewLayoutBiasedColumn))
	{
		// Fixed offset from the top of stack view.
		_vOffset = ceil(([self bounds].size.width - [[self cardViewClass] cardSize: _cardSize].width) / 2.0);
		if (_vOffset < 0.0)
			_vOffset = 0.0;
	}
	else
	{
		// We center the cards vertically for spread and stack.
		_vOffset = ceil(([self bounds].size.height - [[self cardViewClass] cardSize: _cardSize].height) / 2.0);
		if (_vOffset < 0.0)
			_vOffset = 0.0;
	}
	
	// Compute corner radius.
	if (_cornerRadius < 0)
	{
		_cornerRadiusInternal = [[self cardViewClass] playingCardCornerRadius: _cardSize];
		if (_layout == kCEStackViewLayoutStandardSpread)
		{
			CGFloat		delta;
			
			delta = ([self frame].size.height - [[self cardViewClass] cardSize: _cardSize].height) / 2.0;
			_cornerRadiusInternal = _cornerRadiusInternal + delta;
		}
		else
		{
			CGFloat		delta;
			
			delta = ([self frame].size.width - [[self cardViewClass] cardSize: _cardSize].width) / 2.0;
			_cornerRadiusInternal = _cornerRadiusInternal + delta;
		}
	}
	else
	{
		_cornerRadiusInternal = _cornerRadius;
	}
}

// --------------------------------------------------------------------------------------------- shouldRevealCardOnTouch

- (BOOL) shouldRevealCardOnTouch: (UITouch *) touch
{
	if (_layout == kCEStackViewLayoutStacked)
	{
		return NO;
	}
	else if (_layout == kCEStackViewLayoutStandardSpread)
	{
		NSUInteger	cardIndex;
		
		// Sanity check (not needed I think).
		require (_stack, bail);
		require ([_stack numberOfCards] > 0, bail);
		
		// Get card index for touch location.
		cardIndex = [self cardIndexToRevealAtLocation: [touch locationInView: self]];
		require (cardIndex != NSNotFound, bail);
		
		// No reveal on top card.  Otherwise, yes.
		if (cardIndex == ([_stack numberOfCards] - 1))
		{
			return NO;
		}
		else
		{
			// NEED CODE IN HERE THAT DETERMINES WHEN IT IS CRAMPED AND WE SHOULD REVEAL, OTHERWISE WE SHOULD NOT
			return YES;
		}
	}
	
bail:
	
	return NO;
}

// ----------------------------------------------------------------------------------------- cardIndexToRevealAtLocation

- (NSUInteger) cardIndexToRevealAtLocation: (CGPoint) location
{
	CGRect		ourBounds;
	NSUInteger	count;
	NSUInteger	i;
	NSUInteger	index = NSNotFound;
	
	// Get our bounds.
	ourBounds = [self bounds];
	
	// Walk card view list from front to back (in reverse order).
	count = [_cardViews count];
	for (i = count; i > 0; i--)
	{
		CGRect		frame;
		
		// Hit-test extended view.
		frame = [[_cardViews objectAtIndex: i - 1] frame];
		frame.origin.y = 0.0;
		frame.size.height = ourBounds.size.height;
		if (CGRectContainsPoint (frame, location))
		{
			index = i - 1;
			break;
		}
	}
	
	return index;
}

// ------------------------------------------------------------------------------------------------- cardIndexAtLocation

- (NSUInteger) cardIndexAtLocation: (CGPoint) location
{
	NSUInteger	count;
	NSUInteger	i;
	NSUInteger	index = NSNotFound;
	
	// Walk card view list from front to back (in reverse order).
	count = [_cardViews count];
	for (i = count; i > 0; i--)
	{
		// Hit-test view.
		if (CGRectContainsPoint ([[_cardViews objectAtIndex: i - 1] frame], location))
		{
			// For a stacked layout, a hit means top (last) card.
			if (_layout == kCEStackViewLayoutStacked)
				index = [_stack numberOfCards] - 1;
			else
				index = i - 1;
			break;
		}
	}
	
	return index;
}

// ------------------------------------------------------------------------------------------------ cardViewForCardIndex

- (CECardView *) cardViewForCardIndex: (NSUInteger) index
{
	CECardView	*view = nil;
	
	// Param check.
	require (index != NSNotFound, bail);
	
	// Stacked layout does not have a one-to-one correlation between views and cards.  Special case.
	if (_layout == kCEStackViewLayoutStacked)
	{
		// Sanity check: index ought to correspond to the top card.
		require ((index + 1) == [_stack numberOfCards], bail);
		
		// Top view is for top card.
		view = [_cardViews lastObject];
	}
	else
	{
		// Sanity check: index should be within range.
		require (index < [_stack numberOfCards], bail);
		
		// Second sanity check, index should be within range of the card views.
		require (index < [_cardViews count], bail);
		
		// Card index and view order are one-to-one.
		view = [_cardViews objectAtIndex: index];
	}
	
bail:
	
	return view;
}

// ----------------------------------------------------------------------------------------------------- cardViewForCard

- (CECardView *) cardViewForCard: (CECard *) card
{
	CECardView	*view = nil;
	NSUInteger	count, i;
	
	// Param check.
	require (card, bail);
	
	// Walk through card views looking for the indicated card.
	count = [_cardViews count];
	for (i = 0; i < count; i++)
	{
		if ([[_cardViews objectAtIndex: i] card] == card)
		{
			view = [_cardViews objectAtIndex: i];
			break;
		}
	}
	
bail:
	
	return view;
}

// ------------------------------------------------------------------------------------------------ boundsForCardAtIndex

- (CGRect) boundsForCardAtIndex: (NSUInteger) index forCount: (NSUInteger) count
{
	CGRect		cardBounds = CGRectZero;
	CGRect		ourBounds;
	
	// Param check.
	require (count > 0, bail);
	
	// Get base card bounds.
	cardBounds.origin = CGPointMake (0.0, 0.0);
	cardBounds.size = [[self cardViewClass] cardSize: _cardSize];
	ourBounds = [self frame];
	
	if (_layout == kCEStackViewLayoutStacked)
	{
		cardBounds = CGRectOffset (cardBounds, _hOffset,  ourBounds.size.height - cardBounds.size.height - _vOffset);
	}
	else if (_layout == kCEStackViewLayoutStandardSpread)
	{
		CGFloat		hDelta;
		CGFloat		proposedW;
		
		proposedW = _hOffset + ((count - 1) * _cardSeparation) + cardBounds.size.width + _hOffset;
		if (proposedW > ourBounds.size.width)
		{
			// Need to squeeze cards tighter.
			hDelta = (ourBounds.size.width - _hOffset - _hOffset - cardBounds.size.width) / (count - 1);
			if (hDelta < 1.0)
				hDelta = 1.0;
			hDelta = (hDelta * index) + _hOffset;
		}
		else
		{
			// Cards fit with standard separation.
			hDelta = _hOffset + (index * _cardSeparation);
		}
		
		// Place card.
		cardBounds = CGRectOffset (cardBounds, floor(hDelta), _vOffset);
	}
	else if (_layout == kCEStackViewLayoutColumn)
	{
		CGFloat		proposedH;
		CGFloat		vDelta;
		
		// Determine how much height we would need if all cards were revealed the ideal amount.
		proposedH = _vOffset + ((count - 1) * _cardSeparation) + cardBounds.size.height + _vOffset;
		
		// If this is too tall for our view, we need to start squeezing the cards in tighter.
		if (proposedH > ourBounds.size.height)
		{
			// Need to squeeze cards tighter.
			vDelta = (ourBounds.size.height - _vOffset - _vOffset - cardBounds.size.height) / (count - 1);
			if (vDelta < 1.)
				vDelta = 1.;
			vDelta = (vDelta * index) + _vOffset;
		}
		else
		{
			// Cards fit with standard separation - compute offset.
			vDelta = _vOffset + (index * _cardSeparation);
		}
		
		// Place card.
		cardBounds = CGRectOffset (cardBounds, _hOffset, floor(vDelta));
	}
	else if (_layout == kCEStackViewLayoutBiasedColumn)
	{
		NSUInteger	i;
		NSUInteger	numFaceDown = 0;
		NSUInteger	numFaceUp;
		CGFloat		maxVHeight;
		CGFloat		proposedH;
		CGFloat		vDelta;
		
		// Calculate the number of face up and face down cards.
		for (i = 0; i < count; i++)
		{
			CECard	*card;
			
			card = [_stack cardAtIndex: i];
			if ((card) && ([card isFaceUp] == NO))
				numFaceDown = numFaceDown + 1;
		}
		numFaceUp = count - numFaceDown;
		
		// Determine how much height we would need if all cards were revealed the ideal amount.
		if (numFaceUp == 0)
		{
			proposedH = (_vOffset + (numFaceDown * _cardBiasSeparation) + cardBounds.size.height + _vOffset);
		}
		else
		{
			proposedH = (_vOffset + (numFaceDown * _cardBiasSeparation) + ((numFaceUp - 1) * _cardSeparation) + 
					cardBounds.size.height + _vOffset);
		}
		
		if (proposedH > ourBounds.size.height)
		{
			if (numFaceUp == 0)
			{
				maxVHeight = 0.0;
			}
			else
			{
				maxVHeight = (ourBounds.size.height - _vOffset - (numFaceDown * _cardBiasSeparation) - 
						cardBounds.size.height - _vOffset) / (numFaceUp - 1);
			}
			
			// Cards fit with standard separation.
			vDelta = _vOffset;
			for (i = 0; i < index; i++)
			{
				CECard	*card;
				
				card = [_stack cardAtIndex: i];
				if ((card) && ([card isFaceUp] == NO))
					vDelta = vDelta + _cardBiasSeparation;
				else
					vDelta = vDelta + maxVHeight;
			}
		}
		else
		{
			// Cards fit with standard separation.
			vDelta = _vOffset;
			for (i = 0; i < index; i++)
			{
				CECard	*card;
				
				card = [_stack cardAtIndex: i];
				if ((card) && ([card isFaceUp] == NO))
					vDelta = vDelta + _cardBiasSeparation;
				else
					vDelta = vDelta + _cardSeparation;
			}
		}
		
		// Place card.
		cardBounds = CGRectOffset (cardBounds, _hOffset, floor(vDelta));
	}
	
bail:
	
	return cardBounds;
}

// --------------------------------------------------------------------------------------------------------- layoutCards

- (void) layoutCards
{
	NSUInteger	count;
	NSUInteger	i;
	
	// Remove all playing card subviews.
	count = [_cardViews count];
	for (i = 0; i < count; i++)
		[[_cardViews objectAtIndex: i] removeFromSuperview];
	[_cardViews removeAllObjects];
	
	// NOP.
	if ((_stack == nil) || ([_stack numberOfCardsExcludingPromised] == 0))
		return;
	
	switch (_layout)
	{
		case kCEStackViewLayoutStacked:
		[self layoutForStack];
		break;
		
		case kCEStackViewLayoutStandardSpread:
		[self layoutForSpread];
		break;
		
		case kCEStackViewLayoutColumn:
		case kCEStackViewLayoutBiasedColumn:
		[self layoutForColumn];
		break;
		
		default:
		break;
	}
	
	// Add as subviews.
	count = [_cardViews count];
	for (i = 0; i < count; i++)
		[self addSubview: [_cardViews objectAtIndex: i]];
}

// ------------------------------------------------------------------------------------------------------ layoutForStack

- (void) layoutForStack
{
	NSArray			*cards;
	NSUInteger		count;
	CGRect			frame;
	CECardView		*cardView;
	
	// Reset card bounding box.
	_cardBoundingRect = CGRectZero;
	
	// Make sure we have at least 1 card.
	cards = [_stack cardsExcludingPromised];
	count = [cards count];
	if (count == 0)
		return;
	
	// If we have more than one card create a view for the card just below the top card.
	if (count > 1)
	{
		frame = [self boundsForCardAtIndex: count - 2 forCount: count];
		cardView = [[[self cardViewClass] alloc] initWithFrame: frame];
		[cardView setCard: [cards objectAtIndex: count - 2]];
		if (!_orderly)
			cardView.transform = cardView.card.transform;
		[_cardViews addObject: cardView];
		[cardView release];
	}
	
	// Create the top playing card view.
	frame = [self boundsForCardAtIndex: count - 1 forCount: count];
	cardView = [[[self cardViewClass] alloc] initWithFrame: frame];
	[cardView setCard: [cards objectAtIndex: count - 1]];
	if (!_orderly)
		cardView.transform = cardView.card.transform;
	if (_displaysCount)
		[cardView setLabel: [NSString stringWithFormat: @"%lu", (unsigned long)[_stack numberOfCards]]];
	else
		[cardView setLabel: nil];
	[_cardViews addObject: cardView];
	[cardView release];
	
	// stack, simple bounding rect.
	_cardBoundingRect = frame;
}

// ----------------------------------------------------------------------------------------------------- layoutForSpread

- (void) layoutForSpread
{
	NSArray			*cards;
	NSUInteger		count;
	NSUInteger		i;
	
	// Reset card bounding box.
	_cardBoundingRect = CGRectZero;
	
	// Walk through cards in stack, create a card view, position, and add as subview.
	cards = [_stack cardsExcludingPromised];
	count = [cards count];
	for (i = 0; i < count; i++)
	{
		CGRect		frame;
		CECardView	*cardView;
		
		frame = [self boundsForCardAtIndex: i forCount: count];
		cardView = [[[self cardViewClass] alloc] initWithFrame: frame];
		[cardView setCard: [cards objectAtIndex: i]];
		if (!_orderly)
			cardView.transform = cardView.card.transform;
		[_cardViews addObject: cardView];
		[cardView release];
		
		// Get the union of all card bounds.
		_cardBoundingRect = CGRectUnion (_cardBoundingRect, frame);
	}
}

// ----------------------------------------------------------------------------------------------------- layoutForColumn

- (void) layoutForColumn
{
	NSArray			*cards;
	NSUInteger		count;
	NSUInteger		i;
	
	// Reset card bounding box.
	_cardBoundingRect = CGRectZero;
	
	// Walk through cards in stack, create a card view, position, and add as subview.
	cards = [_stack cardsExcludingPromised];
	count = [cards count];
	for (i = 0; i < count; i++)
	{
		CGRect		frame;
		CECardView	*cardView;
		
		frame = [self boundsForCardAtIndex: i forCount: count];
		cardView = [[[self cardViewClass] alloc] initWithFrame: frame];
		[cardView setCard: [cards objectAtIndex: i]];
		if (!_orderly)
			cardView.transform = cardView.card.transform;
		[_cardViews addObject: cardView];
		[cardView release];
		
		// Get the union of all card bounds.
		_cardBoundingRect = CGRectUnion (_cardBoundingRect, frame);
	}
}

#pragma mark ------ animation
// ----------------------------------------------------------------------------------------------------- handleAnimation

- (void) handleAnimation: (NSMutableDictionary *) dictionary
{
	// Handle animating card from point to point.
	if ([[dictionary objectForKey: @"type"] isEqualToString: @"moveCardFromPointToPoint"])
	{
		int		stage;
		
		// Get stage of animation.
		stage = [[dictionary objectForKey: @"stage"] intValue];
		
		if (stage == 0)
		{
			CECard			*card;
			BOOL			faceUp;
			BOOL			cardIsFaceUp;
			BOOL			willFlip;
			CGPoint			startPt;
			CGPoint			endPt;
			CGRect			frame;
			UIImageView		*imageView;
			UIImage			*image;
			CECard			*tempCard;
			CECardView		*tempView;
			CGPoint			wayPt;
			NSTimeInterval	totalDuration;
			CETableView		*cardTable;
			
			// Indicate stage 1.
			[dictionary setObject: [NSNumber numberWithInt: 1] forKey: @"stage"];
			
			// Get card and faceup-edness from dictionary.
			card = [dictionary objectForKey: @"card"];
			faceUp = [[dictionary objectForKey: @"faceUp"] boolValue];		
			cardIsFaceUp = [card isFaceUp];
			willFlip = (cardIsFaceUp != faceUp);
			startPt = [[dictionary objectForKey: @"startPt"] CGPointValue];
			endPt = [[dictionary objectForKey: @"endPt"] CGPointValue];
			
			// Set up rectangle for card size.
			frame.origin = CGPointMake (0.0, 0.0);
			frame.size = [[self cardViewClass] cardSize: _cardSize];
			frame.size.width = frame.size.width + kCardShadowOffset;
			frame.size.height = frame.size.height + kCardShadowOffset;
			
			// Create the main view we're going to animate.
			imageView = [[UIImageView alloc] initWithFrame: frame];
			[self addSubviewToSuperview: imageView];
			[imageView setCenter: startPt];
			
			// Create temporary playing card view.
			tempView = [[[self cardViewClass] alloc] initWithFrame: frame];
			tempView.hasShadow = YES;
			
			// Calling -[copy] on the card is preferred.
			// NOTE TO SELF - ADD COPY PROTOCOL TO PLAYINGCARD
			tempCard = [[CECard alloc] initWithIndex: [card index]];
			[tempView setCard: tempCard];
			if (!_orderly)
				tempView.transform = tempCard.transform;
			[tempCard release];
			
			// Set card image for view.
			UIGraphicsBeginImageContext (frame.size);
			if (cardIsFaceUp)
				[tempView drawCardFace];
			else
				[tempView drawCardBack];
			[imageView setImage: UIGraphicsGetImageFromCurrentImageContext ()];
			UIGraphicsEndImageContext ();
			
			// If the card is to flip, create a secondary image view for the card.
			if (willFlip)
			{
				// Create an alternate image for the card.
				UIGraphicsBeginImageContext (frame.size);
				if (faceUp)
					[tempView drawCardFace];
				else
					[tempView drawCardBack];
				image = UIGraphicsGetImageFromCurrentImageContext ();
				UIGraphicsEndImageContext ();
				
				// Add image view for start image view.
				[dictionary setObject: image forKey: @"alternateImage"];
				
				// Set transform (squash to appear as though the card is flipping).
				[dictionary setObject: [NSValue valueWithCGAffineTransform: 
						CGAffineTransformMakeScale (0.01, kCardEnlargeScale)] forKey: @"transform"];
				
				// Set way point.
				if (endPt.x < startPt.x)
					wayPt.x = startPt.x - ([[self cardViewClass] cardSize: _cardSize].width / 2.0) - 2.0;
				else
					wayPt.x = startPt.x + ([[self cardViewClass] cardSize: _cardSize].width / 2.0) + 2.0;
				wayPt.y = startPt.y;
				[dictionary setObject: [NSValue valueWithCGPoint: wayPt] forKey: @"wayPt"];
				
				// Set duration.
				totalDuration = [[dictionary objectForKey: @"totalDuration"] doubleValue];
				[dictionary setObject: [NSNumber numberWithDouble: totalDuration / 4.] forKey: @"duration"];
			}
			else
			{
				// Set transform (no squashing for a psuedo-flip).
				[dictionary setObject: [NSValue valueWithCGAffineTransform: 
						CGAffineTransformMakeScale (kCardEnlargeScale, kCardEnlargeScale)] forKey: @"transform"];
				
				// Set way point.
				wayPt.x = startPt.x + ((endPt.x - startPt.x) / 3.0);
				wayPt.y = startPt.y + ((endPt.y - startPt.y) / 3.0);
				[dictionary setObject: [NSValue valueWithCGPoint: wayPt] forKey: @"wayPt"];
				
				// Set duration.
				totalDuration = [[dictionary objectForKey: @"totalDuration"] doubleValue];
				[dictionary setObject: [NSNumber numberWithDouble: totalDuration / 3.0] forKey: @"duration"];
			}
			
			[dictionary setObject: imageView forKey: @"view"];
			
			// Set animation curve.
			[dictionary setObject: [NSNumber numberWithInt: UIViewAnimationCurveEaseIn] forKey: @"curve"];
			
			// Done with temporary views.
			[tempView release];
			[imageView release];
			
			// Call delegate animation begin routine.
			if ((_delegate) && ([_delegate respondsToSelector: @selector (stackView:beginAnimatingCardMove:)]))
				[_delegate stackView: self beginAnimatingCardMove: card];
			
			// The enclosing card table keeps track of the animation count.
			cardTable = [self enclosingCETableView];
			if (cardTable)
				[cardTable stackView: self beginAnimatingCardMove: card];
			
			// Animate.
			[self animateWithDictionary: dictionary];
		}
		else if (stage == 1)
		{
			CECard			*card;
			BOOL			faceUp;
			BOOL			cardIsFaceUp;
			BOOL			willFlip;
			CGPoint			wayPt;
			NSTimeInterval	totalDuration;
			
			// Indicate stage 2.
			[dictionary setObject: [NSNumber numberWithInt: 2] forKey: @"stage"];
			
			// Determine if we are fliping the card.
			card = [dictionary objectForKey: @"card"];
			faceUp = [[dictionary objectForKey: @"faceUp"] boolValue];		
			cardIsFaceUp = [card isFaceUp];
			willFlip = (cardIsFaceUp != faceUp);
			
			if (willFlip)
			{
				UIImage			*image;
				UIImageView		*view;
				CGPoint			startPt;
				
				// Swap in alternate view.
				image = [dictionary objectForKey: @"alternateImage"];
				view = [dictionary objectForKey: @"view"];
				[view setImage: image];
				
				// Set way point.
				wayPt = [[dictionary objectForKey: @"wayPt"] CGPointValue];
				startPt = [[dictionary objectForKey: @"startPt"] CGPointValue];
				wayPt.x = wayPt.x + (wayPt.x - startPt.x);
				[dictionary setObject: [NSValue valueWithCGPoint: wayPt] forKey: @"wayPt"];
				
				// Set duration.
				totalDuration = [[dictionary objectForKey: @"totalDuration"] doubleValue];
				[dictionary setObject: [NSNumber numberWithDouble: totalDuration / 4.0] forKey: @"duration"];
			}
			else
			{
				CGPoint		endPt;
				
				wayPt = [[dictionary objectForKey: @"wayPt"] CGPointValue];
				endPt = [[dictionary objectForKey: @"endPt"] CGPointValue];
				wayPt.x = (wayPt.x + endPt.x) / 2.0;
				wayPt.y = (wayPt.y + endPt.y) / 2.0;
				
				[dictionary setObject: [NSValue valueWithCGPoint: wayPt] forKey: @"wayPt"];
				// Set duration.
				totalDuration = [[dictionary objectForKey: @"totalDuration"] doubleValue];
				[dictionary setObject: [NSNumber numberWithDouble: totalDuration / 3.0] forKey: @"duration"];
			}
			
			// Set transform.
			[dictionary setObject: [NSValue valueWithCGAffineTransform: 
					CGAffineTransformMakeScale (kCardEnlargeScale, kCardEnlargeScale)] forKey: @"transform"];
			
			// Set animation curve.
			[dictionary setObject: [NSNumber numberWithInt: UIViewAnimationCurveLinear] forKey: @"curve"];
			
			// Animate.
			[self animateWithDictionary: dictionary];
		}
		else if (stage == 2)
		{
			CECard			*card;
			BOOL			faceUp;
			BOOL			cardIsFaceUp;
			BOOL			willFlip;
			CGPoint			wayPt;
			NSTimeInterval	totalDuration;
			
			// Indicate stage 3.
			[dictionary setObject: [NSNumber numberWithInt: 3] forKey: @"stage"];
			
			// Determine if we are fliping the card.
			card = [dictionary objectForKey: @"card"];
			faceUp = [[dictionary objectForKey: @"faceUp"] boolValue];		
			cardIsFaceUp = [card isFaceUp];
			willFlip = (cardIsFaceUp != faceUp);
			
			// Set way point.
			wayPt = [[dictionary objectForKey: @"endPt"] CGPointValue];
			[dictionary setObject: [NSValue valueWithCGPoint: wayPt] forKey: @"wayPt"];
			
			// Set transform.
			[dictionary setObject: [NSValue valueWithCGAffineTransform: CGAffineTransformIdentity] forKey: @"transform"];
			
			if (willFlip)
			{
				// Set duration.
				totalDuration = [[dictionary objectForKey: @"totalDuration"] doubleValue];
				[dictionary setObject: [NSNumber numberWithDouble: totalDuration / 2.0] forKey: @"duration"];
			}
			else
			{
				// Set duration.
				totalDuration = [[dictionary objectForKey: @"totalDuration"] doubleValue];
				[dictionary setObject: [NSNumber numberWithDouble: totalDuration / 3.0] forKey: @"duration"];
			}
			
			// Set animation curve.
			[dictionary setObject: [NSNumber numberWithInt: UIViewAnimationCurveEaseOut] forKey: @"curve"];
			
			// Animate.
			[self animateWithDictionary: dictionary];
		}
		else
		{
			UIView		*view;
			CECard		*card;
			CEStack		*destStack;
			BOOL		faceUp;
			CETableView	*cardTable;
			
			// Remove the temporary in-flight view.
			view = [dictionary objectForKey: @"view"];
			[view removeFromSuperview];
			
			// Now is the time to move the card.
			card = [dictionary objectForKey: @"card"];
			destStack = [dictionary objectForKey: @"destStack"];
			faceUp = [[dictionary objectForKey: @"faceUp"] boolValue];
			
			// Flip and add card to destination stack.
			[card setFaceUp: faceUp];
			[destStack promiseKeptForCard: card];
			[card release];
			
			// Call delegate animation completion routine.
			if ((_delegate) && ([_delegate respondsToSelector: @selector (stackView:finishedAnimatingCardMove:)]))
				[_delegate stackView: self finishedAnimatingCardMove: card];
			
			// Call private delegate animation completion routine.
			if ((_privateDelegate) && ([_privateDelegate respondsToSelector: @selector (stackView:finishedAnimatingCardMove:)]))
				[_privateDelegate stackView: self finishedAnimatingCardMove: card];
			
			// The enclosing card table keeps track of the animation count.
			cardTable = [self enclosingCETableView];
			if (cardTable)
				[cardTable stackView: self finishedAnimatingCardMove: card];
			
			// Notify observers that the card animating has landed.
			[[NSNotificationCenter defaultCenter] postNotificationName: StackViewCardReleasedNotification 
					object: self userInfo: nil];
			
			// Done.
			[dictionary autorelease];
		}
	}
	else if ([[dictionary objectForKey: @"type"] isEqualToString: @"flipCard"])
	{
		int		stage;
		
		// Get stage of animation.
		stage = [[dictionary objectForKey: @"stage"] intValue];
		
		if (stage == 0)
		{
			CECard			*card;
			BOOL			faceUp;
			BOOL			cardIsFaceUp;
			CGRect			frame;
			UIImageView		*imageView;
			UIImage			*image;
			CECard			*tempCard;
			CECardView		*tempView;
			NSTimeInterval	totalDuration;
			CETableView		*cardTable;
			
			// Indicate stage 1.
			[dictionary setObject: [NSNumber numberWithInt: 1] forKey: @"stage"];
			
			// Get card and faceup-edness from dictionary.
			card = [dictionary objectForKey: @"card"];
			faceUp = [[dictionary objectForKey: @"faceUp"] boolValue];		
			
			// Set face-upedness.
			cardIsFaceUp = [card isFaceUp];
			
			// Set up rectangle for card size.
			frame.origin = CGPointMake (0.0, 0.0);
			frame.size = [[self cardViewClass] cardSize: _cardSize];
			
			// Create the main view we're going to animate.
			imageView = [[UIImageView alloc] initWithFrame: frame];
			[self addSubviewToSuperview: imageView];
			
			// Create temporary playing card view.
			tempView = [[[self cardViewClass] alloc] initWithFrame: frame];
			
			// Calling -[copy] on the card is preferred.
			// NOTE TO SELF - ADD COPY PROTOCOL TO PLAYINGCARD
			tempCard = [[CECard alloc] initWithIndex: [card index]];
			[tempView setCard: tempCard];
			if (!_orderly)
				tempView.transform = tempCard.transform;
			[tempCard release];
			
			// Create an image for the card.
			UIGraphicsBeginImageContext (frame.size);
			if (cardIsFaceUp)
				[tempView drawCardFace];
			else
				[tempView drawCardBack];
			[imageView setImage: UIGraphicsGetImageFromCurrentImageContext ()];
			UIGraphicsEndImageContext ();
			
			// To flip, create a secondary image view for the card.
			UIGraphicsBeginImageContext (frame.size);
			if (faceUp)
				[tempView drawCardFace];
			else
				[tempView drawCardBack];
			image = UIGraphicsGetImageFromCurrentImageContext ();
			UIGraphicsEndImageContext ();
			
			// Get the pre-determined bounds for the view.
			frame = [[dictionary objectForKey: @"frame"] CGRectValue];
			[imageView setFrame: frame];
			
			// Add image view for start image view.
			[dictionary setObject: image forKey: @"alternateImage"];
			
			// Set transform (squash to appear as though the card is flipping).
			[dictionary setObject: [NSValue valueWithCGAffineTransform: 
					CGAffineTransformMakeScale (0.01, kCardEnlargeScale)] forKey: @"transform"];
			
			// Assign view.
			[dictionary setObject: imageView forKey: @"view"];
			
			// Set duration.
			totalDuration = [[dictionary objectForKey: @"totalDuration"] doubleValue];
			[dictionary setObject: [NSNumber numberWithDouble: totalDuration / 2.] forKey: @"duration"];
			
			// Set animation curve.
			[dictionary setObject: [NSNumber numberWithInt: UIViewAnimationCurveEaseIn] forKey: @"curve"];
			
			// Done with temporary views.
			[tempView release];
			[imageView release];
			
			// Call delegate animation begin routine.
			if ((_delegate) && ([_delegate respondsToSelector: @selector (stackView:beginAnimatingCardFlip:)]))
				[_delegate stackView: self beginAnimatingCardFlip: card];
			
			// The enclosing card table keeps track of the animation count.
			cardTable = [self enclosingCETableView];
			if (cardTable)
				[cardTable stackView: self beginAnimatingCardFlip: card];
			
			// Animate.
			[self animateWithDictionary: dictionary];
		}
		else if (stage == 1)
		{
			UIImageView		*view;
			UIImage			*image;
			NSTimeInterval	totalDuration;
			
			// Indicate stage 2.
			[dictionary setObject: [NSNumber numberWithInt: 2] forKey: @"stage"];
			
			// Switch to the flipped card view.
			view = [dictionary objectForKey: @"view"];
			image = [dictionary objectForKey: @"alternateImage"];
			[view setImage: image];
			
			// Set transform.
			[dictionary setObject: [NSValue valueWithCGAffineTransform: CGAffineTransformIdentity] forKey: @"transform"];
			
			// Set duration.
			totalDuration = [[dictionary objectForKey: @"totalDuration"] doubleValue];
			[dictionary setObject: [NSNumber numberWithDouble: totalDuration / 2.0] forKey: @"duration"];
			
			// Set animation curve.
			[dictionary setObject: [NSNumber numberWithInt: UIViewAnimationCurveEaseOut] forKey: @"curve"];
			
			// Animate.
			[self animateWithDictionary: dictionary];
		}
		else
		{
			UIView		*view;
			CECard		*card;
			BOOL		faceUp;
			CECardView	*cardView;
			CETableView	*cardTable;
			
			// Remove temporary animating view.
			view = [dictionary objectForKey: @"view"];
			[view removeFromSuperview];
			
			// Get card and faceup-edness from dictionary.
			card = [dictionary objectForKey: @"card"];
			faceUp = [[dictionary objectForKey: @"faceUp"] boolValue];		
			
			// Get view associated with card.
			cardView = [self cardViewForCard: card];

			// Face up.
			[card setFaceUp: faceUp];
			
			// Unhide card view.
			[cardView setHidden: NO];
			
			// Needs to be redrawn.  Clearing the hidden flag does not force a redraw.
			[cardView setNeedsDisplay];
			
			// Call delegate animation completion routine.
			if ((_delegate) && ([_delegate respondsToSelector: @selector (stackView:finishedAnimatingCardFlip:)]))
				[_delegate stackView: self finishedAnimatingCardFlip: card];
			
			// The enclosing card table keeps track of the animation count.
			cardTable = [self enclosingCETableView];
			if (cardTable)
				[cardTable stackView: self finishedAnimatingCardFlip: card];
			
			// Done.
			[dictionary autorelease];
		}
	}
}

// ----------------------------------------------------------------------------------------------- animateWithDictionary

- (void) animateWithDictionary: (NSDictionary *) dictionary
{
	UIView		*view;
	NSNumber	*number;
	NSValue		*value;
	
	// Indicate an animation is in progress.
	_animationRefCount += 1;
	
	view = [dictionary objectForKey: @"view"];
	
	// Set up animation using the dictionary passed in as a reference.
	[UIView beginAnimations: nil context: dictionary];
	[UIView setAnimationDelegate: self];
	[UIView setAnimationDidStopSelector: @selector (animationStopped:finished:context:)];
	
	// Duration.
	number = [dictionary objectForKey: @"duration"];
	if (number)
		[UIView setAnimationDuration: [number doubleValue]];
	
	// Animation curve.
	number = [dictionary objectForKey: @"curve"];
	if (number)
		[UIView setAnimationCurve: [number intValue]];
	
	// Transform.
	value = [dictionary objectForKey: @"transform"];
	if (value)
		[view setTransform: [value CGAffineTransformValue]];

	value = [dictionary objectForKey: @"wayPt"];
	if (value)
		[view setCenter: [value CGPointValue]];
	
	[UIView commitAnimations];
}

// ----------------------------------------------------------------------------------- animationDidStop:finished:context

- (void) animationStopped: (NSString *) animationID finished: (NSNumber *) finished context: (void *) context
{
	// Clear animation flag.
	_animationRefCount -= 1;
	
	// Call handle animation again.
	[self handleAnimation: (NSMutableDictionary *) context];
}

#pragma mark ------ notifications
// --------------------------------------------------------------------------------------------------- stackChangedCount

- (void) stackChangedCount: (NSNotification *) notification
{
	// Cards need re-laying out.
	[self layoutCards];
	
	// The stack shadow has to be reckoned with.
	if (_layout == kCEStackViewLayoutStacked)
		[self setNeedsDisplay];
}

// --------------------------------------------------------------------------------------------- stackChangedCardFlipped

- (void) stackChangedCardFlipped: (NSNotification *) notification
{
	CECard	*card;
	
	// Get card that needs to be redrawn - no card specified then redraw all.
	card = [[notification userInfo] objectForKey: @"card"];
	if (card == nil)
		[self setNeedsDisplay];
	else
		[[self cardViewForCard: card] setNeedsDisplay];
}

// --------------------------------------------------------------------------------------------------- stackChangedOrder

- (void) stackChangedOrder: (NSNotification *) notification
{
	// WE CAN OPTIMIZE HERE IN THE FUTURE FOR SPREAD CARDS TO SIMPLY REASSIGN THE EXISTING VIEWS
	// FOR A STACK THAT ARE NOT SPREAD WHERE THE TOPCARD IS FACE DOWN WE NEED DO NOTHING
	// FOR THAT MATTER FOR ANY LAYOUT WHERE ALL VISIBLE CARDS ARE FACE DOWN WE CAN DO NOTHING
	
	// Cards need re-laying out.
	[self layoutCards];
}

@end

