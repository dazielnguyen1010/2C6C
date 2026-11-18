//
//  DZLJB2C6CRootListController.m
//  2C6CPrefs v3.0 — Trang Cài Đặt Tiếng Việt cho 2C6C (com.dzljb.2c6c)
//
//  Author: dzljb
//

#import "DZLJB2C6CRootListController.h"
#import <spawn.h>
#import <unistd.h>

extern char **environ;

static NSString * const kDZLJBPrefsFile    = @"/var/jb/var/mobile/Library/Preferences/com.dzljb.2c6c.plist";
static NSString * const kDZLJBLayoutsFile  = @"/var/jb/var/mobile/Library/Preferences/com.dzljb.2c6c.layouts.plist";
static CFStringRef const kDZLJBNotifyName  = CFSTR("com.dzljb.2c6c/ReloadPrefs");
static CFStringRef const kDZLJBResetShapes = CFSTR("com.dzljb.2c6c/ResetLayouts");

@implementation DZLJB2C6CHeaderCell

- (instancetype)initWithSpecifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DZLJB2C6CHeaderCell" specifier:specifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _glassCardView = [[UIView alloc] initWithFrame:CGRectZero];
        _glassCardView.clipsToBounds = YES;
        _glassCardView.layer.cornerRadius = 28.0;
        _glassCardView.layer.cornerCurve  = kCACornerCurveContinuous;
        [self.contentView addSubview:_glassCardView];

        _cardGradientLayer = [CAGradientLayer layer];
        _cardGradientLayer.startPoint = CGPointMake(0.0, 0.0);
        _cardGradientLayer.endPoint   = CGPointMake(1.0, 1.0);
        _cardGradientLayer.colors = @[
            (id)[UIColor colorWithRed:0.10 green:0.22 blue:0.42 alpha:0.96].CGColor,
            (id)[UIColor colorWithRed:0.06 green:0.12 blue:0.25 alpha:0.98].CGColor,
            (id)[UIColor colorWithRed:0.16 green:0.34 blue:0.58 alpha:0.95].CGColor
        ];
        _cardGradientLayer.locations = @[@0.0, @0.52, @1.0];
        [_glassCardView.layer addSublayer:_cardGradientLayer];

        _rimGradientLayer = [CAGradientLayer layer];
        _rimGradientLayer.startPoint = CGPointMake(0.0, 0.0);
        _rimGradientLayer.endPoint   = CGPointMake(1.0, 1.0);
        _rimGradientLayer.colors = @[
            (id)[UIColor colorWithWhite:1.0 alpha:0.95].CGColor,
            (id)[UIColor colorWithRed:0.70 green:0.92 blue:1.0 alpha:0.24].CGColor,
            (id)[UIColor colorWithWhite:1.0 alpha:0.84].CGColor
        ];
        _rimGradientLayer.locations = @[@0.0, @0.5, @1.0];

        _rimMaskLayer = [CAShapeLayer layer];
        _rimMaskLayer.fillColor   = [UIColor clearColor].CGColor;
        _rimMaskLayer.strokeColor = [UIColor whiteColor].CGColor;
        _rimMaskLayer.lineWidth   = 1.4;
        _rimGradientLayer.mask    = _rimMaskLayer;
        [_glassCardView.layer addSublayer:_rimGradientLayer];

        _titleBannerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleBannerLabel.text = @"2C6C";
        _titleBannerLabel.font = [UIFont systemFontOfSize:34.0 weight:UIFontWeightHeavy];
        _titleBannerLabel.textColor = [UIColor whiteColor];
        _titleBannerLabel.textAlignment = NSTextAlignmentCenter;
        [_glassCardView addSubview:_titleBannerLabel];

        _subtitleBannerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _subtitleBannerLabel.text = @"Giao diện Liquid Glass iOS 26.7 • dzljb";
        _subtitleBannerLabel.font = [UIFont systemFontOfSize:13.5 weight:UIFontWeightMedium];
        _subtitleBannerLabel.textColor = [UIColor colorWithRed:0.84 green:0.93 blue:1.0 alpha:0.95];
        _subtitleBannerLabel.textAlignment = NSTextAlignmentCenter;
        [_glassCardView addSubview:_subtitleBannerLabel];

        _badgeStatusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _badgeStatusLabel.text = @"✦ v3.0 • Shader Khúc Xạ Kép & Tuỳ Biến Toàn Diện";
        _badgeStatusLabel.font = [UIFont systemFontOfSize:11.5 weight:UIFontWeightSemibold];
        _badgeStatusLabel.textColor = [UIColor colorWithRed:0.66 green:0.94 blue:1.0 alpha:0.96];
        _badgeStatusLabel.textAlignment = NSTextAlignmentCenter;
        _badgeStatusLabel.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.12];
        _badgeStatusLabel.clipsToBounds = YES;
        _badgeStatusLabel.layer.cornerCurve = kCACornerCurveContinuous;
        [_glassCardView addSubview:_badgeStatusLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect cardRect = CGRectInset(self.contentView.bounds, 16.0, 8.0);
    if (cardRect.size.width <= 0 || cardRect.size.height <= 0) return;

    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    self.glassCardView.frame = cardRect;
    CGRect lb = self.glassCardView.bounds;
    self.cardGradientLayer.frame = lb;
    self.rimGradientLayer.frame  = lb;
    self.rimMaskLayer.frame      = lb;
    self.rimMaskLayer.path       = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(lb, 0.7, 0.7) cornerRadius:27.3].CGPath;

    self.titleBannerLabel.frame    = CGRectMake(12.0, 18.0, lb.size.width - 24.0, 38.0);
    self.subtitleBannerLabel.frame = CGRectMake(12.0, 58.0, lb.size.width - 24.0, 20.0);

    CGFloat badgeW = MIN(lb.size.width - 28.0, 300.0);
    CGFloat badgeH = 24.0;
    self.badgeStatusLabel.frame = CGRectMake((lb.size.width - badgeW) * 0.5, 86.0, badgeW, badgeH);
    self.badgeStatusLabel.layer.cornerRadius = badgeH * 0.5;

    [CATransaction commit];
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width { return 140.0; }
- (CGFloat)preferredHeightForWidth:(CGFloat)width inTableView:(UITableView *)tableView { return 140.0; }

