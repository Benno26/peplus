//
//  Helper.c
//  Artnestopia
//
//  Created by arthur on 22/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Util.h"

UIFont *fontWithName(NSString *fontName, NSString *str, CGSize fits)
{
    CGFloat fontSize = 12.0f;
    CGFloat val = (fits.width > fits.height) ? fits.height : fits.width;
    for(;;) {
        UIFont *f = [UIFont fontWithName:fontName size:fontSize+1.0f];
        CGSize s = [str sizeWithFont:f];
        if ((s.width > val) || (s.height > val)) {
            return f;
        }
        fontSize += 1.0f;
    }
}

UIImage *imageWithPileOfPoo(CGSize size)
{
    NSString *str = @"\ue05a";
    UIFont *font = fontWithName(@"AppleColorEmoji", str, size);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
/*    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor colorWithRed:0.875 green:0.875 blue:0.5 alpha:1.0] set];
    CGContextFillRect(context, CGRectMake(0.0, 0.0, size.width, size.height));*/
    CGSize pileOfPooSize = [str sizeWithFont:font];
    [str drawInRect:CGRectMake((size.width-pileOfPooSize.width)/2.0, (size.height-pileOfPooSize.height)/2.0, pileOfPooSize.width, pileOfPooSize.height) withFont:font];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

NSString *getPathInDocs(NSString *name)
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [[paths objectAtIndex:0] stringByAppendingPathComponent:name];
}

UIFont *emojiFontOfSize(CGFloat size)
{
    return [UIFont fontWithName:@"AppleColorEmoji" size:size];
}

BOOL isTablet()
{
    return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? YES : NO;
}

NSString *getPathInBundle(NSString *name)
{
    return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:name];
}

NSMutableArray *readContentsOfPath(NSString *path)
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSMutableArray *arr = [[[NSMutableArray alloc] init] autorelease];
    NSDirectoryEnumerator *dirEnum =[fm enumeratorAtPath:path];
    NSString *file;
    while (file = [dirEnum nextObject]) {
        if ([[dirEnum fileAttributes] fileType] == NSFileTypeRegular) {
            [arr addObject:getPathInDocs(file)];
        }
    }
    return arr;
}

void sortFileArrayAlphabetically(NSMutableArray *arr)
{
    NSComparator cmp = ^(NSString *a, NSString *b) {
        if ([a.lowercaseString hasPrefix:[b.lowercaseString stringByDeletingPathExtension]])
            return (NSComparisonResult)NSOrderedDescending;
        if ([b.lowercaseString hasPrefix:[a.lowercaseString stringByDeletingPathExtension]])
            return (NSComparisonResult)NSOrderedAscending;
        return (NSComparisonResult)[a localizedCaseInsensitiveCompare:b];
    };
    [arr sortUsingComparator:^(id a, id b) { return cmp(a, b); }];
}

NSString *getDisplayNameForPath(NSString *path)
{
    return [[path lastPathComponent] stringByDeletingPathExtension];
}


BOOL containsString(NSString *str, NSString *match)
{
    NSRange r = [str rangeOfString:match];
    return (r.location == NSNotFound) ? NO : YES;
}

const char *getCString(NSString *str)
{
    static char buf[1024];
    [str getCString:buf maxLength:1024 encoding:NSASCIIStringEncoding];
    return buf;
}

@implementation Util

+ (NSString *)getDocsPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

@end
