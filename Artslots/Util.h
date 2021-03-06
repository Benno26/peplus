//
//  Util.h
//  
//
//  Created by arthur on 22/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/* Emoji Unicode
    Toilet = @"\ue140"
    PileOfPoo = @"\ue05a"
*/

UIFont *fontWithName(NSString *fontName, NSString *str, CGSize fits);
UIImage *imageWithPileOfPoo(CGSize size);
UIFont *emojiFontOfSize(CGFloat size);
BOOL isTablet(void);
NSString *getPathInDocs(NSString *name);
NSString *getPathInBundle(NSString *name);
NSMutableArray *readContentsOfPath(NSString *path);
void sortFileArrayAlphabetically(NSMutableArray *arr);
NSString *getDisplayNameForPath(NSString *path);
BOOL containsString(NSString *str, NSString *match);
const char *getCString(NSString *str);
NSString *getPathInDocs(NSString *path);

@interface Util : NSObject
+ (NSString *)getDocsPath;
@end
