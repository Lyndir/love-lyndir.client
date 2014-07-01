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

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#import "LLModel.h"
#import "PearlAlert.h"
#import "PearlStringUtils.h"
#import "PearlLogger.h"
#import "PearlCodeUtils.h"
#import "PearlStrings.h"

#import "PearlOverlay.h"
#import "PearlObjectUtils.h"
#import "PearlUIUtils.h"

#import "LLConfig.h"
#ifndef LL_HOST
#define LL_HOST @"http://192.168.1.20:8080"
#endif
#ifndef LL_OPAQUE_KEY
#define LL_OPAQUE_KEY [@"DEVELOPMENT" dataUsingEncoding:NSUTF8StringEncoding]
#endif
#ifdef DEBUG
#define LL_API_USER(email) strf(@"%@/app/rest/user/%@;mode=SANDBOX", LL_HOST, [email encodeURL])
#define LL_APPLE_MANAGE [NSURL URLWithString:@"https://sandbox.itunes.apple.com/WebObjects/MZFinance.woa/wa/manageSubscriptions"]
#else
#define LL_API_USER(email) strf(@"%@/app/rest/user/%@", LL_HOST, [email encodeURL])
#define LL_APPLE_MANAGE [NSURL URLWithString:@"https://buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/manageSubscriptions"]
#endif

NSString *const LLCurrentLevelKey = @"LLCurrentLevelKey";
NSString *const LLEmailAddressKey = @"LLEmailAddressKey";
NSString *const LLReceiptHandledKey = @"LLReceiptHandledKey";
NSString *const LLLoveLevelUpdatedNotification = @"LLLoveLevelUpdatedNotification";
NSString *const LLEmailAddressUpdatedNotification = @"LLEmailAddressUpdatedNotification";
NSString *const LLPurchaseAvailabilityNotification = @"LLPurchaseAvailabilityNotification";

@interface LLModel()<SKProductsRequestDelegate, SKPaymentTransactionObserver>
@end

@implementation LLModel {
    NSUbiquitousKeyValueStore *_cloud;
    NSUserDefaults *_local;
    NSNumberFormatter *_priceFormatter;
    NSDictionary *_products;
    PearlOverlay *_purchasingActivity;
    NSOperationQueue *_serverQueue;
    SKProductsRequest *_productsRequest;
    NSError *_error;
    __weak UIViewController *_purchaseInitiatorVC;
}

+ (instancetype)sharedModel {

    static LLModel *sharedModel = nil;
    if (!sharedModel)
        sharedModel = [LLModel new];

    return sharedModel;
}

- (id)init {

    if (!(self = [super init]))
        return nil;

    [_cloud = [NSUbiquitousKeyValueStore defaultStore] synchronize];
    [_local = [NSUserDefaults standardUserDefaults] synchronize];
    [_priceFormatter = [NSNumberFormatter new] setNumberStyle:NSNumberFormatterCurrencyStyle];
    [_serverQueue = [NSOperationQueue new] setName:@"Love Lyndir Server Connector"];
    [_serverQueue setMaxConcurrentOperationCount:1];

    if (_cloud)
        [[NSNotificationCenter defaultCenter] addObserverForName:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:_cloud
                                                           queue:nil usingBlock:^(NSNotification *note) {
            NSArray *changedKeys = note.userInfo[NSUbiquitousKeyValueStoreChangedKeysKey];
            if ([changedKeys containsObject:LLCurrentLevelKey])
                [[NSNotificationCenter defaultCenter] postNotificationName:LLLoveLevelUpdatedNotification object:self];
            if ([changedKeys containsObject:LLEmailAddressKey])
                [[NSNotificationCenter defaultCenter] postNotificationName:LLEmailAddressUpdatedNotification object:self];
        }];

    // Make products available for purchase.
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [self updateProducts];

    // Make sure our receipt has been submitted and we have the latest server state.
    if ([self ensureReceiptHandled:NO])
        [self updateLevel];

    return self;
}

