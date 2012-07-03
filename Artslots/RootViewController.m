//
//  RootViewController.m
//  Artnestopia
//
//  Created by arthur on 20/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RootViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <pthread.h>
#import "Helper.h"
#import "SlotInputView.h"
#import "TableViewController.h"

extern void audio_close(void);
extern void audio_open(void);

extern TableViewController *tableViewController;
RootViewController *rootViewController = nil;
TouchInputView *inputView = nil;
ScreenView *screenView = nil;

@implementation RootViewController

@synthesize game = _game;
@synthesize debugLabel = _debugLabel;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    NSLog(@"dealloc RootViewController");
    peplus_stop();
    self.game = nil;
    rootViewController = nil;
}

- (id)initWithGame:(NSArray *)game
{
    NSLog(@"alloc RootViewController");
    self = [super init];
    if (self) {
        rootViewController = self;
        self.game = game;
        peplus_load(self.game);
    }
    return self;
}

- (void)loadView
{
    NSLog(@"rootViewController loadView");
    self.view = inputView = [[TouchInputView alloc] initWithFrame:tableViewController.view.frame];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
/*    self.view.opaque = YES;
    self.view.clearsContextBeforeDrawing = NO;
    self.view.userInteractionEnabled = YES;
    self.view.multipleTouchEnabled = YES;
    self.view.exclusiveTouch = NO;*/
}

- (void)viewDidUnload
{
    [inputView release];
    inputView = nil;
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
/*    UILabel *(^toilet)(CGRect r) = ^(CGRect r) {
        UILabel *l = [[[UILabel alloc] initWithFrame:CGRectMake(r.size.width*0.95, 0.0, r.size.width*0.05, r.size.height*0.05)] autorelease];
        l.backgroundColor = [UIColor clearColor];
        l.text = @"\ue05a";
        l.font = emojiFontOfSize(17.0);
        l.textAlignment = UITextAlignmentCenter;
        return l;
    };
    toiletLabel = [toilet(self.view.frame) retain];
    toiletLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:toiletLabel];*/
/*    self.debugLabel = [[[UILabel alloc] initWithFrame:self.view.frame] autorelease];
    self.debugLabel.backgroundColor = [UIColor clearColor];
    self.debugLabel.font = [UIFont systemFontOfSize:12.0];
    self.debugLabel.textColor = [UIColor whiteColor];
    self.debugLabel.numberOfLines = 1;
    self.debugLabel.userInteractionEnabled = NO;
    [self setDebugText:@"DEBUG"];
    [self.view addSubview:self.debugLabel];*/
}

- (void)viewDidDisappear:(BOOL)animated
{
/*    [self.debugLabel removeFromSuperview];
    self.debugLabel = nil;*/
    [toiletLabel removeFromSuperview];
    [toiletLabel release];
    toiletLabel = nil;
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
#if 0
    [UIView animateWithDuration:duration delay:0.0 options:0 animations:^{ screenView.frame = get_screen_rect(toInterfaceOrientation); } completion:nil];
#endif
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
#if 0
    screenView.frame = get_screen_rect(self.interfaceOrientation);
#endif
}

- (void)handleReset
{
    UIAlertView *av = [[[UIAlertView alloc] initWithTitle:@"Reset" message:@"Are you sure?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] autorelease];
    [av show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        extern NSArray *loaded;
        NSArray *game = loaded;
        peplus_stop();
        delete_nvram(game);
        peplus_load(game);
    }
}

#if 0
- (void)changeScreenViewToSize:(CGSize)size
{
    BOOL has_superview = NO;
    if (screenView) {
        has_superview = (screenView.superview) ? YES : NO;
        [screenView removeFromSuperview];
        [screenView release];
    }
    extern void dealloc_screen_surface(void);
    dealloc_screen_surface();
    extern int screen_width, screen_height;
    screen_width = size.width;
    screen_height = size.height;
    extern void init_screen_surface(void);
    init_screen_surface();
    screenView = [[ScreenView alloc] initWithFrame:get_screen_rect(self.interfaceOrientation)];
    if (has_superview) {
        [self.view addSubview:screenView];
    }
    
}
#endif

- (void)setDebugText:(NSString *)text
{
    self.debugLabel.text = text;
    [self.debugLabel sizeToFit];
}

@end
