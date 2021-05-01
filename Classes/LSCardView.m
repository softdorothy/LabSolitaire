// =====================================================================================================================
//  LSCardView.h
// =====================================================================================================================


#import "LSCardView.h"


#define DRAW_CARD_TINT		1


@implementation LSCardView
// ========================================================================================================== LSCardView
// ------------------------------------------------------------------------------------------------------------ cardSize

+ (CGSize) cardSize: (CECardSize) size
{
	return CGSizeMake (82, 114);
}

// --------------------------------------------------------------------------------------------- playingCardCornerRadius

+ (CGFloat) playingCardCornerRadius: (CECardSize) size
{
	return 4;
}

// ---------------------------------------------------------------------------------------------------------- drawShadow

- (void) drawShadow
{
	UIImage		*shadowImage;
	
	// Fetch the card shadow image.
	shadowImage = [UIImage imageNamed: @"CardShadow"];
	
	// Draw.
	[shadowImage drawAtPoint: CGPointMake (6.0, 6.0) blendMode: kCGBlendModeNormal alpha: 0.25];
}

// -------------------------------------------------------------------------------------------------------- drawCardFace

- (void) drawCardFace
{
	UIImage		*cardImage = nil;
	
	// Fetch the card image.
	if (self.card.suit == kCESuitSpades)
		cardImage = [UIImage imageNamed: [NSString stringWithFormat: @"%dS", self.card.rank]];
	if (self.card.suit == kCESuitHearts)
		cardImage = [UIImage imageNamed: [NSString stringWithFormat: @"%dH", self.card.rank]];
	if (self.card.suit == kCESuitClubs)
		cardImage = [UIImage imageNamed: [NSString stringWithFormat: @"%dC", self.card.rank]];
	if (self.card.suit == kCESuitDiamonds)
		cardImage = [UIImage imageNamed: [NSString stringWithFormat: @"%dD", self.card.rank]];
	
	// Draw.
//	[cardImage drawAtPoint: CGPointZero];
	[cardImage drawAtPoint: CGPointZero blendMode: kCGBlendModeNormal alpha: self.card.alpha];
	
#if DRAW_CARD_TINT
	CGRect	bounds = [self bounds];
	bounds.origin.x += 1.0;
	bounds.origin.y += 1.0;
	bounds.size.width -= 1.0;
	bounds.size.height -= 1.0;
	[[UIColor colorWithRed: 0.90 green: 0.75 blue: 0.0 alpha: 0.08 * self.card.alpha] set];
	CEFillRoundedRect (UIGraphicsGetCurrentContext (), bounds, [LSCardView playingCardCornerRadius: _cardSize]);
#endif	// DRAW_CARD_TINT
	
	// Highlight.
	if ((self.highlight) && (self.highlightColor))
	{
		[self.highlightColor set];
		CEFillRoundedRect (UIGraphicsGetCurrentContext (), [self bounds], [LSCardView playingCardCornerRadius: _cardSize]);
	}
}

@end