- (void)updateProducts {

    _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:
            [NSSet setWithObjects:[self productIdentifierForLevel:LLLoveLevelLiked],
                                  [self productIdentifierForLevel:LLLoveLevelLoved],
                                  nil]];
    _productsRequest.delegate = self;
    [_productsRequest start];
}

- (LLLoveLevel)level {

    if (_cloud)
        return (LLLoveLevel)MAX(LLLoveLevelFree, MIN( LLLoveLevelLoved, (LLLoveLevel)[_cloud longLongForKey:LLCurrentLevelKey] ));
    if (_local)
        return (LLLoveLevel)MAX(LLLoveLevelFree, MIN( LLLoveLevelLoved, (LLLoveLevel)[_local integerForKey:LLCurrentLevelKey] ));
    return LLLoveLevelFree;
}

- (void)setLevel:(LLLoveLevel)level {

    if (_cloud) {
        [_cloud setLongLong:level forKey:LLCurrentLevelKey];
        [_cloud synchronize];
    }
    if (_local) {
        [_local setInteger:level forKey:LLCurrentLevelKey];
        [_local synchronize];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:LLLoveLevelUpdatedNotification object:self];
}

- (NSString *)emailAddress {

    if (_cloud)
        return [_cloud stringForKey:LLEmailAddressKey];
    if (_local)
        return [_local stringForKey:LLEmailAddressKey];
    return nil;
}

- (void)setEmailAddress:(NSString *)emailAddress {

    if (_cloud) {
        [_cloud setString:emailAddress forKey:LLEmailAddressKey];
        [_cloud synchronize];
    }
    if (_local) {
        [_local setObject:emailAddress forKey:LLEmailAddressKey];
        [_local synchronize];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:LLEmailAddressUpdatedNotification object:self];
    if (![self sendReceipt:nil])
        [self updateLevel];
}

- (BOOL)receiptHandled {

    if (_cloud)
        return [_cloud boolForKey:LLReceiptHandledKey];
    if (_local)
        return [_local boolForKey:LLReceiptHandledKey];
    return NO;
}

- (void)setReceiptHandled:(BOOL)handled {

    if (_cloud) {
        [_cloud setBool:handled forKey:LLReceiptHandledKey];
        [_cloud synchronize];
    }
    if (_local) {
        [_local setBool:handled forKey:LLReceiptHandledKey];
        [_local synchronize];
    }
}

- (BOOL)isPurchaseAvailableOrError:(NSError **)error {

    if (error)
        *error = _error;
    if (![_products count] && error && !*error)
        *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey : @"Products unavailable" }];

    return [_products count] > 0;
}

