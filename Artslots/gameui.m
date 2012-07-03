//
//  gameui.c
//  Artslots
//
//  Created by arthur on 29/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ScreenView.h"
#import "RootViewController.h"

#include <stdio.h>

extern NSArray *loaded;

extern UINT8 input_sensor;
extern UINT8 clobber_sound;
extern UINT8 input_bank_b;
extern UINT8 input_bank_c;
extern UINT8 input_door;
extern UINT8 input_touch_x;
extern UINT8 input_touch_y;
extern UINT8 output_bank_b;

void addSlotButton(UIView *v, CGFloat x, CGFloat y, CGFloat w, CGFloat h, UIColor *color, NSString *text, int tag);
void addSlotButton(UIView *v, CGFloat x, CGFloat y, CGFloat w, CGFloat h, UIColor *color, NSString *text, int tag)
{
    NSLog(@"addHelpBox %.f %.f %.f %.f", x, y, w, h);
    UILabel *l = [[[UILabel alloc] initWithFrame:CGRectMake(x, y, w, h)] autorelease];
    l.backgroundColor = color;
    l.text = text;
    l.font = [UIFont boldSystemFontOfSize:17.0];
    l.textColor = [UIColor blackColor];
    l.numberOfLines = 1;
    l.adjustsFontSizeToFitWidth = YES;
    l.lineBreakMode = UILineBreakModeWordWrap;
    l.tag = tag;
    l.textAlignment = UITextAlignmentCenter;
    l.userInteractionEnabled = NO;
    [v addSubview:l];
}

void addAuxButtons(UIView *v, CGRect entireframe, CGRect screenframe, NSString *labels)
{
    CGRect r;
    CGFloat w, h, sw, sh;
    if (entireframe.size.width > entireframe.size.height) {
        w = entireframe.size.width;
        h = entireframe.size.height;
    } else {
        w = entireframe.size.height;
        h = entireframe.size.width;
    }
    if (screenframe.size.width > screenframe.size.height) {
        sw = screenframe.size.width;
        sh = screenframe.size.height;
    } else {
        sw = screenframe.size.height;
        sh = screenframe.size.width;
    }
    NSLog(@"addAuxButtons %.f %.f %.f %.f", w, h, sw, sh);
    NSArray *arr = [labels componentsSeparatedByString:@":"];
    r.origin.x = 0;
    r.origin.y = sh - (h - sh);
    r.size.width = (w / arr.count);
    r.size.height = h - sh;
    int tag = 11;
    for (NSString *elt in arr) {
        addSlotButton(v, r.origin.x+1.0, r.origin.y+1.0, r.size.width-2.0, r.size.height-2.0, [UIColor colorWithRed:0.75    green:0.75 blue:0.75 alpha:0.5], elt, tag);
        r.origin.x += r.size.width;
        tag++;
    }
}

void addSlotButtons(UIView *v, CGRect entireframe, CGRect screenframe, NSString *labels)
{
    CGRect r;
    CGFloat w, h, sw, sh;
    if (entireframe.size.width > entireframe.size.height) {
        w = entireframe.size.width;
        h = entireframe.size.height;
    } else {
        w = entireframe.size.height;
        h = entireframe.size.width;
    }
    if (screenframe.size.width > screenframe.size.height) {
        sw = screenframe.size.width;
        sh = screenframe.size.height;
    } else {
        sw = screenframe.size.height;
        sh = screenframe.size.width;
    }
    NSLog(@"helpForSlots %.f %.f %.f %.f", w, h, sw, sh);
    NSArray *arr = [labels componentsSeparatedByString:@":"];
    r.origin.x = 0;
    r.origin.y = sh;
    r.size.width = (w / arr.count);
    r.size.height = h - sh;
    int tag = 1;
    for (NSString *elt in arr) {
        addSlotButton(v, r.origin.x+1.0, r.origin.y+1.0, r.size.width-2.0, r.size.height-2.0, [UIColor colorWithRed:0.75    green:0.75 blue:0.75 alpha:1.0], elt, tag);
        r.origin.x += r.size.width;
        tag++;
    }
}

void add_slot_buttons(NSString *dealspinstart, UIView *v)
{
    NSString *slotButtonTitles = [NSString stringWithFormat:@"%@:Max Bet:Self Test:Jackpot Reset:Door", dealspinstart];
    extern ScreenView *screenView;
    addSlotButtons(v, v.frame, screenView.frame, slotButtonTitles);
}

