// =====================================================================================================================
//  LocalPlayer.m
// =====================================================================================================================


#import <AssertMacros.h>
#import <GameKit/GameKit.h>
#import "LocalPlayer_priv.h"


@implementation LocalPlayer
// ========================================================================================================= LocalPlayer
// --------------------------------------------------------------------------------------------------------- @synthesize

@synthesize playerID = _playerID;
@synthesize alias = _alias;
@synthesize authenticated = _authenticated;
@synthesize usingGameCenter = _usingGameCenter;
@synthesize delegate = _delegate;

// ---------------------------------------------------------------------------------------------------------------- init

- (id) init
{
	id		myself = nil;
	
	if ((self = [super init]))
	{
		// Create instance variables.
		_playerID = nil;
		_alias = nil;
		_authenticated = NO;
		_usingGameCenter = NO;
		_delegate = nil;
		
		// Try to authenticate local player with Game Center (if avail).
		[self authenticateLocalPlayer];
		
		// Success.
		myself = self;
	}
	
	return myself;
}

// ------------------------------------------------------------------------------------------------------------- dealloc

- (void) dealloc
{
	// Release instance vars.
	[_playerID release];
	[_alias release];
	
	// Super.
	[super dealloc];
}

// ------------------------------------------------------------------------------------------ postLocalScore:forCategory

- (void) postLocalScore: (NSInteger) score forCategory: (NSString *) category
{
	NSUserDefaults		*defaults;
	NSDictionary		*storedDictionary;
	NSMutableDictionary	*scoreDictionary;
	
	// Get standard defaults.
	defaults = [NSUserDefaults standardUserDefaults];
	
	// Fetch the player's local score dictionary (if there is one yet).
	if (_playerID)
		storedDictionary = [defaults dictionaryForKey: _playerID];
	else
		storedDictionary = [defaults dictionaryForKey: @"Local"];
	
	// Create a mutable dictionary from stored dictionary (or a new one if required).
	if (storedDictionary)
		scoreDictionary = [NSMutableDictionary dictionaryWithDictionary: storedDictionary];
	else
		scoreDictionary = [NSMutableDictionary dictionaryWithCapacity: 1];
	
	// Store score with category as key.
	[scoreDictionary setObject: [NSNumber numberWithInteger: score] forKey: category];
	
	// Save.
	if (_playerID)
		[defaults setObject: scoreDictionary forKey: _playerID];
	else
		[defaults setObject: scoreDictionary forKey: @"Local"];
	[defaults synchronize];
	
bail:
	
	return;
}

// ------------------------------------------------------------------------------------ postLeaderboardScore:forCategory

- (BOOL) postLeaderboardScore: (NSInteger) score forCategory: (NSString *) category
{
	BOOL		success = NO;
	
	// We have to have been authenticated already.
	if (_authenticated == NO)
		goto bail;
	
	if (_usingGameCenter)
	{
		NSUserDefaults		*defaults;
		NSDictionary		*storedDictionary;
		NSMutableDictionary	*scoreDictionary;
		GKScore				*scoreReporter;
		
		// Get standard defaults.
		defaults = [NSUserDefaults standardUserDefaults];
		
		// Fetch the player's local score dictionary (if there is one yet).
		storedDictionary = [defaults dictionaryForKey: _playerID];
		
		// Store the score using category as the key.
		if (storedDictionary)
			scoreDictionary = [NSMutableDictionary dictionaryWithDictionary: storedDictionary];
		else
			scoreDictionary = [NSMutableDictionary dictionaryWithCapacity: 1];
		[scoreDictionary setObject: [NSNumber numberWithInteger: score] forKey: category];
		
		// Save with playerID as key.
		[defaults setObject: scoreDictionary forKey: _playerID];
		success = [defaults synchronize];
		
		// Create object to report score. Assign points.
		scoreReporter = [[[GKScore alloc] initWithLeaderboardIdentifier: category] autorelease];
		scoreReporter.value = score;
		
		// Report score.
//		[scoreReporter reportScoreWithCompletionHandler: ^(NSError *error)
		[GKScore reportScores: [NSArray arrayWithObject: scoreReporter] withCompletionHandler: ^(NSError *error)
		{
			if (error != nil)
			{
				if ([_delegate respondsToSelector: @selector (localPlayer:failedPostScoreForCategory:error:)])
					[_delegate localPlayer: self failedPostScoreForCategory: category error: error];
			}
		}];
	}
	else
	{
		NSUserDefaults	*defaults;
		
		// Get standard defaults.
		defaults = [NSUserDefaults standardUserDefaults];
		
		// Store the score using category as the key.
		[defaults setObject: [NSNumber numberWithInteger: score] forKey: category];
		success = [defaults synchronize];
	}
	
bail:
	
	return success;
}

