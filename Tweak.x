//
//  Tweak.x
//  2C6C v3.0 — iOS 26.7 Liquid Glass Control Center cho iOS 15 – 16 Rootless
//
//  Package: com.dzljb.2c6c
//  Author:  dzljb
//

#import "Tweak.h"
#import <spawn.h>

extern char **environ;

// ============================================================================
// MARK: - Định nghĩa Biến Toàn cục
// ============================================================================

BOOL gEnabled                    = YES;
DZLJBGlassStyleMode gGlassStyle  = DZLJBGlassStyleClear;
CGFloat gCCBackgroundBlur        = 0.25;
CGFloat gCCBackgroundDimAlpha    = 0.05;
CGFloat gButtonBlurRadius        = 14.0;
CGFloat gButtonTintAlpha         = 0.14;
CGFloat gSpecularIntensity       = 0.85;
CGFloat gRimBorderWidth          = 1.25;
CGFloat gPlatterSquircleRadius   = 37.0;
BOOL gEdgeRefractionEnabled      = YES;
BOOL gGyroSpecularEnabled        = YES;

BOOL gEnableEditResize           = YES;
BOOL gShowTopActionButtons       = YES;
BOOL gShowRightPageBar           = YES;
BOOL gModernConnectivityGrid     = YES;
BOOL gModernMediaCard            = YES;
BOOL gColorSliderGlyphs          = YES;

BOOL gBouncePhysicsEnabled       = YES;
CGFloat gBounceIntensity         = 1.05;
BOOL gHapticsEnabled             = YES;
BOOL gIsEditModeActive           = NO;
NSUInteger gPrefsRevision        = 1;

static const void *kDZLJBGlassArtifactKey      = &kDZLJBGlassArtifactKey;
static const void *kDZLJBModuleExpandedKey     = &kDZLJBModuleExpandedKey;
static const void *kDZLJBModuleIDKey           = &kDZLJBModuleIDKey;
static const void *kDZLJBResizeHandleKey       = &kDZLJBResizeHandleKey;
static const void *kDZLJBMinusBadgeKey         = &kDZLJBMinusBadgeKey;
static const void *kDZLJBDragStartKey          = &kDZLJBDragStartKey;
static const void *kDZLJBMediaOverlayKey       = &kDZLJBMediaOverlayKey;
static const void *kDZLJBPillTitleKey          = &kDZLJBPillTitleKey;
static const void *kDZLJBPillStateKey          = &kDZLJBPillStateKey;
static const void *kDZLJBTopPlusBtnKey         = &kDZLJBTopPlusBtnKey;
static const void *kDZLJBTopPowerBtnKey        = &kDZLJBTopPowerBtnKey;
static const void *kDZLJBSidebarKey            = &kDZLJBSidebarKey;
static const void *kDZLJBBottomAddPillKey      = &kDZLJBBottomAddPillKey;
static const void *kDZLJBBgDimViewKey          = &kDZLJBBgDimViewKey;
static const void *kDZLJBLastBounceTimeKey     = &kDZLJBLastBounceTimeKey;
static const void *kDZLJBEmptyLongPressKey     = &kDZLJBEmptyLongPressKey;
static const void *kDZLJBEmptyTapKey           = &kDZLJBEmptyTapKey;

static NSHashTable<UIView *> *gTrackedViews = nil;
static NSHashTable<CCUIContentModuleContainerViewController *> *gTrackedContainerVCs = nil;
static NSMutableDictionary<NSString *, NSDictionary *> *gCustomSizes = nil;

static __weak UIView *gOverlayBackgroundMatView = nil;
static __weak CCUIModularControlCenterOverlayViewController *gActiveOverlayVC = nil;
static __weak CCUIModuleCollectionViewController *gActiveCollectionVC = nil;

static UIImpactFeedbackGenerator *gSoftFeedback       = nil;
static UISelectionFeedbackGenerator *gSelectFeedback  = nil;

// ============================================================================
// MARK: - Tiện ích Truy cập Ivar, Rung & Màu Vector CAPackage
// ============================================================================

static id DZLJBSafeIvar(id obj, const char *name) {
    if (!obj || !name) return nil;
    Ivar iv = class_getInstanceVariable(object_getClass(obj), name);
    return iv ? object_getIvar(obj, iv) : nil;
}

void DZLJBTriggerSoftHaptic(CGFloat intensity) {
    if (!gEnabled || !gHapticsEnabled) return;
    if (@available(iOS 13.0, *)) {
        if (!gSoftFeedback) {
            gSoftFeedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleSoft];
        }
        [gSoftFeedback prepare];
        [gSoftFeedback impactOccurredWithIntensity:MIN(1.0, MAX(0.2, intensity))];
    }
}

void DZLJBTriggerSelectionTick(void) {
    if (!gEnabled || !gHapticsEnabled) return;
    if (!gSelectFeedback) {
        gSelectFeedback = [[UISelectionFeedbackGenerator alloc] init];
    }
    [gSelectFeedback prepare];
    [gSelectFeedback selectionChanged];
}

static void DZLJBTrackView(UIView *v) {
    if (!v) return;
    if (!gTrackedViews) gTrackedViews = [NSHashTable weakObjectsHashTable];
    [gTrackedViews addObject:v];
}

static void DZLJBTrackContainerVC(CCUIContentModuleContainerViewController *vc) {
    if (!vc) return;
    if (!gTrackedContainerVCs) gTrackedContainerVCs = [NSHashTable weakObjectsHashTable];
    [gTrackedContainerVCs addObject:vc];
}

static UIView *DZLJBFindSubviewNamed(UIView *root, NSString *clsName, NSInteger depth) {
    if (!root || !clsName || depth < 0) return nil;
    Class cls = NSClassFromString(clsName);
    if (cls && [root isKindOfClass:cls]) return root;
    for (UIView *sub in root.subviews) {
        UIView *hit = DZLJBFindSubviewNamed(sub, clsName, depth - 1);
        if (hit) return hit;
    }
    return nil;
}

static void DZLJBCollectContainers(UIView *root, NSMutableArray<CCUIContentModuleContentContainerView *> *outArr) {
    if (!root || !outArr || root.hidden || root.alpha < 0.01) return;
    Class cls = NSClassFromString(@"CCUIContentModuleContentContainerView");
    if (cls && [root isKindOfClass:cls]) {
        [outArr addObject:(CCUIContentModuleContentContainerView *)root];
        return;
    }
    for (UIView *sub in root.subviews) {
        DZLJBCollectContainers(sub, outArr);
    }
}

// Tô màu đệ quy trực tiếp lên cây CAShapeLayer bên trong CCUICAPackageView (khắc phục lỗi icon Mặt trời / Loa bị đen!)
static void DZLJBColorizeLayerTree(CALayer *layer, UIColor *color, BOOL restoreDefault) {
    if (!layer) return;
    if (!restoreDefault) {
        layer.compositingFilter = nil;
        [layer setValue:nil forKey:@"filters"];
    }

    if ([layer isKindOfClass:[CAShapeLayer class]]) {
        CAShapeLayer *shape = (CAShapeLayer *)layer;
        if (!restoreDefault && color) {
            if (shape.fillColor && CGColorGetAlpha(shape.fillColor) > 0.05) {
                shape.fillColor = color.CGColor;
            }
            if (shape.strokeColor && CGColorGetAlpha(shape.strokeColor) > 0.05) {
                shape.strokeColor = color.CGColor;
            }
        }
    }

    for (CALayer *sub in layer.sublayers) {
        DZLJBColorizeLayerTree(sub, color, restoreDefault);
    }
}

static BOOL DZLJBIsAnyModuleCurrentlyExpanded(void) {
    for (CCUIContentModuleContainerViewController *vc in [gTrackedContainerVCs allObjects]) {
        if ([vc respondsToSelector:@selector(isExpanded)] && vc.isExpanded) {
            return YES;
        }
    }
    return NO;
}

static NSString *DZLJBModuleVietnameseName(NSString *modID) {
    NSDictionary<NSString *, NSString *> *dict = @{
        @"com.apple.control-center.FlashlightModule": @"Đèn pin",
        @"com.apple.control-center.LowPowerModule": @"Nguồn điện thấp",
        @"com.apple.control-center.OrientationLockModule": @"Khóa hướng dọc",
        @"com.apple.control-center.CalculatorModule": @"Máy tính",
        @"com.apple.control-center.CameraModule": @"Camera",
        @"com.apple.control-center.StopwatchModule": @"Bấm giờ",
        @"com.apple.control-center.AlarmModule": @"Báo thức",
        @"com.apple.control-center.DarkModeModule": @"Chế độ Tối",
        @"com.apple.control-center.TextSizeModule": @"Cỡ chữ",
        @"com.apple.control-center.MagnifierModule": @"Kính lúp",
        @"com.apple.control-center.QRCodeModule": @"Quét mã QR",
        @"com.apple.control-center.VoiceMemosModule": @"Ghi âm",
        @"com.apple.control-center.HearingDevicesModule": @"Nghe",
        @"com.apple.replaykit.controlcenter.screencapture": @"Ghi màn hình",
        @"com.apple.mediaremote.controlcenter.airplaymirroring": @"Phản chiếu",
        @"com.apple.shazamkit.controlcenter.ShazamModule": @"Nhận dạng nhạc",
        @"com.apple.mobiletimer.controlcenter.timer": @"Hẹn giờ"
    };
    if (modID && dict[modID]) return dict[modID];
    NSString *tail = [[modID componentsSeparatedByString:@"."] lastObject] ?: @"Điều khiển";
    return [tail stringByReplacingOccurrencesOfString:@"Module" withString:@""];
}

// ============================================================================
// MARK: - Đọc / Ghi Cấu hình & Làm Mới Giao diện Thời gian Thực
// ============================================================================

static BOOL DZLJBBool(NSDictionary *d, NSString *k, BOOL defVal) {
    id v = d[k];
    return [v respondsToSelector:@selector(boolValue)] ? [v boolValue] : defVal;
}

static CGFloat DZLJBFloat(NSDictionary *d, NSString *k, CGFloat defVal, CGFloat minV, CGFloat maxV) {
    id v = d[k];
    if ([v respondsToSelector:@selector(doubleValue)]) {
        return MIN(maxV, MAX(minV, (CGFloat)[v doubleValue]));
    }
    return defVal;
}

static void DZLJBSaveLayouts(void) {
    if (!gCustomSizes) return;
    NSString *dir = [kDZLJBLayoutsPlistPath stringByDeletingLastPathComponent];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    [gCustomSizes writeToFile:kDZLJBLayoutsPlistPath atomically:YES];
}

