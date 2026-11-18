//
//  DZLJBControlsGallery.m
//  2C6C v3.0 — Thư viện Thêm Điều khiển Chuẩn iOS 18 / iOS 26 (Khớp Ảnh 5)
//
//  Package: com.dzljb.2c6c
//  Author:  dzljb
//

#import "Tweak.h"

@interface DZLJBControlItemModel : NSObject
@property (nonatomic, copy) NSString *moduleID;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *symbolName;
@end

@implementation DZLJBControlItemModel
+ (instancetype)itemWithID:(NSString *)mid title:(NSString *)title symbol:(NSString *)sym {
    DZLJBControlItemModel *m = [[DZLJBControlItemModel alloc] init];
    m.moduleID   = mid;
    m.title      = title;
    m.symbolName = sym;
    return m;
}
@end

@interface DZLJBControlSectionModel : NSObject
@property (nonatomic, copy) NSString *sectionTitle;
@property (nonatomic, copy) NSString *headerSymbol;
@property (nonatomic, strong) UIColor *badgeColor;
@property (nonatomic, strong) NSArray<DZLJBControlItemModel *> *items;
@end

@implementation DZLJBControlSectionModel
@end

@interface DZLJBControlsGalleryViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UIVisualEffectView *sheetBlurView;
@property (nonatomic, strong) UITextField *searchField;
@property (nonatomic, strong) UIScrollView *gridScrollView;
@property (nonatomic, strong) NSArray<DZLJBControlSectionModel *> *allSections;
@property (nonatomic, copy) NSString *filterQuery;
@end

@implementation DZLJBControlsGalleryViewController

- (void)buildCatalog {
    DZLJBControlSectionModel *capture = [[DZLJBControlSectionModel alloc] init];
    capture.sectionTitle = @"Chụp & Quay";
    capture.headerSymbol = @"camera.fill";
    capture.badgeColor   = [UIColor colorWithRed:0.04 green:0.52 blue:1.0 alpha:1.0];
    capture.items = @[
        [DZLJBControlItemModel itemWithID:@"com.apple.control-center.CameraModule" title:@"Camera" symbol:@"camera.fill"],
        [DZLJBControlItemModel itemWithID:@"com.apple.control-center.MagnifierModule" title:@"Kính lúp" symbol:@"plus.magnifyingglass"],
        [DZLJBControlItemModel itemWithID:@"com.apple.control-center.QRCodeModule" title:@"Quét mã QR" symbol:@"qrcode.viewfinder"],
        [DZLJBControlItemModel itemWithID:@"com.apple.replaykit.controlcenter.screencapture" title:@"Ghi màn hình" symbol:@"record.circle"]
    ];

    DZLJBControlSectionModel *clock = [[DZLJBControlSectionModel alloc] init];
    clock.sectionTitle = @"Đồng hồ";
    clock.headerSymbol = @"clock.fill";
    clock.badgeColor   = [UIColor colorWithWhite:0.22 alpha:1.0];
    clock.items = @[
        [DZLJBControlItemModel itemWithID:@"com.apple.control-center.AlarmModule" title:@"Báo thức" symbol:@"alarm.fill"],
        [DZLJBControlItemModel itemWithID:@"com.apple.mobiletimer.controlcenter.timer" title:@"Hẹn giờ" symbol:@"timer"],
        [DZLJBControlItemModel itemWithID:@"com.apple.control-center.StopwatchModule" title:@"Bấm giờ" symbol:@"stopwatch.fill"]
    ];

    DZLJBControlSectionModel *utilities = [[DZLJBControlSectionModel alloc] init];
    utilities.sectionTitle = @"Tiện ích & Hiển thị";
    utilities.headerSymbol = @"flashlight.on.fill";
    utilities.badgeColor   = [UIColor colorWithRed:0.19 green:0.82 blue:0.35 alpha:1.0];
    utilities.items = @[
        [DZLJBControlItemModel itemWithID:@"com.apple.control-center.FlashlightModule" title:@"Đèn pin" symbol:@"flashlight.off.fill"],
        [DZLJBControlItemModel itemWithID:@"com.apple.control-center.LowPowerModule" title:@"Nguồn điện thấp" symbol:@"battery.25"],
        [DZLJBControlItemModel itemWithID:@"com.apple.control-center.DarkModeModule" title:@"Chế độ Tối" symbol:@"circle.righthalf.filled"],
        [DZLJBControlItemModel itemWithID:@"com.apple.control-center.CalculatorModule" title:@"Máy tính" symbol:@"function"],
        [DZLJBControlItemModel itemWithID:@"com.apple.control-center.TextSizeModule" title:@"Cỡ chữ" symbol:@"textformat.size"],
        [DZLJBControlItemModel itemWithID:@"com.apple.shazamkit.controlcenter.ShazamModule" title:@"Nhận dạng nhạc" symbol:@"shazam.logo.fill"],
        [DZLJBControlItemModel itemWithID:@"com.apple.control-center.VoiceMemosModule" title:@"Ghi âm" symbol:@"waveform"],
        [DZLJBControlItemModel itemWithID:@"com.apple.control-center.HearingDevicesModule" title:@"Nghe" symbol:@"ear"],
        [DZLJBControlItemModel itemWithID:@"com.apple.control-center.WalletModule" title:@"Ví" symbol:@"creditcard.fill"]
    ];

    self.allSections = @[capture, clock, utilities];
}

