//
//  DZLJBGlassShader.m
//  2C6C v3.0 — Động cơ Optical Liquid Glass Shader (Dual-Backdrop Lensing + CAColorMatrix + Gyroscope)
//
//  Package: com.dzljb.2c6c
//  Author:  dzljb
//

#import "Tweak.h"

static const void *kDZLJBHiddenByShaderKey = &kDZLJBHiddenByShaderKey;
static NSHashTable<DZLJBGlassArtifact *> *gLiveArtifacts = nil;
static CMMotionManager *gMotionManager = nil;

// ============================================================================
// MARK: - Tính toán Hình học Chuẩn iOS 26.7 (Tròn / Viên thuốc / Squircle 37pt)
// ============================================================================

CGFloat DZLJBComputeCornerRadius(CGSize size, BOOL isExpanded, BOOL *outUseCircular) {
    if (isExpanded) {
        if (outUseCircular) *outUseCircular = NO;
        return 38.0;
    }
    CGFloat minSide = MIN(size.width, size.height);
    if (minSide <= 2.0) {
        if (outUseCircular) *outUseCircular = NO;
        return 0.0;
    }
    // 1x1 nút tròn, 1x2 thanh trượt dọc & 2x1 viên thuốc ngang -> Tròn tuyệt đối (kCACornerCurveCircular)
    if (minSide <= 92.0) {
        if (outUseCircular) *outUseCircular = YES;
        return minSide * 0.5;
    }
    // Khối 2x2 và 4x2 (Connectivity, Media) -> Deep Squircle (mặc định 37pt, kCACornerCurveContinuous)
    if (outUseCircular) *outUseCircular = NO;
    return MIN(gPlatterSquircleRadius, minSide * 0.5);
}

UIButton *DZLJBCreateLiquidCircleButton(NSString *sfSymbolName, CGFloat sideLength) {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(0, 0, sideLength, sideLength);
    btn.tintColor = [UIColor whiteColor];
    btn.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.14];
    btn.clipsToBounds = YES;
    btn.layer.cornerRadius = sideLength * 0.5;
    btn.layer.cornerCurve  = kCACornerCurveCircular;
    btn.layer.borderWidth  = 1.0;
    btn.layer.borderColor  = [UIColor colorWithWhite:1.0 alpha:0.42].CGColor;

    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:15.5 weight:UIImageSymbolWeightSemibold];
        UIImage *img = [UIImage systemImageNamed:sfSymbolName withConfiguration:cfg];
        if (img) [btn setImage:img forState:UIControlStateNormal];
    }
    return btn;
}

// ============================================================================
// MARK: - Tay Nắm Kéo Góc Cong (◞) & Thanh Phân Trang Cạnh Phải
// ============================================================================

@interface DZLJBShaderPassThroughView : UIView
@end

@implementation DZLJBShaderPassThroughView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = YES;
    }
    return self;
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    return nil;
}
@end

@implementation DZLJBResizeHandleView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        self.clipsToBounds = NO;

        _arcShapeLayer = [CAShapeLayer layer];
        _arcShapeLayer.fillColor     = [UIColor clearColor].CGColor;
        _arcShapeLayer.strokeColor   = [UIColor colorWithWhite:0.96 alpha:0.96].CGColor;
        _arcShapeLayer.lineWidth     = 5.4;
        _arcShapeLayer.lineCap       = kCALineCapRound;
        _arcShapeLayer.shadowColor   = [UIColor blackColor].CGColor;
        _arcShapeLayer.shadowOffset  = CGSizeMake(0.0, 1.5);
        _arcShapeLayer.shadowRadius  = 3.5;
        _arcShapeLayer.shadowOpacity = 0.45f;
        [self.layer addSublayer:_arcShapeLayer];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    if (w <= 0 || h <= 0) return;

    CGPoint center = CGPointMake(w - 16.0, h - 16.0);
    UIBezierPath *arc = [UIBezierPath bezierPathWithArcCenter:center
                                                       radius:13.0
                                                   startAngle:0.06
                                                     endAngle:(CGFloat)(M_PI_2 - 0.06)
                                                    clockwise:YES];
    self.arcShapeLayer.frame = self.bounds;
    self.arcShapeLayer.path  = arc.CGPath;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return CGRectContainsPoint(CGRectInset(self.bounds, -12.0, -12.0), point);
}

