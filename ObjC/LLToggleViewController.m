/**
 * Copyright Maarten Billemont (http://www.lhunath.com, lhunath@lyndir.com)
 *
 * See the enclosed file LICENSE for license information (LGPLv3). If you did
 * not receive this file, see http://www.gnu.org/licenses/lgpl-3.0.txt
 *
 * @author   Maarten Billemont <lhunath@lyndir.com>
 * @license  http://www.gnu.org/licenses/lgpl-3.0.txt
 */

//
//  LLToggleViewController.h
//  LLToggleViewController
//
//  Created by lhunath on 2013-10-17.
//  Copyright, lhunath (Maarten Billemont) 2013. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import <StoreKit/StoreKit.h>
#import "LLToggleViewController.h"
#import "LLModel.h"
#import "PearlAlert.h"
#import "PearlStrings.h"
#import "PearlStringUtils.h"
#import "PearlLogger.h"
#import "PearlUIUtils.h"

#define LL_IN_APP_OPEN_HEIGHT 120

@interface LLToggleViewController()<SKStoreProductViewControllerDelegate>
@end

@implementation LLToggleViewController {
    CGFloat _togglePositionPanFromConstant;
}

- (void)viewDidLoad {

    [[NSNotificationCenter defaultCenter]
            addObserverForName:LLLoveLevelUpdatedNotification object:nil queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *note) {
                        if (self.toggleGestureRecognizer.state != UIGestureRecognizerStatePossible)
                                // Drag ongoing, don't interrupt.
                            return;

                        [self updateTogglePosition];
                    }];
    [[NSNotificationCenter defaultCenter]
            addObserverForName:LLEmailAddressUpdatedNotification object:nil queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *note) {
                        [self.userNameButton setTitle:[self emailAddress] forState:UIControlStateNormal];
                    }];
    [[NSNotificationCenter defaultCenter]
            addObserverForName:LLPurchaseAvailabilityNotification object:nil queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *note) {
                        [self updateAvailability];
                    }];

    [self updateTogglePosition];
    [self.userNameButton setTitle:[self emailAddress] forState:UIControlStateNormal];
    [self updateAvailability];
    [self toggleInApp:[LLModel sharedModel].level == LLLoveLevelFree animated:NO];

    [super viewDidLoad];
}

- (NSString *)emailAddress {

    NSString *emailAddress = [LLModel sharedModel].emailAddress;
    if ([emailAddress length])
        return emailAddress;

    return @"Tap to set your email address.";
}

- (void)updateTogglePosition {

    [self.issueView loadRequest:[NSURLRequest requestWithURL:
            [LLModel sharedModel].level == LLLoveLevelFree?
                    [NSURL URLWithString:@"http://love.lyndir.com/about.html"]:
                    [NSURL URLWithString:@"http://love.lyndir.com/issues/current.html"]]];

    self.togglePositionConstraint.constant = [self togglePositionConstantForLevel:[LLModel sharedModel].level];
    [self updateToggleAppearanceAndModel];
}

- (void)updateAvailability {

    NSError *error = nil;
    BOOL available = [[LLModel sharedModel] isPurchaseAvailableOrError:&error];
    self.unavailableLabel.hidden = available;
    self.availableContainer.hidden = !available;
    self.unavailableLabel.text = [error localizedDescription];
}

- (IBAction)onUserName:(id)sender {

    [PearlAlert showAlertWithTitle:@"E-mail Address"
                           message:@"Your email address is used to make your purchase available across all Lyndir apps."
                         viewStyle:UIAlertViewStylePlainTextInput
                         initAlert:^(UIAlertView *alert, UITextField *firstField) {
                             firstField.text = [LLModel sharedModel].emailAddress;
                             firstField.placeholder = @"eg. myname@icloud.com";
                         }
                 tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                     if (buttonIndex == [alert cancelButtonIndex])
                         return;

                     [LLModel sharedModel].emailAddress = [alert textFieldAtIndex:0].text;
                 }
                       cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonSave, nil];
}

- (IBAction)longOnUserName:(UILongPressGestureRecognizer *)sender {

    if (sender.state != UIGestureRecognizerStateBegan)
            // Only fire when the gesture was first detected.
        return;

    [[LLModel sharedModel] restorePurchases];
}