- (NSArray<NSString *> *)currentEnabledModuleIDs {
    Class providerCls = NSClassFromString(@"CCSModuleSettingsProvider");
    if (providerCls && [providerCls respondsToSelector:@selector(sharedProvider)]) {
        CCSModuleSettingsProvider *prov = [providerCls sharedProvider];
        if ([prov respondsToSelector:@selector(orderedUserEnabledModuleIdentifiers)]) {
            return prov.orderedUserEnabledModuleIdentifiers ?: @[];
        }
    }
    return @[];
}

- (void)toggleModuleWithIdentifier:(NSString *)moduleID {
    if (!moduleID) return;
    Class providerCls = NSClassFromString(@"CCSModuleSettingsProvider");
    if (!providerCls || ![providerCls respondsToSelector:@selector(sharedProvider)]) return;

    CCSModuleSettingsProvider *prov = [providerCls sharedProvider];
    if (![prov respondsToSelector:@selector(orderedUserEnabledModuleIdentifiers)] ||
        ![prov respondsToSelector:@selector(setAndSaveOrderedUserEnabledModuleIdentifiers:)]) {
        return;
    }

    NSMutableArray<NSString *> *list = [prov.orderedUserEnabledModuleIdentifiers mutableCopy] ?: [NSMutableArray array];
    if ([list containsObject:moduleID]) {
        [list removeObject:moduleID];
    } else {
        [list addObject:moduleID];
    }
    [prov setAndSaveOrderedUserEnabledModuleIdentifiers:list];
    DZLJBTriggerSoftHaptic(0.85);

    if (self.onModulesChanged) {
        self.onModulesChanged();
    }
    [self rebuildGridContent];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self buildCatalog];
    self.view.backgroundColor = [UIColor clearColor];

    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterialDark];
    self.sheetBlurView = [[UIVisualEffectView alloc] initWithEffect:blur];
    self.sheetBlurView.clipsToBounds = YES;
    self.sheetBlurView.layer.cornerRadius = 36.0;
    self.sheetBlurView.layer.cornerCurve  = kCACornerCurveContinuous;
    self.sheetBlurView.layer.borderWidth  = 1.1;
    self.sheetBlurView.layer.borderColor  = [UIColor colorWithWhite:1.0 alpha:0.25].CGColor;
    [self.view addSubview:self.sheetBlurView];

    UIView *grabber = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 38, 5)];
    grabber.tag = 9001;
    grabber.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.32];
    grabber.layer.cornerRadius = 2.5;
    [self.sheetBlurView.contentView addSubview:grabber];

    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.tag = 9002;
    [closeBtn setTitle:@"Xong" forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    closeBtn.tintColor = [UIColor whiteColor];
    [closeBtn addTarget:self action:@selector(dismissGallery) forControlEvents:UIControlEventTouchUpInside];
    [self.sheetBlurView.contentView addSubview:closeBtn];

    // Thanh tìm kiếm chuẩn iOS 18 / 26 (Ảnh 5: Search Controls)
    self.searchField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.searchField.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.12];
    self.searchField.layer.cornerRadius = 18.0;
    self.searchField.layer.cornerCurve  = kCACornerCurveContinuous;
    self.searchField.textColor = [UIColor whiteColor];
    self.searchField.font = [UIFont systemFontOfSize:15.5 weight:UIFontWeightRegular];
    self.searchField.attributedPlaceholder = [[NSAttributedString alloc]
        initWithString:@"🔍  Tìm kiếm điều khiển..."
            attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.52]}];
    UIView *padLeft = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14, 36)];
    self.searchField.leftView = padLeft;
    self.searchField.leftViewMode = UITextFieldViewModeAlways;
    self.searchField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.searchField.returnKeyType = UIReturnKeyDone;
    self.searchField.delegate = self;
    [self.searchField addTarget:self action:@selector(searchTextChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.sheetBlurView.contentView addSubview:self.searchField];

    self.gridScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.gridScrollView.showsVerticalScrollIndicator = NO;
    self.gridScrollView.alwaysBounceVertical = YES;
    [self.sheetBlurView.contentView addSubview:self.gridScrollView];

    [self rebuildGridContent];
}

