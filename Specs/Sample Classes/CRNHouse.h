#import "Crane.h"
#import "CRNDoor.h"
#import "CRNWindow.h"


@interface CRNHouse : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) CRNDoor<CRNInject, NSObject> *frontDoor;
@property (strong, nonatomic) CRNWindow<CRNInject, CRNInject> *window;

@end
