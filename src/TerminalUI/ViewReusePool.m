#import "ViewReusePool.h"

@implementation ViewReusePool
- (instancetype)init {
	if ((self = [super init])) {
		self.freeObjects = [NSMutableArray array];
	}
	return self;
}

- (id)getObject {
	id ret = [_freeObjects lastObject];
	if (ret) { [_freeObjects removeLastObject]; }
	return ret;
}

- (void)returnObject:(id)object {
	[object prepareForReuse];
	[_freeObjects addObject:object];
}
@end

