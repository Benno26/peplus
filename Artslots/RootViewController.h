//
//  RootViewController.h
//  Artnestopia
//
//  Created by arthur on 20/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScreenView.h"

@interface RootViewController : UIViewController
{
    UILabel *toiletLabel;
}
- (id)initWithGame:(NSArray *)game;
- (void)handleReset;
- (void)changeScreenViewToSize:(CGSize)size;
- (void)setDebugText:(NSString *)text;
@property (nonatomic, retain) NSArray *game;
@property (nonatomic, retain) UILabel *debugLabel;
@end
