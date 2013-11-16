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
//  LLButtonViewController.h
//  LLButtonViewController
//
//  Created by lhunath on 2013-10-17.
//  Copyright, lhunath (Maarten Billemont) 2013. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LLButtonView : UIButton

/**
 * Set this to the view controller responsible for this view.  It will be used to present child view controllers.
 */
@property(nonatomic, strong) UIViewController *viewController;

/**
 * Set this to YES if your app is in the Kids category.  It will cause a parental gate to appear before allowing access to the in-app purchase section.
 */
@property(nonatomic) BOOL kidsMode;

@end
