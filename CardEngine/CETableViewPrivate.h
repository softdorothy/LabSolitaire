// =====================================================================================================================
//  CETableViewPrivate.h
// =====================================================================================================================


#import <UIKit/UIKit.h>
#import "CETableView.h"


@class CECard, CEStackView;


@interface CETableView (CETableViewPriv)

- (void) stackView: (CEStackView *) view beginAnimatingCardMove: (CECard *) card;
- (void) stackView: (CEStackView *) view beginAnimatingCardFlip: (CECard *)card;
- (void) stackView: (CEStackView *) view finishedAnimatingCardMove: (CECard *) card;
- (void) stackView: (CEStackView *) view finishedAnimatingCardFlip: (CECard *) card;

@end
