#import "ScreenView.h"

@implementation ScreenLayer

+ (id)defaultActionForKey:(NSString *)key
{
    return nil;
}

- (id)init
{
	self = [super init];
    if (self) {
        [self setMagnificationFilter:kCAFilterLinear];
        [self setMinificationFilter:kCAFilterLinear];        
    }
	return self;
}
	
- (void)display
{        
    extern CoreSurfaceBufferRef screen_surface;
    CoreSurfaceBufferLock(screen_surface, 3);
    self.contents = nil;    
    self.contents = (id)screen_surface;    
    CoreSurfaceBufferUnlock(screen_surface);
}

@end

@implementation ScreenView

+ (Class) layerClass
{
    return [ScreenLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])!=nil) {       
       self.opaque = YES;
       self.clearsContextBeforeDrawing = NO;
       self.multipleTouchEnabled = NO;
	   self.userInteractionEnabled = NO;
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
}

@end