- (void)purchaseLevel:(LLLoveLevel)level fromVC:(UIViewController *)initiatorVC {

    if (!self.emailAddress) {
        // Missing email address.
        [PearlAlert showAlertWithTitle:@"Missing Email Address" message:@"Begin by setting your email address at the bottom of the screen."
                             viewStyle:UIAlertViewStyleDefault initAlert:nil tappedButtonBlock:nil
                           cancelTitle:[PearlStrings get].commonButtonBack otherTitles:nil];
        return;
    }

    if (level == self.level) {
        // Already at this level, don't need to purchase.
        return;
    }

    SKProduct *product = [self productForLevel:level];
    if (!product) {
        // This product cannot be purchased.
        return;
    }

    _purchaseInitiatorVC = initiatorVC;
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    if ([payment respondsToSelector:@selector(setApplicationUsername:)])
        payment.applicationUsername =
                [[[self.emailAddress dataUsingEncoding:NSUTF8StringEncoding]
                        hmacWith:PearlHashSHA1 key:LL_OPAQUE_KEY] encodeBase64];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)restorePurchases {

    [_purchasingActivity cancelOverlayAnimated:YES];
    _purchasingActivity = [PearlOverlay showProgressOverlayWithTitle:@"Restoring Purchases"];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (UIImage *)buttonImage {

    return [self buttonImageForLevel:[self level]];
}

- (UIImage *)buttonImageForLevel:(LLLoveLevel)level {

    switch (level) {
        case LLLoveLevelFree:
            return [UIImage imageNamed:@"love-lyndir.button.grey.png"];
        case LLLoveLevelLiked:
            return [UIImage imageNamed:@"love-lyndir.button.green.png"];
        case LLLoveLevelLoved:
            return [UIImage imageNamed:@"love-lyndir.button.red.png"];
    }

    return nil;
}

- (UIImage *)heartImage {

    return [self heartImageForLevel:[self level]];
}

- (UIImage *)heartImageForLevel:(LLLoveLevel)level {

    switch (level) {
        case LLLoveLevelFree:
            return [UIImage imageNamed:@"love-lyndir.heart.grey.png"];
        case LLLoveLevelLiked:
            return [UIImage imageNamed:@"love-lyndir.heart.green.png"];
        case LLLoveLevelLoved:
            return [UIImage imageNamed:@"love-lyndir.heart.red.png"];
    }

    return nil;
}

- (NSString *)levelTitle {

    return [self levelTitleForLevel:[self level]];
}

- (NSString *)levelTitleForLevel:(LLLoveLevel)level {

    switch (level) {
        case LLLoveLevelFree:
            return @"Free";
        case LLLoveLevelLiked:
            return @"Like";
        case LLLoveLevelLoved:
            return @"Love";
    }

    return nil;
}

- (NSString *)productIdentifierForLevel:(LLLoveLevel)level {

    switch (level) {
        case LLLoveLevelFree:
            return nil;
        case LLLoveLevelLiked:
            return strf( @"%@.love.liked", [[NSBundle mainBundle] bundleIdentifier] );
        case LLLoveLevelLoved:
            return strf( @"%@.love.loved", [[NSBundle mainBundle] bundleIdentifier] );
    }

    return nil;
}

- (SKProduct *)productForLevel:(LLLoveLevel)level {

    NSString *productId = [self productIdentifierForLevel:level];
    if (!productId)
        return nil;

    return (SKProduct *)(_products[productId]);
}

- (NSString *)priceStringForLevel:(LLLoveLevel)level {

    SKProduct *product = [self productForLevel:level];
    [_priceFormatter setLocale:product.priceLocale];
    return [_priceFormatter stringFromNumber:product.price]?: @"";
}

/**
 * @return YES if the receipt was successfully parsed and sent off to the server.
 */
- (BOOL)sendReceipt:(SKPaymentTransaction *)transaction {

    if (!self.emailAddress)
            // Missing email address, cannot identify user.
        return NO;

    NSData *receipt = nil;
    if (floor( NSFoundationVersionNumber ) > NSFoundationVersionNumber_iOS_6_1)
        receipt = [NSData dataWithContentsOfURL:[NSBundle mainBundle].appStoreReceiptURL];
    else {
        // pre-iOS 7
        receipt = transaction.transactionReceipt;
        if (!receipt)
            receipt = transaction.originalTransaction.transactionReceipt;
    }
    if (![receipt length]) {
        wrn(@"No receipt for: %@, %@", self.emailAddress, transaction);
        return NO;
    }

    // Got a receipt, begin handling it.
    self.receiptHandled = NO;

    NSError *error = nil;
    NSData *requestContent = [NSJSONSerialization dataWithJSONObject:@{
            @"receiptB64"  : [receipt encodeBase64],
            @"application" : [NSBundle mainBundle].bundleIdentifier
    }                                                        options:NSJSONWritingPrettyPrinted error:&error];
    if (!requestContent) {
        wrn(@"Error serializing request: %@", _error = error);
        return NO;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:LL_API_USER(self.emailAddress)]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"utf-8" forHTTPHeaderField:@"Accept-Charset"];
    [request setHTTPBody:requestContent];
    [request setHTTPMethod:@"PUT"];

    [NSURLConnection sendAsynchronousRequest:request queue:_serverQueue completionHandler:
            ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                [self handleJSONResponse:response data:data error:connectionError successHandler:
                        ^(NSHTTPURLResponse *httpResponse, NSDictionary *responseObject) {
                            dbg(@"Successfully submitted receipt, updated user:\n%@", responseObject);
                            self.level = [responseObject[@"loveLevel"] unsignedIntegerValue];
                            self.receiptHandled = YES;

                            if (_purchaseInitiatorVC)
                                [PearlAlert showAlertWithTitle:@"Thanks!" message:strf( @"Thanks for %@ Lyndir's products.",
                                        self.level == LLLoveLevelLiked? @"liking": @"loving" )
                                                     viewStyle:UIAlertViewStyleDefault initAlert:nil
                                             tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                                                 if (buttonIndex == [alert firstOtherButtonIndex])
                                                     [self sharePurchase];

                                                 _purchaseInitiatorVC = nil;
                                             } cancelTitle:[PearlStrings get].commonButtonDone otherTitles:@"Share", nil];

                            int activeSubscriptions = [NSNullToNil(responseObject[@"activeSubscriptions"]) intValue];
                            if (activeSubscriptions > 1)
                                [PearlAlert showAlertWithTitle:@"Multiple Subscriptions" message:
                                        strf( @"It looks like you have %ld active subscriptions.\n"
                                                @"Only you can cancel subscriptions.  "
                                                @"You do this from the App Store's “Manage Subscriptions” page.",
                                                (long)activeSubscriptions )
                                                     viewStyle:UIAlertViewStyleDefault initAlert:nil
                                             tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                                                 if (buttonIndex == [alert cancelButtonIndex])
                                                     return;
                                                 if (buttonIndex == [alert firstOtherButtonIndex])
                                                     [UIApp openURL:LL_APPLE_MANAGE];
                                             } cancelTitle:[PearlStrings get].commonButtonDone otherTitles:@"Manage", nil];
                        } failureHandler:
                        ^(NSHTTPURLResponse *httpResponse, NSString *entity) {
                            if (httpResponse.statusCode == 404) {
                                wrn(@"User disappeared: %@", self.emailAddress);
                                self.level = LLLoveLevelFree;
                                _purchaseInitiatorVC = nil;
                            }
                        }];
            }];

    return YES;
}

