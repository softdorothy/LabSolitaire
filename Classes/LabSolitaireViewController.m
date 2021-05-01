// =====================================================================================================================
//  LabSolitaireViewController.m
// =====================================================================================================================


#import <AssertMacros.h>
#import "CEStackViewPrivate.h"
#import "LabSolitaireViewController.h"
#import "LSStackView.h"
#import "SimpleAudioEngine.h"


#define DISPLAY_OUTLINE_IN_TABLEAU		0
#define DISPLAY_OUTLINE_FOR_FOUNDATIONS	1
#define DISALLOW_TOUCHES_IF_ANIMATION	0
#define DISALLOW_DRAGTO_IF_ANIMATION	0	// 1


// Card size.
#define kCardWide						82
#define kCardTall						114

// Button sizes.
#define kButtonWide						93	// 92
#define kButtonTall						47	// 45

// Portrait layout constants.
#define kPLayoutHOffset					8
#define kPLayoutVOffset					100
#define kPCellFoundationHGap			10
#define kPFoundationHOffset				kPLayoutHOffset + 394
#define kPTableauHGap					14
#define kPTableauVOffset				kPLayoutVOffset + kCardTall + 20
#define kPTableauTall					566
#define kPNewButtonY					182	// 181
#define kPUndoButtonY					129	// 128
#define kPInfoButtonY					76	// 75

// Landscape layout constants.
#define kLLayoutHOffset					143
#define kLLayoutVOffset					16
#define kLCellFoundationHGap			10
#define kLFoundationHOffset				kLLayoutHOffset + 387
#define kLTableauHGap					13
#define kLTableauVOffset				kLLayoutVOffset + kCardTall + 20
#define kLTableauTall					584
#define kLNewButtonY					189	// 188
#define kLUndoButtonY					136	// 135
#define kLInfoButtonY					83	// 82

#define kHighlighterVOffset				328

// Misc.
#define kDealAnimationDuration			0.25
#define kDealAnimationDelay				0.23
#define kPutawayAnimationDuration		0.25	// 0.30
#define kPutawayAnimationDelay			0.25	// 0.30
#define kWaitForTouchToEndDelay			0.02
#define kResetTableAlertTag				1
#define kUndoAllAlertTag				2
#define	kMaxLeaderboardScores			15	// 10


enum
{
	kNoDragRestriction = 0, 
	kDisallowEmptyColumnDragRestriction = 2, 
	kEmptyColumnOnlyDragRestriction = 3
};

enum
{
	kAutoPutawayModeSmart = 0, 
	kAutoPutawayModeAll = 1
};

enum
{
	kLeaderboardMostPlayedMode = 0, 
	kLeaderboardMostWonMode = 1
};


@implementation LabSolitaireViewController
// ========================================================================================== LabSolitaireViewController
// ------------------------------------------------------------------------------------------ adjustLayoutForOrientation

- (void) adjustLayoutForOrientation: (UIInterfaceOrientation) orientation
{
	CGRect	mainBounds;
	CGRect	buttonFrame;

	mainBounds = [[UIScreen mainScreen] bounds];
	
	if (UIInterfaceOrientationIsPortrait (orientation))
	{
		int		i;
		
		// Adjust cells.
		for (i = 0; i < 4; i++)
			_cellViews[i].frame = CGRectMake (kPLayoutHOffset + (i * (kPCellFoundationHGap + kCardWide)), kPLayoutVOffset, kCardWide, kCardTall);

		// Adjust foundations.
		for (i = 0; i < 4; i++)
			_foundationViews[i].frame = CGRectMake (kPFoundationHOffset + (i * (kPCellFoundationHGap + kCardWide)), kPLayoutVOffset, kCardWide, kCardTall);
		
		// Adjust tableau.
		for (i = 0; i < 8; i++)
			_tableauViews[i].frame = CGRectMake (kPLayoutHOffset + (i * (kPTableauHGap + kCardWide)), kPTableauVOffset, kCardWide, kPTableauTall);
		
		buttonFrame = _newButton.frame;
		buttonFrame.origin = CGPointMake (mainBounds.size.width - kButtonWide, mainBounds.size.height - kPNewButtonY);
		_newButton.frame = buttonFrame;
		[_newButton setImage: [UIImage imageNamed: @"NewSelectedP"] forState: UIControlStateHighlighted];
		
		buttonFrame = _undoButton.frame;
		buttonFrame.origin = CGPointMake (mainBounds.size.width - kButtonWide, mainBounds.size.height - kPUndoButtonY);
		_undoButton.frame = buttonFrame;
		[_undoButton setImage: [UIImage imageNamed: @"UndoSelectedP"] forState: UIControlStateHighlighted];
		
		buttonFrame = _infoButton.frame;
		buttonFrame.origin = CGPointMake (mainBounds.size.width - kButtonWide, mainBounds.size.height - kPInfoButtonY);
		_infoButton.frame = buttonFrame;
		[_infoButton setImage: [UIImage imageNamed: @"InfoSelectedP"] forState: UIControlStateHighlighted];
		
		_darkView.frame = mainBounds;
		
//		if (_infoView)
		if ((0))
		{
			CGRect	frame;
			
			frame = _infoView.frame;
			if (_infoViewIsOpen)
				frame.origin = CGPointMake ((mainBounds.size.width - frame.size.width) / 2.0, mainBounds.size.height - frame.size.height);
			else
				frame.origin = CGPointMake ((mainBounds.size.width - frame.size.width) / 2.0, mainBounds.size.height);
			_infoView.frame = frame;
		}
	}
	else
	{
		int		i;
		
		// Adjust cells.
		for (i = 0; i < 4; i++)
			_cellViews[i].frame = CGRectMake (kLLayoutHOffset + (i * (kLCellFoundationHGap + kCardWide)), kLLayoutVOffset, kCardWide, kCardTall);
		
		// Adjust foundations.
		for (i = 0; i < 4; i++)
			_foundationViews[i].frame = CGRectMake (kLFoundationHOffset + (i * (kLCellFoundationHGap + kCardWide)), kLLayoutVOffset, kCardWide, kCardTall);
		
		// Create tableau.
		for (i = 0; i < 8; i++)
			_tableauViews[i].frame = CGRectMake (kLLayoutHOffset + (i * (kLTableauHGap + kCardWide)), kLTableauVOffset, kCardWide, kLTableauTall);
		
		buttonFrame = _newButton.frame;
		buttonFrame.origin = CGPointMake (mainBounds.size.height - kButtonWide, mainBounds.size.width - kLNewButtonY);
		_newButton.frame = buttonFrame;
		[_newButton setImage: [UIImage imageNamed: @"NewSelectedL"] forState: UIControlStateHighlighted];
		
		buttonFrame = _undoButton.frame;
		buttonFrame.origin = CGPointMake (mainBounds.size.height - kButtonWide, mainBounds.size.width - kLUndoButtonY);
		_undoButton.frame = buttonFrame;
		[_undoButton setImage: [UIImage imageNamed: @"UndoSelectedL"] forState: UIControlStateHighlighted];
		
		buttonFrame = _infoButton.frame;
		buttonFrame.origin = CGPointMake (mainBounds.size.height - kButtonWide, mainBounds.size.width - kLInfoButtonY);
		_infoButton.frame = buttonFrame;
		[_infoButton setImage: [UIImage imageNamed: @"InfoSelectedL"] forState: UIControlStateHighlighted];
		
		_darkView.frame = CGRectMake (0.0, 0.0, mainBounds.size.height, mainBounds.size.width);
		
//		if (_infoView)
		if ((0))
		{
			CGRect	frame;
			
			frame = _infoView.frame;
			if (_infoViewIsOpen)
				frame.origin = CGPointMake ((mainBounds.size.height - frame.size.width) / 2.0, mainBounds.size.width - frame.size.height);
			else
				frame.origin = CGPointMake ((mainBounds.size.height - frame.size.width) / 2.0, mainBounds.size.width);
			_infoView.frame = frame;
		}
	}
}

#pragma mark ------ card routines
// --------------------------------------------------------------------------------------------- noteAtleastOneCardMoved

- (void) noteAtleastOneCardMoved
{
	NSInteger	gamesPlayed;
	
	// Store score.
	[_localPlayer retrieveLocalScore: &gamesPlayed forCategory: @"com.softdorothy.labsolitaire.games_played"];
	[_localPlayer postLocalScore: gamesPlayed + 1 forCategory: @"com.softdorothy.labsolitaire.games_played"];
	[_localPlayer postLeaderboardScore: gamesPlayed + 1 forCategory: @"com.softdorothy.labsolitaire.games_played"];
	
	// Count this game only once.
	_playedAtleastOneCard = YES;
}

// ------------------------------------------------------------------------------------------------------- worryBackCard

- (void) worryBackCard: (CECard *) card
{
	[_worriedCards addObject: [NSNumber numberWithUnsignedInteger: card.index]];
}

// -------------------------------------------------------------------------------------------------- wasCardWorriedBack

- (BOOL) wasCardWorriedBack: (CECard *) card
{
	BOOL	worried = NO;
	
	for (NSNumber *number in _worriedCards)
	{
		if ([number intValue] == card.index)
		{
			worried = YES;
			break;
		}
	}
	
	return worried;
}

// ---------------------------------------------------------------------------------------- foundationToPutAwayCardSmart

- (CEStackView *) foundationToPutAwayCardSmart: (CECard *) card
{
	int			i;
	CERank		lowestRedFoundationRank;
	CERank		lowestBlackFoundationRank;
	CEStackView	*stackToPutAwayTo = nil;
	
	// Initially, assume no rank is greatest.
	lowestRedFoundationRank = kCERankKing;
	lowestBlackFoundationRank = kCERankKing;
	
	// Walk foundations finding the lowest black ranking card and lowest red ranking card on the foundation.
	for (i = 0; i < 4; i++)
	{
		CECard	*foundationCard;
		
		// Top card of foundation.
		foundationCard = [_foundationViews[i].stack topCard];
		
		// Compare.
		if (foundationCard == nil)
		{
			// If no card on foundation, this becomes (zero) the lowest card of the given color.
			if ((i == kCESuitDiamonds) || (i == kCESuitHearts))
				lowestRedFoundationRank = 0;
			else
				lowestBlackFoundationRank = 0;
		}
		else
		{
			if ((((i == kCESuitDiamonds) || (i == kCESuitHearts))) && (foundationCard.rank < lowestRedFoundationRank))
				lowestRedFoundationRank = foundationCard.rank;
			else if ((((i == kCESuitClubs) || (i == kCESuitSpades))) && (foundationCard.rank < lowestBlackFoundationRank))
				lowestBlackFoundationRank = foundationCard.rank;
		}
	}
	
	// Walk the foundations looking for a match.
	for (i = 0; i < 4; i++)
	{
		CECard	*foundationCard;
		
		// Top card of foundation.
		foundationCard = [_foundationViews[i].stack topCard];
		
		if (foundationCard == nil)
		{
			// Foundation is empty (no top card). Only an ace may be placed.
			if ((card.suit == i) && (card.rank == kCERankAce))
				stackToPutAwayTo = _foundationViews[i];
		}
		else if ((card.suit == foundationCard.suit) && (card.rank == (foundationCard.rank + 1)))
		{
			// First pass: card must ranked one greater than the top card of the foundation correspoding to card's suit.
			// Second pass: two's are always put up (Microsoft way).
			if (card.rank <= kCERankTwo)
			{
				stackToPutAwayTo = _foundationViews[i];
				break;
			}
			
			// Third pass: put up if both opposite color foundations are built up to within two of the card's rank.
			// Also: Microsoft way.
			if ((CESuitIsRed (card.suit)) && (card.rank <= (lowestBlackFoundationRank + 1)))
				stackToPutAwayTo = _foundationViews[i];
			else if ((CESuitIsBlack (card.suit)) && (card.rank <= (lowestRedFoundationRank + 1)))
				stackToPutAwayTo = _foundationViews[i];
			
			// Fourth pass: there is one case we will also allow, if card ranks is within 2 greater than both the 
			// opposite color's foundation ranks AND within 3 of it's same-color-opposite-suit foundation card.
			// NETCell way.
			if (stackToPutAwayTo == nil)
			{
				if ((card.suit == kCESuitDiamonds) && (card.rank <= (lowestBlackFoundationRank + 2)))
				{
					CECard	*oppositeFoundationCard;
					
					// Top card of 'opposite' foundation (same color, other suit).
					oppositeFoundationCard = [_foundationViews[kCESuitHearts].stack topCard];
					if (card.rank <= (oppositeFoundationCard.rank + 3))
						stackToPutAwayTo = _foundationViews[i];
				}
				else if ((card.suit == kCESuitClubs) && (card.rank <= (lowestRedFoundationRank + 2)))
				{
					CECard	*oppositeFoundationCard;
					
					// Top card of 'opposite' foundation (same color, other suit).
					oppositeFoundationCard = [_foundationViews[kCESuitSpades].stack topCard];
					if (card.rank <= (oppositeFoundationCard.rank + 3))
						stackToPutAwayTo = _foundationViews[i];
				}
				else if ((card.suit == kCESuitHearts) && (card.rank <= (lowestBlackFoundationRank + 2)))
				{
					CECard	*oppositeFoundationCard;
					
					// Top card of 'opposite' foundation (same color, other suit).
					oppositeFoundationCard = [_foundationViews[kCESuitDiamonds].stack topCard];
					if (card.rank <= (oppositeFoundationCard.rank + 3))
						stackToPutAwayTo = _foundationViews[i];
				}
				else if ((card.suit == kCESuitSpades) && (card.rank <= (lowestRedFoundationRank + 2)))
				{
					CECard	*oppositeFoundationCard;
					
					// Top card of 'opposite' foundation (same color, other suit).
					oppositeFoundationCard = [_foundationViews[kCESuitClubs].stack topCard];
					if (card.rank <= (oppositeFoundationCard.rank + 3))
						stackToPutAwayTo = _foundationViews[i];
				}
			}
		}
	}
	
	return stackToPutAwayTo;
}

