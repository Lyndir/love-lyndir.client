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
//  LLGitTip.h
//  LLGitTip
//
//  Created by lhunath on 1/26/2014.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LLGitTip : UIButton

/**
 * Set this to YES if your app is in the Kids category.  It will cause a parental gate to appear before allowing access to the in-app purchase section.
 */
@property(nonatomic) BOOL kidsMode;

@property(nonatomic, copy) NSString *appURL;
@end
