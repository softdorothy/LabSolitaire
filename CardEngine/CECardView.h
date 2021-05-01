// =====================================================================================================================
//  CECardView.h
// =====================================================================================================================


#import <UIKit/UIKit.h>


@class CECard;


typedef int CECardSize;
enum
{
	kCardSizeMini = 1,								// (46.0, x 64.0)
	kCardSizeSmall = 2,								// (56.0, x 78.0)
	kCardSizeMedium = 3,							// (64.0, x 90.0)
	kCardSizeLarge = 4,								// (80.0, x 112.0)
	kCardSizeExtraLarge = 5							// (92.0, x 128.0)
};


@interface CECardView : UIView
{
	CECard			*_card;
	CECardSize		_cardSize;
	UIColor			*_highlightColor;				// Fill color when view is highlighted.
	NSString		*_label;						// Optional label to display (usually card count).
	BOOL			_highlight;						// Highlight state.
	BOOL			_hasShadow;						// Shadow state.
}

@property(nonatomic,retain)	CECard		*card;				// The card object backing the view. This is the card displayed.
@property(nonatomic,retain)	UIColor		*highlightColor;	// Fill color when view is highlighted. Can be set to nil.
@property(nonatomic,retain)	NSString	*label;				// Fill color when view is highlighted. Can be set to nil.
@property(nonatomic)		BOOL		highlight;			// During live drag, view may highlight when stack dragged into.
@property(nonatomic)		BOOL		hasShadow;			// Whether to draw a shadow beneath card. Default is NO.

// Returns the default playing card view size for the specified size constant.
+ (CGSize) cardSize: (CECardSize) size;

// Returns the corner radius for the specified playing card size.
+ (CGFloat) playingCardCornerRadius: (CECardSize) size;

// How much to slide a card vertically (up) to reveal its rank and suit.
+ (CGFloat) playingCardVerticalReveal: (CECardSize) size;

// The below methods are not to be called directly but rather are provided for subclassers in order to customize the 
// drawing of playing cards.
- (void) drawShadow;
- (void) drawCardFace;
- (void) drawCardBack;

@end