// ------------------------------------------------------------------------------------------ foundationToPutAwayCardAll

- (CEStackView *) foundationToPutAwayCardAll: (CECard *) card
{
	int			i;
	CEStackView	*stackToPutAwayTo = nil;
	
	// Walk the foundations looking for a match.
	for (i = 0; i < 4; i++)
	{
		CECard	*foundationCard;
		
		// Top card of foundation.
		foundationCard = [_foundationViews[i].stack topCard];
		
		if (foundationCard == nil)
		{
			// Foundation is empty (no top card). Only an ace may be placed.
			if ((card.suit == i) && (card.rank == kCERankAce))
				stackToPutAwayTo = _foundationViews[i];
		}
		else if ((card.suit == foundationCard.suit) && (card.rank == (foundationCard.rank + 1)))
		{
			// "AllPlay" means put away any card that it is leagal to put away.
			stackToPutAwayTo = _foundationViews[i];
			break;
		}
	}
	
	return stackToPutAwayTo;
}

// ---------------------------------------------------------------------------------------- determineIfCardsCanBePutAway

- (void) determineIfCardsCanBePutAway
{
	BOOL	didFindCard;
	
	do
	{
		int		i;
		
		// Indicate no card found at this point.
		didFindCard = NO;
		
		// Walk the tableaus, examining the top cards of eack stack.
		for (i = 0; i < 8; i++)
		{
			CEStackView	*destFoundation;
			
			// If the card was worried back, the player doesn't want us messing with the card.
			if ([self wasCardWorriedBack: [_tableauViews[i].stack topCard]])
				continue;
			
			// Determine if top card of tableau has a foundation it should be put-away to.
			if (_autoPutawayMode == kAutoPutawayModeSmart)
				destFoundation = [self foundationToPutAwayCardSmart: [_tableauViews[i].stack topCard]];
			else
				destFoundation = [self foundationToPutAwayCardAll: [_tableauViews[i].stack topCard]];
			if (destFoundation != nil)
			{
				if ([_tableauViews[i] touchState] == kStackViewTouchStateIdle)
				{
					[_tableauViews[i].stack topCard].alpha = 1;
					[_tableauViews[i] dealTopCardToStackView: destFoundation faceUp: YES duration: kPutawayAnimationDuration];
					[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: kPutawayAnimationDelay]];
				}
				else
				{
					[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: kWaitForTouchToEndDelay]];
				}
				didFindCard = YES;
			}
		}
		
		// Walk the cells, examining the top cards of eack stack.
		for (i = 0; i < 4; i++)
		{
			CEStackView	*destFoundation;
			
			// Determine if top card of cell has a foundation it should be put-away to.
			if (_autoPutawayMode == kAutoPutawayModeSmart)
				destFoundation = [self foundationToPutAwayCardSmart: [_cellViews[i].stack topCard]];
			else
				destFoundation = [self foundationToPutAwayCardAll: [_cellViews[i].stack topCard]];
			if (destFoundation != nil)
			{
				if ([_cellViews[i] touchState] == kStackViewTouchStateIdle)
				{
					[_cellViews[i].stack topCard].alpha = 1;
					[_cellViews[i] dealTopCardToStackView: destFoundation faceUp: YES duration: kPutawayAnimationDuration];
					[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: kPutawayAnimationDelay]];
				}
				else
				{
					[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: kWaitForTouchToEndDelay]];
				}
				didFindCard = YES;
			}
		}
	}
	while (didFindCard == YES);
}

// -------------------------------------------------------------------------------------------------- allCardsArePutAway

- (BOOL) allCardsArePutAway
{
	return (([_foundationViews[0].stack numberOfCards] == 13) && ([_foundationViews[1].stack numberOfCards] == 13) && 
			([_foundationViews[2].stack numberOfCards] == 13) && ([_foundationViews[2].stack numberOfCards] == 13));
}

// ------------------------------------------------------------------------------------------------- countOfCardsOnTable

- (NSInteger) countOfCardsOnTable
{
	NSInteger	i;
	NSInteger	count = 0;
	
	for (i = 0; i < 4; i++)
		count = count + _cellViews[i].stack.numberOfCards;

	for (i = 0; i < 4; i++)
		count = count + _foundationViews[i].stack.numberOfCards;

	for (i = 0; i < 8; i++)
		count = count + _tableauViews[i].stack.numberOfCards;
	
	return count;
}

// ------------------------------------------------------------------------------------------------------ checkGameState

- (void) checkGameState
{
	// NOP.
	if (_gameWon)
		return;
	
	if ([self allCardsArePutAway])
	{
		NSInteger		gamesWon = 0;
		NSInteger		gamesPlayed = 0;
		
		// Get score.
		[_localPlayer retrieveLocalScore: &gamesWon forCategory: @"com.softdorothy.labsolitaire.games_won"];
		gamesWon += 1;
		
		// Hack! It is possible for someone to 'log in' with Game Center mid-game, win the game, and have recorded more 
		// times having won than having played (since the 'played' was logged earlier when they weren't logged in).
		[_localPlayer retrieveLocalScore: &gamesPlayed forCategory: @"com.softdorothy.labsolitaire.games_played"];
		if (gamesWon > gamesPlayed)
		{
			gamesPlayed = gamesWon;
			[_localPlayer postLocalScore: gamesPlayed forCategory: @"com.softdorothy.labsolitaire.games_played"];
			[_localPlayer postLeaderboardScore: gamesPlayed forCategory: @"com.softdorothy.labsolitaire.games_played"];
		}
		
		// Store score.
		[_localPlayer postLocalScore: gamesWon forCategory: @"com.softdorothy.labsolitaire.games_won"];
		[_localPlayer postLeaderboardScore: gamesWon forCategory: @"com.softdorothy.labsolitaire.games_won"];
		
		// Display number of games won.
		_gameWon = YES;
		
		// Bring up game-over view.
		[self performSelector: @selector (openGameOverView:) withObject: nil afterDelay: 0.5];
	}
}

// ------------------------------------------------------------------------------------------------------- storeSeedUsed

- (void) storeSeedUsed: (NSUInteger) seed
{
	NSUserDefaults	*defaults;
	
	// Get standard defaults.
	defaults = [NSUserDefaults standardUserDefaults];
	
	// Store new number of games played.
	[defaults setObject: [NSNumber numberWithUnsignedInteger: seed] forKey: @"Seed"];
	[defaults synchronize];
}

// -------------------------------------------------------------------------------------------------------- seedUsedLast

- (NSUInteger) seedUsedLast
{
	NSUserDefaults	*defaults;
	NSNumber		*seedValue;
	NSUInteger		seed = NSNotFound;
	
	// Get standard defaults.
	defaults = [NSUserDefaults standardUserDefaults];
	
	// Get seed.
	seedValue = [defaults objectForKey: @"Seed"];
	if (seedValue)
		seed = [seedValue unsignedIntegerValue];
	
	return seed;
}

// ---------------------------------------------------------------------------------------------------------- resetTable

- (void) resetTable: (BOOL) newDeck
{
	int			i;
	CEStack		*deck;
	
	// A game has begun but no card yet has been touched.
	if (newDeck == YES)
		_playedAtleastOneCard = NO;
	_gameWon = NO;
	
	// Remove all cards.
	for (i = 0; i < 4; i++)
		[_cellViews[i].stack removeAllCards];
	for (i = 0; i < 4; i++)
		[_foundationViews[i].stack removeAllCards];
	for (i = 0; i < 8; i++)
		[_tableauViews[i].stack removeAllCards];
	
	// Clear Undo actions.
	[[CETableView sharedCardUndoManager] removeAllActions];
	
	// No more worried cards.
	[_worriedCards removeAllObjects];
	
	// Create deck of cards.
	deck = [CEStack deckOfCards];
	if (newDeck == YES)
	{
		NSUInteger	seed;
		
		// Shuffle.
		seed = time (nil);
		[deck shuffleWithSeed: seed];
		[self storeSeedUsed: seed];
	}
	else
	{
		NSUInteger	seed;
		
		// Use the same shuffle used originally.
		seed = [self seedUsedLast];
		if (seed == NSNotFound)
		{
			[deck shuffleWithSeed: time (nil)];
		}
		else
		{
			[deck shuffleWithSeed: seed];
			[self storeSeedUsed: seed];
		}
	}
	
	// Initial card layout.
	for (i = 0; i < 52; i++)
	{
		CECard	*topCard;
		
		// Add top card to tableau, remove from deck.
		topCard = [deck topCard];
		topCard.faceUp = YES;
		topCard.alpha = 0;
		[topCard randomizeTransform];
		[_tableauViews[i % 8].stack addCard: topCard];
		[deck removeCard: topCard];
	}
	
	_dealIndex = 0;
	/* NSTimer 	*_dealTimer = */ (void) [NSTimer scheduledTimerWithTimeInterval: 0 /*0.017*/ target: self 
				selector: @selector (dealTimer:) userInfo: nil repeats: YES];
	
	// Fire off timer to check for cards that can be put up in the foundation.
	if ((_splashDismissed) && (_autoPutaway))
	{
		_putawayTimer = [NSTimer scheduledTimerWithTimeInterval: 2 /* 1 */ target: self 
				selector: @selector (putawayTimer:) userInfo: nil repeats: NO];
	}
}

// ----------------------------------------------------------------------------------------------------------- dealTimer

- (void) dealTimer: (NSTimer *) timer
{
	CEStackView	*stackView;
	NSUInteger	cardIndex;
	CEStack		*stack;
	
	stackView = _tableauViews [_dealIndex % 8];
	stack = stackView.stack;
	cardIndex = _dealIndex / 8;
	if (stack.numberOfCards > cardIndex)
	{
		CECard		*card;
		
		card = [stack cardAtIndex: cardIndex];
		card.alpha = 1;
		[[stackView cardViewForCard: card] setNeedsDisplay];
	}
	
	_dealIndex += 1;
	if (_dealIndex >= 52)
	{
		[timer invalidate];
	}
}

// ----------------------------------------------------------------------------------------------- createCardTableLayout

