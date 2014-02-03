Crane
======

Experimental DI injection implementation.

Please don't use it.

Notables
--------

Values can be injected via properties, via a property:

```
@interface House
@property (strong, nonatomic) Door<CRNInject> *door;
@property (strong, nonatomic) Window *window;
@end

@implementation House
- (id)init {
    self = [super init];
    if (self) {
        [CRNCrane injectIntoObject:self];
    }
    return self;
}
@end
```

Here, door gets injected because of door. But not
window because it lacks the CRNInject property.

Anything Else
--------------

Nope. Just a sample idea.

