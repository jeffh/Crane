#import <Foundation/Foundation.h>

@class CRNCrane;
typedef id(^CRNFactoryBlock)(CRNCrane *crane);

#define CRN_PROVIDE(X) ^id(CRNCrane *__crane__) { return (X); }
#define CRN_DEFINE_INJECTED_INIT() \
- (id)init { \
    self = [super init]; \
    if (self) {\
        [CRNCrane injectIntoObject:self]; \
    } \
    return self; \
}

@protocol CRNInject
@end


@interface CRNCrane : NSObject

+ (instancetype)sharedInstance;
+ (void)injectIntoObject:(id)object;
+ (void)registerKey:(id)object toBlock:(CRNFactoryBlock)block;

- (id)init;
- (void)injectIntoObject:(id)object;
- (void)registerKey:(id)object toBlock:(CRNFactoryBlock)block;

@end