@end

@implementation DZLJBPageSidebarView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        NSArray<NSString *> *symbols = @[@"heart.fill", @"music.note", @"house.fill", @"antenna.radiowaves.left.and.right"];
        NSMutableArray<UIButton *> *arr = [NSMutableArray array];

        for (NSUInteger i = 0; i < symbols.count; i++) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
            btn.tag = (NSInteger)i;
            if (@available(iOS 13.0, *)) {
                UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:12.5 weight:UIImageSymbolWeightSemibold];
                [btn setImage:[UIImage systemImageNamed:symbols[i] withConfiguration:cfg] forState:UIControlStateNormal];
            }
            btn.tintColor = (i == 0) ? [UIColor whiteColor] : [UIColor colorWithWhite:1.0 alpha:0.40];
            [btn addTarget:self action:@selector(onButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:btn];
            [arr addObject:btn];
        }
        _symbolButtons = [arr copy];
        _activeIndex = 0;
    }
    return self;
}

- (void)onButtonTapped:(UIButton *)sender {
    DZLJBTriggerSelectionTick();
    [self setHighlightedSection:sender.tag];
    if (self.onSelectSection) {
        self.onSelectSection(sender.tag);
    }
}

- (void)setHighlightedSection:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.symbolButtons.count) return;
    _activeIndex = index;
    for (NSUInteger i = 0; i < self.symbolButtons.count; i++) {
        UIButton *btn = self.symbolButtons[i];
        BOOL active = ((NSInteger)i == index);
        [UIView animateWithDuration:0.20 animations:^{
            btn.tintColor = active ? [UIColor whiteColor] : [UIColor colorWithWhite:1.0 alpha:0.40];
            btn.transform = active ? CGAffineTransformMakeScale(1.18, 1.18) : CGAffineTransformIdentity;
        }];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat itemH = 26.0;
    CGFloat spacing = 14.0;
    CGFloat totalH = self.symbolButtons.count * itemH + (self.symbolButtons.count - 1) * spacing;
    CGFloat startY = (self.bounds.size.height - totalH) * 0.5;
    for (NSUInteger i = 0; i < self.symbolButtons.count; i++) {
        self.symbolButtons[i].frame = CGRectMake(0.0, startY + i * (itemH + spacing), self.bounds.size.width, itemH);
    }
}

@end

// ============================================================================
// MARK: - DZLJBGlassArtifact (Dual-Backdrop Refraction + CAColorMatrix + Gyroscope)
// ============================================================================

@implementation DZLJBGlassArtifact

+ (void)registerArtifact:(DZLJBGlassArtifact *)artifact {
    if (!artifact) return;
    if (!gLiveArtifacts) {
        gLiveArtifacts = [NSHashTable weakObjectsHashTable];
    }
    [gLiveArtifacts addObject:artifact];
}

+ (void)startGyroscopeUpdatesIfNeeded {
    if (!gEnabled || !gGyroSpecularEnabled) {
        [self stopGyroscopeUpdates];
        return;
    }
    if (!gMotionManager) {
        gMotionManager = [[CMMotionManager alloc] init];
    }
    if (!gMotionManager.isDeviceMotionAvailable || gMotionManager.isDeviceMotionActive) {
        return;
    }
    gMotionManager.deviceMotionUpdateInterval = 1.0 / 30.0;
    [gMotionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue]
                                        withHandler:^(CMDeviceMotion *motion, NSError *error) {
        if (!motion || !gEnabled || !gGyroSpecularEnabled) return;
        // Chuyển góc nghiêng máy thành véc-tơ dịch chuyển ánh sáng phản quang mượt mà
        CGFloat roll  = MAX(-0.45, MIN(0.45, motion.attitude.roll));
        CGFloat pitch = MAX(-0.45, MIN(0.45, motion.attitude.pitch));

        CGPoint sPt = CGPointMake(MAX(0.0, MIN(1.0, 0.12 + roll * 0.55)),
                                  MAX(0.0, MIN(1.0, 0.04 + pitch * 0.45)));
        CGPoint ePt = CGPointMake(MAX(0.0, MIN(1.0, 0.88 - roll * 0.55)),
                                  MAX(0.0, MIN(1.0, 0.96 - pitch * 0.45)));

        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        for (DZLJBGlassArtifact *art in [gLiveArtifacts allObjects]) {
            if (!art.bezelOverlayView.hidden) {
                art.rimSpecularLayer.startPoint = sPt;
                art.rimSpecularLayer.endPoint   = ePt;
            }
        }
        [CATransaction commit];
    }];
}

