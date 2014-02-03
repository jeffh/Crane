#import "CRNDoor.h"
#import "Crane.h"

@implementation CRNDoor

- (id)init
{
    self = [super init];
    if (self) {
        [CRNCrane injectIntoObject:self];
    }
    return self;
}

@end
