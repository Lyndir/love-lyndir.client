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
//  LLModel.h
//  LLModel
//
//  Created by lhunath on 2013-10-18.
//  Copyright, lhunath (Maarten Billemont) 2013. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, LLLoveLevel) {
    LLLoveLevelMIN,
    LLLoveLevelFree = LLLoveLevelMIN,
    LLLoveLevelLiked,
    LLLoveLevelLoved,
    LLLoveLevelMAX = LLLoveLevelLoved,
};

extern NSString *const LLCurrentLevelKey;
extern NSString *const LLLoveLevelUpdatedNotification;
extern NSString *const LLEmailAddressUpdatedNotification;
extern NSString *const LLPurchaseAvailabilityNotification;

@interface LLModel : NSObject

+ (instancetype)sharedModel;

- (LLLoveLevel)level;
- (NSString *)emailAddress;
- (void)setEmailAddress:(NSString *)emailAddress;

- (UIImage *)buttonImage;
- (UIImage *)buttonImageForLevel:(LLLoveLevel)level;

- (UIImage *)heartImage;
- (UIImage *)heartImageForLevel:(LLLoveLevel)level;

- (NSString *)levelTitle;
- (NSString *)levelTitleForLevel:(LLLoveLevel)level;

- (NSString *)priceStringForLevel:(LLLoveLevel)level;

- (BOOL)isPurchaseAvailableOrError:(NSError **)error;
- (void)purchaseLevel:(LLLoveLevel)level fromVC:(UIViewController *)initiatorVC;
- (void)restorePurchases;

@end
