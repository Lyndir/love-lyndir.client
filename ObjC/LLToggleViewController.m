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
#import "LLToggleViewController.h"
#import "LLModel.h"
#import "PearlAlert.h"
#import "PearlStrings.h"
#import "PearlStringUtils.h"

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

    [super viewDidLoad];
}

- (NSString *)emailAddress {

    NSString *emailAddress = [LLModel sharedModel].emailAddress;
    if ([emailAddress length])
        return emailAddress;

    return @"Tap to set your email address.";
}

- (void)updateTogglePosition {

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

    [PearlAlert showAlertWithTitle:@"Email Address"
                           message:@"Your email address is necessary to make your purchase available across all Lyndir apps."
                         viewStyle:UIAlertViewStylePlainTextInput
                         initAlert:^(UIAlertView *alert, UITextField *firstField) {
                             firstField.text = [LLModel sharedModel].emailAddress;
                             firstField.placeholder = @"E-mail address";
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
        label.text = PearlString( @"%@\n%@",
                [[LLModel sharedModel] levelTitleForLevel:level], [[LLModel sharedModel] priceStringForLevel:level] );
    }

    return pannedLevel;
}

- (IBAction)close:(id)sender {

    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