static void DZLJBLoadPrefs(void) {
    NSDictionary *p = [NSDictionary dictionaryWithContentsOfFile:kDZLJBPrefsPlistPath];
    gEnabled                = DZLJBBool(p, @"enabled", YES);
    gGlassStyle             = (DZLJBGlassStyleMode)(NSInteger)DZLJBFloat(p, @"glassStyle", 0, 0, 1);
    gCCBackgroundBlur       = DZLJBFloat(p, @"ccBackgroundBlur", 0.25, 0.0, 1.0);
    gCCBackgroundDimAlpha   = DZLJBFloat(p, @"ccBackgroundDimAlpha", 0.05, 0.0, 0.65);
    gButtonBlurRadius       = DZLJBFloat(p, @"buttonBlurRadius", 14.0, 0.0, 32.0);
    gButtonTintAlpha        = DZLJBFloat(p, @"buttonTintAlpha", 0.14, 0.0, 0.60);
    gSpecularIntensity      = DZLJBFloat(p, @"specularIntensity", 0.85, 0.0, 1.0);
    gRimBorderWidth         = DZLJBFloat(p, @"rimBorderWidth", 1.25, 0.5, 2.5);
    gPlatterSquircleRadius  = DZLJBFloat(p, @"platterSquircleRadius", 37.0, 20.0, 42.0);
    gEdgeRefractionEnabled  = DZLJBBool(p, @"edgeRefractionEnabled", YES);
    gGyroSpecularEnabled    = DZLJBBool(p, @"gyroSpecularEnabled", YES);

    gEnableEditResize       = DZLJBBool(p, @"enableEditResize", YES);
    gShowTopActionButtons   = DZLJBBool(p, @"showTopActionButtons", YES);
    gShowRightPageBar       = DZLJBBool(p, @"showRightPageBar", YES);
    gModernConnectivityGrid = DZLJBBool(p, @"modernConnectivityGrid", YES);
    gModernMediaCard        = DZLJBBool(p, @"modernMediaCard", YES);
    gColorSliderGlyphs      = DZLJBBool(p, @"colorSliderGlyphs", YES);

    gBouncePhysicsEnabled   = DZLJBBool(p, @"bouncePhysicsEnabled", YES);
    gBounceIntensity        = DZLJBFloat(p, @"bounceIntensity", 1.05, 0.5, 1.5);
    gHapticsEnabled         = DZLJBBool(p, @"hapticsEnabled", YES);

    NSDictionary *savedLayouts = [NSDictionary dictionaryWithContentsOfFile:kDZLJBLayoutsPlistPath];
    gCustomSizes = savedLayouts ? [savedLayouts mutableCopy] : (gCustomSizes ?: [NSMutableDictionary dictionary]);
    gPrefsRevision++;
}

void DZLJBTriggerLiveGridRelayout(BOOL animated) {
    CCUIModuleCollectionViewController *colVC = gActiveCollectionVC;
    if (!colVC) {
        Class cls = NSClassFromString(@"CCUIModularControlCenterOverlayViewController");
        if (!cls) cls = NSClassFromString(@"CCUIModularControlCenterViewController");
        if (cls && [cls respondsToSelector:@selector(_sharedCollectionViewController)]) {
            colVC = [cls _sharedCollectionViewController];
        }
    }
    if (!colVC || ![colVC respondsToSelector:@selector(_refreshPositionProviders)]) return;

    void (^work)(void) = ^{
        [colVC _refreshPositionProviders];
        if (colVC.viewLoaded) {
            [colVC.view setNeedsLayout];
            [colVC.view layoutIfNeeded];
        }
    };

    if (animated) {
        [UIView animateWithDuration:0.42
                              delay:0.0
             usingSpringWithDamping:0.66
              initialSpringVelocity:0.6
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                         animations:work
                         completion:nil];
    } else {
        work();
    }
}

static void DZLJBRefreshAllLiveObjects(void) {
    if (gActiveOverlayVC) {
        [gActiveOverlayVC dzljb_refreshOverlayUI];
    }
    for (CCUIContentModuleContainerViewController *vc in [gTrackedContainerVCs allObjects]) {
        [vc dzljb_updateContainerEditChrome];
        [vc dzljb_updateModernMediaOverlay];
    }
    for (UIView *v in [gTrackedViews allObjects]) {
        if ([v respondsToSelector:@selector(dzljb_refreshLiquidGlass)]) {
            [(CCUIContentModuleContentContainerView *)v dzljb_refreshLiquidGlass];
        }
        if ([v respondsToSelector:@selector(dzljb_refreshButtonLiquidGlass)]) {
            [(CCUIButtonModuleView *)v dzljb_refreshButtonLiquidGlass];
        }
        [v setNeedsLayout];
    }
}

static void DZLJBOnPrefsChanged(CFNotificationCenterRef c, void *o, CFStringRef n, const void *obj, CFDictionaryRef u) {
    dispatch_async(dispatch_get_main_queue(), ^{
        DZLJBLoadPrefs();
        DZLJBRefreshAllLiveObjects();
        DZLJBTriggerLiveGridRelayout(NO);
    });
}

static void DZLJBOnResetLayouts(CFNotificationCenterRef c, void *o, CFStringRef n, const void *obj, CFDictionaryRef u) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [gCustomSizes removeAllObjects];
        [[NSFileManager defaultManager] removeItemAtPath:kDZLJBLayoutsPlistPath error:nil];
        gPrefsRevision++;
        DZLJBTriggerLiveGridRelayout(YES);
        DZLJBRefreshAllLiveObjects();
    });
}

// ============================================================================
// MARK: - Lớp Giao diện Mục Nhạc Chuẩn Ảnh 4 (Album Art + Nút Tai Nghe Tròn + Căn Trái)
// ============================================================================

@interface DZLJBMediaCardHeaderView : UIView
@property (nonatomic, strong) UIImageView *artworkBox;
@property (nonatomic, strong) UIImageView *fallbackMusicGlyph;
@property (nonatomic, strong) UIButton *routeCircleButton;
@property (nonatomic, strong) UILabel *songTitleLabel;
@property (nonatomic, strong) UILabel *artistSubtitleLabel;
@property (nonatomic, copy) void (^onTapRoute)(void);
- (void)refreshNowPlayingMetadata;
@end

@implementation DZLJBMediaCardHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

        // Ô vuông bo góc Album Art góc trên-trái giống hệt Ảnh 4 (image_f3a15b.png)
        _artworkBox = [[UIImageView alloc] initWithFrame:CGRectZero];
        _artworkBox.backgroundColor = [UIColor colorWithRed:0.34 green:0.38 blue:0.48 alpha:0.52];
        _artworkBox.contentMode = UIViewContentModeScaleAspectFill;
        _artworkBox.clipsToBounds = YES;
        _artworkBox.layer.cornerRadius = 12.5;
        _artworkBox.layer.cornerCurve  = kCACornerCurveContinuous;
        _artworkBox.layer.borderWidth  = 0.8;
        _artworkBox.layer.borderColor  = [UIColor colorWithWhite:1.0 alpha:0.22].CGColor;
        [self addSubview:_artworkBox];

        _fallbackMusicGlyph = [[UIImageView alloc] initWithFrame:CGRectZero];
        _fallbackMusicGlyph.contentMode = UIViewContentModeCenter;
        _fallbackMusicGlyph.tintColor   = [UIColor colorWithWhite:1.0 alpha:0.45];
        if (@available(iOS 13.0, *)) {
            UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:19.0 weight:UIImageSymbolWeightSemibold];
            _fallbackMusicGlyph.image = [UIImage systemImageNamed:@"music.note" withConfiguration:cfg];
        }
        [_artworkBox addSubview:_fallbackMusicGlyph];

        // Nút định tuyến tai nghe / AirPlay tròn góc trên-phải giống Ảnh 4
        _routeCircleButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _routeCircleButton.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15];
        _routeCircleButton.tintColor = [UIColor whiteColor];
        _routeCircleButton.clipsToBounds = YES;
        _routeCircleButton.layer.cornerCurve = kCACornerCurveCircular;
        if (@available(iOS 13.0, *)) {
            UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:15.0 weight:UIImageSymbolWeightSemibold];
            UIImage *airpods = [UIImage systemImageNamed:@"airpodspro" withConfiguration:cfg];
            if (!airpods) airpods = [UIImage systemImageNamed:@"airplayaudio" withConfiguration:cfg];
            [_routeCircleButton setImage:airpods forState:UIControlStateNormal];
        }
        [_routeCircleButton addTarget:self action:@selector(handleRouteTap) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_routeCircleButton];

        // Nhãn bài hát căn trái đậm nét bên dưới Album Art
        _songTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _songTitleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightBold];
        _songTitleLabel.textColor = [UIColor colorWithWhite:0.96 alpha:0.92];
        _songTitleLabel.textAlignment = NSTextAlignmentLeft;
        _songTitleLabel.text = @"Không phát";
        [self addSubview:_songTitleLabel];

        _artistSubtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _artistSubtitleLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium];
        _artistSubtitleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.58];
        _artistSubtitleLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:_artistSubtitleLabel];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refreshNowPlayingMetadata)
                                                     name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
                                                   object:nil];
        [self refreshNowPlayingMetadata];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleRouteTap {
    DZLJBTriggerSelectionTick();
    if (self.onTapRoute) self.onTapRoute();
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    CGPoint ptInRoute = [self convertPoint:point toView:self.routeCircleButton];
    if (CGRectContainsPoint(CGRectInset(self.routeCircleButton.bounds, -8.0, -8.0), ptInRoute)) {
        return self.routeCircleButton;
    }
    return nil; // Cho phép chạm xuyên xuống vùng mở bài hát & các nút tua ⏮ ▶ ⏭ bên dưới!
}