void add_poker_buttons(UIView *v)
{
    NSString *pokerButtonTitles = @"Hold 1:Hold 2:Hold 3:Hold 4:Hold 5";
    extern ScreenView *screenView;
//    addAuxButtons(v, v.frame, screenView.frame, pokerButtonTitles);
    add_slot_buttons(@"Deal", v);
}

void add_blackjack_buttons(UIView *v)
{
    NSString *blackjackButtonTitles = @"Stand:Double:Split:Insurance:Surrender";
    extern ScreenView *screenView;
    addAuxButtons(v, v.frame, screenView.frame, blackjackButtonTitles);
    add_slot_buttons(@"Deal", v);
}

void add_keno_buttons(UIView *v)
{
    NSString *kenoButtonTitles = @"Erase:Coin";
    extern ScreenView *screenView;
    addAuxButtons(v, v.frame, screenView.frame, kenoButtonTitles);
    add_slot_buttons(@"Start", v);
}

void add_game_buttons(UIView *v)
{
    NSString *type = get_game_type(loaded);
    if ([@"slots" compare:type] == NSOrderedSame) {
        add_slot_buttons(@"Spin", v);
    } else if ([@"poker" compare:type] == NSOrderedSame) {
        add_poker_buttons(v);
    } else if ([@"blackjack" compare:type] == NSOrderedSame) {
        add_blackjack_buttons(v);
    } else if ([@"keno" compare:type] == NSOrderedSame) {
        add_keno_buttons(v);
    } else {
        NSLog(@"add_game_buttons: unknown game type %@", type);
    }
}

#define INPUT_JACKPOT_RESET 1
#define INPUT_SELF_TEST 2
#define INPUT_HOLD_1 3
#define INPUT_HOLD_2 4
#define INPUT_HOLD_3 5
#define INPUT_HOLD_4 6
#define INPUT_HOLD_5 7
#define INPUT_STAND 4
#define INPUT_DOUBLE 6
#define INPUT_SPLIT 7
#define INPUT_INSURANCE 5
#define INPUT_SURRENDER 3
#define INPUT_CLEAR 7
#define INPUT_DEAL_SPIN_START 1
#define INPUT_MAX_BET 2
#define INPUT_PLAY_CREDIT 4
#define INPUT_CASHOUT 5
#define INPUT_CHANGE_REQUEST 6
#define INPUT_BILL_ACCEPTOR 7

void handle_slots_input(CGRect frameRect, CGRect screenRect, UITouch *t, CGPoint p)
{
    if (p.y < screenRect.size.height)
        return;
    int x = p.x / (frameRect.size.width / 5);
    NSLog(@"x %d", x);
    if (x == 0) {
        input_bank_b = INPUT_DEAL_SPIN_START;
        if (t.phase == UITouchPhaseBegan) {
            clobber_sound += 7;
        }
    } else if (x == 1) {
        input_bank_b = INPUT_MAX_BET;
        if (t.phase == UITouchPhaseBegan) {
            clobber_sound += 21;
        }
    } else if (x == 2) {
        input_bank_c = INPUT_SELF_TEST;
    } else if (x == 3) {
        input_bank_c = INPUT_JACKPOT_RESET;
        if (t.phase == UITouchPhaseBegan) {
            clobber_sound++;
        }
    } else if (x == 4) {
        if (t.phase == UITouchPhaseBegan) {
            input_door = (input_door) ? 0 : 1;
        }
    }
}

void handle_coin_input(CGRect frameRect, CGRect screenRect, UITouch *t, CGPoint p)
{
    if (p.y < screenRect.size.height) {
        if (t.phase == UITouchPhaseBegan) {
            NSLog(@"coin");
            input_sensor++;
            clobber_sound++;
        }
        return;
    }
    handle_slots_input(frameRect, screenRect, t, p);
}

void handle_poker_input(CGRect frameRect, CGRect screenRect, UITouch *t, CGPoint p)
{
    if (p.y < screenRect.size.height) {
        if (p.y > screenRect.size.height / 2) {
            int x = p.x / (frameRect.size.width / 5);
            NSLog(@"poker x %d", x);
            if (x == 0) {
                input_bank_c = INPUT_HOLD_1;
            } else if (x == 1) {
                input_bank_c = INPUT_HOLD_2;
            } else if (x == 2) {
                input_bank_c = INPUT_HOLD_3;
            } else if (x == 3) {
                input_bank_c = INPUT_HOLD_4;
            } else if (x == 4) {
                input_bank_c = INPUT_HOLD_5;
            }
            return;
        }
    }
    handle_coin_input(frameRect, screenRect, t, p);
}

