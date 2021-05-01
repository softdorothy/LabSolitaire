// =====================================================================================================================
//  LabSolitaireAppDelegate.h
// =====================================================================================================================


#import <UIKit/UIKit.h>


@class LabSolitaireViewController;


@interface LabSolitaireAppDelegate : NSObject <UIApplicationDelegate>
{
	UIWindow				*_window;
	LabSolitaireViewController	*_viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow					*_window;
@property (nonatomic, retain) IBOutlet LabSolitaireViewController	*_viewController;

@end

