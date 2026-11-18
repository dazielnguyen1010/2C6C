//
//  DZLJB2C6CRootListController.h
//  2C6CPrefs v2.0 — Trang Cài Đặt Tiếng Việt cho 2C6C (com.dzljb.2c6c)
//
//  Author: dzljb
//

#ifndef DZLJB_2C6C_ROOT_LIST_CONTROLLER_H
#define DZLJB_2C6C_ROOT_LIST_CONTROLLER_H

#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@protocol PreferencesTableCustomView
- (instancetype)initWithSpecifier:(PSSpecifier *)specifier;
@optional
- (CGFloat)preferredHeightForWidth:(CGFloat)width;
- (CGFloat)preferredHeightForWidth:(CGFloat)width inTableView:(UITableView *)tableView;
@end

@interface DZLJB2C6CHeaderCell : PSTableCell <PreferencesTableCustomView>
@property (nonatomic, strong) UIView *glassCardView;
@property (nonatomic, strong) CAGradientLayer *cardGradientLayer;
@property (nonatomic, strong) CAGradientLayer *rimGradientLayer;
@property (nonatomic, strong) CAShapeLayer *rimMaskLayer;
@property (nonatomic, strong) UILabel *titleBannerLabel;
@property (nonatomic, strong) UILabel *subtitleBannerLabel;
@property (nonatomic, strong) UILabel *badgeStatusLabel;
@end

@interface DZLJB2C6CRootListController : PSListController
- (void)respringDevice;
- (void)resetPreferences;
- (void)resetModuleShapes;
- (NSString *)authorCreditValue:(PSSpecifier *)specifier;
@end

#endif /* DZLJB_2C6C_ROOT_LIST_CONTROLLER_H */
