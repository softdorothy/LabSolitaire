// =====================================================================================================================
//  CETableView.m
// =====================================================================================================================


#import <AssertMacros.h>
#import "CEStack.h"
#import "CEStackView.h"
#import "CETableViewPrivate.h"


static NSUndoManager	*_gSharedUndoManager = nil;


@implementation CETableView
// ========================================================================================================= CETableView
// ---------------------------------------------------------------------------------------------------------- synthesize

@synthesize portraitImagePath = _portraitImagePath;
@synthesize landscapeImagePath = _landscapeImagePath;

// ----------------------------------------------------------------------------------------------- sharedCardUndoManager

+ (NSUndoManager *) sharedCardUndoManager
{
	if (_gSharedUndoManager == nil)
	{
		_gSharedUndoManager = [[NSUndoManager alloc] init];
	}
	
	return _gSharedUndoManager;
}

// -------------------------------------------------------------------------------------------------- initForOrientation

- (id) initForOrientation: (UIInterfaceOrientation) orientation
{
	id		myself = nil;
	CGRect	frame;
	
	// Get application frame.
	frame = [[UIScreen mainScreen] applicationFrame];
	
	if (orientation == UIInterfaceOrientationPortrait)
	{
		// Simple, create view the size of application frame.
		myself = [self initWithFrame: frame];
	}
	else if (orientation == UIInterfaceOrientationLandscapeRight)
	{
		CGFloat				edge;
		CGFloat				offset;
		CGAffineTransform	transform;
		
		// Swap width and height.
		edge = frame.size.width;
		frame.size.width = frame.size.height;
		frame.size.height = edge;
		
		// Create view for swapped width-height application frame.
		myself = [self initWithFrame: frame];
		
		// Detemine the translational offset after rotating about center.
		offset = (frame.size.width - frame.size.height) / 2.;
		
		// Create and set transform to achieve proper orientation for subviews.
		transform = CGAffineTransformRotate (CGAffineTransformIdentity, 1.570796);
		transform = CGAffineTransformTranslate (transform, offset, offset);
		[self setTransform: transform];
	}
	else if (orientation == UIInterfaceOrientationPortraitUpsideDown)
	{
		CGAffineTransform	transform;
		
		// Use application frame to create the view.
		myself = [self initWithFrame: frame];
		
		// Rotate transform 180 degrees.
		transform = CGAffineTransformRotate (CGAffineTransformIdentity, 3.141592);
		[self setTransform: transform];
	}
	else if (orientation == UIInterfaceOrientationLandscapeLeft)
	{
		CGFloat				edge;
		CGFloat				offset;
		CGAffineTransform	transform;
		
		// Swap width and height.
		edge = frame.size.width;
		frame.size.width = frame.size.height;
		frame.size.height = edge;
		
		// Create view for swapped width-height application frame.
		myself = [self initWithFrame: frame];
		
		// Detemine the translational offset after rotating about center.
		offset = (frame.size.width - frame.size.height) / 2.;
		
		// Create and set transform to achieve proper orientation for subviews.
		transform = CGAffineTransformRotate (CGAffineTransformIdentity, -1.570796);
		transform = CGAffineTransformTranslate (transform, -offset, -offset);
		[self setTransform: transform];
	}
	
	// Set resize flags.
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	// Initialize instance variable.
	self.backgroundColor = [UIColor colorWithRed: 20.0 / 255.0 green: 92.0 / 255.0 blue: 28.0 / 255.0 alpha: 1.0];
	
	return myself;
}

// ------------------------------------------------------------------------------------------------------- initWithFrame

- (id) initWithFrame: (CGRect) frame
{
	id		myself = nil;
	
	// Super.
	myself = [super initWithFrame: frame];
	require (myself, bail);
	
bail:
	
	return myself;
}

// ------------------------------------------------------------------------------------------------------------- dealloc

- (void) dealloc
{
	// Release instance variables.
	[_portraitImagePath release];
	[_landscapeImagePath release];
	
	// Super.
	[super dealloc];
}

// -------------------------------------------------------------------------------------------------------- drawGradient

- (void) drawGradient
{
	CGContextRef	context;
	CGRect			bounds;
	CGColorSpaceRef	colorspace = nil;
	CGFloat			components[8] = {0.35, 0.73, 0.28, 1.0, 0.12, 0.52, 0.25, 1.0};
	CGGradientRef	gradient = nil;
	
	context = UIGraphicsGetCurrentContext ();
	bounds = self.bounds;
	colorspace = CGColorSpaceCreateDeviceRGB ();
	gradient = CGGradientCreateWithColorComponents (colorspace, components, nil, 2);
	CGContextDrawLinearGradient (context, gradient, 
			CGPointMake (CGRectGetMidX (bounds), CGRectGetMinY (bounds)), 
			CGPointMake (CGRectGetMidX (bounds), CGRectGetMaxY (bounds)), 
			0);
	
	// Clean up.
	if (colorspace)
		CGColorSpaceRelease (colorspace);
	if (gradient)
		CGGradientRelease (gradient);
}

// ------------------------------------------------------------------------------------------------------------ drawRect

- (void) drawRect: (CGRect) rect
{
	UIInterfaceOrientation	orientation;
	
	orientation = [[UIApplication sharedApplication] statusBarOrientation];
	if (UIInterfaceOrientationIsPortrait (orientation))
	{
		if (_portraitImagePath)
			[[UIImage imageNamed: _portraitImagePath] drawAtPoint: CGPointMake (0.0, 0.0)];
		else
			[self drawGradient];
	}
	else
	{
		if (_landscapeImagePath)
			[[UIImage imageNamed: _landscapeImagePath] drawAtPoint: CGPointMake (0.0, 0.0)];
		else
			[self drawGradient];
	}
}