+ (void)stopGyroscopeUpdates {
    if (gMotionManager && gMotionManager.isDeviceMotionActive) {
        [gMotionManager stopDeviceMotionUpdates];
    }
}

- (NSArray *)buildFilterChainWithBlur:(CGFloat)blurRadius saturation:(CGFloat)saturation isTinted:(BOOL)isTinted {
    Class filterCls = NSClassFromString(@"CAFilter");
    if (!filterCls || ![filterCls respondsToSelector:@selector(filterWithType:)]) return @[];

    NSMutableArray *chain = [NSMutableArray array];

    if (blurRadius > 0.2) {
        CAFilter *blur = [filterCls filterWithType:@"gaussianBlur"];
        if (blur) {
            [blur setValue:@(blurRadius) forKey:@"inputRadius"];
            [blur setValue:@YES forKey:@"inputNormalizeEdges"];
            [blur setValue:@"default" forKey:@"inputQuality"];
            [chain addObject:blur];
        }
    }

    CAFilter *saturate = [filterCls filterWithType:@"colorSaturate"];
    if (saturate) {
        [saturate setValue:@(saturation) forKey:@"inputAmount"];
        [chain addObject:saturate];
    }

    // Ma trận màu CAColorMatrix 4x5 tăng độ trong trẻo quang học chuẩn iOS 26.7 Clear / Tinted
    if ([NSValue respondsToSelector:@selector(valueWithCAColorMatrix:)]) {
        CAFilter *matrixFilter = [filterCls filterWithType:@"colorMatrix"];
        if (matrixFilter) {
            float boost = isTinted ? 1.02f : 1.08f;
            float lift  = isTinted ? 0.015f : 0.035f;
            CAColorMatrix mat = {
                boost, 0.0f,  0.0f,  0.0f, lift,
                0.0f,  boost, 0.0f,  0.0f, lift,
                0.0f,  0.0f,  boost + 0.03f, 0.0f, lift + 0.01f,
                0.0f,  0.0f,  0.0f,  1.0f, 0.0f
            };
            [matrixFilter setValue:[NSValue valueWithCAColorMatrix:mat] forKey:@"inputColorMatrix"];
            [chain addObject:matrixFilter];
        }
    }

    return chain;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _backdropClipView = [[DZLJBShaderPassThroughView alloc] initWithFrame:CGRectZero];

        Class backdropCls = NSClassFromString(@"CABackdropLayer");
        if (backdropCls) {
            // Tầng 1: Thân kính chính (Inner Body Backdrop)
            _bodyBackdropLayer = (CABackdropLayer *)[backdropCls layer];
            if ([_bodyBackdropLayer respondsToSelector:@selector(setAllowsInPlaceFiltering:)]) {
                _bodyBackdropLayer.allowsInPlaceFiltering = YES;
            }
            if ([_bodyBackdropLayer respondsToSelector:@selector(setScale:)]) {
                _bodyBackdropLayer.scale = 0.5;
            }
            [_backdropClipView.layer addSublayer:_bodyBackdropLayer];

            // Tầng 2: Viền Khúc xạ Thấu kính 2.5pt phóng nhẹ 1.06x (Bezel Lensing Refraction)
            _rimLensBackdropLayer = (CABackdropLayer *)[backdropCls layer];
            if ([_rimLensBackdropLayer respondsToSelector:@selector(setAllowsInPlaceFiltering:)]) {
                _rimLensBackdropLayer.allowsInPlaceFiltering = YES;
            }
            if ([_rimLensBackdropLayer respondsToSelector:@selector(setScale:)]) {
                _rimLensBackdropLayer.scale = 0.5;
            }
            _rimLensMaskLayer = [CAShapeLayer layer];
            _rimLensMaskLayer.fillColor   = [UIColor clearColor].CGColor;
            _rimLensMaskLayer.strokeColor = [UIColor whiteColor].CGColor;
            _rimLensMaskLayer.lineWidth   = 2.6;
            _rimLensBackdropLayer.mask    = _rimLensMaskLayer;
            [_backdropClipView.layer addSublayer:_rimLensBackdropLayer];
        }

        _tintFillView = [[DZLJBShaderPassThroughView alloc] initWithFrame:CGRectZero];
        [_backdropClipView addSubview:_tintFillView];

        // Tầng 3: Lớp Phản quang Mặt trong + Viền Bezel 1.2pt nằm trên cùng (không chứa blur để icon nét căng)
        _bezelOverlayView = [[DZLJBShaderPassThroughView alloc] initWithFrame:CGRectZero];

        _innerSpecularLayer = [CAGradientLayer layer];
        _innerSpecularLayer.startPoint = CGPointMake(0.0, 0.0);
        _innerSpecularLayer.endPoint   = CGPointMake(1.0, 1.0);
        _innerSpecularLayer.colors = @[
            (id)[UIColor colorWithWhite:1.0 alpha:0.24].CGColor,
            (id)[UIColor colorWithWhite:1.0 alpha:0.02].CGColor,
            (id)[UIColor colorWithWhite:0.0 alpha:0.04].CGColor,
            (id)[UIColor colorWithWhite:1.0 alpha:0.13].CGColor
        ];
        _innerSpecularLayer.locations = @[@0.0, @0.35, @0.70, @1.0];
        [_bezelOverlayView.layer addSublayer:_innerSpecularLayer];

        _rimSpecularLayer = [CAGradientLayer layer];
        _rimSpecularLayer.startPoint = CGPointMake(0.1, 0.0);
        _rimSpecularLayer.endPoint   = CGPointMake(0.9, 1.0);
        _rimSpecularLayer.colors = @[
            (id)[UIColor colorWithWhite:1.0 alpha:0.78].CGColor,
            (id)[UIColor colorWithWhite:1.0 alpha:0.12].CGColor,
            (id)[UIColor colorWithWhite:1.0 alpha:0.06].CGColor,
            (id)[UIColor colorWithWhite:1.0 alpha:0.46].CGColor
        ];
        _rimSpecularLayer.locations = @[@0.0, @0.45, @0.80, @1.0];

        _rimSpecularMaskLayer = [CAShapeLayer layer];
        _rimSpecularMaskLayer.fillColor   = [UIColor clearColor].CGColor;
        _rimSpecularMaskLayer.strokeColor = [UIColor whiteColor].CGColor;
        _rimSpecularLayer.mask = _rimSpecularMaskLayer;
        [_bezelOverlayView.layer addSublayer:_rimSpecularLayer];

        _lastBounds   = CGRectZero;
        _lastRadius   = -1.0;
        _lastRevision = 0;

        [DZLJBGlassArtifact registerArtifact:self];
    }
    return self;
}

