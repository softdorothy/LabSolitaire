// =====================================================================================================================
//  CECardDealer.h
// =====================================================================================================================


#import <UIKit/UIKit.h>


@protocol CECardDealerDelegate;


@class CEStackView;


@interface CECardDealer : NSObject
{
	CEStackView					*_sourceStack;
	CEStackView					*_destStack;
	NSUInteger					_count;
	NSTimeInterval				_delay;
	NSTimeInterval				_duration;
	BOOL						_dealing;
	BOOL						_enableUndoGrouping;
	NSTimer						*_dealTimer;
	id <CECardDealerDelegate>	_delegate;
}

@property(nonatomic,retain,readonly)	CEStackView					*sourceStack;
@property(nonatomic,retain,readonly)	CEStackView					*destStack;
@property(nonatomic)					NSTimeInterval				dealDuration;	// Default: 0.25 seconds.
@property(nonatomic)					NSTimeInterval				dealDelay;		// Default: 0.20 seconds.
@property(nonatomic)					BOOL						enableUndoGrouping;
@property(nonatomic,assign)				id <CECardDealerDelegate>	delegate;		// Optional delegate.
@property(nonatomic,readonly)			BOOL						dealing;

- (void) dealCardsFromStackView: (CEStackView *) source toStackView: (CEStackView *) dest count: (NSUInteger) count;
- (void) quickComplete;

@end

@protocol CECardDealerDelegate<NSObject>

@optional

// Called when the last card has been dealt.
- (void) cardDealerCompletedDeal: (CECardDealer *) dealer;

@end
