// =====================================================================================================================
//  CETableView.h
// =====================================================================================================================


#import <UIKit/UIKit.h>


@class CEStackView;


@interface CETableView : UIView
{
	NSString	*_portraitImagePath;
	NSString	*_landscapeImagePath;
	NSInteger	_animatingCount;
}

@property(nonatomic,retain)	NSString		*portraitImagePath;		// If nil no image is drawn.
@property(nonatomic,retain)	NSString		*landscapeImagePath;	// If nil no image is drawn.
@property(nonatomic,readonly)	BOOL		animationInProgress;	// Returns YES if there is an animation in progress.

// Returns a singleton NSUndoManager. All card drags register with this undo manager.
+ (NSUndoManager *) sharedCardUndoManager;

// Preferred initializer. This creates a card table view full screen (does not hide the status bar) with the proper 
// transform such that subviews will be rotated correctly for the specified orientation. Note: does not change the 
// status bar orientation, you should have called [UIApplication setStatusBarOrientation:] already.
- (id) initForOrientation: (UIInterfaceOrientation) orientation;

// Searches its subviews for a StackView with specified identifier.  Returns nil if none found.
- (CEStackView *) stackViewWithIdentifier: (NSString *) identifier;

// These routines save and restore the state of the Stacks that are subviews of CardTableView. It walks subviews 
// looking for StackViews.  It flattens the card data as an array and stores it in NSUserDefaults using the origin 
// of the StackView as the key.  So long as you perform the restore after setting up the StackViews and so long 
// as the origins are consistant, the cards will be properly restored.

// Returns YES if synchronize returns YES. Passing identifier allows multiple game states to be saved.
- (BOOL) archiveStackStateWithIdentifier: (NSString *) identifier;

// Returns YES if archived card data was found for all StackView subviews.
- (BOOL) restoreStackStateWithIdentifier: (NSString *) identifier;

@end
