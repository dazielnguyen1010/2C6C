//
//  Tweak.h
//  2C6C v3.0 — iOS 26.7 Liquid Glass Shader & Bố cục Trung tâm điều khiển
//
//  Package: com.dzljb.2c6c
//  Author:  dzljb
//

#ifndef DZLJB_2C6C_TWEAK_H
#define DZLJB_2C6C_TWEAK_H

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreMotion/CoreMotion.h>
#import <MediaPlayer/MediaPlayer.h>
#import <objc/runtime.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>

// ============================================================================
// MARK: - Hằng số Đường dẫn Rootless & Thông báo
// ============================================================================

static NSString * const kDZLJBPrefsDomain        = @"com.dzljb.2c6c";
static NSString * const kDZLJBPrefsPlistPath     = @"/var/jb/var/mobile/Library/Preferences/com.dzljb.2c6c.plist";
static NSString * const kDZLJBLayoutsPlistPath   = @"/var/jb/var/mobile/Library/Preferences/com.dzljb.2c6c.layouts.plist";
static CFStringRef const kDZLJBReloadPrefsNotif  = CFSTR("com.dzljb.2c6c/ReloadPrefs");
static CFStringRef const kDZLJBResetLayoutsNotif = CFSTR("com.dzljb.2c6c/ResetLayouts");

// Cấu trúc ma trận màu 4x5 chuẩn của QuartzCore (Private API trên iOS)
typedef struct CAColorMatrix {
    float m11, m12, m13, m14, m15;
    float m21, m22, m23, m24, m25;
    float m31, m32, m33, m34, m35;
    float m41, m42, m43, m44, m45;
} CAColorMatrix;

// Phải giữ đúng tên struct CCUILayoutSize của Apple để @encode(CCUILayoutSize) khớp nhị phân arm64
typedef struct CCUILayoutSize {
    NSUInteger width;
    NSUInteger height;
} CCUILayoutSize;

typedef NS_ENUM(NSInteger, DZLJBGlassStyleMode) {
    DZLJBGlassStyleClear  = 0, // Kính Trong iOS 26.7 (Blur 14pt, khúc xạ cao, trong vắt)
    DZLJBGlassStyleTinted = 1  // Kính Phủ Mờ iOS 26.7 (Blur 26pt, nền dịu sâu)
};

// ============================================================================
// MARK: - Biến Cấu hình Toàn cục Chia sẻ giữa các Module
// ============================================================================

extern BOOL gEnabled;
extern DZLJBGlassStyleMode gGlassStyle;
extern CGFloat gCCBackgroundBlur;
extern CGFloat gCCBackgroundDimAlpha;
extern CGFloat gButtonBlurRadius;
extern CGFloat gButtonTintAlpha;
extern CGFloat gSpecularIntensity;
extern CGFloat gRimBorderWidth;
extern CGFloat gPlatterSquircleRadius;
extern BOOL gEdgeRefractionEnabled;
extern BOOL gGyroSpecularEnabled;

extern BOOL gEnableEditResize;
extern BOOL gShowTopActionButtons;
extern BOOL gShowRightPageBar;
extern BOOL gModernConnectivityGrid;
extern BOOL gModernMediaCard;
extern BOOL gColorSliderGlyphs;

extern BOOL gBouncePhysicsEnabled;
extern CGFloat gBounceIntensity;
extern BOOL gHapticsEnabled;
extern BOOL gIsEditModeActive;
extern NSUInteger gPrefsRevision;

void DZLJBTriggerSoftHaptic(CGFloat intensity);
void DZLJBTriggerSelectionTick(void);
void DZLJBTriggerLiveGridRelayout(BOOL animated);

// ============================================================================
// MARK: - Khai báo Private APIs đã Xác thực trên iOS 15 – 16
// ============================================================================

@interface NSValue (DZLJBPrivateQuartzAndCCUI)
+ (NSValue *)valueWithCAColorMatrix:(CAColorMatrix)t;
+ (NSValue *)ccui_valueWithLayoutSize:(CCUILayoutSize)size;
- (CCUILayoutSize)ccui_layoutSizeValue;
@end