void handle_blackjack_input(CGRect frameRect, CGRect screenRect, UITouch *t, CGPoint p)
{
    if (p.y < screenRect.size.height) {
        if (p.y > screenRect.size.height - (frameRect.size.height - screenRect.size.height)) {
            int x = p.x / (frameRect.size.width / 5);
            NSLog(@"blackjack x %d", x);
            if (x == 0) {
                input_bank_c = INPUT_STAND;
            } else if (x == 1) {
                input_bank_c = INPUT_DOUBLE;
            } else if (x == 2) {
                input_bank_c = INPUT_SPLIT;
            } else if (x == 3) {
                input_bank_c = INPUT_INSURANCE;
            } else if (x == 4) {
                input_bank_c = INPUT_SURRENDER;
            }
            return;
        }
    }
    handle_coin_input(frameRect, screenRect, t, p);
}

void handle_keno_input(CGRect frameRect, CGRect screenRect, UITouch *t, CGPoint p)
{
    if (p.y < screenRect.size.height) {
        if (p.y > screenRect.size.height - (frameRect.size.height - screenRect.size.height)) {
            int x = p.x / (frameRect.size.width / 2);
            NSLog(@"keno a x %d", x);
            if (x == 0) {
                input_bank_c = INPUT_CLEAR;
            } else if (x == 1) {
                if (t.phase == UITouchPhaseBegan) {
                    input_sensor++;
                    clobber_sound++;
                }
            }
            return;
        }
        int x = p.x / (frameRect.size.width / 10);
        NSLog(@"keno b x %d", x);
        input_touch_x = x;
        input_touch_y = x;
    }
    handle_slots_input(frameRect, screenRect, t, p);
}

void handle_game_input(CGRect frameRect, CGRect screenRect, UITouch *t, CGPoint p)
{
    NSString *type = get_game_type(loaded);
    if ([@"slots" compare:type] == NSOrderedSame) {
        return handle_coin_input(frameRect, screenRect, t, p);
    } else if ([@"poker" compare:type] == NSOrderedSame) {
        return handle_poker_input(frameRect, screenRect, t, p);
    } else if ([@"blackjack" compare:type] == NSOrderedSame) {
        return handle_blackjack_input(frameRect, screenRect, t, p);
    } else if ([@"keno" compare:type] == NSOrderedSame) {
        return handle_keno_input(frameRect, screenRect, t, p);
    } else {
        NSLog(@"handle_game_input: unknown type %@", type);
    }
}

void handle_game_output(UINT8 data)
{
    extern RootViewController *rootViewController;
    void (^func)(int tag, int val) = ^(int tag, int val) {
        UIView *v = [rootViewController.view viewWithTag:tag];
        if (v) {
            CGFloat alpha = (tag > 10) ? 0.5 : 1.0;
            if (val) {
                v.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:alpha];
            } else {
                v.backgroundColor = [UIColor colorWithRed:0.75 green:0.75 blue:0.75 alpha:alpha];
            }
        } else {
            errorlog("view not found %d", tag);
        }
    };
    void (^update)(NSString *name, UINT8 mask, int tag) = ^(NSString *name, UINT8 mask, int tag) {
        if ((output_bank_b & mask) == (data & mask))
            return;
        debuglog("peplus_output_bank_b %@ %d %d", name, tag, data & mask);
        func(tag, data & mask);
    };
    NSString *type = get_game_type(loaded);
    int slots = 0;
    int poker = 0;
    int blackjack = 0;
    int keno = 0;
    if ([@"slots" compare:type] == NSOrderedSame) {
        slots = 1;
    } else if ([@"poker" compare:type] == NSOrderedSame) {
        poker = 1;
    } else if ([@"blackjack" compare:type] == NSOrderedSame) {
        blackjack = 1;
    } else if ([@"keno" compare:type] == NSOrderedSame) {
        keno = 1;
    }
    if (poker) {
        update(@"hold", 0x01, 12);
        update(@"hold", 0x01, 13);
        update(@"hold", 0x01, 14);
    } else if (blackjack) {
        update(@"insurance", 0x01, 14);
    }
    update(@"deal-spin-start", 0x02, 1);
    // update("cashout", 0x04, 0);
    if (poker) {
        update(@"hold", 0x08, 11);
    } else if (blackjack) {
        update(@"double", 0x08, 11);
    }
    update(@"bet_max", 0x10, 2);
    // update(@"change_request", 0x20, 0);
    update(@"door_open", 0x40, 5);
    if (poker) {
        update(@"hold", 0x80, 15);
    } else if (blackjack) {
        update(@"split", 0x80, 13);
    } else if (keno) {
        update(@"keno", 0x80, 11);
    }
}