@end

@implementation DZLJB2C6CRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"2C6C";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithTitle:@"Respring"
                style:UIBarButtonItemStylePlain
               target:self
               action:@selector(respringDevice)];
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kDZLJBPrefsFile];
    NSString *key = [specifier propertyForKey:@"key"];
    if (key && prefs[key] != nil) return prefs[key];
    return [specifier propertyForKey:@"default"];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:kDZLJBPrefsFile] ?: [NSMutableDictionary dictionary];
    NSString *key = [specifier propertyForKey:@"key"];
    if (key && value != nil) {
        prefs[key] = value;
        NSString *dir = [kDZLJBPrefsFile stringByDeletingLastPathComponent];
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:dir]) {
            [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        [prefs writeToFile:kDZLJBPrefsFile atomically:YES];
        CFPreferencesSetAppValue((__bridge CFStringRef)key, (__bridge CFPropertyListRef)value, CFSTR("com.dzljb.2c6c"));
        CFPreferencesAppSynchronize(CFSTR("com.dzljb.2c6c"));
    }
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kDZLJBNotifyName, NULL, NULL, YES);
}

- (NSString *)authorCreditValue:(PSSpecifier *)specifier {
    return @"dzljb (com.dzljb.2c6c)";
}

- (void)resetModuleShapes {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Khôi phục kích thước nút"
                         message:@"Đưa tất cả các nút điều khiển đã kéo giãn về lại kích thước mặc định?"
                  preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Khôi phục" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        [[NSFileManager defaultManager] removeItemAtPath:kDZLJBLayoutsFile error:nil];
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kDZLJBResetShapes, NULL, NULL, YES);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)executeRootlessRespring {
    pid_t pid = 0;
    if (access("/var/jb/usr/bin/sbreload", X_OK) == 0) {
        const char *args[] = { "sbreload", NULL };
        if (posix_spawn(&pid, "/var/jb/usr/bin/sbreload", NULL, NULL, (char * const *)args, environ) == 0) return;
    }
    if (access("/var/jb/usr/bin/killall", X_OK) == 0) {
        const char *args[] = { "killall", "-9", "SpringBoard", NULL };
        posix_spawn(&pid, "/var/jb/usr/bin/killall", NULL, NULL, (char * const *)args, environ);
    }
}

- (void)respringDevice {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Khởi động lại màn hình"
                         message:@"Áp dụng toàn bộ cài đặt 2C6C v3.0 và làm mới SpringBoard ngay?"
                  preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"Respring ngay" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        [self executeRootlessRespring];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil]];
    if (alert.popoverPresentationController) {
        alert.popoverPresentationController.sourceView = self.view;
        alert.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 1, 1);
    }
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)resetPreferences {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Đặt lại cài đặt gốc"
                         message:@"Xóa toàn bộ tuỳ chỉnh hiện tại và khôi phục thông số Liquid Glass chuẩn iOS 26.7?"
                  preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Đặt lại" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm removeItemAtPath:kDZLJBPrefsFile error:nil];
        [fm removeItemAtPath:kDZLJBLayoutsFile error:nil];
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kDZLJBResetShapes, NULL, NULL, YES);
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kDZLJBNotifyName, NULL, NULL, YES);
        [self reloadSpecifiers];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
