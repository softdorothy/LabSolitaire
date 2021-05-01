// =====================================================================================================================
//  LocalPlayer_priv.h
// =====================================================================================================================


#import "LocalPlayer.h"


@interface LocalPlayer (LocalPlayer_priv)

- (BOOL) gameCenterAPIAvailable;
- (void) authenticateLocalPlayer;

@end