- (void) createCardTableLayout
{
	NSUserDefaults	*defaults;
	NSNumber		*number;
	int				i;
	CGRect			mainBounds;
	
	// Store orientation.
	_orientation = self.interfaceOrientation;
	
	// Get standard defaults, what is the user preference for auto-putaway.
	defaults = [NSUserDefaults standardUserDefaults];
	number = [defaults objectForKey: @"AutoPutaway"];
	if (number)
		_autoPutaway = [number boolValue];
	else
		_autoPutaway = YES;
	
	// What is the user preference for auto-putaway mode?
	number = [defaults objectForKey: @"AutoPutawayMode"];
	if (number)
		_autoPutawayMode = [number integerValue];
	else
		_autoPutawayMode = kAutoPutawayModeAll;
	
	// What is the user preference for sound playback?
	defaults = [NSUserDefaults standardUserDefaults];
	number = [defaults objectForKey: @"PlaySounds"];
	if (number)
	{
		_playSounds = [number boolValue];
	}
	else
	{
		_playSounds = YES;
	}
	
	// What is the user preference for leaderboard scope?
	defaults = [NSUserDefaults standardUserDefaults];
	number = [defaults objectForKey: @"LeaderboardScope"];
	if (number)
	{
		_leaderboardFriendsOnly = [number boolValue];
	}
	else
	{
		_leaderboardFriendsOnly = NO;
	}
	
	// Assign portrait and landscape images.
	[(CETableView *) self.view setPortraitImagePath: @"TablePortrait"];
	[(CETableView *) self.view setLandscapeImagePath: @"TableLandscape"];
	
	// Create cells.
	for (i = 0; i < 4; i++)
	{
		_cellViews[i] = [[LSStackView alloc] initWithFrame: 
				CGRectMake (kPLayoutHOffset + (i * (kPCellFoundationHGap + kCardWide)), kPLayoutVOffset, kCardWide, kCardTall)];
		[_cellViews[i] setCardSize: kCardSizeLarge];
		[_cellViews[i] setLayout: kCEStackViewLayoutStacked];
		[_cellViews[i] setBorderColor: [UIColor colorWithWhite: 0.0 alpha: 0.22]];
		[_cellViews[i] setFillColor: nil];
		[_cellViews[i] setLabelColor: [UIColor colorWithWhite: 0.0 alpha: 0.22]];
		[_cellViews[i] setLabelFont: [UIFont fontWithName: @"Arial" size: 32.0]];
		[_cellViews[i] setLabel: @"Free"];
		[_cellViews[i] setTag: i];
		[_cellViews[i] setDelegate: self];
		[_cellViews[i] setIdentifier: @"Cell"];
		[_cellViews[i] setArchiveIdentifier: [NSString stringWithFormat: @"Cell%d", i]];
		[(CETableView *) self.view addSubview: _cellViews[i]];
		[_cellViews[i] release];
	}
	
	// Create foundations.
	for (i = 0; i < 4; i++)
	{
		_foundationViews[i] = [[LSStackView alloc] initWithFrame: 
				CGRectMake (kPFoundationHOffset + (i * (kPCellFoundationHGap + kCardWide)), kPLayoutVOffset, kCardWide, kCardTall)];
		[_foundationViews[i] setCardSize: kCardSizeLarge];
		[_foundationViews[i] setLayout: kCEStackViewLayoutStacked];
#if DISPLAY_OUTLINE_FOR_FOUNDATIONS
		[_foundationViews[i] setBorderColor: [UIColor colorWithWhite: 0.0 alpha: 0.22]];
		[_foundationViews[i] setFillColor: nil];
		[_foundationViews[i] setLabelColor: [UIColor colorWithWhite: 0.0 alpha: 0.22]];
#else	// DISPLAY_OUTLINE_FOR_FOUNDATIONS
		[_foundationViews[i] setBorderColor: nil];
		[_foundationViews[i] setFillColor: [UIColor colorWithWhite: 0.0 alpha: 0.16]];
		[_foundationViews[i] setLabelColor: [UIColor colorWithWhite: 0.0 alpha: 0.14]];
#endif	// DISPLAY_OUTLINE_FOR_FOUNDATIONS
		[_foundationViews[i] setLabelFont: [UIFont fontWithName: @"Arial" size: 64.0]];
		[_foundationViews[i] setLabel: [CECard stringForSuit: i]];
		[_foundationViews[i] setTag: i];
		[_foundationViews[i] setDelegate: self];
		[_foundationViews[i] setIdentifier: @"Foundation"];
		[_foundationViews[i] setArchiveIdentifier: [NSString stringWithFormat: @"Foundation%d", i]];
		[(CETableView *) self.view addSubview: _foundationViews[i]];
		[_foundationViews[i] release];
	}
	
	// Create tableau.
	for (i = 0; i < 8; i++)
	{
		_tableauViews[i] = [[LSStackView alloc] initWithFrame: 
				CGRectMake (kPLayoutHOffset + (i * (kPTableauHGap + kCardWide)), kPTableauVOffset, kCardWide, kPTableauTall)];
		[_tableauViews[i] setCardSize: kCardSizeLarge];
		[_tableauViews[i] setLayout: kCEStackViewLayoutColumn];
#if DISPLAY_OUTLINE_IN_TABLEAU
		[_tableauViews[i] setBorderColor: [UIColor colorWithWhite: 0.0 alpha: 0.22]];
		[_tableauViews[i] setFillColor: nil];
		[_tableauViews[i] setLabelColor: [UIColor colorWithWhite: 0.0 alpha: 0.22]];
		[_tableauViews[i] setLabelFont: [UIFont fontWithName: @"Arial" size: 32.0]];
		[_tableauViews[i] setLabel: @"Any"];
#else	// DISPLAY_OUTLINE_IN_TABLEAU
		[_tableauViews[i] setBorderColor: nil];
		[_tableauViews[i] setFillColor: nil];
		[_tableauViews[i] setLabelColor: [UIColor colorWithRed: 0.5 green: 0.0 blue: 0.0 alpha: 0.5]];
		[_tableauViews[i] setLabelFont: [UIFont fontWithName: @"Arial" size: 64.0]];
#endif	// DISPLAY_OUTLINE_IN_TABLEAU
		[_tableauViews[i] setTag: i];
		[_tableauViews[i] setDelegate: self];
		[_tableauViews[i] setIdentifier: @"Tableau"];
		[_tableauViews[i] setArchiveIdentifier: [NSString stringWithFormat: @"Tableau%d", i]];
		[_tableauViews[i] setOrderly: NO];
		[(CETableView *) self.view addSubview: _tableauViews[i]];
		[_tableauViews[i] release];
	}
	
	// Layout the buttons.
	mainBounds = [[UIScreen mainScreen] bounds];
	
	// New button.
	_newButton = [[UIButton alloc] initWithFrame: CGRectMake (mainBounds.size.width - kButtonWide, mainBounds.size.height - kPNewButtonY, kButtonWide, kButtonTall)];
	[_newButton setImage: [UIImage imageNamed: @"NewSelectedP"] forState: UIControlStateHighlighted];
	[_newButton addTarget: self action: @selector (new:) forControlEvents: UIControlEventTouchUpInside];
	[self.view addSubview: _newButton];
	
	// Undo button.
	_undoButton = [[UIButton alloc] initWithFrame: CGRectMake (mainBounds.size.width - kButtonWide, mainBounds.size.height - kPUndoButtonY, kButtonWide, kButtonTall)];
	[_undoButton setImage: [UIImage imageNamed: @"UndoSelectedP"] forState: UIControlStateHighlighted];
	[_undoButton addTarget: self action: @selector (undo:) forControlEvents: UIControlEventTouchUpInside];
	[_undoButton addTarget: self action: @selector (undoDown:) forControlEvents: UIControlEventTouchDown];
	[_undoButton addTarget: self action: @selector (undoDragOutside:) forControlEvents: UIControlEventTouchDragOutside];
	[self.view addSubview: _undoButton];
	
	// Info button.
	_infoButton = [[UIButton alloc] initWithFrame: CGRectMake (mainBounds.size.width - kButtonWide, mainBounds.size.height - kPInfoButtonY, kButtonWide, kButtonTall)];
	[_infoButton setImage: [UIImage imageNamed: @"InfoSelectedP"] forState: UIControlStateHighlighted];
	[_infoButton addTarget: self action: @selector (info:) forControlEvents: UIControlEventTouchUpInside];
	[self.view addSubview: _infoButton];
	
	// Create "dark view" and lay over the entire card table and cards. It is only used to fade out the card table 
	// when the "Info" view is put up. It ignores user interaction.
	_darkView = [[UIView alloc] initWithFrame: mainBounds];
	_darkView.backgroundColor = [UIColor colorWithWhite: 0.0 alpha: 0.0];
	_darkView.userInteractionEnabled = NO;
	[self.view addSubview: _darkView];
	
	// Indicate the dark view as the overlaying view. This prevetns card animation from happening above of this view.
	_overlayingView = _darkView;
	
	// Create storage for worried cards.
	_worriedCards = [[NSMutableArray alloc] initWithCapacity: 3];
	
	// Load sounds.
	[[SimpleAudioEngine sharedEngine] preloadEffect: @"Shuffle.wav"];
	for (i = 0; i < kNumCardDrawSounds; i++)
	{
		[[SimpleAudioEngine sharedEngine] preloadEffect: [NSString stringWithFormat: @"CardDraw%d.wav", i]];
	}
	for (i = 0; i < kNumCardPlaceSounds; i++)
	{
		[[SimpleAudioEngine sharedEngine] preloadEffect: [NSString stringWithFormat: @"CardPlace%d.wav", i]];
	}
	[[SimpleAudioEngine sharedEngine] preloadEffect: @"ClickOpen.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect: @"ClickClose.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect: @"Blip.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect: @"Buzz.wav"];
	[[SimpleAudioEngine sharedEngine] preloadEffect: @"Babip.wav"];
	
skipAudio:
	
	// Create local player object.
	_localPlayer = [[LocalPlayer alloc] init];
	_localPlayer.delegate = self;
	_leaderboardPlayerIDs = [[NSMutableArray alloc] initWithCapacity: 3];
	_leaderboardGamesPlayed = [[NSMutableArray alloc] initWithCapacity: 3];
	_leaderboardGamesWon = [[NSMutableArray alloc] initWithCapacity: 3];
	
	// Listen for these.
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector (cardDragged:) 
			name: StackViewDidDragCardToStackNotification object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector (cardPickedUp:) 
			name: StackViewCardPickedUpNotification object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector (cardReleased:) 
			name: StackViewCardReleasedNotification object: nil];
	
	_splashDismissed = NO;
}

// ------------------------------------------------------------------------------------------------ openSplashAfterDelay

- (void) openSplashAfterDelay
{
	[self performSelector: @selector (info:) withObject: nil afterDelay: 0.5];
}

// ----------------------------------------------------------------------------------------------------------- saveState

- (void) saveState
{
	// Determine if we have a game in progress.
	if (([_foundationViews[0].stack numberOfCards] < 13) || ([_foundationViews[1].stack numberOfCards] < 13) || 
			([_foundationViews[2].stack numberOfCards] < 13) || ([_foundationViews[3].stack numberOfCards] < 13))
	{
		NSUserDefaults	*defaults;
		
		[(CETableView *) self.view archiveStackStateWithIdentifier: @"LabSolitaire"];
		
		defaults = [NSUserDefaults standardUserDefaults];
		[defaults setBool: YES forKey: @"SavedGame"];
		[defaults setBool: _playedAtleastOneCard forKey: @"PlayedAtleastOneCard"];
		[defaults setObject: _worriedCards forKey: @"WorriedCards"];
		[defaults synchronize];
	}
	else
	{
		NSUserDefaults	*defaults;
		
		defaults = [NSUserDefaults standardUserDefaults];
		[defaults setBool: NO forKey: @"SavedGame"];
		[defaults setBool: NO forKey: @"PlayedAtleastOneCard"];
		[defaults synchronize];
	}
}

// -------------------------------------------------------------------------------------------------------- restoreState

