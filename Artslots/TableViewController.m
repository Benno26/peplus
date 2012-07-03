//
//  TableViewController.m
//  Artnestopia
//
//  Created by arthur on 22/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TableViewController.h"
#import "RootViewController.h"
#import "Helper.h"

TableViewController *tableViewController = nil;
CoreSurfaceBufferRef screen_surface = nil;
unsigned char *videobuf = NULL;
UINT32 screen_width=0, screen_height=0;

void dealloc_screen_surface()
{
    videobuf = NULL;
    screen_width = screen_height = 0;
    if(screen_surface != nil)
    {
        CFRelease(screen_surface);
        screen_surface = nil;
    }
}

void init_screen_surface()
{
    CFMutableDictionaryRef dict;
    if (!screen_width || !screen_height) {
        screen_width = 320;
        screen_height = 200;
    }
    int w = screen_width;
    int h = screen_height;

    int pitch = w * 2, allocSize = 2 * w * h;
    char *pixelFormat = "565L";

    dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
                                     &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(dict, kCoreSurfaceBufferGlobal, kCFBooleanTrue);
    CFDictionarySetValue(dict, kCoreSurfaceBufferMemoryRegion,
                         @"IOSurfaceMemoryRegion");
    CFDictionarySetValue(dict, kCoreSurfaceBufferPitch,
                         CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &pitch));
    CFDictionarySetValue(dict, kCoreSurfaceBufferWidth,
                         CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &w));
    CFDictionarySetValue(dict, kCoreSurfaceBufferHeight,
                         CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &h));
    CFDictionarySetValue(dict, kCoreSurfaceBufferPixelFormat,
                         CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, pixelFormat));
    CFDictionarySetValue(dict, kCoreSurfaceBufferAllocSize,
                         CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &allocSize));

    screen_surface = CoreSurfaceBufferCreate(dict);

    videobuf = (unsigned char *) CoreSurfaceBufferGetBaseAddress(screen_surface);                                                
}

@implementation TableViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    NSLog(@"TableViewController dealloc");
    dealloc_screen_surface();
    [arr release];
    arr = nil;
    tableViewController = nil;
    [super dealloc];
}

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        tableViewController = self;
        arr = get_games_arr();
        init_screen_surface();
    }
    return self;
}

- (void)viewDidLoad
{
    UILabel *l;
    l = [[[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height)] autorelease];
    l.numberOfLines = 0;
    l.textAlignment = UITextAlignmentCenter;
    l.font = emojiFontOfSize(17.0);
    l.text = @"Swipe from the left edge to the right to exit\nSwipe to the left to reset\n* For games marked with an asterix,\nWhen it says CALL ATTENDANT, open the door\nWhen it says CMOS DATA, hold down Self Test\nuntil you hear a tone, close the door,\nthen press Jackpot Reset";
    l.backgroundColor = [UIColor clearColor];
    [l sizeToFit];
    self.tableView.tableHeaderView = l;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)row
{
    return [arr count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 72.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"cell1";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
    }
    cell.textLabel.text = get_game_name([arr objectAtIndex:indexPath.row]);
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RootViewController *vc = [[[RootViewController alloc] initWithGame:[arr objectAtIndex:indexPath.row]] autorelease];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
