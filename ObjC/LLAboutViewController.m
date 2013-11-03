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
//  LLAboutViewController.h
//  LLAboutViewController
//
//  Created by lhunath on 11/3/2013.
//  Copyright, lhunath (Maarten Billemont) 2013. All rights reserved.
//

#import "LLAboutViewController.h"

@implementation LLAboutViewController

- (IBAction)action:(id)sender {

    [self presentViewController:[[UIActivityViewController alloc] initWithActivityItems:@[
            @"Lyndir made all its apps free and open source. Get them, use them, and if you love them, pay what you want!",
            [NSURL URLWithString:@"https://itunes.apple.com/artist/id302275462"]
    ]                                                             applicationActivities:nil]
                       animated:YES completion:nil];
}

@end