- (void)sharePurchase {

    [_purchaseInitiatorVC presentViewController:[[UIActivityViewController alloc] initWithActivityItems:@[
            @"I just signed up for donation to Lyndir's awesome free apps campaign. Pay what you want or nothing at all.",
            [NSURL URLWithString:@"https://itunes.apple.com/artist/id302275462"]
    ]                                                                             applicationActivities:nil]
                                       animated:YES completion:nil];
}

- (void)updateLevel {

    if (!self.emailAddress)
            // Missing email address, cannot identify user.
        return;

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:LL_API_USER(self.emailAddress)]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"utf-8" forHTTPHeaderField:@"Accept-Charset"];
    [request setHTTPMethod:@"GET"];

    [NSURLConnection sendAsynchronousRequest:request queue:_serverQueue completionHandler:
            ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                [self handleJSONResponse:response data:data error:connectionError successHandler:
                        ^(NSHTTPURLResponse *httpResponse, NSDictionary *responseObject) {
                            dbg(@"Successfully updated user:\n%@", responseObject);
                            self.level = [responseObject[@"loveLevel"] unsignedIntegerValue];
                        } failureHandler:
                        ^(NSHTTPURLResponse *httpResponse, NSString *entity) {
                            if (httpResponse.statusCode == 404) {
                                wrn(@"User disappeared: %@, will try to recreate by submitting receipt.", self.emailAddress);
                                [self sendReceipt:nil];
                            }
                        }];
            }];
}

- (void)handleJSONResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *)connectionError
            successHandler:(void (^)(NSHTTPURLResponse *httpResponse, NSDictionary *responseObject))successHandler
            failureHandler:(void (^)(NSHTTPURLResponse *httpResponse, NSString *entity))failureHandler {

    @try {
        if (connectionError) {
            err(@"Error sending receipt: %@", _error = connectionError);
            if (!response) {
                failureHandler( nil, nil );
                return;
            }
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSString *entity = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (httpResponse.statusCode >= 300) {
            err(@"Unsuccessful response code %@(%ld): %@", //
            [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode], (long)httpResponse.statusCode, entity);
            failureHandler( httpResponse, entity );
            return;
        }

        if (![data length]) {
            err(@"Missing response.");
            failureHandler( httpResponse, entity );
            return;
        }

        NSError *error_ = nil;
        NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error_];
        if (!responseObject) {
            err(@"Error parsing response: %@", _error = error_);
            failureHandler( httpResponse, entity );
            return;
        }

        // Success.
        _error = nil;
        successHandler( httpResponse, responseObject );
    }
    @finally {
        [_purchasingActivity cancelOverlayAnimated:YES];
        [self ensureReceiptHandled:YES];
    }
}

