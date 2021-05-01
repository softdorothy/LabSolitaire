// =====================================================================================================================
//  LocalPlayer.h
// =====================================================================================================================


#import <Foundation/Foundation.h>


@protocol LocalPlayerDelegate;


@interface LocalPlayer : NSObject
{
	NSString			*_playerID;
	NSString			*_alias;
	BOOL				_authenticated;
	BOOL				_usingGameCenter;
	id					_delegate;
}

@property(nonatomic,readonly)	NSString	*playerID;			// Only valid if using Game Center. Must be authenticated.
@property(nonatomic,readonly)	NSString	*alias;				// Only valid if using Game Center. Must be authenticated.
@property(nonatomic,readonly)	BOOL		authenticated;		// Returns YES if authenticated (always YES if local).
@property(nonatomic,readonly)	BOOL		usingGameCenter;	// Returns YES if LocalPlayer is from Game Center.
@property(nonatomic,assign)		id <LocalPlayerDelegate>	delegate;	// Delegate called for asynchronous completions.

// Creates a LocalPlayer object. If Game Center is available, LocalPlayer initialized with the local player. Otherwise 
// NSUserDefaults will be used to post and retrieve scores.
- (id) init;

// If GameCenter was available, calls into Game Center to post a score for the local player. Otherwise, stores value 
// in NSUserDefaults (category becomes the key). Returns NO if player not yet authenticated or if failure.
- (BOOL) postLeaderboardScore: (NSInteger) score forCategory: (NSString *) category;

- (void) postLocalScore: (NSInteger) score forCategory: (NSString *) category;

// Retrieves score from local NSUserDefaults. Uses playerID (for Game Center) or "Local" for key. Returns YES if score
// for category was found in NSUserDefaults.
- (BOOL) retrieveLocalScore: (NSInteger *) score forCategory: (NSString *) category;

// Returns NO if no authenticated local player or no Game Center support. Retrieves leaderboard scores for category 
// from Game Center. This is an asynchronous operation and as such, results are passed to delegate (see below).
// A category is required, count must be 75 or less.
- (BOOL) retrieveLeaderboardScores: (NSUInteger) count forCategory: (NSString *) category friendsOnly: (BOOL) friends;

// Returns NO if no authenticated local player or no Game Center support. Retrieves leaderboard scores for category 
// from Game Center. This is an asynchronous operation and as such, results are passed to delegate (see below).
- (BOOL) retrieveLeaderboardScoresForPlayerIDs: (NSArray *) playerIDs forCategory: (NSString *) category;

// Like -[retrieveLeaderboardScoresForPlayerIDs:forCategory] above but will report leaderboard scores for category 
// for the array of playerID's passed in.
- (BOOL) retrieveAliasesForPlayerIDs: (NSArray *) playerIDs;

// Returns NO if no authenticated local player or no Game Center support. Retrieves leaderboard scores for category 
// from Game Center for th elocal player. This is an asynchronous operation and as such, results are passed to delegate (see below).
- (BOOL) retrieveLeaderboardScoreForLocalPlayerForCategory: (NSString *) category;

@end


@protocol LocalPlayerDelegate<NSObject>

@optional

// Called when the LocalPlayer has been authenticated. The player may not stay authenticated during the life-cycle of 
// the game however. See -[localPlayer:failedAuthenticationWithError] below.
- (void) localPlayerAuthenticated: (LocalPlayer *) player;

// Called either due to an actual error or if the player does not connect to their Game Center account.
// This can be called at any point within the app lifecycle since the game might switch into the background and the 
// player log out of Game Center.
- (void) localPlayer: (LocalPlayer *) player failedAuthenticationWithError: (NSError *) error;

// Called when the global leaderboard scores have been retrieved.
- (void) localPlayer: (LocalPlayer *) player retrievedLeaderboardScores: (NSArray *) scores 
		playerIDs: (NSArray *) players forCategory: (NSString *) category;

// Called when the playerID aliases have been retrieved.
- (void) localPlayer: (LocalPlayer *) player retrievedAliasesForPlayerIDs: (NSArray *) aliases;

// Called when the global leaderboard score for the local player has been retrieved.
- (void) localPlayer: (LocalPlayer *) player retrievedLeaderboardScoreForLocalPlayer: (int64_t) score forCategory: (NSString *) category;

// Optional methods called during error conditions.
- (void) localPlayer: (LocalPlayer *) player failedRetrieveScoreForCategory: (NSString *) category error: (NSError *) error;
- (void) localPlayer: (LocalPlayer *) player failedPostScoreForCategory: (NSString *) category error: (NSError *) error;
- (void) localPlayer: (LocalPlayer *) player failedRetrieveAliasesForPlayerIDs: (NSError *) error;

@end
