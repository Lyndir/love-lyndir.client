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
#import "LLModel.h"

@implementation LLButtonView

- (id)initWithFrame:(CGRect)frame {

    if (!(self = [super initWithFrame:frame]))
        return nil;

    [self setup];

    return self;
}

- (id)initWithCoder:(NSCoder *)coder {

    if (!(self = [super initWithCoder:coder]))
        return nil;

    [self setup];

    return self;
}

- (void)setup {

    [self addTarget:self action:@selector(didTapButton) forControlEvents:UIControlEventTouchUpInside];

    [self setImage:[LLModel sharedModel].buttonImage forState:UIControlStateNormal];
    [[NSNotificationCenter defaultCenter] addObserverForName:LLLoveLevelUpdatedNotification object:nil queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      [self setImage:[LLModel sharedModel].buttonImage forState:UIControlStateNormal];
                                                  }];
}

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didTapButton {

    UIViewController *viewController = self.viewController;
    if (!viewController)
        viewController = self.window.rootViewController;

    UIStoryboard *loveLyndirStoryboard = [UIStoryboard storyboardWithName:@"LoveLyndir" bundle:[NSBundle mainBundle]];
    [viewController presentViewController:loveLyndirStoryboard.instantiateInitialViewController animated:YES completion:nil];
}

@end