// --------------------------------------------------------------------------------------------- stackViewWithIdentifier

- (CEStackView *) stackViewWithIdentifier: (NSString *) identifier
{
	NSArray		*subviews;
	NSUInteger	count, i;
	CEStackView	*stack = nil;
	
	// Walk subviews.
	subviews = [self subviews];
	count = [subviews count];
	for (i = 0; i < count; i++)
	{
		UIView		*view;
		
		// Is this subview a StackView?
		view = [subviews objectAtIndex: i];
		if ([view isKindOfClass: [CEStackView class]])
		{
			if ([identifier isEqualToString: [(CEStackView *)view identifier]])
			{
				stack = (CEStackView *)view;
				break;
			}
		}
	}
	
	return stack;
}

// ------------------------------------------------------------------------------------- archiveStackStateWithIdentifier

- (BOOL) archiveStackStateWithIdentifier: (NSString *) identifier
{
	NSUserDefaults		*defaults;
	NSMutableDictionary	*dictionary = nil;
	NSArray				*subviews;
	NSUInteger			count, i;
	
	// Get standard defaults.
	defaults = [NSUserDefaults standardUserDefaults];
	
	// If an identifier was passed in, store settings in sub-dictionary within user defaults.
	if (identifier)
		dictionary = [[NSMutableDictionary alloc] initWithCapacity: 3];
	
	// Walk subviews.
	subviews = [self subviews];
	count = [subviews count];
	for (i = 0; i < count; i++)
	{
		UIView		*view;
		
		// Is this subview a StackView?
		view = [subviews objectAtIndex: i];
		if ([view isKindOfClass: [CEStackView class]])
		{
			NSString	*key;
			NSArray		*array;
			
			// See first if the stack presents an identifer.
			key = [(CEStackView *) view archiveIdentifier];
			
			// Create 'key' from origin of StackView. 
			// The assumption is this will be unique (unless multiple oreintations supported - whoops).
			if (key == nil)
				key = NSStringFromCGPoint ([view frame].origin);
			
			// Get flattened card state (as array).
			array = [[(CEStackView *) view stack] cardArrayRepresentation];
			
			// Store state of cards for the key.  We can restore from this.
			// Store in sub-dictionary if identifier passed in.
			if (dictionary)
				[dictionary setObject: array forKey: key];
			else
				[defaults setObject: array forKey: key];
		}
	}
	
	// If we are storing as a sub-dictionary, add that to user-defaults.
	if (dictionary)
	{
		[defaults setObject: dictionary forKey: identifier];
		[dictionary release];
	}
	
	return [defaults synchronize];
}

// ------------------------------------------------------------------------------------- restoreStackStateWithIdentifier

- (BOOL) restoreStackStateWithIdentifier: (NSString *) identifier
{
	NSUserDefaults	*defaults;
	NSDictionary	*dictionary = nil;
	NSUInteger		count, i;
	NSArray			*subviews;
	BOOL			foundAllData = YES;
	
	// Get standard defaults.
	defaults = [NSUserDefaults standardUserDefaults];
	[defaults synchronize];
	
	// If an identifier was passed in, restore settings from sub-dictionary within user-defaults.
	if (identifier)
		dictionary = [defaults dictionaryForKey: identifier];
	
	// Walk subviews.
	subviews = [self subviews];
	count = [subviews count];
	for (i = 0; i < count; i++)
	{
		CEStackView		*view;
		
		// Is this subview a StackView?
		view = (CEStackView *) [subviews objectAtIndex: i];
		if ([view isKindOfClass: [CEStackView class]])
		{
			NSString	*key;
			NSArray		*array;
			
			// See first if the stack presents an identifer.
			key = view.archiveIdentifier;
			
			// Create 'key' from origin of StackView. 
			// The assumption is this will be unique (unless multiple oreintations supported - whoops).
			if (key == nil)
				key = NSStringFromCGPoint ([view frame].origin);
			
			// See if there is an entry in the user defaults for this stack view.
			if (dictionary)
				array = [dictionary objectForKey: key];
			else
				array = [defaults arrayForKey: key];
			
			// Did we find the key?
			if (array)
			{
				// Restore state of cards.
				[view.stack addCardsFromCardArrayRepresentation: array randomize: (view.orderly == NO)];
			}
			else
			{
				// Indicate we did not find all the data.
				foundAllData = NO;
			}
		}
	}
	
	return foundAllData;
}

// ------------------------------------------------------------------------------------------------- animationInProgress

- (BOOL) animationInProgress
{
	return (_animatingCount != 0);
}

@end


@implementation CETableView (CETableViewPriv)
// ======================================================================================= CETableView (CETableViewPriv)
// ------------------------------------------------------------------------------------ stackView:beginAnimatingCardMove

- (void) stackView: (CEStackView *) view beginAnimatingCardMove: (CECard *) card
{
	_animatingCount = _animatingCount + 1;
}

// ------------------------------------------------------------------------------------ stackView:beginAnimatingCardFlip

- (void) stackView: (CEStackView *) view beginAnimatingCardFlip: (CECard *) card
{
	_animatingCount = _animatingCount + 1;
}

// --------------------------------------------------------------------------------- stackView:finishedAnimatingCardMove

- (void) stackView: (CEStackView *) view finishedAnimatingCardMove: (CECard *) card
{
	_animatingCount = _animatingCount - 1;
}

// --------------------------------------------------------------------------------- stackView:finishedAnimatingCardFlip

- (void) stackView: (CEStackView *) view finishedAnimatingCardFlip: (CECard *) card
{
	_animatingCount = _animatingCount - 1;
}

@end
