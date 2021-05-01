// =====================================================================================================================
//  main.m
// =====================================================================================================================


#import <UIKit/UIKit.h>


int main (int argc, char *argv[])
{    
	NSAutoreleasePool	*pool;
	
	pool = [[NSAutoreleasePool alloc] init];
	int retVal = UIApplicationMain (argc, argv, nil, @"LabSolitaireAppDelegate");
	[pool release];
	
	return retVal;
}