- (void) restoreState
{
	// Initial card layout.
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"SavedGame"] == YES)
	{
		BOOL	success;
		
		success = [(CETableView *) self.view restoreStackStateWithIdentifier: @"LabSolitaire"];
		if ((success == NO) || ([self countOfCardsOnTable] != 52))
		{
			// Either the archive was corrupt or non-existant, start a new game.
			printf ("-[CETableView restoreStackStateWithIdentifier:] failed in -[LabSolitaireViewCOntroller restoreState]\n");
			[self resetTable: YES];
		}
		else
		{
			_playedAtleastOneCard = [[NSUserDefaults standardUserDefaults] boolForKey: @"PlayedAtleastOneCard"];
			[_worriedCards removeAllObjects];
			[_worriedCards addObjectsFromArray: [[NSUserDefaults standardUserDefaults] arrayForKey: @"WorriedCards"]];
		}
	}
	else
	{
		// No saved game - start a new one.
		[self resetTable: YES];
	}
}

#pragma mark ------ actions
// ----------------------------------------------------------------------------------------------------------------- new

#define NEW_GAME_TITLE			NSLocalizedString (@"New Game Title", @"")
#define NEW_GAME_MESSAGE		NSLocalizedString (@"If you start a new game this game will count as a loss.", @"")
#define NEW_GAME_CANCEL_BUTTON	NSLocalizedString (@"Cancel", @"")
#define NEW_GAME_BUTTON			NSLocalizedString (@"New Game", @"")

- (void) new: (id) sender
{
	if (_playSounds)
	{
		[[SimpleAudioEngine sharedEngine] playEffect: @"ClickOpen.wav"];
	}
	
	if ((_playedAtleastOneCard == NO) || ([self allCardsArePutAway]))
	{
		if (_playSounds)
		{
			[[SimpleAudioEngine sharedEngine] playEffect: @"Shuffle.wav"];
		}
		
		// If the game is over, no need for alert.
		[self resetTable: YES];
	}
	else
	{
		UIAlertView	*alert;
		
		// A game is in progress, allow the user to cancel the new game.
		alert = [[UIAlertView alloc] initWithTitle: NEW_GAME_TITLE message: NEW_GAME_MESSAGE delegate: self 
				cancelButtonTitle: NEW_GAME_CANCEL_BUTTON otherButtonTitles: NEW_GAME_BUTTON, nil];
		alert.tag = kResetTableAlertTag;
		[alert show];
		[alert release];
	}
}

// ---------------------------------------------------------------------------------------------------------------- undo

- (void) undo: (id) sender
{
	// Ignore if player has help Undo button.
	if (_undoAllAlertOpen)
	{
		return;
	}
	
	// Kill Undo-held timer.
	if (_undoHeldTimer)
	{
		[_undoHeldTimer invalidate];
	}
	_undoHeldTimer = nil;
	
	if (_playSounds)
	{
		if ([[CETableView sharedCardUndoManager] canUndo])
		{
			[[SimpleAudioEngine sharedEngine] playEffect: @"Blip.wav"];
		}
		else
		{
			[[SimpleAudioEngine sharedEngine] playEffect: @"Buzz.wav"];
		}
	}
	
	[[CETableView sharedCardUndoManager] undo];
}

// ------------------------------------------------------------------------------------------------------------- undoAll

#define UNDO_TITLE			NSLocalizedString (@"Undo All Actions", @"")
#define UNDO_MESSAGE		NSLocalizedString (@"You can Undo all actions in this game.", @"")
#define UNDO_CANCEL_BUTTON	NSLocalizedString (@"Cancel", @"")
#define UNDO_ALL_BUTTON		NSLocalizedString (@"Undo All", @"")

- (void) undoAll: (id) sender
{
	if (([[CETableView sharedCardUndoManager] canUndo]) && ([self seedUsedLast] != NSNotFound))
	{
		UIAlertView	*alert;
		
		if (_playSounds)
		{
			[[SimpleAudioEngine sharedEngine] playEffect: @"ClickOpen.wav"];
		}
		
		_undoAllAlertOpen = YES;
		
		// Allow the player to decide if they want to Undo to the beginning of the game.
		alert = [[UIAlertView alloc] initWithTitle: UNDO_TITLE message: UNDO_MESSAGE delegate: self 
				cancelButtonTitle: UNDO_CANCEL_BUTTON otherButtonTitles: UNDO_ALL_BUTTON, nil];
		alert.tag = kUndoAllAlertTag;
		[alert show];
		[alert release];
	}
}

// ------------------------------------------------------------------------------------------------------- undoHeldTimer

- (void) undoHeldTimer: (NSTimer *) timer
{
	// Clean up timer.
	[timer invalidate];
	_undoHeldTimer = nil;
	
	[self undoAll: nil];
}

// ------------------------------------------------------------------------------------------------------------ undoDown

- (void) undoDown: (id) sender
{
	_undoHeldTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0 target: self 
			selector: @selector (undoHeldTimer:) userInfo: nil repeats: NO];
}

// ----------------------------------------------------------------------------------------------------- undoDragOutside

- (void) undoDragOutside: (id) sender
{
	// Dragging outside Undo button will kill Undo-held timer.
	if (_undoHeldTimer)
	{
		[_undoHeldTimer invalidate];
	}
	_undoHeldTimer = nil;
}

// ----------------------------------------------------------------------------------------- updateGlobalScoresInterface

- (void) updateGlobalScoresInterface
{
	NSMutableString	*allNames;
	NSMutableString	*allPlayed;
	NSMutableString	*allWon;
	NSMutableString	*allPercent;
	NSUInteger		count;
	unichar			carriageReturn = 0x000D;
	CGRect			frame;
	NSInteger		played = 0;
	NSInteger		won = 0;
	BOOL			appendedColon = NO;
	
	// Leaderboard alias's.
	allNames = [NSMutableString stringWithCapacity: 80];
	count = 0;
	if ((_leaderboardAliases) && ([_leaderboardAliases count] > 0))
	{
		for (NSString *name in _leaderboardAliases)
		{
			[allNames appendString: name];
			[allNames appendString: [NSString stringWithCharacters: &carriageReturn length: 1]];
			count = count + 1;
		}
		
		// Append player if they are not in the list.
		if (_playerLeaderboardIndex == NSNotFound)
		{
			if (count >= 10)
			{
				appendedColon = YES;
				[allNames appendString: @"     :"];
				[allNames appendString: [NSString stringWithCharacters: &carriageReturn length: 1]];
				count = count + 1;
			}
			if (_localPlayer.alias)
				[allNames appendString: _localPlayer.alias];
			else
				[allNames appendString: @"You"];
			count = count + 1;
		}
	}
	else
	{
		if (_localPlayer.alias)
			[allNames appendString: _localPlayer.alias];
		else
			[allNames appendString: @"You"];
		count = count + 1;
	}
	
	_globalScoreNameLabel.numberOfLines = count;
	frame = _globalScoreNameLabel.frame;
	frame.size.height = count * 20;
	_globalScoreNameLabel.frame = frame;
	_globalScoreNameLabel.text = allNames;
	
	// Leaderboard games played.
	allPlayed = [NSMutableString stringWithCapacity: 80];
	count = 0;
	if ([_leaderboardGamesPlayed count] > 0)
	{
		for (NSString *number in _leaderboardGamesPlayed)
		{
			[allPlayed appendString: number];
			[allPlayed appendString: [NSString stringWithCharacters: &carriageReturn length: 1]];
			count = count + 1;
		}
		
		// Append player's games played if they are not in the list.
		if (_playerLeaderboardIndex == NSNotFound)
		{
			if (appendedColon)
			{
				[allPlayed appendString: @":"];
				[allPlayed appendString: [NSString stringWithCharacters: &carriageReturn length: 1]];
				count = count + 1;
			}
			
			[_localPlayer retrieveLocalScore: &played forCategory: @"com.softdorothy.labsolitaire.games_played"];
			[allPlayed appendString: [NSString stringWithFormat: @"%ld", (long) played]];
			count = count + 1;
		}
	}
	else
	{
		[_localPlayer retrieveLocalScore: &played forCategory: @"com.softdorothy.labsolitaire.games_played"];
		[allPlayed appendString: [NSString stringWithFormat: @"%ld", (long) played]];
		count = count + 1;
	}
	
	_globalScorePlayedLabel.numberOfLines = count;
	frame = _globalScorePlayedLabel.frame;
	frame.size.height = count * 20;
	_globalScorePlayedLabel.frame = frame;
	_globalScorePlayedLabel.text = allPlayed;
	
	// Leaderboard games won.
	allWon = [NSMutableString stringWithCapacity: 80];
	count = 0;
	if ([_leaderboardGamesWon count] > 0)
	{
		for (NSString *number in _leaderboardGamesWon)
		{
			[allWon appendString: number];
			[allWon appendString: [NSString stringWithCharacters: &carriageReturn length: 1]];
			count = count + 1;
		}
		
		// Append player's games won if they are not in the list.
		if (_playerLeaderboardIndex == NSNotFound)
		{
			if (appendedColon)
			{
				[allWon appendString: @":"];
				[allWon appendString: [NSString stringWithCharacters: &carriageReturn length: 1]];
				count = count + 1;
			}
			
			[_localPlayer retrieveLocalScore: &won forCategory: @"com.softdorothy.labsolitaire.games_won"];
			[allWon appendString: [NSString stringWithFormat: @"%ld", (long )won]];
			count = count + 1;
		}
	}
	else
	{
		[_localPlayer retrieveLocalScore: &won forCategory: @"com.softdorothy.labsolitaire.games_won"];
		[allWon appendString: [NSString stringWithFormat: @"%ld", (long) won]];
		count = count + 1;
	}
	
	_globalScoreWonLabel.numberOfLines = count;
	frame = _globalScoreWonLabel.frame;
	frame.size.height = count * 20;
	_globalScoreWonLabel.frame = frame;
	_globalScoreWonLabel.text = allWon;
	
	// Leaderboard percentage games won.
	allPercent = [NSMutableString stringWithCapacity: 80];
	count = 0;
	if (([_leaderboardGamesPlayed count] > 0) && ([_leaderboardGamesWon count] > 0) && 
			([_leaderboardGamesPlayed count] == [_leaderboardGamesWon count]))
	{
		for (NSString *playedNumber in _leaderboardGamesPlayed)
		{
			NSInteger	gamesPlayed, gamesWon;
			
			gamesPlayed = [playedNumber integerValue];
			gamesWon = [[_leaderboardGamesWon objectAtIndex: count] integerValue];
			
			if (gamesPlayed == 0)
			{
				[allPercent appendString: @"-"];
				[allPercent appendString: [NSString stringWithCharacters: &carriageReturn length: 1]];				
			}
			else
			{
//				[allPercent appendString: [NSString stringWithFormat: @"%d%%", (gamesWon * 100) / gamesPlayed]];
				[allPercent appendString: [NSString stringWithFormat: @"%ld%%", (long) round (((CGFloat) gamesWon * 100.0) / (CGFloat) gamesPlayed)]];
				[allPercent appendString: [NSString stringWithCharacters: &carriageReturn length: 1]];				
			}
			
			count = count + 1;
		}
		
		// Append player's percentage games won if they are not in the list.
		if (_playerLeaderboardIndex == NSNotFound)
		{
			if (appendedColon)
			{
				[allPercent appendString: @":"];
				[allPercent appendString: [NSString stringWithCharacters: &carriageReturn length: 1]];
				count = count + 1;
			}
			if (played == 0)
				[allPercent appendString: @"-"];
			else
//				[allPercent appendString: [NSString stringWithFormat: @"%d%%", (won * 100) / played]];
				[allPercent appendString: [NSString stringWithFormat: @"%ld%%", (long) round (((CGFloat) won * 100.0) / (CGFloat) played)]];
			count = count + 1;
		}
	}
	else
	{
		if (played == 0)
			[allPercent appendString: @"-"];
		else
//			[allPercent appendString: [NSString stringWithFormat: @"%d%%", (won * 100) / played]];
			[allPercent appendString: [NSString stringWithFormat: @"%ld%%", (long) round (((CGFloat) won * 100.0) / (CGFloat) played)]];
		count = count + 1;
	}
	
	_globalScorePercentLabel.numberOfLines = count;
	frame = _globalScorePercentLabel.frame;
	frame.size.height = count * 20;
	_globalScorePercentLabel.frame = frame;
	_globalScorePercentLabel.text = allPercent;
	
	// Hide/show leaderboard scope UI.
	if (_localPlayer.usingGameCenter)
	{
		_displayScopeLabel.hidden = NO;
		_friendScopeButton.hidden = NO;
		_allScopeButton.hidden = NO;
		_scopeSelectedImage.hidden = NO;
	}
	else
	{
		_displayScopeLabel.hidden = YES;
		_friendScopeButton.hidden = YES;
		_allScopeButton.hidden = YES;
		_scopeSelectedImage.hidden = YES;
	}
	
	// Leaderboard local player highlight.
	frame = _highlightView.frame;
	if (_leaderboardAliases)
	{
		if (_playerLeaderboardIndex == NSNotFound)
		{
			if (appendedColon)
				frame.origin.y = kHighlighterVOffset + ((kMaxLeaderboardScores + 1) * 20);
			else
				frame.origin.y = kHighlighterVOffset + ([_leaderboardAliases count] * 20);
		}
		else
		{
			frame.origin.y = kHighlighterVOffset + (_playerLeaderboardIndex * 20);
		}
	}
	else
	{
		frame.origin.y = kHighlighterVOffset;
	}
	_highlightView.frame = frame;
}