// -------------------------------------------------------------------------------------- retrieveLocalScore:forCategory

- (BOOL) retrieveLocalScore: (NSInteger *) score forCategory: (NSString *) category
{
	NSUserDefaults	*defaults;
	NSDictionary	*scoreDictionary;
	BOOL			retrieved = NO;
	
	// Initialize to zero.
	if (score)
		*score = 0;
	
	// Param check.
	require (category, bail);
	
	// Get standard user defaults; look for player ID (or 'local') sub-dictionary.
	defaults = [NSUserDefaults standardUserDefaults];
	if (_playerID)
		scoreDictionary = [defaults dictionaryForKey: _playerID];
	else
		scoreDictionary = [defaults dictionaryForKey: @"Local"];
	
	// See if we have a local copy of the score stored here. Return that quickly.
	if (scoreDictionary)
	{
		NSNumber	*scoreNumber;
		
		scoreNumber = [scoreDictionary objectForKey: category];
		if (scoreNumber)
		{
			// Pass back.
			if (score)
				*score = [scoreNumber integerValue];
			retrieved = YES;
		}
	}
	
bail:
	
	return retrieved;
}

// ------------------------------------------------------------------- retrieveLeaderboardScores:forCategory:friendsOnly

- (BOOL) retrieveLeaderboardScores: (NSUInteger) count forCategory: (NSString *) category friendsOnly: (BOOL) friends
{
	GKLeaderboard	*leaderboardRequest;
	BOOL			success = NO;
	
	// Param checking.
	require (count <= 75, bail);
	require (category, bail);
	
	// We have to have been authenticated and using Game Center.
	if ((_authenticated == NO) || (_usingGameCenter == NO))
		goto bail;
	
	// Create leaderboard object to request global scores.
	leaderboardRequest = [[GKLeaderboard alloc] init];
	require (leaderboardRequest, bail);
	
	// Leaderboard attributes.
	leaderboardRequest.identifier = category;
	if (friends)
		leaderboardRequest.playerScope = GKLeaderboardPlayerScopeFriendsOnly;
	else
		leaderboardRequest.playerScope = GKLeaderboardPlayerScopeGlobal;
	leaderboardRequest.timeScope = GKLeaderboardTimeScopeAllTime;
	
	// An odd bug, if a player ID comes back as "G: ANONYMOUS", we will fail to get 
	// their scores later (in -[retrieveLeaderboardScoresForPlayerIDs:forCategory:] below).
	// I'm going to request more than the client asked for and filter out 'anonymous' players.
	leaderboardRequest.range = NSMakeRange (1, count + 8);
	
	// Load the scores.
	[leaderboardRequest loadScoresWithCompletionHandler: ^(NSArray *scores, NSError *error)
	{
		NSMutableArray	*values = nil;
		NSMutableArray	*players = nil;
		NSUInteger		index = 0;
		
		// Handle error. Even with an error, there may be a partial list of scores, however.
		if (error != nil)
		{
			if ([_delegate respondsToSelector: @selector (localPlayer:failedRetrieveScoreForCategory:error:)])
				[_delegate localPlayer: self failedRetrieveScoreForCategory: category error: error];
		}
		
		// See if we have some score data.
		if (scores)
		{
			// Array to hold scores and player ID's.
			values = [NSMutableArray arrayWithCapacity: 3];
			players = [NSMutableArray arrayWithCapacity: 3];
			
			for (GKScore *oneScore in scores)
			{
				// Skip over "anonymous" scores.
				if ([oneScore.playerID isEqualToString: @"G: ANONYMOUS"] == NO)
				{
					[values addObject: [NSString stringWithFormat: @"%lld", oneScore.value]];
					[players addObject: oneScore.playerID];
					
					// Return only as many scores requested.
					index += 1;
					if (index == count)
						break;
				}
			}
		}
		
		// Call delegate with the leaderboard scores.
		if ([_delegate respondsToSelector: @selector (localPlayer:retrievedLeaderboardScores:playerIDs:forCategory:)])
			[_delegate localPlayer: self retrievedLeaderboardScores: values playerIDs: players forCategory: category];
	}];
	
	success = YES;
	
bail:
	
	return success;
}

