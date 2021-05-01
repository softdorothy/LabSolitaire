// =====================================================================================================================
//  CECardDealer.m
// =====================================================================================================================


#import <AssertMacros.h>
#import "CECardDealer.h"
#import "CEStack.h"
#import "CEStackViewPrivate.h"
#import "CETableView.h"


#define kDefaultDealAnimationDuration		0.25
#define kDefaultDealAnimationDelay			0.20


@implementation CECardDealer
// ======================================================================================================== CECardDealer
// ---------------------------------------------------------------------------------------------------------- synthesize

@synthesize sourceStack = _sourceStack;
@synthesize destStack = _destStack;
@synthesize dealDuration = _duration;
@synthesize dealDelay = _delay;
@synthesize enableUndoGrouping = _enableUndoGrouping;
@synthesize dealing = _dealing;
@synthesize delegate = _delegate;

// ---------------------------------------------------------------------------------------------------------------- init

- (id) init
{
	id		myself;
	
	// Super.
	myself = [super init];
	require (myself, bail);
	
	// Initialize instance variables.
	_duration = kDefaultDealAnimationDuration;
	_delay = kDefaultDealAnimationDelay;
	_enableUndoGrouping = NO;
	_dealing = NO;
	
bail:
	
	return self;
}

// ------------------------------------------------------------------------------------------------------------- dealloc

- (void) dealloc
{
	// Finish any deal in progress.
	if (_dealing)
		[self quickComplete];
	
	// Release instance var.
	[_sourceStack release];
	[_destStack release];
	
	// Clean up timer.
	if (_dealTimer)
		[_dealTimer invalidate];
	
	// Super.
	[super dealloc];
}

// --------------------------------------------------------------------------------------------------------- dealOneCard

- (void) dealOneCard
{
	// Deal n'th card.
	[_sourceStack dealTopCardToStackView: _destStack faceUp: YES duration: _duration];
	_count = _count - 1;
	
	if (([_sourceStack.stack topCard] == nil) || (_count == 0))
	{
		if (_enableUndoGrouping)
			[[CETableView sharedCardUndoManager] endUndoGrouping];
		_count = 0;
		[_sourceStack release];
		[_destStack release];
		_dealing = NO;
	}
	else
	{
		_dealTimer = [NSTimer scheduledTimerWithTimeInterval: _delay target: self 
				selector: @selector (dealTimerOperation:) userInfo: nil repeats: NO];
	}
	
	if ((_dealing == NO) && (_delegate) && ([_delegate respondsToSelector: @selector (cardDealerCompletedDeal:)]))
		[_sourceStack setPrivateDelegate: self];
}

// -------------------------------------------------------------------------------------------------- dealTimerOperation

- (void) dealTimerOperation: (NSTimer *) timer
{
	// Clean up timer.
	[timer invalidate];
	_dealTimer = nil;
	
	// Deal n'th card.
	[self dealOneCard];
}

// ---------------------------------------------------------------------------- dealCardsFromStackView:toStackView:count

- (void) dealCardsFromStackView: (CEStackView *) source toStackView: (CEStackView *) dest count: (NSUInteger) count
{
	// NOP.
	if (count == 0)
		return;
	
	// NOP. No top card to deal.
	if ([source.stack topCard] == nil)
		return;
	
	// Retain stacks.
	_sourceStack = [source retain];
	_destStack = [dest retain];
	_count = count;
	_dealing = YES;
	
	// Bracket a deal within an Undo group.
	if (_enableUndoGrouping)
		[[CETableView sharedCardUndoManager] beginUndoGrouping];
	
	// Deal the first card.
	[self dealOneCard];
}

// ------------------------------------------------------------------------------------------------------- quickComplete

- (void) quickComplete
{
	// Nix timer.
	if (_dealTimer)
		[_dealTimer invalidate];
	_dealTimer = nil;
	
	// Wrap up the deal (will not call delegate).
	if (_dealing)
	{
		if (_count > 0)
		{
			do
			{
				if ([_sourceStack.stack topCard] == nil)
				{
					[_sourceStack dealTopCardToStackView: _destStack faceUp: YES duration: 0];
					_count = _count - 1;
				}
				else
				{
					_count = 0;
				}
			}
			while (_count > 0);
		}
		else
		{
			printf ("ERROR: [CECardDealer quickComplete]; count == 0 but _dealing == YES.");
		}
		
		// Wrap up.
		if (_enableUndoGrouping)
			[[CETableView sharedCardUndoManager] endUndoGrouping];
		_count = 0;
		[_sourceStack release];
		[_destStack release];
		_dealing = NO;
	}
}

// --------------------------------------------------------------------------------- stackView:finishedAnimatingCardMove

- (void) stackView: (CEStackView *) view finishedAnimatingCardMove: (CECard *) card
{
	[_sourceStack setPrivateDelegate: nil];
	if ((_delegate) && ([_delegate respondsToSelector: @selector (cardDealerCompletedDeal:)]))
		[_delegate cardDealerCompletedDeal: self];
}

@end
