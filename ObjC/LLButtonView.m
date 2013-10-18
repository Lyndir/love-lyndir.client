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

#import "LLButtonView.h"

@implementation LLButtonView

- (id)init {

    if (!(self = [super init]))
        return nil;
    
    [self setImage:[UIImage imageNamed:@"love-lyndir.button.grey.png"] forState:UIControlStateNormal];
    [self addTarget:self action:@selector(didTapButton) forControlEvents:UIControlEventTouchUpInside];

    return self;
}

- (id)initWithFrame:(CGRect)frame {

    if (!(self = [super initWithFrame:frame]))
        return nil;
    
    [self setImage:[UIImage imageNamed:@"love-lyndir.button.grey.png"] forState:UIControlStateNormal];
    [self addTarget:self action:@selector(didTapButton) forControlEvents:UIControlEventTouchUpInside];

    return self;
}

- (id)initWithCoder:(NSCoder *)coder {

    if (!(self = [super initWithCoder:coder]))
        return nil;

    [self setImage:[UIImage imageNamed:@"love-lyndir.button.grey.png"] forState:UIControlStateNormal];
    [self addTarget:self action:@selector(didTapButton) forControlEvents:UIControlEventTouchUpInside];

    return self;
}

- (void)didTapButton {

    UIViewController *viewController = self.viewController;
    if (!viewController)
        viewController = self.window.rootViewController;

    UIStoryboard *loveLyndirStoryboard = [UIStoryboard storyboardWithName:@"LoveLyndir" bundle:[NSBundle mainBundle]];
    [viewController presentViewController:loveLyndirStoryboard.instantiateInitialViewController animated:YES completion:nil];
}

@end