// ---------------------------------------------------------------------------------------------------------------- info

- (void) info: (id) sender
{
	if (_playSounds)
	{
		[[SimpleAudioEngine sharedEngine] playEffect: @"ClickOpen.wav"];
	}
	
	_infoViewIsOpen = YES;
	_wasAutoPutaway = _autoPutaway;
	_wasAutoPutawayMode = _autoPutawayMode;
	
	// Refresh the global scores.
	if ((_localPlayer.usingGameCenter) && (_localPlayer.authenticated))
	{
		[_localPlayer retrieveLeaderboardScores: kMaxLeaderboardScores forCategory: @"com.softdorothy.labsolitaire.games_won" 
				friendsOnly: _leaderboardFriendsOnly];
	}
	else
	{
		// Update the UI.
		[self updateGlobalScoresInterface];
	}
	
    [_aboutViewController setModalPresentationStyle: UIModalPresentationOverCurrentContext];
    [self presentViewController: _aboutViewController animated: YES completion: nil];
	
	// Initially begin with "about view" being displayed.
	_currentInfoView = _aboutView;
	
	_aboutView.alpha = 1.0;
	[_darkView addSubview: _aboutView];
	
	// Capture touch events.
	_darkView.userInteractionEnabled = YES;
	
	// Animate-in the view sliding in while the dark view becomes darker.
	[UIView beginAnimations: @"SlideInInfoView" context: nil];
	[UIView setAnimationDuration: 0.5];
	_darkView.backgroundColor = [UIColor colorWithWhite: 0.0 alpha: 0.75];
	[self _positionSubviewBottomAndCentered: _aboutView];
	[UIView commitAnimations];
}

// ------------------------------------------------------------------------------------------ openLabSolitaireInAppStore

- (void) openLabSolitaireInAppStore: (id) sender
{
	[[UIApplication sharedApplication] openURL: 
			[NSURL URLWithString: @"itms-apps://itunes.apple.com/app/lab-solitaire/id457535509?ls=1&mt=8"]];
}

// -------------------------------------------------------------------------------------- openParlourSolitaireInAppStore

- (void) openParlourSolitaireInAppStore: (id) sender
{
	[[UIApplication sharedApplication] openURL: 
			[NSURL URLWithString: @"itms-apps://itunes.apple.com/app/parlour-solitaire/id465002121?ls=1&mt=8"]];
}

// ------------------------------------------------------------------------------------------------ openGliderInAppStore

- (void) openGliderInAppStore: (id) sender
{
	[[UIApplication sharedApplication] openURL: 
			[NSURL URLWithString: @"itms-apps://itunes.apple.com/app/glider-classic/id463484447?mt=8"]];
}

// --------------------------------------------------------------------------------------------- updateSettingsInterface

- (void) updateSettingsInterface
{
	CGRect	frame;
	
	// Auto-putaway.
	if (_autoPutaway)
	{
		[_autoPutawayButton setImage: [UIImage imageNamed: @"CheckYes"] forState: UIControlStateNormal];
		_smartPutawayModeLabel.alpha = 1.0;
		_putawaySelectedImage.alpha = 1.0;
		_smartPutawayButton.alpha = 1.0;
		_allPutawayButton.alpha = 1.0;
	}
	else
	{
		[_autoPutawayButton setImage: [UIImage imageNamed: @"CheckNo"] forState: UIControlStateNormal];
		_smartPutawayModeLabel.alpha = 0.33;
		_putawaySelectedImage.alpha = 0.0;
		_smartPutawayButton.alpha = 0.33;
		_allPutawayButton.alpha = 0.33;
	}
	
	// Auto-putaway mode.
	frame = _putawaySelectedImage.frame;
	if (_autoPutawayMode == kAutoPutawayModeSmart)
		frame.origin.x = CGRectGetMinX (_smartPutawayButton.frame) + round ((CGRectGetWidth (_smartPutawayButton.frame) - CGRectGetWidth (frame)) / 2.0);
	else
		frame.origin.x = CGRectGetMinX (_allPutawayButton.frame) + round ((CGRectGetWidth (_allPutawayButton.frame) - CGRectGetWidth (frame)) / 2.0);
	_putawaySelectedImage.frame = frame;
	
	if (_autoPutawayMode == kAutoPutawayModeSmart)
	{
		[_smartPutawayButton setTitleColor: [UIColor colorWithWhite: 0.2 alpha: 1.0]  forState: UIControlStateNormal];
		[_smartPutawayButton setTitleColor: [UIColor colorWithWhite: 0.2 alpha: 1.0] forState: UIControlStateHighlighted];
		[_allPutawayButton setTitleColor: [UIColor colorWithRed: 0.0 green: 0.0 blue: 0.5 alpha: 0.8] forState: UIControlStateNormal];
		[_allPutawayButton setTitleColor: [UIColor colorWithRed: 0.72 green: 0.03 blue: 0.09 alpha: 1.0] forState: UIControlStateHighlighted];
	}
	else
	{
		[_smartPutawayButton setTitleColor: [UIColor colorWithRed: 0.0 green: 0.0 blue: 0.5 alpha: 0.8] forState: UIControlStateNormal];
		[_smartPutawayButton setTitleColor: [UIColor colorWithRed: 0.72 green: 0.03 blue: 0.09 alpha: 1.0] forState: UIControlStateHighlighted];
		[_allPutawayButton setTitleColor: [UIColor colorWithWhite: 0.2 alpha: 1.0]  forState: UIControlStateNormal];
		[_allPutawayButton setTitleColor: [UIColor colorWithWhite: 0.2 alpha: 1.0] forState: UIControlStateHighlighted];
	}
	
	// Play sounds.
	if (_playSounds)
		[_playSoundsButton setImage: [UIImage imageNamed: @"CheckYes"] forState: UIControlStateNormal];
	else
		[_playSoundsButton setImage: [UIImage imageNamed: @"CheckNo"] forState: UIControlStateNormal];
	
	// Leaderboard scope.
	frame = _scopeSelectedImage.frame;
	if (_leaderboardFriendsOnly)
		frame.origin.x = CGRectGetMinX (_friendScopeButton.frame) + round ((CGRectGetWidth (_friendScopeButton.frame) - CGRectGetWidth (frame)) / 2.0);
	else
		frame.origin.x = CGRectGetMinX (_allScopeButton.frame) + round ((CGRectGetWidth (_allScopeButton.frame) - CGRectGetWidth (frame)) / 2.0);
	_scopeSelectedImage.frame = frame;
	
	if (_leaderboardFriendsOnly)
	{
		[_friendScopeButton setTitleColor: [UIColor colorWithWhite: 0.2 alpha: 1.0]  forState: UIControlStateNormal];
		[_friendScopeButton setTitleColor: [UIColor colorWithWhite: 0.2 alpha: 1.0] forState: UIControlStateHighlighted];
		[_allScopeButton setTitleColor: [UIColor colorWithRed: 0.0 green: 0.0 blue: 0.5 alpha: 0.8] forState: UIControlStateNormal];
		[_allScopeButton setTitleColor: [UIColor colorWithRed: 0.72 green: 0.03 blue: 0.09 alpha: 1.0] forState: UIControlStateHighlighted];
	}
	else
	{
		[_friendScopeButton setTitleColor: [UIColor colorWithRed: 0.0 green: 0.0 blue: 0.5 alpha: 0.8] forState: UIControlStateNormal];
		[_friendScopeButton setTitleColor: [UIColor colorWithRed: 0.72 green: 0.03 blue: 0.09 alpha: 1.0] forState: UIControlStateHighlighted];
		[_allScopeButton setTitleColor: [UIColor colorWithWhite: 0.2 alpha: 1.0]  forState: UIControlStateNormal];
		[_allScopeButton setTitleColor: [UIColor colorWithWhite: 0.2 alpha: 1.0] forState: UIControlStateHighlighted];
	}
}

// -------------------------------------------------------------------------------------- updateLocalStatisticsInterface

- (void) updateLocalStatisticsInterface
{
	NSInteger	gamesPlayed;
	NSInteger	gamesWon;
	
	// Get number of games played and won.
	[_localPlayer retrieveLocalScore: &gamesPlayed forCategory: @"com.softdorothy.labsolitaire.games_played"];
	_gamesPlayedLabel.text = [NSString stringWithFormat: @"%ld", (long) gamesPlayed];
	
	[_localPlayer retrieveLocalScore: &gamesWon forCategory: @"com.softdorothy.labsolitaire.games_won"];
	_gamesWonLabel.text = [NSString stringWithFormat: @"%ld", (long) gamesWon];
	
	if (gamesPlayed != 0)
	{
		_gamesWonPercentageLabel.text = [NSString stringWithFormat: @"%ld%%", (long) round (((CGFloat) gamesWon * 100.0) / (CGFloat) gamesPlayed)];
	}
	else
	{
		_gamesWonPercentageLabel.text = @"-";
	}
}

// -------------------------------------------------------------------------------------------------

- (void) _positionSubviewBottomAndCentered: (UIView *) subview
{
	// Get main bounds and orientation.
	CGRect mainBounds = [[UIScreen mainScreen] bounds];
	BOOL portrait = UIInterfaceOrientationIsPortrait ([UIApplication sharedApplication].statusBarOrientation);
	
	CGRect frame = subview.frame;
	if (portrait)
	{
		frame.origin = CGPointMake ((mainBounds.size.width - frame.size.width) / 2.0, mainBounds.size.height - frame.size.height);
	}
	else
	{
		frame.origin = CGPointMake ((mainBounds.size.height - frame.size.width) / 2.0, mainBounds.size.width - frame.size.height);
	}
	subview.frame = frame;
}

// -------------------------------------------------------------------------------------------------

- (void) _addInfoSubview: (UIView *) subview
{
	if (_playSounds)
	{
		[[SimpleAudioEngine sharedEngine] playEffect: @"ClickOpen.wav"];
	}
	
	// Switch to display the subview.
	subview.alpha = 0.0;
	[_darkView addSubview: subview];
	[self _positionSubviewBottomAndCentered: subview];
	
	// Fade-out the previous view while fading in the new one.
	[UIView beginAnimations: @"CrossfadeInfoSubview" context: _aboutView];
	[UIView setAnimationDelegate: self];
	[UIView setAnimationDidStopSelector: @selector (animationStopped:finished:context:)];
	subview.alpha = 1.0;
	_currentInfoView.alpha = 0.0;
	[UIView commitAnimations];
}

// -------------------------------------------------------------------------------------------------

- (void) aboutInfo: (id) sender
{
	// Switch to display the "nfo view".
	[self _addInfoSubview: _aboutView];
}

// -------------------------------------------------------------------------------------------------

- (void) rulesInfo: (id) sender
{
	// Switch to display the "rules view".
	[self _addInfoSubview: _rulesView];
}

