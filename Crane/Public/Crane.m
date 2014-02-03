#import "Crane.h"
#import <objc/runtime.h>


@interface CRNCrane ()
@property (strong, atomic) NSDictionary *bindings;
@end


@implementation CRNCrane

+ (instancetype)sharedInstance
{
    static CRNCrane *sharedInstance__;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance__ = [[CRNCrane alloc] init];
    });
    return sharedInstance__;
}

+ (void)injectIntoObject:(id)object
{
    return [[self sharedInstance] injectIntoObject:object];
}

+ (void)registerKey:(id)object toBlock:(CRNFactoryBlock)block
{
    return [[self sharedInstance] registerKey:object toBlock:block];
}


- (id)init
{
    self = [super init];
    if (self) {
        self.bindings = @{};
    }
    return self;
}

- (void)registerKey:(id)object toBlock:(CRNFactoryBlock)block
{
    NSMutableDictionary *newBindings = [NSMutableDictionary dictionaryWithDictionary:self.bindings];
    newBindings[object] = block;
    self.bindings = [newBindings copy];
}


- (void)injectIntoObject:(id)object
{
    NSDictionary *propertyNamesToTypeString = [self typeStringForPropertiesToInjectOfClass:[object class]];
    for (NSString *propertyName in propertyNamesToTypeString) {
        NSArray *types = propertyNamesToTypeString[propertyName];
        BOOL hasInjected = NO;
        for (id type in types) {
            id injectableValue = [self getInstanceOrNil:type];

            if (injectableValue) {
                [object setValue:injectableValue forKey:propertyName];
                hasInjected = YES;
                break;
            }
        }

        if (!hasInjected) {
            NSMutableArray *humanFriendlyTypes = [NSMutableArray array];
            for (id type in types) {
                if ([[type class] isSubclassOfClass:NSClassFromString(@"Protocol")]) {
                    [humanFriendlyTypes addObject:[NSString stringWithFormat:@"@protocol(%@)", NSStringFromProtocol(type)]];
                } else {
                    [humanFriendlyTypes addObject:type];
                }
            }
            NSString *typeAsReadableString = [humanFriendlyTypes componentsJoinedByString:@", "];
            [NSException raise:NSInvalidArgumentException format:@"Could not inject property '%@' of type %@ for %@", propertyName, typeAsReadableString, object];
        }
    }
}

- (id)getInstanceOrNil:(id)key
{
    if ([key isKindOfClass:NSClassFromString(@"Protocol")]) {
        key = [NSString stringWithFormat:@"@protocol(%@)", key];
    }
    CRNFactoryBlock factory = self.bindings[key];
    if (factory) {
        return factory(self);
    } else if (!factory && class_isMetaClass(object_getClass(key))) {
        return [[key alloc] init];
    }
    return nil;
}

- (NSDictionary *)typeStringForPropertiesToInjectOfClass:(Class)theClass
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSDictionary *propertyNamesToTypeString = [self typeStringForAllPropertiesOfClass:theClass];
    for (NSString *propertyName in propertyNamesToTypeString) {
        NSSet *types = propertyNamesToTypeString[propertyName];
        if ([types containsObject:@protocol(CRNInject)]) {
            result[propertyName] = types;
        }
    }
    return result;
}

- (NSDictionary *)typeStringForAllPropertiesOfClass:(Class)theClass
{
    unsigned int numProperties = 0;
    objc_property_t *properties = class_copyPropertyList(theClass, &numProperties);

    NSMutableDictionary *results = [NSMutableDictionary dictionaryWithCapacity:numProperties];

    for (unsigned int i=0; i<numProperties; i++) {
        objc_property_t property = properties[i];
        unsigned int numAttributes = 0;
        objc_property_attribute_t *attributes = property_copyAttributeList(property, &numAttributes);

        for (unsigned int j=0; j<numAttributes; j++) {
            objc_property_attribute_t attribute = attributes[j];
            if (strcmp(attribute.name, "T") == 0) {
                NSString *name = [NSString stringWithFormat:@"%s", property_getName(property)];
                NSString *typeString = [NSString stringWithFormat:@"%s", attribute.value];
                results[name] = [self typesForTypeString:typeString];
            }
        }

        free(attributes);
    }
    
    free(properties);
    return results;
}

- (NSArray *)typesForTypeString:(NSString *)typeString
{
    // kinds of things we parse (everything in single quotes are IN the string):
    // - '@"NSString"'                           // NSString*
    // - '@"<MyProtocol>"'                       // id<MyProtocol>
    // - '@"MyClass<MyProtocol1><MyProtocol2>"'  // MyClass<MyProtocol1, MyProtocol2>
    // - 'i'                                     // NSInteger/int
    NSScanner *scanner = [NSScanner scannerWithString:typeString];

    if (![scanner scanString:@"@\"" intoString:nil]) {
        return @[];
    }

    NSCharacterSet *classTerminators = [NSCharacterSet characterSetWithCharactersInString:@"<\""];

    NSMutableArray *types = [NSMutableArray new];
    NSString *concreteType = nil;
    [scanner scanUpToCharactersFromSet:classTerminators intoString:&concreteType];

    if (concreteType.length) {
        [types addObject:NSClassFromString(concreteType)];
    }

    if (scanner.isAtEnd){
        return types;
    }


    NSCharacterSet *protocolTerminators = [NSCharacterSet characterSetWithCharactersInString:@">\""];
    while (!scanner.isAtEnd) {
        [scanner scanString:@"<" intoString:nil];

        NSString *protocolType = nil;
        [scanner scanUpToCharactersFromSet:protocolTerminators intoString:&protocolType];
        [scanner scanCharactersFromSet:protocolTerminators intoString:nil];

        if (protocolType.length) {
            [types addObject:NSProtocolFromString(protocolType)];
        }
    }
    return types;
}

@end