// ------------------------------------------------------------------- retrieveLeaderboardScoresForPlayerIDs:forCategory

- (BOOL) retrieveLeaderboardScoresForPlayerIDs: (NSArray *) playerIDs forCategory: (NSString *) category
{
	GKLeaderboard	*leaderboardRequest;
	BOOL			success = NO;
	
	// Param checking.
	require (playerIDs, bail);
	require (category, bail);
	
	// We have to have been authenticated and using Game Center.
	if ((_authenticated == NO) || (_usingGameCenter == NO))
		goto bail;
	
	// Create leaderboard object to request global scores.
	leaderboardRequest = [[GKLeaderboard alloc] initWithPlayerIDs: playerIDs];
	require (leaderboardRequest, bail);
	
	// Leaderboard attributes.
	leaderboardRequest.identifier = category;
	
	// Load the scores.
	[leaderboardRequest loadScoresWithCompletionHandler: ^(NSArray *scores, NSError *error)
	{
		NSMutableArray	*values = nil;
		NSMutableArray	*players = nil;
		
		// Handle error. Even with an error, there may be a partial list of scores, however.
		if (error != nil)
		{
			if ([_delegate respondsToSelector: @selector (localPlayer:failedRetrieveScoreForCategory:error:)])
				[_delegate localPlayer: self failedRetrieveScoreForCategory: category error: error];
		}
		
		// See if we have some score data.
		if (scores)
		{
			// Array to hold scores.
			values = [NSMutableArray arrayWithCapacity: 3];
			players = [NSMutableArray arrayWithCapacity: 3];
			
			for (NSString *onePlayerID in playerIDs)
			{
				BOOL	foundMatch = NO;
				
				for (GKScore *oneScore in scores)
				{
					if ([onePlayerID isEqualToString: oneScore.playerID])
					{
						[values addObject: [NSString stringWithFormat: @"%lld", oneScore.value]];
						[players addObject: onePlayerID];
						
						foundMatch = YES;
						break;
					}
				}
				
				// Insert a placeholder.
				if (foundMatch == NO)
				{
					[values addObject: @"0"];
					[players addObject: onePlayerID];
				}
			}
		}
		
		// Call delegate with the leaderboard scores.
		if ([_delegate respondsToSelector: @selector (localPlayer:retrievedLeaderboardScores:playerIDs:forCategory:)])
			[_delegate localPlayer: self retrievedLeaderboardScores: values playerIDs: players forCategory: category];
	}];
	
	success = YES;
	
bail:
	
	return success;
}

// ----------------------------------------------------------------------------------------- retrieveAliasesForPlayerIDs

- (BOOL) retrieveAliasesForPlayerIDs: (NSArray *) playerIDs
{
	BOOL	success = NO;
	
	// We have to have been authenticated and using Game Center.
	if ((_authenticated == NO) || (_usingGameCenter == NO))
		goto bail;
	
	success = YES;
	
	[GKPlayer loadPlayersForIdentifiers: playerIDs withCompletionHandler: ^(NSArray *players, NSError *error)
	{
		NSMutableArray	*aliases = nil;
		
		if (error != nil)
		{
			if ([_delegate respondsToSelector: @selector (localPlayer:failedRetrieveAliasesForPlayerIDs:)])
				[_delegate localPlayer: self failedRetrieveAliasesForPlayerIDs: error];
		}
		
		if (players)
		{
			// Array to hold aliases.
			aliases = [NSMutableArray arrayWithCapacity: 3];
			
			for (NSString *onePlayerID in playerIDs)
			{
				BOOL	foundMatch = NO;
				
				for (GKPlayer *onePlayer in players)
				{
					if ([onePlayerID isEqualToString: onePlayer.playerID])
					{
						// Add to aliases.
						[aliases addObject: onePlayer.alias];
						
						foundMatch = YES;
						break;
					}
				}
				
				// Insert a placeholder.
				if (foundMatch == NO)
					[aliases addObject: @"???"];
			}
		}
		
		// Call delegate with the player aliases.
		if ([_delegate respondsToSelector: @selector (localPlayer:retrievedAliasesForPlayerIDs:)])
			[_delegate localPlayer: self retrievedAliasesForPlayerIDs: aliases];
	}];
	
bail:
	
	return success;
}

