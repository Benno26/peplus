//
//  TouchInputView.m
//  Artsnes9x
//
//  Created by arthur on 28/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SlotInputView.h"
#import "RootViewController.h"
#import "HelpView.h"
#import "ScreenView.h"
#import "TableViewController.h"

#import "glue.h"

extern ScreenView *screenView;
extern TableViewController *tableViewController;
extern RootViewController *rootViewController;

int inputcode[1000];

CGRect get_screen_rect()
{
    CGRect r = tableViewController.view.frame;
    extern int screen_width, screen_height;
    int tmp_width = r.size.width;
    int tmp_height = ((((tmp_width * screen_height) / screen_width)+7)&~7);
    if(tmp_height > r.size.height)
    {
        tmp_height = r.size.height;
        tmp_width = ((((tmp_height * screen_width) / screen_height)+7)&~7);
    }   
    r.origin.x = ((int)r.size.width - tmp_width) / 2;             
    r.origin.y = 0; //((int)r.size.height - tmp_height) / 2;
    r.size.width = tmp_width;
    r.size.height = tmp_height;    
    return r;
}


@implementation TouchInputView

@synthesize helpView = _helpView;

- (void)dealloc
{
    NSLog(@"inputView dealloc");
    self.helpView = nil;
    [screenView release];
    screenView = nil;
    void (^removegr)(UISwipeGestureRecognizer **gr) = ^(UISwipeGestureRecognizer **gr) {
        [self removeGestureRecognizer:*gr];
        [*gr release];
        *gr = nil;
    };
    removegr(&grSwipeLeft);
    removegr(&grSwipeRight);
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    NSLog(@"inputView initWithFrame");
    self = [super initWithFrame:frame];
    if (self) {
        UISwipeGestureRecognizer *(^addswipegr)(SEL selector, UISwipeGestureRecognizerDirection direction) = ^(SEL selector, UISwipeGestureRecognizerDirection direction) {
            UISwipeGestureRecognizer *gr = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:selector];
            gr.direction = direction;
            [self addGestureRecognizer:gr];
            return gr;
        };
        grSwipeLeft = addswipegr(@selector(handleSwipeLeft), UISwipeGestureRecognizerDirectionLeft);
        grSwipeRight = addswipegr(@selector(handleSwipeRight), UISwipeGestureRecognizerDirectionRight);
        
        self.userInteractionEnabled = YES;
        self.multipleTouchEnabled = YES;
        self.exclusiveTouch = NO;  
        self.backgroundColor = [UIColor clearColor];

        screenView = [[ScreenView alloc] initWithFrame:get_screen_rect()];
        screenView.frame = get_screen_rect();
        [self addSubview:screenView];

        add_game_buttons(self);
    }
    return self;
}

- (void)handleTouches:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"handleTouchesPad");
    extern UINT8 input_bank_b;
    extern UINT8 input_bank_c;
    input_bank_b = input_bank_c = 0;
    for (UITouch *t in event.allTouches) {
        if (t.phase == UITouchPhaseCancelled)
            continue;
        if (t.phase == UITouchPhaseEnded)
            continue;
        CGPoint p = [t locationInView:self];
        extern ScreenView *screenView;
        handle_game_input(self.frame, screenView.frame, t, p); 
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self handleTouches:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouches:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouches:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouches:touches withEvent:event];
}

- (void)handleSwipeLeft
{
    [rootViewController handleReset];
}

- (void)handleSwipeRight
{
    NSLog(@"handleSwipeRight");
    CGPoint p = [grSwipeRight locationInView:self];
    if (p.x < self.frame.size.width * 0.05) {
        extern RootViewController *rootViewController;
        [rootViewController.navigationController popViewControllerAnimated:YES];
    }
}

- (void)handleGameOutput:(id)sender
{
    NSNumber *num = sender;
    UINT8 data = num.unsignedIntValue;
    handle_game_output(data);
}

@end
