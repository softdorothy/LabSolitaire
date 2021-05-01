// =====================================================================================================================
//  LabSolitaireAppDelegate.m
// =====================================================================================================================


#import "LabSolitaireAppDelegate.h"
#import "LabSolitaireViewController.h"


@implementation LabSolitaireAppDelegate
// ============================================================================================= LabSolitaireAppDelegate
// ---------------------------------------------------------------------------------------------------------- synthesize

@synthesize _window;
@synthesize _viewController;

// --------------------------------------------------------------------------- application:didFinishLaunchingWithOptions

- (BOOL) application: (UIApplication *) application didFinishLaunchingWithOptions: (NSDictionary *) launchOptions
{        
	// Override point for customization after app launch. 
	[_window setRootViewController: _viewController];
	[_window addSubview: _viewController.view];
	[_window makeKeyAndVisible];
	
	// Create stacks.
	[_viewController createCardTableLayout];
	
	// Restore card layout.
	[_viewController restoreState];
	
	// Display splash (info) view.
	[_viewController openSplashAfterDelay];
	
	return YES;
}

// --------------------------------------------------------------------------------------- applicationDidEnterBackground

- (void) applicationDidEnterBackground: (UIApplication *) application
{
	// Store away game state.
	[_viewController saveState];
}

// -------------------------------------------------------------------------------------------- applicationWillTerminate

- (void) applicationWillTerminate: (UIApplication *) application
{
	// Store away game state.
	[_viewController saveState];
}

// ---------------------------------------------------------------------------------- applicationDidReceiveMemoryWarning

- (void) applicationDidReceiveMemoryWarning: (UIApplication *) application
{
	printf ("applicationDidReceiveMemoryWarning\n");
}

// ------------------------------------------------------------------------------------------------------------- dealloc

- (void) dealloc
{
	[_viewController release];
	[_window release];
	[super dealloc];
}

@end