// ------------------------------------------------------------------- retrieveLeaderboardScoreForLocalPlayerForCategory

- (BOOL) retrieveLeaderboardScoreForLocalPlayerForCategory: (NSString *) category
{
	GKLeaderboard	*leaderboardRequest;
	BOOL			success = NO;
	
	// Param checking.
	require (category, bail);
	
	// We have to have been authenticated and using Game Center.
	if ((_authenticated == NO) || (_usingGameCenter == NO))
		goto bail;
	
	// Create leaderboard object to request global scores.
	leaderboardRequest = [[GKLeaderboard alloc] initWithPlayerIDs: [NSArray arrayWithObject: _playerID]];
	require (leaderboardRequest, bail);
	
	// Leaderboard attributes.
	leaderboardRequest.identifier = category;
	
	// Load the scores.
	[leaderboardRequest loadScoresWithCompletionHandler: ^(NSArray *scores, NSError *error)
	{
		// Handle error. Even with an error, there may be a partial list of scores, however.
		if (error != nil)
		{
			if ([_delegate respondsToSelector: @selector (localPlayer:failedRetrieveScoreForCategory:error:)])
				[_delegate localPlayer: self failedRetrieveScoreForCategory: category error: error];
		}
		
		// See if we have some score data.
		if (scores)
		{
			GKScore	*oneScore;
			
			// Call delegate with the leaderboard score.
			oneScore = [scores objectAtIndex: 0];
			if ([_delegate respondsToSelector: @selector (localPlayer:retrievedLeaderboardScoreForLocalPlayer:forCategory:)])
				[_delegate localPlayer: self retrievedLeaderboardScoreForLocalPlayer: oneScore.value forCategory: category];
		}
	}];
	
	success = YES;
	
bail:
	
	return success;
}

@end


@implementation LocalPlayer (LocalPlayer_priv)
// ====================================================================================== LocalPlayer (LocalPlayer_priv)
// ---------------------------------------------------------------------------------------------- gameCenterAPIAvailable

- (BOOL) gameCenterAPIAvailable
{
	BOOL		localPlayerClassAvailable;
	NSString	*requiredSystemVersion = @"4.1";
	NSString	*currentSystemVersion;
	BOOL		osVersionSupported;
	
	localPlayerClassAvailable = (NSClassFromString (@"GKLocalPlayer") != nil);
	currentSystemVersion = [[UIDevice currentDevice] systemVersion];
	osVersionSupported = ([currentSystemVersion compare: requiredSystemVersion options: NSNumericSearch] != NSOrderedAscending);
	
	return (localPlayerClassAvailable && osVersionSupported);
}

// --------------------------------------------------------------------------------------------- authenticateLocalPlayer

- (void) authenticateLocalPlayer
{
	if ([self gameCenterAPIAvailable])
	{
		GKLocalPlayer *localPlayer;
		
		localPlayer = [GKLocalPlayer localPlayer];
		localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error)
		{
			if (localPlayer.isAuthenticated)
			{
				_playerID = [[NSString alloc] initWithString: localPlayer.playerID];
				_alias = [[NSString alloc] initWithString: localPlayer.alias];
				_authenticated = YES;
				_usingGameCenter = YES;
				
				if ([_delegate respondsToSelector: @selector (localPlayerAuthenticated:)])
					[_delegate localPlayerAuthenticated: self];
			}
			else
			{
				if (_playerID)
				{
					[_playerID release];
					_playerID = nil;
				}
				if (_alias)
				{
					[_alias release];
					_alias = nil;
				}
				_authenticated = YES;
				_usingGameCenter = NO;
				
				if ([_delegate respondsToSelector: @selector (localPlayer:failedAuthenticationWithError:)])
					[_delegate localPlayer: self failedAuthenticationWithError: error];
			}
		};
	}
	else
	{
		_authenticated = YES;
		_usingGameCenter = NO;
	}
}

@end