- (IBAction)didPanToggle:(UIPanGestureRecognizer *)sender {

    BOOL updateModel = NO;
    CGFloat target = _togglePositionPanFromConstant + [sender translationInView:self.view].x;

    switch (sender.state) {
        case UIGestureRecognizerStatePossible:
            return;
        case UIGestureRecognizerStateBegan:
            _togglePositionPanFromConstant = self.togglePositionConstraint.constant;
            return;
        case UIGestureRecognizerStateChanged:
            break;
        case UIGestureRecognizerStateEnded:
            target = [self togglePositionConstantEndForIntermediary:target];
            updateModel = YES;
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            target = [self togglePositionConstantForLevel:[LLModel sharedModel].level];
            break;
    }

    self.togglePositionConstraint.constant = MIN(99, MAX( -99, target ) );
    LLLoveLevel pannedLevel = [self updateToggleAppearanceAndModel];
    if (updateModel)
        [[LLModel sharedModel] purchaseLevel:pannedLevel fromVC:self];
}

- (CGFloat)togglePositionConstantEndForIntermediary:(CGFloat)target {

    if (target < -50)
        target = -99;
    else if (target > 50)
        target = 99;
    else
        target = 0;
    return target;
}

- (CGFloat)togglePositionConstantForLevel:(LLLoveLevel)level {

    switch (level) {
        case LLLoveLevelFree:
            return -99;
        case LLLoveLevelLiked:
            return 0;
        case LLLoveLevelLoved:
            return 99;
    }

    return 0;
}

- (LLLoveLevel)updateToggleAppearanceAndModel {

    LLLoveLevel pannedLevel;
    CGFloat togglePositionTargetConstant = [self togglePositionConstantEndForIntermediary:self.togglePositionConstraint.constant];
    if (togglePositionTargetConstant > 0)
        pannedLevel = LLLoveLevelLoved;
    else if (togglePositionTargetConstant == 0)
        pannedLevel = LLLoveLevelLiked;
    else
        pannedLevel = LLLoveLevelFree;
    [self.toggleButton setImage:[[LLModel sharedModel] heartImageForLevel:pannedLevel] forState:UIControlStateNormal];
    [self.inappToggleButton setImage:[[LLModel sharedModel] heartImageForLevel:pannedLevel] forState:UIControlStateNormal];

    for (LLLoveLevel level = LLLoveLevelMIN; level <= LLLoveLevelMAX; ++level) {
        UILabel *label;
        switch (level) {
            case LLLoveLevelFree:
                label = self.freePriceLabel;
                break;
            case LLLoveLevelLiked:
                label = self.likePriceLabel;
                break;
            case LLLoveLevelLoved:
                label = self.lovePriceLabel;
                break;
        }
        label.hidden = pannedLevel != level;
        label.text = strf( @"%@\n%@",
                [[LLModel sharedModel] levelTitleForLevel:level], [[LLModel sharedModel] priceStringForLevel:level] );
    }

    return pannedLevel;
}

- (IBAction)close:(id)sender {

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)apps:(id)sender {

    [self showApps:YES];
}

- (IBAction)toggleInApp:(id)sender {

    [self toggleInApp:self.inAppContainer.frame.size.height < LL_IN_APP_OPEN_HEIGHT animated:YES];
}

- (void)toggleInApp:(BOOL)visible animated:(BOOL)animated {

    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            [self toggleInApp:visible animated:NO];
        }];
        return;
    }

    CGFloat collapsedHeight = self.userNameButton.frame.size.height;
    if (visible)
        self.inAppContainerHeight.constant = LL_IN_APP_OPEN_HEIGHT;
    else
        self.inAppContainerHeight.constant = collapsedHeight;
    [self.inAppContainer layoutIfNeeded];
}

- (void)showApps:(BOOL)inApp {

    if (!inApp) {
        [UIApp openURL:[NSURL URLWithString:@"itms://itunes.com/artist/id302275462"]];
        return;
    }

    @try {
        SKStoreProductViewController *storeViewController = [SKStoreProductViewController new];
        storeViewController.delegate = self;
        [storeViewController loadProductWithParameters:@{
                SKStoreProductParameterITunesItemIdentifier : @"302275462"
        }                              completionBlock:^(BOOL result, NSError *error) {
            if (!result) {
                err( @"Failed to load in-app details: %@", error );
                [self showApps:NO];
                return;
            }
        }];
        [self presentViewController:storeViewController animated:YES completion:nil];
    }
    @catch (NSException *exception) {
        err(@"Exception while loading in-app details: %@", exception);
        [self showApps:NO];
    }
}

- (NSUInteger)supportedInterfaceOrientations {

    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {

    return UIInterfaceOrientationPortrait;
}

- (BOOL)prefersStatusBarHidden {

    return NO;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {

    return UIStatusBarAnimationSlide;
}

#pragma mark - SKStoreProductViewControllerDelegate

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {

    [viewController dismissViewControllerAnimated:YES completion:nil];
}

@end