- (void)applyToHostView:(UIView *)hostView
      hideStockMaterial:(UIView *)stockMaterialView
           shadowTarget:(UIView *)shadowTarget
          frameInShadow:(CGRect)frameInShadow
           cornerRadius:(CGFloat)radius
       useCircularCurve:(BOOL)circularCurve
             isExpanded:(BOOL)isExpanded
       suppressBackdrop:(BOOL)suppressBackdrop {
    if (!hostView) return;
    CGRect bounds = hostView.bounds;
    if (CGRectIsEmpty(bounds) || bounds.size.width < 10.0 || bounds.size.height < 10.0) return;

    // Ẩn triệt để nền xám xi-măng gốc của MTMaterialView để CABackdropLayer lấy mẫu trực tiếp màu hình nền!
    if (stockMaterialView) {
        objc_setAssociatedObject(stockMaterialView, kDZLJBHiddenByShaderKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        stockMaterialView.alpha  = 0.0;
        stockMaterialView.hidden = YES;
    }

    if (!suppressBackdrop) {
        if (self.backdropClipView.superview != hostView) {
            [self.backdropClipView removeFromSuperview];
            [hostView insertSubview:self.backdropClipView atIndex:0];
        } else if (hostView.subviews.firstObject != self.backdropClipView) {
            [hostView sendSubviewToBack:self.backdropClipView];
        }
        self.backdropClipView.hidden = NO;
    } else {
        self.backdropClipView.hidden = YES;
    }

    if (self.bezelOverlayView.superview != hostView) {
        [self.bezelOverlayView removeFromSuperview];
        [hostView addSubview:self.bezelOverlayView];
    } else if (hostView.subviews.lastObject != self.bezelOverlayView) {
        [hostView bringSubviewToFront:self.bezelOverlayView];
    }
    self.bezelOverlayView.hidden = NO;

    BOOL geomChanged = !CGRectEqualToRect(bounds, self.lastBounds) ||
                       (fabs(radius - self.lastRadius) > 0.05) ||
                       (isExpanded != self.lastExpanded);
    BOOL revChanged  = (self.lastRevision != gPrefsRevision);

    if (!geomChanged && !revChanged) return;

    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    CALayerCornerCurve curve = circularCurve ? kCACornerCurveCircular : kCACornerCurveContinuous;

    self.backdropClipView.frame = bounds;
    self.backdropClipView.layer.cornerCurve  = curve;
    self.backdropClipView.layer.cornerRadius = radius;

    BOOL isTinted = (gGlassStyle == DZLJBGlassStyleTinted);
    CGFloat activeBlur = isTinted ? MAX(24.0, gButtonBlurRadius) : gButtonBlurRadius;
    CGFloat activeSat  = isTinted ? 1.55 : 1.90;

    if (self.bodyBackdropLayer) {
        self.bodyBackdropLayer.frame = bounds;
        self.bodyBackdropLayer.cornerCurve  = curve;
        self.bodyBackdropLayer.cornerRadius = radius;
        if (revChanged || isExpanded != self.lastExpanded) {
            NSArray *bodyFilters = [self buildFilterChainWithBlur:activeBlur saturation:activeSat isTinted:isTinted];
            [self.bodyBackdropLayer setValue:bodyFilters forKey:@"filters"];
        }
    }

    // Khúc xạ mép thấu kính 2.5pt (phóng 1.06x từ tâm để bẻ cong hình nền ở viền nút kính!)
    if (self.rimLensBackdropLayer) {
        BOOL showEdgeLens = (gEdgeRefractionEnabled && !isExpanded && !suppressBackdrop);
        self.rimLensBackdropLayer.hidden = !showEdgeLens;
        if (showEdgeLens) {
            self.rimLensBackdropLayer.bounds   = bounds;
            self.rimLensBackdropLayer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
            self.rimLensBackdropLayer.transform = CATransform3DMakeScale(1.06, 1.06, 1.0);
            if (revChanged) {
                NSArray *rimFilters = [self buildFilterChainWithBlur:MAX(3.5, activeBlur * 0.38)
                                                          saturation:2.18
                                                            isTinted:NO];
                [self.rimLensBackdropLayer setValue:rimFilters forKey:@"filters"];
            }
            CGRect lensStrokeRect = CGRectInset(bounds, 1.3, 1.3);
            self.rimLensMaskLayer.frame = bounds;
            if (lensStrokeRect.size.width > 2.0 && lensStrokeRect.size.height > 2.0) {
                self.rimLensMaskLayer.path = [UIBezierPath bezierPathWithRoundedRect:lensStrokeRect
                                                                        cornerRadius:MAX(0.0, radius - 1.3)].CGPath;
            }
        }
    }

    // Nền phủ màu kính: tự động tối xuống rgba(15,15,20,0.65) khi mở rộng (chuẩn iOS 26.4+)
    self.tintFillView.frame = bounds;
    if (isExpanded) {
        self.tintFillView.backgroundColor = [UIColor colorWithRed:15.0/255.0 green:15.0/255.0 blue:20.0/255.0 alpha:0.65];
    } else if (isTinted) {
        self.tintFillView.backgroundColor = [UIColor colorWithRed:30.0/255.0 green:30.0/255.0 blue:35.0/255.0 alpha:MAX(0.38, gButtonTintAlpha)];
    } else {
        self.tintFillView.backgroundColor = [UIColor colorWithRed:20.0/255.0 green:22.0/255.0 blue:28.0/255.0 alpha:gButtonTintAlpha];
    }

    self.bezelOverlayView.frame = bounds;
    self.bezelOverlayView.layer.cornerCurve  = curve;
    self.bezelOverlayView.layer.cornerRadius = radius;

    self.innerSpecularLayer.frame   = bounds;
    self.innerSpecularLayer.opacity = self.isPressed ? 1.25f : 1.0f;

    self.rimSpecularLayer.frame   = bounds;
    self.rimSpecularLayer.opacity = (float)MIN(1.0, gSpecularIntensity + (self.isPressed ? 0.16 : 0.0));

    CGFloat rimW  = gRimBorderWidth;
    CGFloat halfW = rimW * 0.5;
    CGRect rimInset = CGRectInset(bounds, halfW, halfW);
    self.rimSpecularMaskLayer.frame     = bounds;
    self.rimSpecularMaskLayer.lineWidth = rimW;
    if (rimInset.size.width > 0 && rimInset.size.height > 0) {
        self.rimSpecularMaskLayer.path = [UIBezierPath bezierPathWithRoundedRect:rimInset
                                                                    cornerRadius:MAX(0.0, radius - halfW)].CGPath;
    }

    // Đổ bóng chiều sâu 3D cố định shadowPath (60fps mượt trên A11)
    if (shadowTarget && !shadowTarget.clipsToBounds && !isExpanded && !CGRectIsEmpty(frameInShadow)) {
        CALayer *sl = shadowTarget.layer;
        sl.shadowColor   = [UIColor blackColor].CGColor;
        sl.shadowOffset  = CGSizeMake(0.0, 6.0);
        sl.shadowRadius  = 12.0;
        sl.shadowOpacity = 0.16f;
        sl.shadowPath    = [UIBezierPath bezierPathWithRoundedRect:frameInShadow cornerRadius:radius].CGPath;
    } else if (shadowTarget) {
        shadowTarget.layer.shadowOpacity = 0.0f;
    }

    [CATransaction commit];

    self.lastBounds   = bounds;
    self.lastRadius   = radius;
    self.lastExpanded = isExpanded;
    self.lastRevision = gPrefsRevision;
}

- (void)setTouchIlluminated:(BOOL)pressed {
    self.isPressed = pressed;
    [CATransaction begin];
    [CATransaction setAnimationDuration:pressed ? 0.14 : 0.30];
    self.rimSpecularLayer.opacity   = (float)MIN(1.0, gSpecularIntensity + (pressed ? 0.18 : 0.0));
    self.innerSpecularLayer.opacity = pressed ? 1.35f : 1.0f;
    [CATransaction commit];
}

- (void)teardownWithStockMaterial:(UIView *)stockMaterialView shadowTarget:(UIView *)shadowTarget {
    self.backdropClipView.hidden = YES;
    self.bezelOverlayView.hidden = YES;
    if (stockMaterialView) {
        objc_setAssociatedObject(stockMaterialView, kDZLJBHiddenByShaderKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        stockMaterialView.hidden = NO;
        stockMaterialView.alpha  = 1.0;
    }
    if (shadowTarget) {
        shadowTarget.layer.shadowOpacity = 0.0f;
        shadowTarget.layer.shadowPath    = NULL;
    }
    self.lastRevision = 0;
}

@end
