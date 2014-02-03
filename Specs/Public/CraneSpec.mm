#import "Crane.h"
#import "CRNHouse.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(CraneSpec)

describe(@"Crane", ^{
    describe(@"creating an object", ^{
        __block CRNHouse *house;

        beforeEach(^{
            house = [[CRNHouse alloc] init];
        });

        it(@"should inject with any property with the CRNInjected protocol", ^{
            house.frontDoor should be_instance_of([CRNDoor class]);
            house.window should be_instance_of([CRNWindow class]);
        });

        it(@"should inject dependencies", ^{
            house.frontDoor.window should be_instance_of([CRNWindow class]);
            house.frontDoor.window should_not be_same_instance_as(house.window);
        });

        it(@"should not inject with any property without the CRNInjected protocol", ^{
            house.name should be_nil;
        });
    });

    describe(@"creating an object with registering", ^{
        __block CRNHouse *house;
        __block CRNDoor *theDoor;

        beforeEach(^{
            theDoor = [[CRNDoor alloc] init];
            [CRNCrane registerKey:[CRNDoor class] toBlock:CRN_PROVIDE(theDoor)];
            house = [[CRNHouse alloc] init];
        });

        it(@"should inject with any property with the CRNInjected protocol", ^{
            house.frontDoor should be_same_instance_as(theDoor);
            house.window should be_instance_of([CRNWindow class]);
        });

        it(@"should not inject with any property without the CRNInjected protocol", ^{
            house.name should be_nil;
        });
    });
});

SPEC_END
