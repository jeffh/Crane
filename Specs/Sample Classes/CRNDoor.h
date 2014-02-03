#import "Crane.h"
#import "CRNWindow.h"

@interface CRNDoor : NSObject

@property (strong, nonatomic) CRNWindow<CRNInject> *window;

@end