@interface CAFilter : NSObject <NSCopying, NSMutableCopying>
+ (instancetype)filterWithType:(NSString *)type;
+ (instancetype)filterWithName:(NSString *)name;
- (void)setValue:(id)value forKey:(NSString *)key;
- (id)valueForKey:(NSString *)key;
@end

@interface CABackdropLayer : CALayer
@property (assign) BOOL allowsInPlaceFiltering;
@property (assign) double scale;
@property (assign) double zoom;
@property (copy) NSString *groupName;
@property (assign) BOOL usesGlobalGroupNamespace;
@end

@interface MTMaterialLayer : CABackdropLayer
@property (nonatomic, copy, readwrite) NSString *recipeName;
@property (atomic, assign, readonly) CGRect visibleRect;
@end

@interface MTMaterialView : UIView
@property (nonatomic, copy, readwrite) NSString *recipeName;
@property (nonatomic, assign, readwrite) CGFloat weighting;
@property (nonatomic, assign, getter=isZoomEnabled) BOOL zoomEnabled;
@end

@interface CCSModuleSettingsProvider : NSObject
+ (instancetype)sharedProvider;
@property (nonatomic, copy, readonly) NSArray<NSString *> *orderedUserEnabledModuleIdentifiers;
- (void)setAndSaveOrderedUserEnabledModuleIdentifiers:(NSArray<NSString *> *)identifiers;
@end

@interface CCUILayoutOptions : NSObject
- (CGFloat)itemEdgeSize;
- (CGFloat)itemSpacing;
@end

@interface CCUIBaseSliderView : UIControl
@property (nonatomic, assign) CGFloat continuousSliderCornerRadius;
@property (nonatomic, assign) float value;
- (void)dzljb_tintSliderGlyphAndFill;
- (void)dzljb_refreshLiquidGlass;
@end

@interface CCUIContinuousSliderView : CCUIBaseSliderView
@property (nonatomic, assign) CGFloat continuousSliderCornerRadius;
@end

@interface CCUIButtonModuleView : UIControl
@property (nonatomic, assign, getter=isSelected) BOOL selected;
- (void)dzljb_refreshButtonLiquidGlass;
@end

@interface CCUIButtonModuleViewController : UIViewController
@property (nonatomic, readonly) CCUIButtonModuleView *buttonView;
@property (nonatomic, assign, getter=isSelected) BOOL selected;
@end

@interface CCUIConnectivityModuleViewController : UIViewController
- (void)dzljb_applyModernConnectivityLayout;
@end

@interface CCUIContentModuleContainerView : UIView
@end

@interface CCUIContentModuleContentContainerView : UIView
@property (nonatomic, assign) CGFloat compactContinuousCornerRadius;
@property (nonatomic, assign) CGFloat expandedContinuousCornerRadius;
- (UIView *)dzljb_activeMaterialView;
- (UIView *)dzljb_embeddedSliderView;
- (void)dzljb_refreshLiquidGlass;
@end

@interface CCUIContentModuleContainerViewController : UIViewController
@property (nonatomic, copy) NSString *moduleIdentifier;
@property (nonatomic, retain) CCUIContentModuleContentContainerView *contentContainerView;
@property (nonatomic, retain) UIViewController *contentViewController;
@property (nonatomic, assign, getter=isExpanded) BOOL expanded;
- (void)dzljb_updateContainerEditChrome;
- (void)dzljb_updateModernMediaOverlay;
- (void)dzljb_handleMinusBadgeTap:(UIButton *)sender;
- (void)dzljb_handleResizePan:(UIPanGestureRecognizer *)pan;
@end

@interface CCUIHeaderPocketView : UIView
- (void)setBackgroundAlpha:(double)alpha;
@end

@interface CCUIModuleCollectionViewController : UIViewController
- (void)_refreshPositionProviders;
- (NSArray<NSValue *> *)_sizesForModuleIdentifiers:(NSArray<NSString *> *)moduleIdentifiers
                        moduleInstanceByIdentifier:(NSDictionary *)moduleInstanceByIdentifier
                              interfaceOrientation:(long long)interfaceOrientation;
