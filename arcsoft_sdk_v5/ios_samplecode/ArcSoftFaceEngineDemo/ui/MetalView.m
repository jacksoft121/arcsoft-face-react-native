#import "MetalView.h"
#import <CoreImage/CoreImage.h>

@interface MetalView () <MTKViewDelegate>
{
    CVMetalTextureCacheRef _textureCache;
}
@property (nonatomic, strong, readwrite) CIContext *ciContext;
@property (nonatomic, assign, readwrite) BOOL mirror;
@property (nonatomic, assign, readwrite) CGSize videoSize;
@property (nonatomic, assign, readwrite) CVPixelBufferRef currentPixelBuffer;
@end

@implementation MetalView

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) [self commonInit];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame device:(id<MTLDevice>)device {
    self = [super initWithFrame:frame device:device];
    if (self) [self commonInit];
    return self;
}

- (void)commonInit {
    if (!self.device) self.device = MTLCreateSystemDefaultDevice();
    self.delegate = self;
    self.framebufferOnly = NO;
    self.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    self.userInteractionEnabled = NO;

    CVMetalTextureCacheCreate(NULL, NULL, self.device, NULL, &_textureCache);
    self.ciContext = [CIContext contextWithMTLDevice:self.device];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.drawableSize = self.bounds.size;
}

- (void)updatePixelBuffer:(CVPixelBufferRef)pixelBuffer mirror:(BOOL)mirror {
    if (!pixelBuffer || !self.currentDrawable) return;

    if (_currentPixelBuffer) {
        CVPixelBufferRelease(_currentPixelBuffer);
        _currentPixelBuffer = nil;
    }

    _currentPixelBuffer = CVPixelBufferRetain(pixelBuffer);
    _mirror = mirror;
    self.videoSize = CGSizeMake(CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));

    [self draw];
}

#pragma mark - MTKViewDelegate

- (void)drawInMTKView:(MTKView *)view {
    if (!_currentPixelBuffer) return;
    id<CAMetalDrawable> drawable = view.currentDrawable;
    if (!drawable) return;

    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:_currentPixelBuffer];

    // 前置镜像处理
    if (_mirror) {
        ciImage = [ciImage imageByApplyingTransform:CGAffineTransformMakeScale(-1, 1)];
        ciImage = [ciImage imageByApplyingTransform:CGAffineTransformMakeTranslation(ciImage.extent.size.width, 0)];
    }

    // AspectFit 缩放
    CGSize viewSize = self.bounds.size;
    CGFloat scaleX = viewSize.width / ciImage.extent.size.width;
    CGFloat scaleY = viewSize.height / ciImage.extent.size.height;
    CGFloat scale = MIN(scaleX, scaleY); // AspectFit 用 MIN
    CGFloat newWidth = ciImage.extent.size.width * scale;
    CGFloat newHeight = ciImage.extent.size.height * scale;
    CGFloat offsetX = (viewSize.width - newWidth) / 2.0;
    CGFloat offsetY = (viewSize.height - newHeight) / 2.0;

    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformScale(transform, scale, scale);
    transform = CGAffineTransformTranslate(transform, offsetX / scale, offsetY / scale);

    ciImage = [ciImage imageByApplyingTransform:transform];

    [self.ciContext render:ciImage
                toMTLTexture:drawable.texture
                commandBuffer:nil
                       bounds:CGRectMake(0, 0, viewSize.width, viewSize.height)
                   colorSpace:CGColorSpaceCreateDeviceRGB()];

    [drawable present];

    CVPixelBufferRelease(_currentPixelBuffer);
    _currentPixelBuffer = nil;
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}

@end

