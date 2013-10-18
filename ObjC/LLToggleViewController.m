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

#import "LLToggleViewController.h"

@implementation LLToggleViewController

- (IBAction)close:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