// -------------------------------------------------------------------------------------------------

- (void) settingsInfo: (id) sender
{
	// Switch to display the "settings view".
	[self _addInfoSubview: _settingsView];
}

// ----------------------------------------------------------------------------------------------------------- closeInfo

- (void) closeInfo: (id) sender
{
	CGRect		mainBounds;
	BOOL		portrait;
	CGRect		frame;
	
	if (_playSounds)
	{
		[[SimpleAudioEngine sharedEngine] playEffect: @"ClickClose.wav"];
	}
	
    [_aboutViewController dismissViewControllerAnimated: YES completion: nil];
    
	mainBounds = [[UIScreen mainScreen] bounds];
	portrait = UIInterfaceOrientationIsPortrait ([UIApplication sharedApplication].statusBarOrientation);
	
	// Animate-out the view sliding out while the dark view becomes clear again.
	[UIView beginAnimations: @"SlideOutInfoView" context: nil];
	[UIView setAnimationDuration: 0.5];
	[UIView setAnimationDelegate: self];
	[UIView setAnimationDidStopSelector: @selector (animationStopped:finished:context:)];
	_darkView.backgroundColor = [UIColor colorWithWhite: 0.0 alpha: 0.0];
	frame = _currentInfoView.frame;
	if (portrait)
	{
		frame.origin = CGPointMake ((mainBounds.size.width - frame.size.width) / 2.0, mainBounds.size.height);
	}
	else
	{
		frame.origin = CGPointMake ((mainBounds.size.height - frame.size.width) / 2.0, mainBounds.size.width);
	}
	_currentInfoView.frame = frame;
	[UIView commitAnimations];
	
	// If this is the first time we are dismissing the info view after launching the app.
	if (_splashDismissed == NO)
	{
		_splashDismissed = YES;
		
		// See if cards can be put up.
		if (_autoPutaway)
		{
			_putawayTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0 target: self 
					selector: @selector (putawayTimer:) userInfo: nil repeats: NO];
		}
	}
}

// --------------------------------------------------------------------------------------------------- toggleAutoPutaway

- (void) toggleAutoPutaway: (id) sender
{
	NSUserDefaults	*defaults;
	
	// Toggle preference.
	_autoPutaway = !_autoPutaway;
	
	// Store auto-putaway preference.
	defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject: [NSNumber numberWithBool: _autoPutaway] forKey: @"AutoPutaway"];
	[defaults synchronize];
	
	// Sound effect.
	if ((_playSounds) && (_autoPutaway == YES))
	{
		[[SimpleAudioEngine sharedEngine] playEffect: @"ClickOpen.wav"];
	}
	
	if ((_playSounds) && (_autoPutaway == NO))
	{
		[[SimpleAudioEngine sharedEngine] playEffect: @"ClickClose.wav"];
	}
	
	// Update UI.
	[self updateSettingsInterface];
}

// ----------------------------------------------------------------------------------------------- selectAutoPutawayMode

- (void) selectAutoPutawayMode: (id) sender
{
	NSUserDefaults	*defaults;
	
	// NOP.
	if (_autoPutawayMode == [sender tag])
		return;
	
	// Assign new auto-putaway mode.
	_autoPutawayMode = [sender tag];
	
	// Store auto-putaway preference.
	defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject: [NSNumber numberWithInteger: _autoPutawayMode] forKey: @"AutoPutawayMode"];
	[defaults synchronize];
	
	if (_playSounds)
	{
		[[SimpleAudioEngine sharedEngine] playEffect: @"ClickOpen.wav"];
	}
	
	// Update UI.
	[self updateSettingsInterface];
}

// --------------------------------------------------------------------------------------------------------- toggleSound

- (void) toggleSound: (id) sender
{
	NSUserDefaults	*defaults;
	
	// Toggle preference.
	_playSounds = !_playSounds;
	
	// Store play-sounds preference.
	defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject: [NSNumber numberWithBool: _playSounds] forKey: @"PlaySounds"];
	[defaults synchronize];

	// Sound effect.
	if (_playSounds)
	{
		[[SimpleAudioEngine sharedEngine] playEffect: @"ClickOpen.wav"];
	}
	
	// Update UI.
	if (_playSounds)
	{
		[sender setImage: [UIImage imageNamed: @"CheckYes"] forState: UIControlStateNormal];
	}
	else
	{
		[sender setImage: [UIImage imageNamed: @"CheckNo"] forState: UIControlStateNormal];
	}
}

// ---------------------------------------------------------------------------------------------- selectLeaderboardScope

- (void) selectLeaderboardScope: (id) sender
{
	NSUserDefaults	*defaults;
	
	if ([sender tag] == 0)
	{
		// NOP.
		if (_leaderboardFriendsOnly == YES)
		{
			return;
		}
		
		_leaderboardFriendsOnly = YES;
	}
	else
	{
		// NOP.
		if (_leaderboardFriendsOnly == NO)
		{
			return;
		}
		
		_leaderboardFriendsOnly = NO;
	}
	
	// Store auto-putaway preference.
	defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject: [NSNumber numberWithBool: _leaderboardFriendsOnly] forKey: @"LeaderboardScope"];
	[defaults synchronize];
	
	if (_playSounds)
	{
		[[SimpleAudioEngine sharedEngine] playEffect: @"ClickOpen.wav"];
	}
	
	// Update UI.
	[self updateSettingsInterface];
	[_localPlayer retrieveLeaderboardScores: kMaxLeaderboardScores forCategory: @"com.softdorothy.labsolitaire.games_won" 
			friendsOnly: _leaderboardFriendsOnly];
}

// ---------------------------------------------------------------------------------------------------- openGameOverView

- (void) openGameOverView: (id) sender
{
	if (_infoViewIsOpen)
	{
		// Player won sound.
		if (_playSounds)
		{
			[[SimpleAudioEngine sharedEngine] playEffect: @"Babip.wav"];
		}
		
		// Switch to display the "game over view".
		_gameOverView.alpha = 0.0;
		[_darkView addSubview: _gameOverView];
		
		// Update statistics.
		[self updateLocalStatisticsInterface];
		
		// Animate-out the view sliding out while the dark view becomes clear again.
		[UIView beginAnimations: @"CrossfadeInfoSubview" context: _gameOverView];
		[UIView setAnimationDelegate: self];
		[UIView setAnimationDidStopSelector: @selector (animationStopped:finished:context:)];
		_gameOverView.alpha = 1.0;
		_currentInfoView.alpha = 0.0;
		[UIView commitAnimations];
	}
	else
	{
		_infoViewIsOpen = YES;
		
		// Add "Game Over" view.
		[_darkView addSubview: _gameOverView];
		_currentInfoView = _gameOverView;
		
		// Update statistics.
		[self updateLocalStatisticsInterface];
		
		// Capture touch events.
		_darkView.userInteractionEnabled = YES;
		
		// Animate-in the view sliding in while the dark view becomes darker.
		[UIView beginAnimations: @"SlideInInfoView" context: nil];
		[UIView setAnimationDuration: 0.5];
		[UIView setAnimationDelegate: self];
		[UIView setAnimationDidStopSelector: @selector (animationStopped:finished:context:)];
		_darkView.backgroundColor = [UIColor colorWithWhite: 0.0 alpha: 0.75];
		[self _positionSubviewBottomAndCentered: _gameOverView];
		[UIView commitAnimations];
	}
}

// ----------------------------------------------------------------------------------- animationDidStop:finished:context

- (void) animationStopped: (NSString *) animationID finished: (NSNumber *) finished context: (void *) context
{
	if ([animationID isEqualToString: @"SlideInInfoView"])
	{
		if (_currentInfoView == _gameOverView)
		{
			// Player won sound.
			if (_playSounds)
			{
				[[SimpleAudioEngine sharedEngine] playEffect: @"Babip.wav"];
			}
		}
	}
	else if ([animationID isEqualToString: @"SlideOutInfoView"])
	{
		_infoViewIsOpen = NO;
		
		// No longer capture touch events.
		_darkView.userInteractionEnabled = NO;
		
		if (_currentInfoView)
		{
			[_currentInfoView removeFromSuperview];
			_currentInfoView = nil;
		}
		
		// Fire off auto-putaway timer if the user enabled it.
		if (_autoPutaway)
		{
			// If the player has 'worried back' cards in "All" putaway mode, we should clear that history and mark the 
			// cards 'worry free'.
			if ((_wasAutoPutawayMode == kAutoPutawayModeAll) && (_autoPutawayMode == kAutoPutawayModeSmart))
			{
				[_worriedCards removeAllObjects];
			}
			
			// Fire off timer to look for cards to put up.
			if ((_wasAutoPutaway == NO) || ((_wasAutoPutawayMode == kAutoPutawayModeSmart) && (_autoPutawayMode == kAutoPutawayModeAll)))
			{
				_putawayTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0 target: self selector: 
						@selector (putawayTimer:) userInfo: nil repeats: NO];
			}
		}
		
		// Start new game.
		if (_gameWon)
		{
			// Shuffle sound.
			if (_playSounds)
			{
				[[SimpleAudioEngine sharedEngine] playEffect: @"Shuffle.wav"];
			}
			
			// Deal new hand.
			[self resetTable: YES];
		}
	}
	else if ([animationID isEqualToString: @"CrossfadeInfoSubview"])
	{
		[_currentInfoView removeFromSuperview];
		_currentInfoView = context;
		[_darkView bringSubviewToFront: _currentInfoView];
	}
}

#pragma mark ------ view controller methods
// ------------------------------------------------------------- willRotateToInterfaceOrientation:toInterfaceOrientation

- (void) willRotateToInterfaceOrientation: (UIInterfaceOrientation) orientation duration: (NSTimeInterval) duration
{
	[self adjustLayoutForOrientation: orientation];
}

/*
- (void) willAnimateFirstHalfOfRotationToInterfaceOrientation: (UIInterfaceOrientation) toOrientation duration: (NSTimeInterval) duration
{
}

- (void) didAnimateFirstHalfOfRotationToInterfaceOrientation: (UIInterfaceOrientation) toOrientation
{
}

- (void) willAnimateSecondHalfOfRotationFromInterfaceOrientation: (UIInterfaceOrientation) fromOrientation duration: (NSTimeInterval) duration
{
}
*/

// ------------------------------------------------------------------------------ shouldAutorotateToInterfaceOrientation

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) orientation
{
	return YES;
}

// --------------------------------------------------------------------------------------------- didReceiveMemoryWarning

- (void) didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void) viewDidLoad
{
//	if ([self respondsToSelector:@selector(topLayoutGuide)])
//	{
//		[self.view removeConstraint: self.containerTopSpaceConstraint];
//		
//		self.containerTopSpaceConstraint = [NSLayoutConstraint constraintWithItem: self.contentView 
//				attribute: NSLayoutAttributeTop relatedBy: NSLayoutRelationEqual toItem: self.topLayoutGuide
//				attribute: NSLayoutAttributeBottom multiplier: 1 constant: 0];
//		
//		[self.view addConstraint: self.containerTopSpaceConstraint];
//		[self.view setNeedsUpdateConstraints];
//		[self.view layoutIfNeeded];
//	}
}

// ------------------------------------------------------------------------------------------------------- viewDidUnload

- (void) viewDidUnload
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	[_newButton release];
	[_undoButton release];
	[_infoButton release];
}

// ------------------------------------------------------------------------------------------------------------- dealloc

- (void) dealloc
{
	// No more observing.
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	// Clean up timers.
	if (_putawayTimer)
	{
		[_putawayTimer invalidate];
	}
	_putawayTimer = nil;
	if (_undoHeldTimer)
	{
		[_undoHeldTimer invalidate];
	}
	_undoHeldTimer = nil;
	
	// Super.
	[super dealloc];
}


#pragma mark ------ alert view delegate methods
//--------------------------------------------------------------------------------------- alertView:clickedButtonAtIndex