- (void)refreshNowPlayingMetadata {
    MPMediaItem *item = [[MPMusicPlayerController systemMusicPlayer] nowPlayingItem];
    if (item && item.title.length > 0) {
        self.songTitleLabel.text      = item.title;
        self.songTitleLabel.textColor = [UIColor whiteColor];
        self.artistSubtitleLabel.text = item.artist ?: @"";
        self.artistSubtitleLabel.hidden = (self.artistSubtitleLabel.text.length == 0);
        UIImage *art = [item.artwork imageWithSize:CGSizeMake(120, 120)];
        self.artworkBox.image = art;
        self.fallbackMusicGlyph.hidden = (art != nil);
    } else {
        self.songTitleLabel.text      = @"Không phát";
        self.songTitleLabel.textColor = [UIColor colorWithWhite:0.86 alpha:0.78];
        self.artistSubtitleLabel.text = @"";
        self.artistSubtitleLabel.hidden = YES;
        self.artworkBox.image = nil;
        self.fallbackMusicGlyph.hidden = NO;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    if (w < 100.0 || h < 80.0) return;

    BOOL isWideBanner = (w > 240.0);
    if (isWideBanner) {
        // Bố cục 4x2 rộng (giống khung nhạc ngang đáy Ảnh 3)
        CGFloat artSide = MIN(h - 28.0, 96.0);
        self.artworkBox.frame = CGRectMake(16.0, (h - artSide) * 0.5, artSide, artSide);
        self.fallbackMusicGlyph.frame = self.artworkBox.bounds;
        self.routeCircleButton.frame = CGRectMake(w - 50.0, 16.0, 34.0, 34.0);
        self.routeCircleButton.layer.cornerRadius = 17.0;

        CGFloat textX = CGRectGetMaxX(self.artworkBox.frame) + 14.0;
        CGFloat textW = MAX(60.0, w - textX - 58.0);
        self.songTitleLabel.frame = CGRectMake(textX, 22.0, textW, 20.0);
        self.artistSubtitleLabel.frame = CGRectMake(textX, 42.0, textW, 16.0);
    } else {
        // Bố cục 2x2 chuẩn Ảnh 4 (image_f3a15b.png)
        self.artworkBox.frame = CGRectMake(14.0, 14.0, 48.0, 48.0);
        self.fallbackMusicGlyph.frame = self.artworkBox.bounds;
        self.routeCircleButton.frame = CGRectMake(w - 50.0, 16.0, 36.0, 36.0);
        self.routeCircleButton.layer.cornerRadius = 18.0;

        self.songTitleLabel.frame = CGRectMake(15.0, 72.0, w - 30.0, 20.0);
        self.artistSubtitleLabel.frame = CGRectMake(15.0, 91.0, w - 30.0, 15.0);
    }
}

@end

// ============================================================================
// MARK: - Group 1: Hook Trọng tâm ControlCenterUI, ControlCenterUIKit & MaterialKit
// ============================================================================

%group CoreCCHooks

// ----------------------------------------------------------------------------
// 1. MTMaterialView — Khóa Blur Nền CC Về 0% Trong Vắt & Chặn Nền Xám Module Gốc
// ----------------------------------------------------------------------------

%hook MTMaterialView

- (void)setWeighting:(CGFloat)weighting {
    if (gEnabled && self == gOverlayBackgroundMatView) {
        // Cho phép kéo thanh trượt "Độ mờ nền phía sau CC" về 0.0 để thấy rõ nét màn hình chính!
        %orig(weighting * gCCBackgroundBlur);
        return;
    }
    %orig(weighting);
}

- (void)setAlpha:(CGFloat)alpha {
    NSNumber *suppressed = objc_getAssociatedObject(self, @selector(dzljb_activeMaterialView));
    if (gEnabled && [suppressed boolValue]) {
        %orig(0.0);
        return;
    }
    %orig(alpha);
}

%end

// ----------------------------------------------------------------------------
// 2. CCUILayoutOptions — Khoảng cách Lưới Chuẩn iOS 26.7 (66pt ô / 14pt khe hở)
// ----------------------------------------------------------------------------

%hook CCUILayoutOptions

- (CGFloat)itemEdgeSize {
    CGFloat orig = %orig;
    if (!gEnabled) return orig;
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    if (screenW <= 395.0 && orig > 60.0 && orig < 80.0) {
        return 66.0;
    }
    return orig;
}

- (CGFloat)itemSpacing {
    CGFloat orig = %orig;
    if (!gEnabled) return orig;
    if (orig > 6.0 && orig < 24.0) {
        return 14.0;
    }
    return orig;
}

%end

// ----------------------------------------------------------------------------
// 3. CCUIModuleCollectionViewController — Đổi kích thước nút thực tế theo tay kéo
// ----------------------------------------------------------------------------

%hook CCUIModuleCollectionViewController

- (void)viewDidLoad {
    %orig;
    gActiveCollectionVC = self;
}

- (NSArray<NSValue *> *)_sizesForModuleIdentifiers:(NSArray<NSString *> *)moduleIdentifiers
                        moduleInstanceByIdentifier:(NSDictionary *)moduleInstanceByIdentifier
                              interfaceOrientation:(long long)interfaceOrientation {
    NSArray<NSValue *> *orig = %orig;
    gActiveCollectionVC = self;

    if (!gEnabled || !gCustomSizes || gCustomSizes.count == 0 ||
        !orig || orig.count != moduleIdentifiers.count) {
        return orig;
    }

    NSMutableArray<NSValue *> *mut = [orig mutableCopy];
    BOOL landscape = (interfaceOrientation == 3 || interfaceOrientation == 4);
    NSUInteger maxW = landscape ? 8 : 4;

    for (NSUInteger i = 0; i < moduleIdentifiers.count; i++) {
        NSDictionary *szDict = gCustomSizes[moduleIdentifiers[i]];
        if (!szDict) continue;

        CCUILayoutSize sz;
        sz.width  = MIN(maxW, (NSUInteger)MAX(1, [szDict[@"w"] integerValue]));
        sz.height = MIN((NSUInteger)4, (NSUInteger)MAX(1, [szDict[@"h"] integerValue]));

        NSValue *boxed = nil;
        if ([NSValue respondsToSelector:@selector(ccui_valueWithLayoutSize:)]) {
            boxed = [NSValue ccui_valueWithLayoutSize:sz];
        } else {
            boxed = [NSValue valueWithBytes:&sz objCType:@encode(CCUILayoutSize)];
        }
        if (boxed) mut[i] = boxed;
    }
    return mut;
}

%end

// ----------------------------------------------------------------------------
// 4. CCUIContentModuleContainerView — Mở rộng vùng chạm cho Nút (−) & Tay nắm (◞) ngoài viền cắt
// ----------------------------------------------------------------------------

%hook CCUIContentModuleContainerView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (gEnabled && gIsEditModeActive) {
        for (UIView *sub in self.subviews) {
            if ([sub isKindOfClass:[DZLJBResizeHandleView class]] || sub.tag == 262699) {
                if (!sub.hidden) {
                    CGPoint pt = [self convertPoint:point toView:sub];
                    if (CGRectContainsPoint(CGRectInset(sub.bounds, -12.0, -12.0), pt)) {
                        return YES;
                    }
                }
            }
        }
    }
    return %orig(point, event);
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (gEnabled && gIsEditModeActive) {
        for (UIView *sub in [self.subviews reverseObjectEnumerator]) {
            if ([sub isKindOfClass:[DZLJBResizeHandleView class]] || sub.tag == 262699) {
                if (!sub.hidden) {
                    CGPoint pt = [self convertPoint:point toView:sub];
                    if (CGRectContainsPoint(CGRectInset(sub.bounds, -12.0, -12.0), pt)) {
                        return sub;
                    }
                }
            }
        }
    }
    return %orig(point, event);
}

%end

// ----------------------------------------------------------------------------
// 5. CCUIContentModuleContainerViewController — Tay nắm Kéo giãn KHÔNG BỊ CẮT & Mục Nhạc Ảnh 4
// ----------------------------------------------------------------------------

%hook CCUIContentModuleContainerViewController

