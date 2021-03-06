
#import <UIKit/UIKit.h>
#include <sys/time.h>
#import "CocosView.h"

// cocos2d import
#import "cocos2d.h"

// local import
#import "VisualisationViewController.h"

enum {
	kStateRun,
	kStateEnd,
	kStateAttach,
	kStateDetach,
};


@interface VisualizationViewController (Private)
-(void) attachView;
-(void) detachView;
-(void) runCocos2d;
-(void) endCocos2d;
-(void) tick;
@end

// CLASS IMPLEMENTATIONS
@implementation VisualizationViewController
@synthesize player, trackInfo, cocosView, timer, mp3Filename;


- (void) dealloc {
	[trackInfo release];
	[player release];
	[cocosView release];
	[timer release];
	[super dealloc];
}

enum {
	kTagAttach = 1,
	kTagDettach = 2,
};


//
// Use runWithScene / end
// to remove /add the cocos2d view
// This is the recommended way since it removes the Scenes from memory
//
-(void) runCocos2d
{
	if( state == kStateEnd ) {
		
		[[Director sharedDirector] attachInView:self.view withFrame:CGRectMake(0, 0, 320,400)];
		
		Scene *scene = [Scene node];
		self.cocosView = [[CocosView alloc] init];
		id node = self.cocosView;
		[scene addChild: node];
		
		[[Director sharedDirector] runWithScene:scene];
        
        NSURL *fileURL = [[NSURL alloc] initFileURLWithPath: self.mp3Filename];
        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
        NSLog(@"Starting to play %@", fileURL);
        if(!([self.player prepareToPlay])){
            NSLog(@"audioPlayer:prepareToPlay returned FALSE");
        }
        self.player.delegate = self;
        [self.player play];
		self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01
				target:self selector:@selector(tick) userInfo:nil repeats:YES];
		state = kStateRun;
	}
	else {
		NSLog(@"End the view before running it");
	}
}

-(void) endCocos2d
{
	if( state == kStateRun || state == kStateAttach) {
		// Director end releases the "inner" objects from memory
		[[Director sharedDirector] end];
		state = kStateEnd;
	}
	else
		NSLog(@"Run or Attach the view before calling end");
}

//
// Use attach / detach
// To hide / unhide the cocos2d view.
// If you want to remove them, use runWithScene / end
// IMPORTANT: Memory is not released if you use attach / detach
//
-(void) attachView
{
	if( state == kStateDetach ) {
		[[Director sharedDirector] attachInView:self.view withFrame:CGRectMake(0, 0, 250,350)];
		[[Director sharedDirector] startAnimation];

		state = kStateAttach;
	}
	else
		NSLog(@"Dettach the view before attaching it");
}

-(void) detachView
{
	if( state == kStateRun || state == kStateAttach ) {
		[[Director sharedDirector] detach];
		[[Director sharedDirector] stopAnimation];
		state = kStateDetach;
	} else {
		NSLog(@"Run or Attach the view before calling detach");
	}
}

#pragma mark -
#pragma mark Segment Delegate

//TODO - call this when we leave the view...
- (void)segmentAction:(id)sender
{	
	int idx = [sender selectedSegmentIndex];
	// category 
	if( [sender tag] == 0 ) {	// attach / detach
		if( idx == 0)
			[self attachView];
		else if( idx == 1 )
			[self detachView];
	} else if( [sender tag] == 1 ) { // run / end
		if( idx == 0 )
			[self runCocos2d];
		else if(idx == 1)
			[self endCocos2d];
	}
}

#pragma mark -
#pragma mark Application Delegate

- (void) viewDidLoad{
	[Director useFastDirector];
	
	[[Director sharedDirector] setDisplayFPS:NO];
	[[Director sharedDirector] setAnimationInterval:1/240.0f];

	state = kStateEnd;
}

-(void) viewDidAppear:(BOOL)animated{
	[self runCocos2d];
}


#pragma mark -
#pragma mark 

					  
-(void) tick{
	float trackTime = [self.player currentTime];
	ENSegment *segment = [ self.trackInfo segmentForMillisecond:trackTime];
	if ( segment){
		[cocosView updateSegmentInfo: segment];
	}
}


@end
