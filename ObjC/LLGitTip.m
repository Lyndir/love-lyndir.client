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

#import "LLGitTip.h"
#import "PearlAlert.h"
#import "PearlUIUtils.h"
#import "PearlStrings.h"
#import "PearlStringUtils.h"
#import "PearlInfoPlist.h"

@implementation LLGitTip {
}

- (id)init {

    return [self initWithFrame:CGRectMake( 0, 0, 89, 18 )];
}

- (id)initWithFrame:(CGRect)frame {

    if (!(self = [super initWithFrame:frame]))
        return nil;

    [self setup];

    return self;
}

- (void)awakeFromNib {

    [super awakeFromNib];

    [self setup];
}

- (void)setup {

    self.appURL = PearlString(@"https://github.com/Lyndir/%@", [PearlInfoPlist get].CFBundleName);

    [self addTarget:self action:@selector(didTapButton) forControlEvents:UIControlEventTouchUpInside];
    [self setImage:[UIImage imageNamed:@"gittip.png"] forState:UIControlStateNormal];
    [self sizeToFit];

    dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0 ), ^{
        NSData *tipImageData = [NSURLConnection sendSynchronousRequest:
                [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://img.shields.io/gittip/lhunath.png"]]
                                                     returningResponse:nil error:nil];
        UIImage *tipImage = [UIImage imageWithData:tipImageData];
        dispatch_async( dispatch_get_main_queue(), ^{
            [self setImage:tipImage forState:UIControlStateNormal];
            [self sizeToFit];
        } );
    } );
}

- (void)didTapButton {

    if (self.kidsMode)
            // In kids mode, first show the parental gate.
        [PearlAlert showParentalGate:^(BOOL continuing) {
            if (continuing)
                [self showGitTip];
        }];
    else
        [self showGitTip];
}

- (void)showGitTip {

    [PearlAlert showAlertWithTitle:@"Freedom"
                           message:PearlString(
                                   @"I believe in a free economy where people put their own price tag on the things they use and love.\n"
                                           @"If you feel %@ is worth it, consider putting a price on it.",
                                   [PearlInfoPlist get].CFBundleDisplayName )
                         viewStyle:UIAlertViewStyleDefault initAlert:nil
                 tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                     if (buttonIndex == [alert cancelButtonIndex])
                         return;
                     if (buttonIndex == [alert firstOtherButtonIndex])
                         [self.window.rootViewController presentViewController:
                                 [[UIActivityViewController alloc] initWithActivityItems:@[
                                         PearlString( @"I got %@ for free and it's awesome.", [PearlInfoPlist get].CFBundleDisplayName ),
                                         [NSURL URLWithString:PearlString( @"https://itunes.apple.com/artist/%@", self.iTunesID )]
                                 ]                                 applicationActivities:nil]
                                                                      animated:YES completion:nil];
                     if (buttonIndex == [alert firstOtherButtonIndex] + 1)
                         [UIApp openURL:[NSURL URLWithString:@"https://www.gittip.com/lhunath/"]];
                 }
                       cancelTitle:[PearlStrings get].commonButtonBack otherTitles:@"Share", @"Tip", nil];
}

@end