- (void)dismissGallery {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)searchTextChanged:(UITextField *)sender {
    self.filterQuery = sender.text;
    [self rebuildGridContent];
}

- (void)handleControlButtonTap:(UIButton *)sender {
    NSString *modID = objc_getAssociatedObject(sender, @"dzljb_modID");
    [self toggleModuleWithIdentifier:modID];
}

- (void)handleResetSizesTap:(UIButton *)sender {
    [[NSFileManager defaultManager] removeItemAtPath:kDZLJBLayoutsPlistPath error:nil];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kDZLJBResetLayoutsNotif, NULL, NULL, YES);
    DZLJBTriggerSoftHaptic(0.95);
    [self dismissGallery];
}

- (void)rebuildGridContent {
    for (UIView *sub in self.gridScrollView.subviews) {
        [sub removeFromSuperview];
    }

    CGFloat width = MAX(320.0, self.view.bounds.size.width);
    NSArray<NSString *> *enabledIDs = [self currentEnabledModuleIDs];
    NSString *q = [self.filterQuery stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    CGFloat cursorY = 8.0;
    CGFloat sidePadding = 22.0;
    CGFloat colWidth = (width - sidePadding * 2.0) / 3.0;

    for (DZLJBControlSectionModel *sec in self.allSections) {
        NSMutableArray<DZLJBControlItemModel *> *filtered = [NSMutableArray array];
        for (DZLJBControlItemModel *item in sec.items) {
            if (q.length == 0 || [item.title localizedCaseInsensitiveContainsString:q]) {
                [filtered addObject:item];
            }
        }
        if (filtered.count == 0) continue;

        // Header danh mục có icon vuông bo góc màu sắc giống hệt Ảnh 5
        UIView *iconBadge = [[UIView alloc] initWithFrame:CGRectMake(sidePadding, cursorY, 26.0, 26.0)];
        iconBadge.backgroundColor = sec.badgeColor;
        iconBadge.layer.cornerRadius = 7.0;
        iconBadge.layer.cornerCurve  = kCACornerCurveContinuous;
        if (@available(iOS 13.0, *)) {
            UIImageView *iv = [[UIImageView alloc] initWithFrame:iconBadge.bounds];
            iv.contentMode = UIViewContentModeCenter;
            iv.tintColor   = [UIColor whiteColor];
            UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:13.0 weight:UIImageSymbolWeightSemibold];
            iv.image = [UIImage systemImageNamed:sec.headerSymbol withConfiguration:cfg];
            [iconBadge addSubview:iv];
        }
        [self.gridScrollView addSubview:iconBadge];

        UILabel *secLabel = [[UILabel alloc] initWithFrame:CGRectMake(sidePadding + 34.0, cursorY, width - 80.0, 26.0)];
        secLabel.text      = sec.sectionTitle;
        secLabel.font      = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
        secLabel.textColor = [UIColor whiteColor];
        [self.gridScrollView addSubview:secLabel];

        cursorY += 38.0;

        for (NSUInteger i = 0; i < filtered.count; i++) {
            DZLJBControlItemModel *item = filtered[i];
            NSUInteger col = i % 3;
            NSUInteger row = i / 3;

            CGFloat cellX = sidePadding + col * colWidth;
            CGFloat cellY = cursorY + row * 104.0;

            BOOL isAdded = [enabledIDs containsObject:item.moduleID];

            UIButton *circleBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            circleBtn.frame = CGRectMake(cellX + (colWidth - 64.0) * 0.5, cellY, 64.0, 64.0);
            circleBtn.backgroundColor = isAdded
                ? [UIColor colorWithRed:0.18 green:0.56 blue:1.0 alpha:0.38]
                : [UIColor colorWithWhite:1.0 alpha:0.12];
            circleBtn.layer.cornerRadius = 32.0;
            circleBtn.layer.cornerCurve  = kCACornerCurveCircular;
            circleBtn.layer.borderWidth  = 1.1;
            circleBtn.layer.borderColor  = isAdded
                ? [UIColor colorWithRed:0.45 green:0.80 blue:1.0 alpha:0.85].CGColor
                : [UIColor colorWithWhite:1.0 alpha:0.26].CGColor;
            circleBtn.tintColor = [UIColor whiteColor];

            if (@available(iOS 13.0, *)) {
                UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:23.0 weight:UIImageSymbolWeightMedium];
                UIImage *symImg = [UIImage systemImageNamed:item.symbolName withConfiguration:cfg];
                if (!symImg) symImg = [UIImage systemImageNamed:@"switch.2" withConfiguration:cfg];
                [circleBtn setImage:symImg forState:UIControlStateNormal];
            }

            objc_setAssociatedObject(circleBtn, @"dzljb_modID", item.moduleID, OBJC_ASSOCIATION_COPY_NONATOMIC);
            [circleBtn addTarget:self action:@selector(handleControlButtonTap:) forControlEvents:UIControlEventTouchUpInside];
            [self.gridScrollView addSubview:circleBtn];

            if (isAdded) {
                UILabel *check = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(circleBtn.frame) - 20.0, cellY - 2.0, 20.0, 20.0)];
                check.text = @"✓";
                check.font = [UIFont systemFontOfSize:11.5 weight:UIFontWeightBold];
                check.textColor = [UIColor whiteColor];
                check.textAlignment = NSTextAlignmentCenter;
                check.backgroundColor = [UIColor colorWithRed:0.18 green:0.78 blue:0.40 alpha:1.0];
                check.clipsToBounds = YES;
                check.layer.cornerRadius = 10.0;
                [self.gridScrollView addSubview:check];
            }

            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(cellX + 2.0, cellY + 68.0, colWidth - 4.0, 28.0)];
            lbl.text = item.title;
            lbl.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium];
            lbl.textColor = [UIColor colorWithWhite:0.92 alpha:0.90];
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.numberOfLines = 2;
            [self.gridScrollView addSubview:lbl];
        }

        NSUInteger totalRows = (filtered.count + 2) / 3;
        cursorY += totalRows * 104.0 + 14.0;

        UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(sidePadding, cursorY - 8.0, width - sidePadding * 2.0, 0.6)];
        sep.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.12];
        [self.gridScrollView addSubview:sep];
        cursorY += 10.0;
    }

    UIButton *resetBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    resetBtn.frame = CGRectMake(sidePadding, cursorY + 6.0, width - sidePadding * 2.0, 44.0);
    resetBtn.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.10];
    resetBtn.layer.cornerRadius = 22.0;
    [resetBtn setTitle:@"Đặt lại kích thước các nút mặc định" forState:UIControlStateNormal];
    resetBtn.tintColor = [UIColor colorWithRed:1.0 green:0.55 blue:0.52 alpha:1.0];
    resetBtn.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
    [resetBtn addTarget:self action:@selector(handleResetSizesTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.gridScrollView addSubview:resetBtn];

    self.gridScrollView.contentSize = CGSizeMake(width, cursorY + 74.0);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect b = self.view.bounds;
    CGFloat topMargin = MAX(48.0, self.view.safeAreaInsets.top + 10.0);
    self.sheetBlurView.frame = CGRectMake(0.0, topMargin, b.size.width, b.size.height - topMargin);

    CGRect sb = self.sheetBlurView.bounds;
    UIView *grabber = [self.sheetBlurView.contentView viewWithTag:9001];
    grabber.frame = CGRectMake((sb.size.width - 38.0) * 0.5, 10.0, 38.0, 5.0);

    UIView *closeBtn = [self.sheetBlurView.contentView viewWithTag:9002];
    closeBtn.frame = CGRectMake(sb.size.width - 68.0, 14.0, 52.0, 28.0);

    self.searchField.frame = CGRectMake(20.0, 48.0, sb.size.width - 40.0, 38.0);
    self.gridScrollView.frame = CGRectMake(0.0, 96.0, sb.size.width, sb.size.height - 96.0);
    [self rebuildGridContent];
}

@end
