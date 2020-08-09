//
//  MTIHighlightShadowFilter.h
//  MetalPetal
//
//  Created by YuAo on 2020/8/9.
//

#import <Foundation/Foundation.h>
#import <MetalPetal/MetalPetal.h>

NS_ASSUME_NONNULL_BEGIN

@interface MTIHighlightShadowFilter : NSObject <MTIUnaryFilter>

@property (nonatomic) float radius;

/// Amount for shadow adjustment, -1.0 to 1.0
@property (nonatomic) float shadow;

/// Amount for highlight adjustment, -1.0 to 1.0
@property (nonatomic) float highlight;

@end

NS_ASSUME_NONNULL_END