- (BOOL)ensureReceiptHandled:(BOOL)delayedRetry {

    if (self.receiptHandled)
        return YES;

    if (delayedRetry) {
        dbg(@"Receipt not handled, queuing to submit in 10s");
        dispatch_after( dispatch_time( DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC ),
                dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
                    [self ensureReceiptHandled:NO];
                } );
        return NO;
    }

    [self sendReceipt:nil];
    return NO;
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {

    dbg(@"Response: products=%@, invalidProductIdentifiers=%@", response.products, response.invalidProductIdentifiers);
    NSMutableDictionary *products = [NSMutableDictionary dictionaryWithCapacity:[response.products count]];
    for (SKProduct *product in response.products)
        products[product.productIdentifier] = product;
    _products = products;

    [[NSNotificationCenter defaultCenter] postNotificationName:LLPurchaseAvailabilityNotification object:self];
}

- (void)requestDidFinish:(SKRequest *)request {

    dbg(@"Request finished: %@", request);
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {

    err(@"Request failed: %@\n%@", request, _error = error);
    if (request == _productsRequest) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LLPurchaseAvailabilityNotification object:self];

        inf(@"Will retry failed product request after 20s");
        dispatch_after( dispatch_time( DISPATCH_TIME_NOW, NSEC_PER_SEC * 20 ),
                dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
                    dbg(@"Retrying failed request.");
                    [self updateProducts];
                } );
    }
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {

    dbg(@"Updated transactions: %@", transactions);
    for (SKPaymentTransaction *transaction in transactions)
        switch (transaction.transactionState) {
            case SKPaymentTransactionStateDeferred:
            case SKPaymentTransactionStatePurchasing:
                _purchasingActivity = [PearlOverlay showProgressOverlayWithTitle:strf( @"Purchasing %@",
                ((SKProduct *)(_products)[transaction.payment.productIdentifier]).localizedTitle )];
                break;
            case SKPaymentTransactionStateFailed:
                err( @"In-App Purchase failed: %@", transaction.error );
                [[NSNotificationCenter defaultCenter] postNotificationName:LLLoveLevelUpdatedNotification object:self];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [_purchasingActivity cancelOverlayAnimated:YES];
                [PearlAlert showAlertWithTitle:@"Purchase Failed" message:[transaction.error localizedDescription]
                                     viewStyle:UIAlertViewStyleDefault initAlert:nil
                             tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                                 if (buttonIndex == [alert cancelButtonIndex])
                                     return;

                                 [PearlAlert showAlertWithTitle:@"Purchase Problems" message:
                                         @"If you're having trouble making a purchase, make sure you're connected to a stable Internet connection, "
                                                 @"such as Wi-Fi.  Make sure Safari works.  Try going into Settings -> iTunes & App Store and logging out. "
                                                 @"If problems persist, Apple may have temporary server issues."
                                                      viewStyle:UIAlertViewStyleDefault initAlert:nil tappedButtonBlock:nil
                                                    cancelTitle:[PearlStrings get].commonButtonThanks otherTitles:nil];
                             }
                                   cancelTitle:@"Retry Later" otherTitles:@"Help", nil];
                break;
            case SKPaymentTransactionStatePurchased:
                [self sendReceipt:transaction];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self sendReceipt:transaction];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
        }
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions {

    dbg(@"Removed transactions: %@", transactions);
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {

    err(@"Failed to restore transactions: %@", _error = error);
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {

    dbg(@"Finished restoring transactions");
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray *)downloads {

    dbg(@"Updated downloads: %@", downloads);
}

@end
