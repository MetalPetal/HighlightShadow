//
//  MTIHighlightShadowFilter.m
//  MetalPetal
//
//  Created by YuAo on 2020/8/9.
//

#import "MTIHighlightShadowFilter.h"

@interface MTIHighlightShadowFilter()

@property (nonatomic, strong) MTIMPSGaussianBlurFilter *blurFilter;

@end

@implementation MTIHighlightShadowFilter
@synthesize inputImage = _inputImage;
@synthesize outputPixelFormat = _outputPixelFormat;

+ (MTIRenderPipelineKernel *)kernel {
    return [[MTIRenderPipelineKernel alloc] initWithVertexFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:MTIFilterPassthroughVertexFunctionName]
                                                  fragmentFunctionDescriptor:[[MTIFunctionDescriptor alloc] initWithName:@"shadowHighlightAdjust" libraryURL:MTIDefaultLibraryURLForBundle([NSBundle bundleForClass:self])]];
}

- (instancetype)init {
    if (self = [super init]) {
        _radius = 30;
        _blurFilter = [[MTIMPSGaussianBlurFilter alloc] init];
        _blurFilter.radius = _radius;
    }
    return self;
}

- (MTIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    self.blurFilter.radius = self.radius;
    self.blurFilter.inputImage = self.inputImage;
    MTIImage *blurredImage = self.blurFilter.outputImage;
    return [MTIHighlightShadowFilter.kernel applyToInputImages:@[self.inputImage, blurredImage]
                                                       parameters:@{@"shadow": @(self.shadow),
                                                                    @"highlight": @(self.highlight)}
                                          outputTextureDimensions:self.inputImage.dimensions
                                                outputPixelFormat:self.outputPixelFormat];
}

@end