- (void) alertView: (UIAlertView *) alertView clickedButtonAtIndex: (NSInteger) buttonIndex
{
	if (alertView.tag == kResetTableAlertTag)
	{
		if (buttonIndex == 1)		// New game.
		{
			if (_playSounds)
			{
				[[SimpleAudioEngine sharedEngine] playEffect: @"Shuffle.wav"];
			}
			
			[self resetTable: YES];
		}
	}
	else if (alertView.tag == kUndoAllAlertTag)
	{
		_undoAllAlertOpen = NO;
		
		if (buttonIndex == 1)		// Undo all.
		{
			if (_playSounds)
			{
				[[SimpleAudioEngine sharedEngine] playEffect: @"Shuffle.wav"];
			}
			
			[self resetTable: NO];
		}
	}
}

#pragma mark ------ stack view delegate methods
// --------------------------------------------------------------------------------------------- stackView:allowDragCard

- (BOOL) stackView: (CEStackView *) stackView allowDragCard: (CECard *) card
{
	NSUInteger	cardIndex;
	NSUInteger	cardCount;
	NSUInteger	numberOfCardsDragging;
	NSUInteger	i;
	int			emptyCellCount = 0;
	int			emptyTableauCount = 0;
	CECard		*cardTesting;
	BOOL		wholeColumnDrag;
	BOOL		allowDrag = NO;
	
#if DISALLOW_TOUCHES_IF_ANIMATION
	// Skip out if any stack is animating. For example, when the game is wrapping up, a lot of cards are flying up to 
	// the foundation, you would not allow a card to be dragged at this time.
	if ([(CETableView *) self.view animationInProgress])
		return NO;
#endif	// DISALLOW_TOUCHES_IF_ANIMATION
	
	// Assume, initially, no drag restrictions.
	_dragRestriction = kNoDragRestriction;
	
	// We allow dragging back from the foundation ("worrying back" a card). We have to mark it as such though if 
	// auto-putaway is true (since, it will just get put up again).
	if ((_autoPutaway) && ([[stackView identifier] isEqualToString: @"Foundation"]))
	{
		[self worryBackCard: card];
		allowDrag = YES;
		goto done;
	}
	
	// The player will always be allowed to drag the top card of a stack.
	if (card == [[stackView stack] topCard])
	{
		allowDrag = YES;
		goto done;
	}
	
	// Get the index of the card attempting to be dragged and the number of cards in the stack.
	cardIndex = [[stackView stack] indexForCard: card];
	cardCount = [[stackView stack] numberOfCards];
	
	// We determine how many cards the player is attempting to drag.
	numberOfCardsDragging = (cardCount - cardIndex);
	
	// See how many empty columns there are.
	for (i = 0; i < 8; i++)
	{
		if ([_tableauViews[i].stack topCard] == nil)
			emptyTableauCount = emptyTableauCount + 1;
	}
	
	// We'll allow the player to drag an entire column to an empty column.
	wholeColumnDrag = ((emptyTableauCount > 0) && (numberOfCardsDragging == cardCount));
	
	// Validate first that each card atop the one attempting to be dragged follows down in rank and alternates in color.
	for (i = cardIndex + 1; i < cardCount; i++)
	{
		cardTesting = [[stackView stack] cardAtIndex: i];
		
		// Can't drag if the color sequence of the stack do not alternate.
		if ([card cardIsOppositeColor: cardTesting] == NO)
			goto evaluateWholeColumnDrag;
		
		// The card rank must increase exactly by one.
		if ((cardTesting.rank + 1) != card.rank)
			goto evaluateWholeColumnDrag;
		
		// This will be the card to test for in the next pass through the loop.
		card = cardTesting;
	}
	
	// See how many empty free-cells there are.
	for (i = 0; i < 4; i++)
	{
		if ([_cellViews[i].stack topCard] == nil)
			emptyCellCount = emptyCellCount + 1;
	}
	
	// Take into consideration empty cells and tableau columns.
	if (emptyTableauCount > 0)
	{
		NSInteger	unrestrictedNumberCanDrag;
		NSInteger	restrictedNumberCanDrag;
		
		// An empty tableau column allows us to drag double the number we would be able to drag with empty cells alone.
		// However, there is a restriction that we cannot drag these cards to one of the empty columns. If that is the 
		// case then we have to subtract one of the empty columns from out calculation.
		
		// With no restrictions however, we are free to drag (empty cells + 1) x (empty columns - 1) x 2.
		if (emptyTableauCount > 1)
			unrestrictedNumberCanDrag = (emptyCellCount + 1) * ((emptyTableauCount - 1) * 2);
		else
			unrestrictedNumberCanDrag = emptyCellCount + 1;
		
		// With restrictions we can drag up to (empty cells + 1) x empty columns x 2.
		restrictedNumberCanDrag = (emptyCellCount + 1) * (emptyTableauCount * 2);
		
		// We allow the drag if it meets restricted (larger of the two) drag limitation.
		allowDrag = numberOfCardsDragging <= restrictedNumberCanDrag;
		
		// However, if we are not less than the free drag limitation, we indicate that the drag is restricted and we 
		// will disallow the user from dragging to an empty column.
		if ((allowDrag) && (numberOfCardsDragging > unrestrictedNumberCanDrag) && (wholeColumnDrag == NO))
		{
			_dragRestriction = kDisallowEmptyColumnDragRestriction;
			
			// Display "Cross" over empty columns to indicate the player cannot drag the stack there.
			for (i = 0; i < 8; i++)
			{
				if ([_tableauViews[i].stack topCard] == nil)
				{
					[_tableauViews[i] setLabelColor: [UIColor colorWithRed: 0.5 green: 0.0 blue: 0.0 alpha: 0.5]];
					_tableauViews[i].label = [NSString stringWithFormat: @"%C", (unichar) 0x2613];
				}
			}
		}
	}
	else
	{
		// No empty columns, whether we can drag the stack depends solely on whether there are enough free cells.
		allowDrag = numberOfCardsDragging <= (emptyCellCount + 1);
	}
	
evaluateWholeColumnDrag:
	
	// Allow player to drag the *entire* column, with the restriction they can *only* drag to an empty tableau column.
	if ((allowDrag == NO) && (wholeColumnDrag == YES))
	{
		allowDrag = YES;
		_dragRestriction = kEmptyColumnOnlyDragRestriction;
		
		// Display "Marujirushi" over empty columns to indicate the player can drag the stack there.
		for (i = 0; i < 8; i++)
		{
			if ([_tableauViews[i].stack topCard] == nil)
			{
				[_tableauViews[i] setLabelColor: [UIColor colorWithRed: 0.0 green: 0.5 blue: 0.0 alpha: 0.5]];
				_tableauViews[i].label = [NSString stringWithFormat: @"%C", (unichar) 0x25CB];
			}
		}
	}
	
done:
	
	return allowDrag;
}

// --------------------------------------------------------------------------------- stackView:allowDragCard:toStackView

- (BOOL) stackView: (CEStackView *) stackView allowDragCard: (CECard *) card toStackView: (CEStackView *) dest
{
	CECard	*topDestCard;
	BOOL	allow = NO;
	
#if DISALLOW_DRAGTO_IF_ANIMATION
	if ([(CETableView *) self.view animationInProgress])
		goto bail;
#endif	// DISALLOW_DRAGTO_IF_ANIMATION
	
	// What is the top card on the stack view the player is dragging to?
	topDestCard = [[dest stack] topCard];
	
	// Do we have a top card (if not, we're dragging to an empty stack)?
	if (topDestCard)
	{
		// If there is a card (the destination stack is not empty).
		// Handle the case when the destination stack is the foundation.
		if ([[dest identifier] isEqualToString: @"Foundation"])
		{
			// The card being dragged must be one rank higher than the top card on the foundation, and match its suit.
			if ((card.rank == (topDestCard.rank + 1)) && (card.suit == topDestCard.suit) && ([[stackView stack] topCard] == card))
			{
				allow = YES;
				goto bail;
			}
		}
		else if ([[dest identifier] isEqualToString: @"Cell"])
		{
			// If there is already a card in the cell, the player may not drag another card there.
			allow = NO;
			goto bail;
		}
		else
		{
			// If the stack is the tableau, the rank of the card being dragged must be one smaller and opposite in color.
			if (_dragRestriction == kEmptyColumnOnlyDragRestriction)
				allow = NO;
			else
				allow = (((card.rank + 1) == topDestCard.rank) && ([card cardIsOppositeColor: topDestCard] == YES));
			goto bail;
		}
	}
	else
	{
		// Empty stack. Allow an ace only on foundations, any card may be placed in empty cells or on empty tableua columns.
		if ([[dest identifier] isEqualToString: @"Foundation"])
		{
			// Foundation - since no card on foundation, card must be an Ace.
			if ((card.rank == kCERankAce) && (dest == _foundationViews[card.suit]) && ([[stackView stack] topCard] == card))
			{
				allow = YES;
				goto bail;
			}
		}
		else if ([[dest identifier] isEqualToString: @"Cell"])
		{
			// Cell - only a single card can be dragged, but any one allowed.
			if ([[stackView stack] topCard] == card)
			{
				allow = YES;
				goto bail;
			}
		}
		else
		{
			// Tableau - since no card on tableau, any card allowed (unless a restricted drag).
			if (_dragRestriction == kDisallowEmptyColumnDragRestriction)
				allow = NO;
			else
				allow = YES;
			goto bail;
		}
	}
	
bail:
	
	return allow;
}

// --------------------------------------------------------------------------------------- stackView:cardWasDoubleTapped

- (void) stackView: (CEStackView *) view cardWasDoubleTapped: (CECard *) card
{
	CEStackView	*foundationView;
	NSInteger	emptyTableauColumn = -1;
	NSInteger	i;
	BOOL		cardMoved = NO;
	
	// Only double-tap on top card is allowed.
	if ([[view stack] topCard] != card)
		return;
	
	// Disallow double-tapping the foundation if auto-putaway is true (since, it will just get put up again).
	if ((_autoPutaway) && ([[view identifier] isEqualToString: @"Foundation"]))
		return;
	
#if DISALLOW_TOUCHES_IF_ANIMATION
	// Skip out if any stack is animating.
	if ([(CETableView *) self.view animationInProgress])
		return;
#endif	// DISALLOW_TOUCHES_IF_ANIMATION
	
	// Check first to see if card can be put up in the foundation (we use auto-putaway rules).
	if (_autoPutawayMode == kAutoPutawayModeSmart)
		foundationView = [self foundationToPutAwayCardSmart: card];
	else
		foundationView = [self foundationToPutAwayCardAll: card];
	if (foundationView != nil)
	{
		[view dealTopCardToStackView: _foundationViews[card.suit] faceUp: YES duration: kDealAnimationDuration];
		[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: kDealAnimationDelay]];
		cardMoved = YES;
		goto done;
	}
	
	// Check next for a match on an occupied tableau column.
	for (i = 0; i < 8; i++)
	{
		CECard	*topCard;
		
		// Get top card for tableau column. Skip if no cards in column
		topCard = [_tableauViews[i].stack topCard];
		if (topCard == nil)
		{
			// Note empty tableau column, we may use it later.
			if (emptyTableauColumn == -1)
				emptyTableauColumn = i;
			continue;
		}
		
		// Test if the top card is of the opposite color and if the rank is one larger than the card tapped on.
		if (((topCard.rank) == card.rank + 1) && ([card cardIsOppositeColor: topCard] == YES))
		{
			[view dealTopCardToStackView: _tableauViews[i] faceUp: YES duration: kDealAnimationDuration];
			[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: kDealAnimationDelay]];
			cardMoved = YES;
			goto done;
		}
	}
	
	// We make a special case for Kings: we look first for an empty tableau column rather than an empty cell.
	if ((card.rank == kCERankKing) && (emptyTableauColumn != -1))
	{
		[view dealTopCardToStackView: _tableauViews[emptyTableauColumn] faceUp: YES duration: kDealAnimationDuration];
		[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: kDealAnimationDelay]];
		cardMoved = YES;
		goto done;
	}
	
	// If the card double-tapped is in a cell already, look first for an empty tableau.
	if ([view.identifier isEqualToString: @"Cell"])
	{
		if (emptyTableauColumn != -1)
		{
			[view dealTopCardToStackView: _tableauViews[emptyTableauColumn] faceUp: YES duration: kDealAnimationDuration];
			[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: kDealAnimationDelay]];
			cardMoved = YES;
			goto done;
		}
	}
	else
	{
		// Failing the above tests, we will look for an empty cell.
		for (i = 0; i < 4; i++)
		{
			// Looking for an empty cell.
			if ([_cellViews[i].stack topCard] == nil)
			{
				[view dealTopCardToStackView: _cellViews[i] faceUp: YES duration: kDealAnimationDuration];
				[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: kDealAnimationDelay]];
				cardMoved = YES;
				goto done;
			}
		}
		
		// No empty cells, then finally use an empty tableau columns if we had previously found one.
		if (emptyTableauColumn != -1)
		{
			[view dealTopCardToStackView: _tableauViews[emptyTableauColumn] faceUp: YES duration: kDealAnimationDuration];
			[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: kDealAnimationDelay]];
			cardMoved = YES;
			goto done;
		}
	}
	
	// Finally, at this point let's relax the "Smart" guidance and see if the Foundation will accomodate the card after all.
	if (_autoPutawayMode == kAutoPutawayModeSmart)
	{
		foundationView = [self foundationToPutAwayCardAll: card];
		if (foundationView != nil)
		{
			[view dealTopCardToStackView: _foundationViews[card.suit] faceUp: YES duration: kDealAnimationDuration];
			[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: kDealAnimationDelay]];
			cardMoved = YES;
			goto done;
		}
	}
	