@end

@interface CCUIModularControlCenterViewController : UIViewController
@property (nonatomic, readonly) CCUIModuleCollectionViewController *moduleCollectionViewController;
+ (id)_sharedCollectionViewController;
@end

@interface CCUIModularControlCenterOverlayViewController : CCUIModularControlCenterViewController <UIScrollViewDelegate>
- (void)presentAnimated:(BOOL)animated withCompletionHandler:(id)completion;
- (void)dismissAnimated:(BOOL)animated withCompletionHandler:(id)completion;
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
- (void)dzljb_setEditModeActive:(BOOL)active;
- (void)dzljb_refreshOverlayUI;
- (void)dzljb_performBounceEntry;
- (void)dzljb_resetTransforms;
- (void)dzljb_onTapTopPlus:(UIButton *)sender;
- (void)dzljb_onTapTopPower:(UIButton *)sender;
- (void)dzljb_onTapAddControlsPill:(UIButton *)sender;
- (void)dzljb_onEmptyLongPress:(UILongPressGestureRecognizer *)gesture;
- (void)dzljb_onEmptyTap:(UITapGestureRecognizer *)tap;
@end

// ============================================================================
// MARK: - Khai báo Shader Kính Lỏng & Thư viện Điều khiển (v3.0)
// ============================================================================

@interface DZLJBGlassArtifact : NSObject
@property (nonatomic, strong) UIView *backdropClipView;
@property (nonatomic, strong) CABackdropLayer *bodyBackdropLayer;
@property (nonatomic, strong) CABackdropLayer *rimLensBackdropLayer;
@property (nonatomic, strong) CAShapeLayer *rimLensMaskLayer;
@property (nonatomic, strong) UIView *tintFillView;
@property (nonatomic, strong) UIView *bezelOverlayView;
@property (nonatomic, strong) CAGradientLayer *innerSpecularLayer;
@property (nonatomic, strong) CAGradientLayer *rimSpecularLayer;
@property (nonatomic, strong) CAShapeLayer *rimSpecularMaskLayer;
@property (nonatomic, assign) CGRect lastBounds;
@property (nonatomic, assign) CGFloat lastRadius;
@property (nonatomic, assign) BOOL lastExpanded;
@property (nonatomic, assign) NSUInteger lastRevision;
@property (nonatomic, assign) BOOL isPressed;

+ (void)startGyroscopeUpdatesIfNeeded;
+ (void)stopGyroscopeUpdates;

- (void)applyToHostView:(UIView *)hostView
      hideStockMaterial:(UIView *)stockMaterialView
           shadowTarget:(UIView *)shadowTarget
          frameInShadow:(CGRect)frameInShadow
           cornerRadius:(CGFloat)radius
          useCircularCurve:(BOOL)circularCurve
             isExpanded:(BOOL)isExpanded
       suppressBackdrop:(BOOL)suppressBackdrop;
- (void)setTouchIlluminated:(BOOL)pressed;
- (void)teardownWithStockMaterial:(UIView *)stockMaterialView shadowTarget:(UIView *)shadowTarget;
@end

@interface DZLJBResizeHandleView : UIView
@property (nonatomic, strong) CAShapeLayer *arcShapeLayer;
@end

@interface DZLJBPageSidebarView : UIView
@property (nonatomic, strong) NSArray<UIButton *> *symbolButtons;
@property (nonatomic, assign) NSInteger activeIndex;
@property (nonatomic, copy) void (^onSelectSection)(NSInteger index);
- (void)setHighlightedSection:(NSInteger)index;
@end

@interface DZLJBControlsGalleryViewController : UIViewController
@property (nonatomic, copy) void (^onModulesChanged)(void);
@end

CGFloat DZLJBComputeCornerRadius(CGSize size, BOOL isExpanded, BOOL *outUseCircular);
UIButton *DZLJBCreateLiquidCircleButton(NSString *sfSymbolName, CGFloat sideLength);

#endif /* DZLJB_2C6C_TWEAK_H */
