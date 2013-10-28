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
#import "PearlLogger.h"

@implementation LLToggleViewController {
    CGFloat _togglePositionPanFromConstant;
}

- (void)viewDidLoad {

    [self updateTogglePosition];
    [[NSNotificationCenter defaultCenter]
            addObserverForName:LLLoveLevelUpdatedNotification object:nil queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *note) {
                        if (self.toggleGestureRecognizer.state != UIGestureRecognizerStatePossible)
                                // Drag ongoing, don't interrupt.
                            return;

                        [self updateTogglePosition];
                    }];

    [self updateAvailability];
    [[NSNotificationCenter defaultCenter]
            addObserverForName:LLPurchaseAvailabilityNotification object:nil queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *note) {
                        [self updateAvailability];
                    }];

    [super viewDidLoad];
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

- (IBAction)didPanToggle:(UIPanGestureRecognizer *)sender {

    BOOL updateModel = NO;
    CGFloat target = _togglePositionPanFromConstant + [sender translationInView:self.view].x;
    dbg(@"pan target: %f", target);

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

    dbg(@"pan target post state: %f", target);
    self.togglePositionConstraint.constant = MIN(99, MAX( -99, target ) );
    dbg(@"pan target post bound: %f", self.togglePositionConstraint.constant);
    LLLoveLevel pannedLevel = [self updateToggleAppearanceAndModel];
    if (updateModel)
        [[LLModel sharedModel] purchaseLevel:pannedLevel];
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
        case LLLoveLevelLoved:
            return 0;
        case LLLoveLevelAwesome:
            return 99;
    }

    return 0;
}

- (LLLoveLevel)updateToggleAppearanceAndModel {

    LLLoveLevel pannedLevel;
    CGFloat togglePositionTargetConstant = [self togglePositionConstantEndForIntermediary:self.togglePositionConstraint.constant];
    if (togglePositionTargetConstant > 0)
        pannedLevel = LLLoveLevelAwesome;
    else if (togglePositionTargetConstant == 0)
        pannedLevel = LLLoveLevelLoved;
    else
        pannedLevel = LLLoveLevelFree;
    dbg(@"Updating for level %d, since constant is: %f", pannedLevel, togglePositionTargetConstant);

    self.freePriceLabel.hidden = pannedLevel != LLLoveLevelFree;
    self.lovePriceLabel.hidden = pannedLevel != LLLoveLevelLoved;
    self.awesomePriceLabel.hidden = pannedLevel != LLLoveLevelAwesome;
    [self.toggleButton setImage:[[LLModel sharedModel] heartImageForLevel:pannedLevel] forState:UIControlStateNormal];

    return pannedLevel;
}

- (IBAction)close:(id)sender {

    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