- (void)viewDidLoad {
    %orig;
    DZLJBTrackContainerVC(self);
    if ([self respondsToSelector:@selector(contentContainerView)] && self.contentContainerView) {
        if ([self respondsToSelector:@selector(moduleIdentifier)] && self.moduleIdentifier) {
            objc_setAssociatedObject(self.contentContainerView, kDZLJBModuleIDKey, self.moduleIdentifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
        }
        DZLJBTrackView(self.contentContainerView);
    }
}

- (void)setExpanded:(BOOL)expanded {
    %orig(expanded);
    if (expanded && gIsEditModeActive && gActiveOverlayVC) {
        [gActiveOverlayVC dzljb_setEditModeActive:NO];
    }
    if ([self respondsToSelector:@selector(contentContainerView)] && self.contentContainerView) {
        CCUIContentModuleContentContainerView *c = self.contentContainerView;
        objc_setAssociatedObject(c, kDZLJBModuleExpandedKey, @(expanded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        c.transform = CGAffineTransformIdentity;
        [c dzljb_refreshLiquidGlass];
    }
    [self dzljb_updateContainerEditChrome];
    [self dzljb_updateModernMediaOverlay];
    if (gActiveOverlayVC) {
        [gActiveOverlayVC dzljb_refreshOverlayUI];
    }
}

%new
- (void)dzljb_handleMinusBadgeTap:(UIButton *)sender {
    NSString *modID = [self respondsToSelector:@selector(moduleIdentifier)] ? self.moduleIdentifier : nil;
    if (!modID) return;

    // Nếu nút đang bị kéo giãn khác cỡ gốc -> trả về cỡ gốc trước; nếu đang ở cỡ gốc -> gỡ nút khỏi CC!
    if (gCustomSizes[modID]) {
        DZLJBTriggerSoftHaptic(0.85);
        [gCustomSizes removeObjectForKey:modID];
        DZLJBSaveLayouts();
        DZLJBTriggerLiveGridRelayout(YES);
        return;
    }

    Class provCls = NSClassFromString(@"CCSModuleSettingsProvider");
    if (provCls && [provCls respondsToSelector:@selector(sharedProvider)]) {
        CCSModuleSettingsProvider *prov = [provCls sharedProvider];
        if ([prov respondsToSelector:@selector(orderedUserEnabledModuleIdentifiers)] &&
            [prov respondsToSelector:@selector(setAndSaveOrderedUserEnabledModuleIdentifiers:)]) {
            NSMutableArray *arr = [prov.orderedUserEnabledModuleIdentifiers mutableCopy];
            if ([arr containsObject:modID]) {
                DZLJBTriggerSoftHaptic(0.90);
                [arr removeObject:modID];
                [prov setAndSaveOrderedUserEnabledModuleIdentifiers:arr];
                DZLJBTriggerLiveGridRelayout(YES);
            }
        }
    }
}

%new
- (void)dzljb_handleResizePan:(UIPanGestureRecognizer *)pan {
    if (!gEnabled || !gEnableEditResize || !gIsEditModeActive) return;
    NSString *modID = [self respondsToSelector:@selector(moduleIdentifier)] ? self.moduleIdentifier : nil;
    if (!modID || !self.view) return;

    if (pan.state == UIGestureRecognizerStateBegan) {
        DZLJBTriggerSelectionTick();
        CGSize curSize = self.contentContainerView ? self.contentContainerView.bounds.size : self.view.bounds.size;
        NSInteger cols = MAX(1, (NSInteger)round((curSize.width + 14.0) / 80.0));
        NSInteger rows = MAX(1, (NSInteger)round((curSize.height + 14.0) / 80.0));
        NSDictionary *saved = gCustomSizes[modID];
        if (saved) {
            cols = [saved[@"w"] integerValue];
            rows = [saved[@"h"] integerValue];
        }
        objc_setAssociatedObject(self, kDZLJBDragStartKey, @{@"w": @(cols), @"h": @(rows)}, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        NSDictionary *start = objc_getAssociatedObject(self, kDZLJBDragStartKey);
        if (!start) return;

        CGPoint delta = [pan translationInView:self.view.superview ?: self.view];
        NSInteger sW = [start[@"w"] integerValue];
        NSInteger sH = [start[@"h"] integerValue];

        NSInteger newW = MIN(4, MAX(1, sW + (NSInteger)round(delta.x / 62.0)));
        NSInteger newH = MIN(3, MAX(1, sH + (NSInteger)round(delta.y / 62.0)));
        if (newW == 3) newW = (delta.x >= 0) ? 4 : 2;
        if (newH == 3) newH = 2;

        NSDictionary *cur = gCustomSizes[modID];
        NSInteger prevW = cur ? [cur[@"w"] integerValue] : sW;
        NSInteger prevH = cur ? [cur[@"h"] integerValue] : sH;

        if (newW != prevW || newH != prevH) {
            DZLJBTriggerSelectionTick();
            gCustomSizes[modID] = @{@"w": @(newW), @"h": @(newH)};
            DZLJBSaveLayouts();
            DZLJBTriggerLiveGridRelayout(YES);
        }
    }
}

%new
- (void)dzljb_updateContainerEditChrome {
    if (!self.viewLoaded || !self.view) return;
    BOOL expanded = [self respondsToSelector:@selector(isExpanded)] ? self.isExpanded : NO;
    BOOL show = (gEnabled && gEnableEditResize && gIsEditModeActive && !expanded);

    // QUAN TRỌNG: Gắn nút (−) và tay nắm cong (◞) lên self.view (clipsToBounds = NO) ở NGOÀI mặt cắt tròn!
    if (!expanded) {
        self.view.clipsToBounds = NO;
    }

    DZLJBResizeHandleView *handle = objc_getAssociatedObject(self, kDZLJBResizeHandleKey);
    UIButton *minusBtn = objc_getAssociatedObject(self, kDZLJBMinusBadgeKey);

    if (!show) {
        handle.hidden   = YES;
        minusBtn.hidden = YES;
        return;
    }

    if (!handle) {
        handle = [[DZLJBResizeHandleView alloc] initWithFrame:CGRectMake(0, 0, 38.0, 38.0)];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
            initWithTarget:self
                    action:@selector(dzljb_handleResizePan:)];
        pan.cancelsTouchesInView = YES;
        [handle addGestureRecognizer:pan];

        // Ưu tiên cử chỉ kéo góc tuyệt đối trước UIScrollView của Control Center!
        if (gActiveOverlayVC) {
            UIScrollView *sv = DZLJBSafeIvar(gActiveOverlayVC, "_scrollView");
            if ([sv isKindOfClass:[UIScrollView class]] && sv.panGestureRecognizer) {
                [sv.panGestureRecognizer requireGestureRecognizerToFail:pan];
            }
        }

        [self.view addSubview:handle];
        objc_setAssociatedObject(self, kDZLJBResizeHandleKey, handle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    if (!minusBtn) {
        minusBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        minusBtn.tag = 262699;
        minusBtn.backgroundColor = [UIColor colorWithWhite:0.88 alpha:0.95];
        minusBtn.layer.cornerRadius = 12.0;
        minusBtn.layer.cornerCurve  = kCACornerCurveCircular;
        minusBtn.layer.shadowColor  = [UIColor blackColor].CGColor;
        minusBtn.layer.shadowOffset = CGSizeMake(0, 2);
        minusBtn.layer.shadowRadius = 4.0;
        minusBtn.layer.shadowOpacity = 0.30f;
        [minusBtn setTitle:@"−" forState:UIControlStateNormal];
        [minusBtn setTitleColor:[UIColor colorWithWhite:0.10 alpha:1.0] forState:UIControlStateNormal];
        minusBtn.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold];
        [minusBtn addTarget:self action:@selector(dzljb_handleMinusBadgeTap:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:minusBtn];
        objc_setAssociatedObject(self, kDZLJBMinusBadgeKey, minusBtn, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    CGRect targetFrame = self.contentContainerView ? self.contentContainerView.frame : self.view.bounds;
    handle.hidden   = NO;
    minusBtn.hidden = NO;
    minusBtn.frame  = CGRectMake(CGRectGetMinX(targetFrame) - 6.0, CGRectGetMinY(targetFrame) - 6.0, 24.0, 24.0);
    handle.frame    = CGRectMake(CGRectGetMaxX(targetFrame) - 30.0, CGRectGetMaxY(targetFrame) - 30.0, 38.0, 38.0);
    [self.view bringSubviewToFront:handle];
    [self.view bringSubviewToFront:minusBtn];
}

// Bố cục Mục Nhạc Chuẩn Ảnh 4 (image_f3a15b.png)
%new
- (void)dzljb_updateModernMediaOverlay {
    NSString *modID = [self respondsToSelector:@selector(moduleIdentifier)] ? self.moduleIdentifier : nil;
    if (![modID isEqualToString:@"com.apple.mediaremote.controlcenter.nowplaying"]) return;
    if (!self.contentContainerView) return;

    BOOL expanded = [self respondsToSelector:@selector(isExpanded)] ? self.isExpanded : NO;
    DZLJBMediaCardHeaderView *mediaCard = objc_getAssociatedObject(self, kDZLJBMediaOverlayKey);
    UIView *vcView = (self.contentViewController && self.contentViewController.viewLoaded) ? self.contentViewController.view : nil;

    BOOL active = (gEnabled && gModernMediaCard && !expanded && self.contentContainerView.bounds.size.height >= 120.0);

    // Ẩn nhãn "Không phát" căn giữa cũ ở nửa trên của Media gốc để thay bằng Album Art + Nhãn căn trái kiểu Ảnh 4
    if (vcView) {
        for (UIView *sub in vcView.subviews) {
            for (UIView *deep in sub.subviews) {
                if ([deep isKindOfClass:[UILabel class]] && deep.frame.origin.y < 85.0) {
                    deep.alpha = active ? 0.0 : 1.0;
                }
            }
            if ([sub isKindOfClass:[UILabel class]] && sub.frame.origin.y < 85.0) {
                sub.alpha = active ? 0.0 : 1.0;
            }
        }
    }

    if (!active) {
        if (mediaCard) mediaCard.hidden = YES;
        return;
    }

    if (!mediaCard) {
        mediaCard = [[DZLJBMediaCardHeaderView alloc] initWithFrame:CGRectZero];
        __weak typeof(self) weakSelf = self;
        mediaCard.onTapRoute = ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;
            // Mở chế độ mở rộng âm thanh / chọn tai nghe AirPlay mượt mà
            if ([strongSelf respondsToSelector:@selector(contentContainerView)]) {
                UIButton *stockRoute = (UIButton *)DZLJBFindSubviewNamed(strongSelf.contentContainerView, @"MPButton", 5);
                if ([stockRoute isKindOfClass:[UIControl class]]) {
                    [stockRoute sendActionsForControlEvents:UIControlEventTouchUpInside];
                }
            }
        };
        [self.contentContainerView addSubview:mediaCard];
        objc_setAssociatedObject(self, kDZLJBMediaOverlayKey, mediaCard, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    mediaCard.hidden = NO;
    mediaCard.frame  = self.contentContainerView.bounds;
    [mediaCard refreshNowPlayingMetadata];
    [self.contentContainerView bringSubviewToFront:mediaCard];
}

- (void)viewDidLayoutSubviews {
    %orig;
    [self dzljb_updateContainerEditChrome];
    [self dzljb_updateModernMediaOverlay];
}

%end

// ----------------------------------------------------------------------------
// 6. CCUIContentModuleContentContainerView — Shader Kính Lỏng + Vật lý Chạm Nảy (0.91x -> Damping 0.58)
// ----------------------------------------------------------------------------

%hook CCUIContentModuleContentContainerView

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        DZLJBTrackView(self);
        [self dzljb_refreshLiquidGlass];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig(touches, event);
    BOOL isExpanded = [objc_getAssociatedObject(self, kDZLJBModuleExpandedKey) boolValue];
    if (!gEnabled || !gBouncePhysicsEnabled || isExpanded || gIsEditModeActive) return;

    DZLJBTriggerSoftHaptic(0.72);
    DZLJBGlassArtifact *art = objc_getAssociatedObject(self, kDZLJBGlassArtifactKey);
    [art setTouchIlluminated:YES];

    [UIView animateWithDuration:0.22
                          delay:0.0
         usingSpringWithDamping:0.85
          initialSpringVelocity:0.0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.transform = CGAffineTransformMakeScale(0.91, 0.91);
                     }
                     completion:nil];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig(touches, event);
    DZLJBGlassArtifact *art = objc_getAssociatedObject(self, kDZLJBGlassArtifactKey);
    [art setTouchIlluminated:NO];

    if (!CGAffineTransformIsIdentity(self.transform)) {
        CGFloat damp = MIN(0.82, MAX(0.42, 0.58 / gBounceIntensity));
        [UIView animateWithDuration:0.52
                              delay:0.0
             usingSpringWithDamping:damp
              initialSpringVelocity:0.80
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.transform = CGAffineTransformIdentity;
                         }
                         completion:nil];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig(touches, event);
    DZLJBGlassArtifact *art = objc_getAssociatedObject(self, kDZLJBGlassArtifactKey);
    [art setTouchIlluminated:NO];
    if (!CGAffineTransformIsIdentity(self.transform)) {
        [UIView animateWithDuration:0.45
                              delay:0.0
             usingSpringWithDamping:0.62
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.transform = CGAffineTransformIdentity;
                         }
                         completion:nil];
    }
}

%new
- (UIView *)dzljb_activeMaterialView {
    UIView *mat = DZLJBSafeIvar(self, "_moduleMaterialView");
    if ([mat isKindOfClass:[UIView class]]) return mat;
    return DZLJBFindSubviewNamed(self, @"MTMaterialView", 1);
}

%new
- (UIView *)dzljb_embeddedSliderView {
    return DZLJBFindSubviewNamed(self, @"CCUIBaseSliderView", 4);
}

%new
- (void)dzljb_refreshLiquidGlass {
    DZLJBGlassArtifact *art = objc_getAssociatedObject(self, kDZLJBGlassArtifactKey);
    UIView *matView = [self dzljb_activeMaterialView];

    if (!gEnabled) {
        if (art) {
            if (matView) objc_setAssociatedObject(matView, @selector(dzljb_activeMaterialView), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [art teardownWithStockMaterial:matView shadowTarget:self];
        }
        return;
    }

    BOOL isExpanded = [objc_getAssociatedObject(self, kDZLJBModuleExpandedKey) boolValue];
    UIView *sliderView = [self dzljb_embeddedSliderView];

    // Nếu là thanh trượt: nhường việc vẽ kính cho CCUIBaseSliderView để thanh kéo trắng không bị phủ xám!
    if (sliderView && (!matView || matView.hidden || matView.bounds.size.width < 10.0)) {
        if (art) [art teardownWithStockMaterial:nil shadowTarget:nil];
        if (!self.clipsToBounds && !isExpanded) {
            CGRect sRect = [self convertRect:sliderView.bounds fromView:sliderView];
            BOOL circ = YES;
            CGFloat r = DZLJBComputeCornerRadius(sRect.size, NO, &circ);
            self.layer.shadowColor   = [UIColor blackColor].CGColor;
            self.layer.shadowOffset  = CGSizeMake(0.0, 6.0);
            self.layer.shadowRadius  = 12.0;
            self.layer.shadowOpacity = 0.16f;
            self.layer.shadowPath    = [UIBezierPath bezierPathWithRoundedRect:sRect cornerRadius:r].CGPath;
        } else {
            self.layer.shadowOpacity = 0.0f;
        }
        return;
    }

    if (!matView) return;
    objc_setAssociatedObject(matView, @selector(dzljb_activeMaterialView), @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if (!art) {
        art = [[DZLJBGlassArtifact alloc] init];
        objc_setAssociatedObject(self, kDZLJBGlassArtifactKey, art, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    // Xác định vùng hiển thị thực tế của module (khi mở rộng như Ảnh 2 kết nối, bám theo khung mở rộng thay vì 0,0!)
    UIView *hostView = self;
    CGRect targetBounds = self.bounds;
    if (isExpanded && matView.bounds.size.width > 50.0 && !CGRectEqualToRect(matView.bounds, targetBounds)) {
        // Nếu iOS chỉ mở rộng khung con của module ở giữa màn hình, bám sát theo khung matView!
        targetBounds = matView.frame;
    }

    UIView *btnInside = DZLJBFindSubviewNamed(self, @"CCUIButtonModuleView", 3);
    BOOL isSelectedToggle = NO;
    if (btnInside && [btnInside respondsToSelector:@selector(isSelected)] && self.bounds.size.width <= 92.0 && !isExpanded) {
        isSelectedToggle = [(CCUIButtonModuleView *)btnInside isSelected];
    }

    BOOL useCircular = NO;
    CGFloat r = DZLJBComputeCornerRadius(hostView.bounds.size, isExpanded, &useCircular);
    self.layer.cornerCurve = useCircular ? kCACornerCurveCircular : kCACornerCurveContinuous;
    if ([self respondsToSelector:@selector(setCompactContinuousCornerRadius:)]) {
        self.compactContinuousCornerRadius = r;
    }
    if ([self respondsToSelector:@selector(setExpandedContinuousCornerRadius:)]) {
        self.expandedContinuousCornerRadius = 38.0;
    }

    [art applyToHostView:hostView
       hideStockMaterial:matView
            shadowTarget:self
           frameInShadow:hostView.bounds
            cornerRadius:r
        useCircularCurve:useCircular
              isExpanded:isExpanded
        suppressBackdrop:isSelectedToggle];
}

- (void)layoutSubviews {
    %orig;
    [self dzljb_refreshLiquidGlass];
}

%end

// ----------------------------------------------------------------------------
// 7. CCUIBaseSliderView — Mặt Trời Vàng, Loa Xanh, Kính Trong, Thanh Kéo Trắng 0.78 & Kéo Dãn Overshoot
// ----------------------------------------------------------------------------

%hook CCUIBaseSliderView

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        DZLJBTrackView(self);
        [self dzljb_refreshLiquidGlass];
    }
}

// Kéo lố 0% hoặc 100% -> dãn đàn hồi (0.95, 1.07) đúng đặc tả iOS 26.7
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig(touches, event);
    if (!gEnabled || !gBouncePhysicsEnabled || gIsEditModeActive) return;
    UITouch *t = [touches anyObject];
    if (!t) return;

    CGPoint pt = [t locationInView:self];
    CGFloat h = self.bounds.size.height;
    if (h <= 20.0) return;

    if (pt.y < -4.0) {
        CGFloat pull = MIN(1.0, (-pt.y) / 90.0);
        self.transform = CGAffineTransformConcat(
            CGAffineTransformMakeScale(1.0 - 0.05 * pull, 1.0 + 0.07 * pull),
            CGAffineTransformMakeTranslation(0.0, -5.0 * pull)
        );
    } else if (pt.y > h + 4.0) {
        CGFloat pull = MIN(1.0, (pt.y - h) / 90.0);
        self.transform = CGAffineTransformConcat(
            CGAffineTransformMakeScale(1.0 - 0.05 * pull, 1.0 + 0.07 * pull),
            CGAffineTransformMakeTranslation(0.0, 5.0 * pull)
        );
    } else if (!CGAffineTransformIsIdentity(self.transform)) {
        self.transform = CGAffineTransformIdentity;
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig(touches, event);
    if (!CGAffineTransformIsIdentity(self.transform)) {
        [UIView animateWithDuration:0.46
                              delay:0.0
             usingSpringWithDamping:0.58
              initialSpringVelocity:0.7
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.transform = CGAffineTransformIdentity;
                         }
                         completion:nil];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig(touches, event);
    self.transform = CGAffineTransformIdentity;
}

%new
- (void)dzljb_tintSliderGlyphAndFill {
    // 1. Làm thanh trắng bên trong bán trong suốt 0.78 thay vì trắng đục hay xám đục
    UIView *clippingView = DZLJBSafeIvar(self, "_clippingView");
    if (!clippingView) clippingView = DZLJBSafeIvar(self, "_levelView");
    if ([clippingView isKindOfClass:[UIView class]]) {
        clippingView.alpha = gEnabled ? 0.80 : 1.0;
        for (UIView *fillSub in clippingView.subviews) {
            if ([fillSub isKindOfClass:NSClassFromString(@"MTMaterialView")]) {
                fillSub.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.86];
            }
        }
    }

    // 2. Tô màu trực tiếp lên CAShapeLayer bên trong _glyphPackageView (Mặt trời Vàng / Loa Xanh)
    UIView *glyphPkg = DZLJBSafeIvar(self, "_glyphPackageView");
    UIView *glyphImg = DZLJBSafeIvar(self, "_glyphImageView");
    UIView *compensatingPkg = DZLJBSafeIvar(self, "_compensatingGlyphPackageView");

    if (!gEnabled || !gColorSliderGlyphs) {
        if (glyphPkg) DZLJBColorizeLayerTree(glyphPkg.layer, nil, YES);
        if (compensatingPkg) DZLJBColorizeLayerTree(compensatingPkg.layer, nil, YES);
        return;
    }

    // Nhận diện chính xác Độ sáng vs Âm lượng qua Responder Chain (CCUIDisplayModuleViewController vs Audio)
    BOOL isBrightness = NO;
    UIResponder *resp = self.nextResponder;
    while (resp) {
        NSString *clsStr = NSStringFromClass([resp class]);
        if ([clsStr localizedCaseInsensitiveContainsString:@"Display"] ||
            [clsStr localizedCaseInsensitiveContainsString:@"Brightness"]) {
            isBrightness = YES;
            break;
        }
        if ([clsStr localizedCaseInsensitiveContainsString:@"Audio"] ||
            [clsStr localizedCaseInsensitiveContainsString:@"Volume"]) {
            isBrightness = NO;
            break;
        }
        resp = resp.nextResponder;
    }

    UIColor *accent = isBrightness
        ? [UIColor colorWithRed:1.00 green:0.74 blue:0.04 alpha:1.0]  // Vàng nắng Mặt trời (#FFBC0A)
        : [UIColor colorWithRed:0.08 green:0.70 blue:1.00 alpha:1.0]; // Xanh băng Âm lượng (#14B3FF)

    if (glyphPkg) DZLJBColorizeLayerTree(glyphPkg.layer, accent, NO);
    if (compensatingPkg) DZLJBColorizeLayerTree(compensatingPkg.layer, accent, NO);
    if ([glyphImg isKindOfClass:[UIImageView class]]) {
        UIImageView *iv = (UIImageView *)glyphImg;
        iv.image = [iv.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        iv.tintColor = accent;
    }
}

%new
- (void)dzljb_refreshLiquidGlass {
    DZLJBGlassArtifact *art = objc_getAssociatedObject(self, kDZLJBGlassArtifactKey);
    UIView *stockBg = DZLJBSafeIvar(self, "_backgroundView");

    if (!gEnabled) {
        if (art) {
            if (stockBg) objc_setAssociatedObject(stockBg, @selector(dzljb_activeMaterialView), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [art teardownWithStockMaterial:stockBg shadowTarget:nil];
        }
        [self dzljb_tintSliderGlyphAndFill];
        return;
    }

    CGRect b = self.bounds;
    if (CGRectIsEmpty(b)) return;

    if (stockBg) {
        objc_setAssociatedObject(stockBg, @selector(dzljb_activeMaterialView), @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    if (!art) {
        art = [[DZLJBGlassArtifact alloc] init];
        objc_setAssociatedObject(self, kDZLJBGlassArtifactKey, art, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    BOOL useCircular = YES;
    CGFloat pillRadius = DZLJBComputeCornerRadius(b.size, NO, &useCircular);

    self.clipsToBounds = YES;
    self.layer.cornerCurve  = useCircular ? kCACornerCurveCircular : kCACornerCurveContinuous;
    self.layer.cornerRadius = pillRadius;
    if ([self respondsToSelector:@selector(setContinuousSliderCornerRadius:)]) {
        self.continuousSliderCornerRadius = pillRadius;
    }

    [art applyToHostView:self
       hideStockMaterial:stockBg
            shadowTarget:nil
           frameInShadow:CGRectZero
            cornerRadius:pillRadius
        useCircularCurve:useCircular
              isExpanded:NO
        suppressBackdrop:NO];

    [self dzljb_tintSliderGlyphAndFill];
}

- (void)layoutSubviews {
    %orig;
    [self dzljb_refreshLiquidGlass];
}

%end

// ----------------------------------------------------------------------------
// 8. CCUIButtonModuleView — Nút Tròn 1x1 & Tự Hiện Nhãn Tiếng Việt Khi Kéo Giãn 2x1
// ----------------------------------------------------------------------------

%hook CCUIButtonModuleView

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        DZLJBTrackView(self);
        [self dzljb_refreshButtonLiquidGlass];
    }
}

%new
- (void)dzljb_refreshButtonLiquidGlass {
    CGRect b = self.bounds;
    if (CGRectIsEmpty(b)) return;

    BOOL useCircular = YES;
    CGFloat r = DZLJBComputeCornerRadius(b.size, NO, &useCircular);
    if (gEnabled) {
        self.layer.cornerCurve  = useCircular ? kCACornerCurveCircular : kCACornerCurveContinuous;
        self.layer.cornerRadius = r;
        for (CALayer *sub in self.layer.sublayers) {
            if (CGRectEqualToRect(sub.bounds, b) || sub.cornerRadius > 2.0) {
                sub.cornerCurve  = useCircular ? kCACornerCurveCircular : kCACornerCurveContinuous;
                sub.cornerRadius = r;
            }
        }
    }

    // Kiểm tra có nằm trong cụm Kết nối hay không
    BOOL inConnectivity = NO;
    NSString *modID = nil;
    UIResponder *resp = self.nextResponder;
    while (resp) {
        if ([NSStringFromClass([resp class]) containsString:@"Connectivity"]) {
            inConnectivity = YES;
        }
        if ([resp isKindOfClass:NSClassFromString(@"CCUIContentModuleContainerViewController")]) {
            CCUIContentModuleContainerViewController *cvc = (CCUIContentModuleContainerViewController *)resp;
            if ([cvc respondsToSelector:@selector(moduleIdentifier)]) modID = cvc.moduleIdentifier;
            break;
        }
        resp = resp.nextResponder;
    }

    UILabel *titleLbl = objc_getAssociatedObject(self, kDZLJBPillTitleKey);
    UILabel *stateLbl = objc_getAssociatedObject(self, kDZLJBPillStateKey);
    BOOL isFocus = [modID localizedCaseInsensitiveContainsString:@"Focus"] ||
                   [modID localizedCaseInsensitiveContainsString:@"DoNotDisturb"];

    BOOL show2x1Label = (gEnabled && !inConnectivity && !isFocus && b.size.width >= 120.0 && b.size.height <= 92.0);
    UIView *glyphPkg = DZLJBSafeIvar(self, "_glyphPackageView");
    UIView *glyphImg = DZLJBSafeIvar(self, "_glyphImageView");

    if (show2x1Label) {
        CGFloat midY = b.size.height * 0.5;
        if (glyphPkg) glyphPkg.center = CGPointMake(34.0, midY);
        if (glyphImg) glyphImg.center = CGPointMake(34.0, midY);

        if (!titleLbl) {
            titleLbl = [[UILabel alloc] initWithFrame:CGRectZero];
            titleLbl.font = [UIFont systemFontOfSize:13.5 weight:UIFontWeightSemibold];
            [self addSubview:titleLbl];
            objc_setAssociatedObject(self, kDZLJBPillTitleKey, titleLbl, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        if (!stateLbl) {
            stateLbl = [[UILabel alloc] initWithFrame:CGRectZero];
            stateLbl.font = [UIFont systemFontOfSize:11.5 weight:UIFontWeightMedium];
            [self addSubview:stateLbl];
            objc_setAssociatedObject(self, kDZLJBPillStateKey, stateLbl, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }

        BOOL sel = [self respondsToSelector:@selector(isSelected)] ? self.isSelected : NO;
        titleLbl.hidden    = NO;
        stateLbl.hidden    = NO;
        titleLbl.text      = DZLJBModuleVietnameseName(modID);
        stateLbl.text      = sel ? @"Bật" : @"Tắt";
        titleLbl.textColor = sel ? [UIColor colorWithWhite:0.10 alpha:0.95] : [UIColor whiteColor];
        stateLbl.textColor = sel ? [UIColor colorWithWhite:0.30 alpha:0.90] : [UIColor colorWithWhite:1.0 alpha:0.65];

        CGFloat tx = 62.0;
        CGFloat tw = MAX(40.0, b.size.width - tx - 12.0);
        titleLbl.frame = CGRectMake(tx, midY - 16.0, tw, 17.0);
        stateLbl.frame = CGRectMake(tx, midY + 1.0, tw, 15.0);
    } else {
        titleLbl.hidden = YES;
        stateLbl.hidden = YES;
    }
}

- (void)layoutSubviews {
    %orig;
    [self dzljb_refreshButtonLiquidGlass];
}

%end

// ----------------------------------------------------------------------------
// 9. CCUIHeaderPocketView — Nền Trong Suốt & Đẩy Nhẹ Hàng Sóng/Pin Tránh Đụng Nút Đỉnh
// ----------------------------------------------------------------------------

%hook CCUIHeaderPocketView

- (void)setBackgroundAlpha:(double)alpha {
    %orig(gEnabled ? 0.0 : alpha);
}

%end

// ----------------------------------------------------------------------------
// 10. CCUIModularControlCenterOverlayViewController — Cuộn Trang Mượt, Nút (+) & (⏻) 34pt, Gallery Ảnh 5
// ----------------------------------------------------------------------------

%hook CCUIModularControlCenterOverlayViewController

- (void)viewDidLoad {
    %orig;
    gActiveOverlayVC = self;
    [self dzljb_refreshOverlayUI];
}

%new
- (void)dzljb_onTapTopPlus:(UIButton *)sender {
    DZLJBTriggerSoftHaptic(0.85);
    [self dzljb_setEditModeActive:!gIsEditModeActive];
}

%new
- (void)dzljb_onTapTopPower:(UIButton *)sender {
    DZLJBTriggerSoftHaptic(0.85);
    UIAlertController *sheet = [UIAlertController
        alertControllerWithTitle:@"Nguồn & Hệ thống"
                         message:nil
                  preferredStyle:UIAlertControllerStyleActionSheet];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Khởi động lại màn hình (Respring)" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        pid_t pid = 0;
        if (access("/var/jb/usr/bin/sbreload", X_OK) == 0) {
            const char *args[] = { "sbreload", NULL };
            posix_spawn(&pid, "/var/jb/usr/bin/sbreload", NULL, NULL, (char * const *)args, environ);
        } else {
            const char *args[] = { "killall", "-9", "SpringBoard", NULL };
            posix_spawn(&pid, "/var/jb/usr/bin/killall", NULL, NULL, (char * const *)args, environ);
        }
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Vào Chế độ An toàn (Safe Mode)" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        pid_t pid = 0;
        const char *args[] = { "killall", "-SEGV", "SpringBoard", NULL };
        posix_spawn(&pid, "/var/jb/usr/bin/killall", NULL, NULL, (char * const *)args, environ);
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Menu Tắt nguồn gốc của iOS" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        UIApplication *app = [UIApplication sharedApplication];
        SEL sel = NSSelectorFromString(@"showPowerDownAlert");
        if ([app respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [app performSelector:sel];
#pragma clang diagnostic pop
        }
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil]];
    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = sender;
        sheet.popoverPresentationController.sourceRect = sender.bounds;
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

// Mở Thư viện Thêm Điều Khiển chuẩn Ảnh 5 (image_f39cfe.jpg)
%new
- (void)dzljb_onTapAddControlsPill:(UIButton *)sender {
    DZLJBTriggerSoftHaptic(0.88);
    DZLJBControlsGalleryViewController *gallery = [[DZLJBControlsGalleryViewController alloc] init];
    gallery.modalPresentationStyle = UIModalPresentationOverFullScreen;
    gallery.modalTransitionStyle   = UIModalTransitionStyleCoverVertical;
    gallery.onModulesChanged = ^{
        DZLJBTriggerLiveGridRelayout(YES);
    };
    [self presentViewController:gallery animated:YES completion:nil];
}

%new
- (void)dzljb_onEmptyLongPress:(UILongPressGestureRecognizer *)gesture {
    if (!gEnabled || !gEnableEditResize || gesture.state != UIGestureRecognizerStateBegan) return;
    if (DZLJBIsAnyModuleCurrentlyExpanded()) return;

    CGPoint pt = [gesture locationInView:self.view];
    NSMutableArray<CCUIContentModuleContentContainerView *> *mods = [NSMutableArray array];
    DZLJBCollectContainers(self.view, mods);
    for (UIView *m in mods) {
        if (CGRectContainsPoint([self.view convertRect:m.bounds fromView:m], pt)) return;
    }
    DZLJBTriggerSoftHaptic(0.90);
    [self dzljb_setEditModeActive:!gIsEditModeActive];
}

%new
- (void)dzljb_onEmptyTap:(UITapGestureRecognizer *)tap {
    if (!gIsEditModeActive) return;
    CGPoint pt = [tap locationInView:self.view];

    UIButton *addPill = objc_getAssociatedObject(self, kDZLJBBottomAddPillKey);
    UIButton *plusBtn = objc_getAssociatedObject(self, kDZLJBTopPlusBtnKey);
    if ((addPill && !addPill.hidden && CGRectContainsPoint(CGRectInset(addPill.frame, -10, -10), pt)) ||
        (plusBtn && !plusBtn.hidden && CGRectContainsPoint(CGRectInset(plusBtn.frame, -10, -10), pt))) {
        return;
    }

    for (CCUIContentModuleContainerViewController *vc in [gTrackedContainerVCs allObjects]) {
        if (!vc.viewLoaded || !vc.view.window) continue;
        CGRect r = [self.view convertRect:vc.view.bounds fromView:vc.view];
        if (CGRectContainsPoint(CGRectInset(r, -16.0, -16.0), pt)) return;
    }

    DZLJBTriggerSelectionTick();
    [self dzljb_setEditModeActive:NO];
}

%new
- (void)dzljb_setEditModeActive:(BOOL)active {
    gIsEditModeActive = (active && gEnabled && gEnableEditResize);
    UITapGestureRecognizer *emptyTap = objc_getAssociatedObject(self, kDZLJBEmptyTapKey);
    if (emptyTap) emptyTap.enabled = gIsEditModeActive;

    for (CCUIContentModuleContainerViewController *vc in [gTrackedContainerVCs allObjects]) {
        [vc dzljb_updateContainerEditChrome];
    }
    [self dzljb_refreshOverlayUI];
}

%new
- (void)dzljb_refreshOverlayUI {
    if (!self.viewLoaded || !self.view) return;
    CGRect vBounds = self.view.bounds;
    BOOL anyExpanded = DZLJBIsAnyModuleCurrentlyExpanded();

    // 1. Liên kết _backgroundView với thanh trượt Blur nền CC (0.0 = Xuyên thấu 100%)
    UIView *bgMat = DZLJBSafeIvar(self, "_backgroundView");
    if ([bgMat isKindOfClass:NSClassFromString(@"MTMaterialView")]) {
        gOverlayBackgroundMatView = bgMat;
        MTMaterialView *mt = (MTMaterialView *)bgMat;
        if ([mt respondsToSelector:@selector(setWeighting:)]) {
            mt.weighting = gEnabled ? 1.0 : 1.0; // Hook setWeighting: sẽ nhân trực tiếp với gCCBackgroundBlur!
        }

        UIView *dimOverlay = objc_getAssociatedObject(self, kDZLJBBgDimViewKey);
        if (gEnabled) {
            if (!dimOverlay) {
                dimOverlay = [[UIView alloc] initWithFrame:bgMat.bounds];
                dimOverlay.userInteractionEnabled = NO;
                dimOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                [bgMat addSubview:dimOverlay];
                objc_setAssociatedObject(self, kDZLJBBgDimViewKey, dimOverlay, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            dimOverlay.hidden = NO;
            dimOverlay.frame  = bgMat.bounds;
            dimOverlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:gCCBackgroundDimAlpha];
        } else if (dimOverlay) {
            dimOverlay.hidden = YES;
        }
    }

    // 2. Sửa triệt để lỗi kẹt lướt lên xuống trên _scrollView!
    UIScrollView *sv = DZLJBSafeIvar(self, "_scrollView");
    if ([sv isKindOfClass:[UIScrollView class]]) {
        sv.scrollEnabled = YES;
        sv.alwaysBounceVertical = YES;
        sv.showsVerticalScrollIndicator = NO;
        if (gEnabled) {
            UIEdgeInsets insets = sv.contentInset;
            if (insets.bottom < 220.0) {
                insets.bottom = 220.0; // Mở rộng hành trình cuộn để lướt lên xuống mượt giữa các vùng trang!
                sv.contentInset = insets;
            }
        }
    }

    // 3. Đăng ký nhấn giữ vùng trống để mở Chế độ Sửa
    if (!objc_getAssociatedObject(self, kDZLJBEmptyLongPressKey)) {
        UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc]
            initWithTarget:self action:@selector(dzljb_onEmptyLongPress:)];
        lp.minimumPressDuration = 0.50;
        lp.cancelsTouchesInView = NO;
        [self.view addGestureRecognizer:lp];
        objc_setAssociatedObject(self, kDZLJBEmptyLongPressKey, lp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    if (!objc_getAssociatedObject(self, kDZLJBEmptyTapKey)) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
            initWithTarget:self action:@selector(dzljb_onEmptyTap:)];
        tap.cancelsTouchesInView = NO;
        tap.enabled = gIsEditModeActive;
        [self.view addGestureRecognizer:tap];
        objc_setAssociatedObject(self, kDZLJBEmptyTapKey, tap, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    // 4. Nút Kính Tròn 34x34pt (+) Góc Trái & (⏻) Góc Phải (Tự ẩn khi đang mở rộng module như Ảnh 2!)
    UIButton *plusBtn  = objc_getAssociatedObject(self, kDZLJBTopPlusBtnKey);
    UIButton *powerBtn = objc_getAssociatedObject(self, kDZLJBTopPowerBtnKey);

    if (gEnabled && gShowTopActionButtons && !anyExpanded) {
        if (!plusBtn) {
            plusBtn = DZLJBCreateLiquidCircleButton(@"plus", 34.0);
            [plusBtn addTarget:self action:@selector(dzljb_onTapTopPlus:) forControlEvents:UIControlEventTouchUpInside];
            [self.view addSubview:plusBtn];
            objc_setAssociatedObject(self, kDZLJBTopPlusBtnKey, plusBtn, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        if (!powerBtn) {
            powerBtn = DZLJBCreateLiquidCircleButton(@"power", 34.0);
            [powerBtn addTarget:self action:@selector(dzljb_onTapTopPower:) forControlEvents:UIControlEventTouchUpInside];
            [self.view addSubview:powerBtn];
            objc_setAssociatedObject(self, kDZLJBTopPowerBtnKey, powerBtn, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }

        plusBtn.hidden  = NO;
        powerBtn.hidden = NO;

        CGFloat safeTop = MAX(12.0, self.view.safeAreaInsets.top > 24.0 ? 12.0 : self.view.safeAreaInsets.top + 8.0);
        if (gIsEditModeActive) {
            [plusBtn setImage:nil forState:UIControlStateNormal];
            [plusBtn setTitle:@"Xong" forState:UIControlStateNormal];
            plusBtn.titleLabel.font = [UIFont systemFontOfSize:13.5 weight:UIFontWeightBold];
            plusBtn.frame = CGRectMake(22.0, safeTop, 62.0, 32.0);
            plusBtn.layer.cornerRadius = 16.0;
        } else {
            [plusBtn setTitle:nil forState:UIControlStateNormal];
            if (@available(iOS 13.0, *)) {
                UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:15.5 weight:UIImageSymbolWeightSemibold];
                [plusBtn setImage:[UIImage systemImageNamed:@"plus" withConfiguration:cfg] forState:UIControlStateNormal];
            }
            plusBtn.frame = CGRectMake(22.0, safeTop, 34.0, 34.0);
            plusBtn.layer.cornerRadius = 17.0;
        }

        powerBtn.frame = CGRectMake(vBounds.size.width - 22.0 - 34.0, safeTop, 34.0, 34.0);
        [self.view bringSubviewToFront:plusBtn];
        [self.view bringSubviewToFront:powerBtn];
    } else {
        plusBtn.hidden  = YES;
        powerBtn.hidden = YES;
    }

    // 5. Thanh phân trang cạnh phải (cách mép phải 11pt, tự ẩn khi mở rộng module, bấm nhảy trang mượt mà!)
    DZLJBPageSidebarView *sidebar = objc_getAssociatedObject(self, kDZLJBSidebarKey);
    if (gEnabled && gShowRightPageBar && !anyExpanded) {
        if (!sidebar) {
            sidebar = [[DZLJBPageSidebarView alloc] initWithFrame:CGRectZero];
            __weak typeof(self) weakSelf = self;
            sidebar.onSelectSection = ^(NSInteger idx) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;

                // Trang 1 (♫): Mở nhanh Trình phát nhạc; Trang 3 (📡): Mở nhanh Cụm Kết nối; Trang 0 & 2: Cuộn trang!
                if (idx == 1 || idx == 3) {
                    NSString *wantID = (idx == 1)
                        ? @"com.apple.mediaremote.controlcenter.nowplaying"
                        : @"com.apple.control-center.ConnectivityModule";
                    for (CCUIContentModuleContainerViewController *cvc in [gTrackedContainerVCs allObjects]) {
                        if ([cvc respondsToSelector:@selector(moduleIdentifier)] &&
                            [cvc.moduleIdentifier isEqualToString:wantID] &&
                            [cvc respondsToSelector:@selector(setExpanded:)]) {
                            UIScrollView *s = DZLJBSafeIvar(strongSelf, "_scrollView");
                            if ([s isKindOfClass:[UIScrollView class]]) {
                                [s setContentOffset:CGPointMake(0, -s.contentInset.top) animated:YES];
                            }
                            return;
                        }
                    }
                }

                UIScrollView *s = DZLJBSafeIvar(strongSelf, "_scrollView");
                if ([s isKindOfClass:[UIScrollView class]]) {
                    CGFloat stepY = (idx == 0) ? 0.0 : (idx == 2 ? 180.0 : idx * 95.0);
                    [s setContentOffset:CGPointMake(0.0, stepY - s.contentInset.top) animated:YES];
                }
            };
            [self.view addSubview:sidebar];
            objc_setAssociatedObject(self, kDZLJBSidebarKey, sidebar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        sidebar.hidden = NO;
        CGFloat sbWidth  = 22.0;
        CGFloat sbHeight = 160.0;
        sidebar.frame = CGRectMake(vBounds.size.width - sbWidth - 5.0, (vBounds.size.height - sbHeight) * 0.5, sbWidth, sbHeight);
        [self.view bringSubviewToFront:sidebar];
    } else if (sidebar) {
        sidebar.hidden = YES;
    }

    // 6. Nút "+ Thêm một điều khiển" ở đáy (chỉ hiện trong Chế độ Sửa và khi KHÔNG mở rộng module!)
    UIButton *addPill = objc_getAssociatedObject(self, kDZLJBBottomAddPillKey);
    if (gEnabled && gIsEditModeActive && !anyExpanded) {
        if (!addPill) {
            addPill = [UIButton buttonWithType:UIButtonTypeSystem];
            addPill.backgroundColor = [UIColor colorWithWhite:0.18 alpha:0.78];
            addPill.tintColor = [UIColor whiteColor];
            [addPill setTitle:@"  ⊕ Thêm một điều khiển  " forState:UIControlStateNormal];
            addPill.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
            addPill.layer.cornerCurve = kCACornerCurveCircular;
            addPill.layer.borderWidth = 1.1;
            addPill.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.42].CGColor;
            [addPill addTarget:self action:@selector(dzljb_onTapAddControlsPill:) forControlEvents:UIControlEventTouchUpInside];
            [self.view addSubview:addPill];
            objc_setAssociatedObject(self, kDZLJBBottomAddPillKey, addPill, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        addPill.hidden = NO;
        CGFloat pw = 216.0;
        CGFloat ph = 44.0;
        addPill.frame = CGRectMake((vBounds.size.width - pw) * 0.5, vBounds.size.height - ph - 36.0, pw, ph);
        addPill.layer.cornerRadius = ph * 0.5;
        [self.view bringSubviewToFront:addPill];
    } else if (addPill) {
        addPill.hidden = YES;
    }
}

- (void)viewDidLayoutSubviews {
    %orig;
    [self dzljb_refreshOverlayUI];
}

%new
- (void)dzljb_performBounceEntry {
    if (!gEnabled || !gBouncePhysicsEnabled) return;

    NSNumber *last = objc_getAssociatedObject(self, kDZLJBLastBounceTimeKey);
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    if (last && (now - [last doubleValue]) < 0.35) return;
    objc_setAssociatedObject(self, kDZLJBLastBounceTimeKey, @(now), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    CCUIModuleCollectionViewController *colVC = [self respondsToSelector:@selector(moduleCollectionViewController)]
        ? self.moduleCollectionViewController
        : DZLJBSafeIvar(self, "_moduleCollectionViewController");
    UIView *root = (colVC && colVC.viewLoaded) ? colVC.view : self.view;
    if (!root) return;

    NSMutableArray<CCUIContentModuleContentContainerView *> *mods = [NSMutableArray array];
    DZLJBCollectContainers(root, mods);
    if (mods.count == 0) return;

    [mods sortUsingComparator:^NSComparisonResult(UIView *a, UIView *b) {
        CGRect ra = [a convertRect:a.bounds toView:nil];
        CGRect rb = [b convertRect:b.bounds toView:nil];
        if (fabs(ra.origin.y - rb.origin.y) > 26.0) {
            return (ra.origin.y < rb.origin.y) ? NSOrderedAscending : NSOrderedDescending;
        }
        return (ra.origin.x < rb.origin.x) ? NSOrderedAscending : NSOrderedDescending;
    }];

    CGFloat firstY = [mods.firstObject convertRect:mods.firstObject.bounds toView:nil].origin.y;
    CGFloat damp = MIN(0.80, MAX(0.44, 0.58 / gBounceIntensity));

    for (CCUIContentModuleContentContainerView *m in mods) {
        if ([objc_getAssociatedObject(m, kDZLJBModuleExpandedKey) boolValue]) continue;
        CGRect sr = [m convertRect:m.bounds toView:nil];
        NSInteger row = MAX(0, (NSInteger)round((sr.origin.y - firstY) / 76.0));
        NSInteger col = MAX(0, (NSInteger)round(sr.origin.x / 84.0));

        CGFloat drop = -(34.0 + row * 18.0) * gBounceIntensity;
        m.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.90, 1.08),
                                              CGAffineTransformMakeTranslation(0.0, drop));
        m.alpha = 0.20;

        NSTimeInterval delay = MIN(0.20, row * 0.026 + col * 0.007);
        [UIView animateWithDuration:0.56
                              delay:delay
             usingSpringWithDamping:damp
              initialSpringVelocity:0.85
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             m.transform = CGAffineTransformIdentity;
                             m.alpha = 1.0;
                         }
                         completion:nil];
    }
}

%new
- (void)dzljb_resetTransforms {
    if (!self.viewLoaded) return;
    NSMutableArray<CCUIContentModuleContentContainerView *> *mods = [NSMutableArray array];
    DZLJBCollectContainers(self.view, mods);
    for (UIView *m in mods) {
        m.transform = CGAffineTransformIdentity;
        m.alpha = 1.0;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);
    gActiveOverlayVC = self;
    [DZLJBGlassArtifact startGyroscopeUpdatesIfNeeded];
    [self dzljb_refreshOverlayUI];
    if (animated) [self dzljb_performBounceEntry];
}

- (void)presentAnimated:(BOOL)animated withCompletionHandler:(id)completion {
    %orig(animated, completion);
    gActiveOverlayVC = self;
    [DZLJBGlassArtifact startGyroscopeUpdatesIfNeeded];
    [self dzljb_refreshOverlayUI];
    if (animated) [self dzljb_performBounceEntry];
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig(animated);
    [DZLJBGlassArtifact stopGyroscopeUpdates];
    if (gIsEditModeActive) [self dzljb_setEditModeActive:NO];
    [self dzljb_resetTransforms];
}

// Đồng bộ cuộn mượt với thanh phân trang cạnh phải & hiệu ứng dãn sóng kính
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    %orig(scrollView);
    if (!gEnabled || !scrollView) return;

    CGFloat offset = scrollView.contentOffset.y + scrollView.contentInset.top;

    DZLJBPageSidebarView *sidebar = objc_getAssociatedObject(self, kDZLJBSidebarKey);
    if (sidebar && !sidebar.hidden && (scrollView.isDragging || scrollView.isDecelerating)) {
        NSInteger sec = 0;
        if (offset > 150.0) sec = 3;
        else if (offset > 95.0) sec = 2;
        else if (offset > 40.0) sec = 1;
        if (sec != sidebar.activeIndex) {
            [sidebar setHighlightedSection:sec];
        }
    }

    UIView *header = DZLJBSafeIvar(self, "_headerPocketView");
    UIButton *plusBtn  = objc_getAssociatedObject(self, kDZLJBTopPlusBtnKey);
    UIButton *powerBtn = objc_getAssociatedObject(self, kDZLJBTopPowerBtnKey);
    CGFloat headerAlpha = (offset > 0.0) ? MAX(0.0, 1.0 - offset / 95.0) : 1.0;
    if ([header isKindOfClass:[UIView class]]) header.alpha = headerAlpha;
    if (plusBtn && !gIsEditModeActive) plusBtn.alpha = headerAlpha;
    if (powerBtn) powerBtn.alpha = headerAlpha;

    if (!gBouncePhysicsEnabled || gIsEditModeActive) return;

    CCUIModuleCollectionViewController *colVC = [self respondsToSelector:@selector(moduleCollectionViewController)]
        ? self.moduleCollectionViewController
        : DZLJBSafeIvar(self, "_moduleCollectionViewController");
    UIView *root = (colVC && colVC.viewLoaded) ? colVC.view : nil;
    if (!root) return;

    NSMutableArray<CCUIContentModuleContentContainerView *> *mods = [NSMutableArray array];
    DZLJBCollectContainers(root, mods);
    if (mods.count == 0) return;

    if (offset < -2.0) {
        CGFloat pull = MIN(130.0, -offset);
        CGFloat topY = [mods.firstObject convertRect:mods.firstObject.bounds toView:nil].origin.y;
        for (CCUIContentModuleContentContainerView *m in mods) {
            if ([objc_getAssociatedObject(m, kDZLJBModuleExpandedKey) boolValue]) continue;
            CGRect sr = [m convertRect:m.bounds toView:nil];
            NSInteger row = MAX(0, (NSInteger)round((sr.origin.y - topY) / 76.0));
            CGFloat dy = pull * row * 0.08 * gBounceIntensity;
            CGFloat sy = 1.0 + MIN(0.06, pull * 0.00042 * gBounceIntensity);
            CGFloat sx = 1.0 - MIN(0.03, pull * 0.00020 * gBounceIntensity);
            m.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(sx, sy),
                                                  CGAffineTransformMakeTranslation(0.0, dy));
        }
    } else if (fabs(offset) <= 2.0 && !scrollView.isDragging) {
        for (UIView *m in mods) {
            if (!CGAffineTransformIsIdentity(m.transform)) {
                m.transform = CGAffineTransformIdentity;
            }
        }
    }
}

%end

%end // End %group CoreCCHooks

// ============================================================================
// MARK: - Group 2: Cụm Kết Nối 2x2 & Phục Hồi Đầy Đủ Nhãn Chữ Khi Mở Rộng (Sửa lỗi Ảnh 2 & 6!)
// ============================================================================

%group ConnectivityBundleHooks

%hook CCUIConnectivityModuleViewController

%new
- (void)dzljb_applyModernConnectivityLayout {
    if (!self.viewLoaded || !self.view) return;
    CGRect b = self.view.bounds;
    if (CGRectIsEmpty(b)) return;

    NSArray *btnVCs = DZLJBSafeIvar(self, "_buttonViewControllers");
    if (![btnVCs isKindOfClass:[NSArray class]] || btnVCs.count < 6) return;

    UIView *fourthMini = [self.view viewWithTag:262604];
    BOOL isExpanded = (b.size.width > 220.0 || b.size.height > 220.0);

    // KHI MỞ RỘNG (Ảnh 2 & Ảnh 6): Khôi phục 100% nhãn chữ tiếng Việt "Dữ liệu di động", "Bluetooth", "Điểm truy cập"!
    if (!gEnabled || !gModernConnectivityGrid || isExpanded || b.size.width < 115.0 || b.size.height < 115.0) {
        if (fourthMini) fourthMini.hidden = YES;
        for (UIViewController *vc in btnVCs) {
            if ([vc isKindOfClass:[UIViewController class]] && vc.viewLoaded) {
                vc.view.transform = CGAffineTransformIdentity;
                for (UIView *sub in vc.view.subviews) {
                    if ([sub isKindOfClass:[UILabel class]]) {
                        sub.hidden = NO;
                        sub.alpha  = 1.0;
                    }
                }
            }
        }
        return;
    }

    CGFloat w = b.size.width;
    CGFloat h = b.size.height;
    CGPoint qTL = CGPointMake(w * 0.275, h * 0.275);
    CGPoint qTR = CGPointMake(w * 0.725, h * 0.275);
    CGPoint qBL = CGPointMake(w * 0.275, h * 0.725);

    CGFloat brX = w * 0.725;
    CGFloat brY = h * 0.725;
    CGFloat off = w * 0.092;

    NSArray<NSNumber *> *largeIdx = @[@0, @4, @2];
    CGPoint largePts[3] = { qTL, qTR, qBL };

    for (NSUInteger i = 0; i < 3; i++) {
        UIViewController *vc = btnVCs[[largeIdx[i] unsignedIntegerValue]];
        if (![vc isKindOfClass:[UIViewController class]] || !vc.view) continue;
        UIView *v = vc.view;
        v.hidden = NO;
        v.alpha  = 1.0;
        v.transform = CGAffineTransformIdentity;
        CGFloat side = MIN(54.0, w * 0.36);
        v.bounds = CGRectMake(0, 0, side, side);
        v.center = largePts[i];
        v.layer.cornerRadius = side * 0.5;
        v.layer.cornerCurve  = kCACornerCurveCircular;
        for (UIView *sub in v.subviews) {
            if ([sub isKindOfClass:[UILabel class]]) sub.hidden = YES;
        }
    }

    NSArray<NSNumber *> *miniIdx = @[@1, @3, @5];
    CGPoint miniPts[3] = {
        CGPointMake(brX - off, brY - off),
        CGPointMake(brX + off, brY - off),
        CGPointMake(brX - off, brY + off)
    };

    for (NSUInteger i = 0; i < 3; i++) {
        UIViewController *vc = btnVCs[[miniIdx[i] unsignedIntegerValue]];
        if (![vc isKindOfClass:[UIViewController class]] || !vc.view) continue;
        UIView *v = vc.view;
        v.hidden = NO;
        v.alpha  = 1.0;
        v.transform = CGAffineTransformIdentity;
        v.bounds = CGRectMake(0, 0, 54.0, 54.0);
        v.layer.cornerRadius = 27.0;
        v.layer.cornerCurve  = kCACornerCurveCircular;
        v.transform = CGAffineTransformMakeScale(0.45, 0.45);
        v.center = miniPts[i];
        for (UIView *sub in v.subviews) {
            if ([sub isKindOfClass:[UILabel class]]) sub.hidden = YES;
        }
    }

    if (!fourthMini) {
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24.3, 24.3)];
        iv.tag = 262604;
        iv.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.16];
        iv.contentMode = UIViewContentModeCenter;
        iv.tintColor = [UIColor colorWithWhite:1.0 alpha:0.88];
        iv.clipsToBounds = YES;
        iv.layer.cornerRadius = 12.15;
        if (@available(iOS 13.0, *)) {
            UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:11.5 weight:UIImageSymbolWeightSemibold];
            iv.image = [UIImage systemImageNamed:@"network" withConfiguration:cfg];
        }
        [self.view addSubview:iv];
        fourthMini = iv;
    }
    fourthMini.hidden = NO;
    fourthMini.center = CGPointMake(brX + off, brY + off);
}

- (void)viewDidLayoutSubviews {
    %orig;
    [self dzljb_applyModernConnectivityLayout];
}

%end

%end // End %group ConnectivityBundleHooks

// ============================================================================
// MARK: - Theo dõi Bundle Nạp động & Constructor (%ctor)
// ============================================================================

static BOOL gConnReady = NO;

static void DZLJBTryHookBundles(void) {
    if (!gConnReady && NSClassFromString(@"CCUIConnectivityModuleViewController") != nil) {
        gConnReady = YES;
        %init(ConnectivityBundleHooks);
    }
}

static void DZLJBBundleLoaded(CFNotificationCenterRef c, void *o, CFStringRef n, const void *obj, CFDictionaryRef u) {
    DZLJBTryHookBundles();
}

%ctor {
    @autoreleasepool {
        if (![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"]) {
            return;
        }

        gTrackedViews        = [NSHashTable weakObjectsHashTable];
        gTrackedContainerVCs = [NSHashTable weakObjectsHashTable];
        gCustomSizes         = [NSMutableDictionary dictionary];
        DZLJBLoadPrefs();

        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,
                                        DZLJBOnPrefsChanged, kDZLJBReloadPrefsNotif, NULL,
                                        CFNotificationSuspensionBehaviorDeliverImmediately);

        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,
                                        DZLJBOnResetLayouts, kDZLJBResetLayoutsNotif, NULL,
                                        CFNotificationSuspensionBehaviorDeliverImmediately);

        %init(CoreCCHooks);

        DZLJBTryHookBundles();
        if (!gConnReady) {
            CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(), NULL,
                                            DZLJBBundleLoaded, (__bridge CFStringRef)NSBundleDidLoadNotification,
                                            NULL, CFNotificationSuspensionBehaviorCoalesce);
        }
    }
}