done:
	
	// Indicate a card was moved.
	if ((cardMoved) && (_playedAtleastOneCard == NO))
		[self noteAtleastOneCardMoved];
	
	if (cardMoved)
	{
		if (_autoPutaway)
		{
			// Fire off the putaway timer.
			_putawayTimer = [NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector: @selector (putawayTimer:) 
					userInfo: nil repeats: NO];
		}
		else
		{
			// See if the game is a wrap.
			[self checkGameState];
		}
	}
}

// --------------------------------------------------------------------------------------------- stackViewOverlayingView

- (UIView *) stackViewOverlayingView: (CEStackView *) view
{
	return _overlayingView;
}

// -------------------------------------------------------------------------------------------- stackView:cardWasTouched

- (void) stackView: (CEStackView *) view cardWasTouched: (CECard *) card
{
	int		i;
	
	// Clear any labels in tableau view.
	for (i = 0; i < 8; i++)
		_tableauViews[i].label = @"";
}

#pragma mark ------ notification methods
// --------------------------------------------------------------------------------------------------------- cardDragged

- (void) cardDragged: (NSNotification *) notification
{
	if (_playedAtleastOneCard == NO)
		[self noteAtleastOneCardMoved];
	
	if (_autoPutaway)
		[self determineIfCardsCanBePutAway];
	
	// See if the game is a wrap.
	[self checkGameState];
}

// -------------------------------------------------------------------------------------------------------- cardPickedUp

- (void) cardPickedUp: (NSNotification *) notification
{
	// Play card drawn sound.
	if (_playSounds)
		[[SimpleAudioEngine sharedEngine] playEffect: [NSString stringWithFormat: @"CardDraw%d.wav", CERandomInt (kNumCardDrawSounds)]];
}

// -------------------------------------------------------------------------------------------------------- cardReleased

- (void) cardReleased: (NSNotification *) notification
{
	int		i;
	
	// Clear any labels in tableau view.
	for (i = 0; i < 8; i++)
		_tableauViews[i].label = @"";
	
	// Play card placed sound.
	if (_playSounds)
		[[SimpleAudioEngine sharedEngine] playEffect: [NSString stringWithFormat: @"CardPlace%d.wav", CERandomInt (kNumCardPlaceSounds)]];
}

// -------------------------------------------------------------------------------------------------------- putawayTimer

- (void) putawayTimer: (NSTimer *) timer
{
	// Clean up timer.
	[timer invalidate];
	_putawayTimer = nil;
	
	// See if any cards can be put away.
	[self determineIfCardsCanBePutAway];
	
	// See if the game is a wrap.
	[self checkGameState];
}

#pragma mark ------ LocalPlayer delegate methods
// -------------------------------------------------------------------------------------------- localPlayerAuthenticated

- (void) localPlayerAuthenticated: (LocalPlayer *) player
{
	[_localPlayer retrieveLeaderboardScores: kMaxLeaderboardScores forCategory: @"com.softdorothy.labsolitaire.games_won" 
			friendsOnly: _leaderboardFriendsOnly];
	
	// Fetch player's leaderboard score.
	[_localPlayer retrieveLeaderboardScoreForLocalPlayerForCategory: @"com.softdorothy.labsolitaire.games_played"];
	[_localPlayer retrieveLeaderboardScoreForLocalPlayerForCategory: @"com.softdorothy.labsolitaire.games_won"];
}

// --------------------------------------------------------------------------- localPlayer:failedAuthenticationWithError
// This can be called if the player disconnects from 
// GameCenter while we were in the background.

- (void) localPlayer: (LocalPlayer *) player failedAuthenticationWithError: (NSError *) error
{
	// Empty leaderboard arrays.
	[_leaderboardPlayerIDs removeAllObjects];
	[_leaderboardGamesPlayed removeAllObjects];
	[_leaderboardGamesWon removeAllObjects];
	[_leaderboardAliases release];
	_leaderboardAliases = nil;
	_playerLeaderboardIndex = NSNotFound;
	
	// Update the UI.
	[self updateGlobalScoresInterface];
}

// -------------------------------------------------------------------------------------------- copyPlayerIDs:toOurArray

- (void) copyPlayerIDs: (NSArray *) players toOurArray: (NSMutableArray *) ourPlayers
{
	// Copy the leaderboard data.
	[ourPlayers removeAllObjects];
	if (players)
		[ourPlayers addObjectsFromArray: players];
}

// ------------------------------------------------------------------------------------ copyLeaderboardScores:toOurArray

- (void) copyLeaderboardScores: (NSArray *) scores toOurArray: (NSMutableArray *) ourScores
{
	// Copy the leaderboard data.
	[ourScores removeAllObjects];
	if (scores)
		[ourScores addObjectsFromArray: scores];
}

// -------------------------------------------------------------- mergeLocalPlayerScoreWithLeaderboardScores:forCategory

- (NSUInteger) mergeLocalPlayerScoreWithLeaderboardScores: (NSMutableArray *) leaderboard forCategory: (NSString *) category
{
	NSInteger	index = 0;
	NSUInteger	playerIndex = NSNotFound;
	
	for (NSString *playerID in _leaderboardPlayerIDs)
	{
		if ([playerID isEqualToString: _localPlayer.playerID])
		{
			NSInteger	localScore;
			
			// Get local score.
			[_localPlayer retrieveLocalScore: &localScore forCategory: category];
			if ([leaderboard count] > index)
			{
				NSInteger	leaderboardValue;
				
				leaderboardValue = [[leaderboard objectAtIndex: index] integerValue];
				if (localScore > leaderboardValue)
					[leaderboard replaceObjectAtIndex: index withObject: [NSString stringWithFormat: @"%ld", (long) localScore]];
				else if (leaderboardValue > localScore)
					[_localPlayer postLocalScore: leaderboardValue forCategory: category];
			}
			else
			{
				[leaderboard addObject: [NSString stringWithFormat: @"%ld", (long) localScore]];
			}
			
			playerIndex = index;
			break;
		}
		
		index += 1;
	}
	
	return playerIndex;
}

// -------------------------------------------------------- localPlayer:retrievedLeaderboardScores:playerIDs:forCategory

- (void) localPlayer: (LocalPlayer *) player retrievedLeaderboardScores: (NSArray *) scores 
		playerIDs: (NSArray *) players forCategory: (NSString *) category
{
	if ([category isEqualToString: @"com.softdorothy.labsolitaire.games_won"])
	{
		// Copy the playerID data.
		[self copyPlayerIDs: players toOurArray: _leaderboardPlayerIDs];
		
		// Copy the leaderboard data.
		[self copyLeaderboardScores: scores toOurArray: _leaderboardGamesWon];
		
		// If our local score is greater than the leaderboard score, substitute our local score in the games-won array.
		_playerLeaderboardIndex = [self mergeLocalPlayerScoreWithLeaderboardScores: _leaderboardGamesWon forCategory: category];
		
		// Fetch the number of games won for the leaderboard players.
		[_localPlayer retrieveLeaderboardScoresForPlayerIDs: _leaderboardPlayerIDs forCategory: @"com.softdorothy.labsolitaire.games_played"];
	}
	else if ([category isEqualToString: @"com.softdorothy.labsolitaire.games_played"])
	{
		// Copy the leaderboard data.
		[self copyLeaderboardScores: scores toOurArray: _leaderboardGamesPlayed];
		
		// If our local score is greater than the leaderboard score, substitute our local score in the games-played array.
		if (_playerLeaderboardIndex != NSNotFound)
			[self mergeLocalPlayerScoreWithLeaderboardScores: _leaderboardGamesPlayed forCategory: category];
		
		// Fetch the names for the player ID's.
		if ((_leaderboardPlayerIDs) && ([_leaderboardPlayerIDs count] > 0))
		{
			[_localPlayer retrieveAliasesForPlayerIDs: _leaderboardPlayerIDs];
		}
		else
		{
			[_leaderboardAliases release];
			_leaderboardAliases = nil;
			[self updateGlobalScoresInterface];
		}
	}
}

// ----------------------------------------------------------------- retrievedLeaderboardScoreForLocalPlayer:forCategory

- (void) localPlayer: (LocalPlayer *) player retrievedLeaderboardScoreForLocalPlayer: (int64_t) score forCategory: (NSString *) category
{
	if ([category isEqualToString: @"com.softdorothy.labsolitaire.games_won"])
	{
		NSInteger	gamesWon;
		
		[_localPlayer retrieveLocalScore: &gamesWon forCategory: @"com.softdorothy.labsolitaire.games_won"];
		if (score > gamesWon)
			[_localPlayer postLocalScore: score forCategory: @"com.softdorothy.labsolitaire.games_won"];
	}
	else if ([category isEqualToString: @"com.softdorothy.labsolitaire.games_played"])
	{
		NSInteger	gamesPlayed;
		
		[_localPlayer retrieveLocalScore: &gamesPlayed forCategory: @"com.softdorothy.labsolitaire.games_played"];
		if (score > gamesPlayed)
			[_localPlayer postLocalScore: score forCategory: @"com.softdorothy.labsolitaire.games_played"];
	}
}

// ---------------------------------------------------------------------------- localPlayer:retrievedAliasesForPlayerIDs

- (void) localPlayer: (LocalPlayer *) player retrievedAliasesForPlayerIDs: (NSArray *) aliases
{
	[_leaderboardAliases release];
	_leaderboardAliases = nil;
	if (aliases)
		_leaderboardAliases = [aliases copy];
	
	// Update the UI.
	[self updateGlobalScoresInterface];
}

// -------------------------------------------------------------------- localPlayer:failedRetrieveScoreForCategory:error

- (void) localPlayer: (LocalPlayer *) player failedRetrieveScoreForCategory: (NSString *) category error: (NSError *) error
{
	printf ("localPlayer:failedRetrieveScoreForCategory:error: %s\n", [[error description] cStringUsingEncoding: NSUTF8StringEncoding]);
}

// ------------------------------------------------------------------------ localPlayer:failedPostScoreForCategory:error

- (void) localPlayer: (LocalPlayer *) player failedPostScoreForCategory: (NSString *) category error: (NSError *) error
{
	printf ("localPlayer:failedPostScoreForCategory:error: %s\n", [[error description] cStringUsingEncoding: NSUTF8StringEncoding]);
}

// ----------------------------------------------------------------------- localPlayer:failedRetrieveAliasesForPlayerIDs

- (void) localPlayer: (LocalPlayer *) player failedRetrieveAliasesForPlayerIDs: (NSError *) error
{
	printf ("localPlayer:failedRetrieveAliasesForPlayerIDs: %s\n", [[error description] cStringUsingEncoding: NSUTF8StringEncoding]);
}

@end
