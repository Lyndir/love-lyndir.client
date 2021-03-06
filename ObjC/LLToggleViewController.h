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

#import <UIKit/UIKit.h>

@interface LLToggleViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIWebView *issueView;
@property (strong, nonatomic) IBOutlet UIPanGestureRecognizer *toggleGestureRecognizer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *togglePositionConstraint;
@property (weak, nonatomic) IBOutlet UIButton *toggleButton;
@property (weak, nonatomic) IBOutlet UILabel *freePriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *likePriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *lovePriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *unavailableLabel;
@property (weak, nonatomic) IBOutlet UIView *availableContainer;
@property (weak, nonatomic) IBOutlet UIButton *userNameButton;
@property (weak, nonatomic) IBOutlet UIButton *inappToggleButton;
@property (weak, nonatomic) IBOutlet UIView *inAppContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inAppContainerHeight;

- (IBAction)onUserName:(id)sender;
- (IBAction)longOnUserName:(id)sender;
- (IBAction)didPanToggle:(UIPanGestureRecognizer *)sender;
- (IBAction)close:(id)sender;
- (IBAction)apps:(id)sender;
- (IBAction)toggleInApp:(id)sender;

@end
