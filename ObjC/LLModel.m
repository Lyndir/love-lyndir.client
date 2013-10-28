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

//#define LL_HOST @"http://love.lyndir.com"
#define LL_HOST @"http://192.168.1.20:8080"
#define LL_API_USER LL_HOST @"/app/rest/user"

NSString *const LLCurrentLevelKey = @"LLCurrentLevelKey";
NSString *const LLReceiptHandledKey = @"LLReceiptHandledKey";
NSString *const LLLoveLevelUpdatedNotification = @"LLLoveLevelUpdatedNotification";
NSString *const LLPurchaseAvailabilityNotification = @"LLPurchaseAvailabilityNotification";

@interface LLModel()<SKProductsRequestDelegate, SKPaymentTransactionObserver>
@end

@implementation LLModel {
    NSUbiquitousKeyValueStore *_cloud;
    NSUserDefaults *_local;
    NSNumberFormatter *_priceFormatter;
    NSDictionary *_products;
    PearlAlert *_purchasingActivity;
    NSOperationQueue *_serverQueue;
    SKProductsRequest *_productsRequest;
    NSError *_error;
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

    // StoreKit setup.
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [self updateProducts];

    self.receiptHandled = NO;
    [self ensureReceiptHandled:NO];

    return self;
}

- (void)updateProducts {

    _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:
            [NSSet setWithObjects:[self productIdentifierForLevel:LLLoveLevelLoved],
                                  [self productIdentifierForLevel:LLLoveLevelAwesome],
                                  nil]];
    _productsRequest.delegate = self;
    [_productsRequest start];
}

- (LLLoveLevel)level {

    if (_cloud)
        return (LLLoveLevel)MAX(LLLoveLevelFree, MIN( LLLoveLevelAwesome, (LLLoveLevel)[_cloud longLongForKey:LLCurrentLevelKey] ));
    if (_local)
        return (LLLoveLevel)MAX(LLLoveLevelFree, MIN( LLLoveLevelAwesome, (LLLoveLevel)[_local integerForKey:LLCurrentLevelKey] ));
    return LLLoveLevelFree;
}

- (void)setLevel:(LLLoveLevel)level {

    NSAssert(!self.receiptHandled, @"Level shouldn't be set when the receipt is not being handled.");

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

    *error = _error;
    return [_products count] > 0;
}

- (void)purchaseLevel:(LLLoveLevel)level {

    if (level == self.level) {
        // Already at this level, don't need to purchase.
        return;
    }

    SKProduct *product = [self productForLevel:level];
    if (product)
        [[SKPaymentQueue defaultQueue] addPayment:[SKPayment paymentWithProduct:product]];
}

- (UIImage *)buttonImage {

    return [self buttonImageForLevel:[self level]];
}

- (UIImage *)buttonImageForLevel:(LLLoveLevel)level {

    switch (level) {
        case LLLoveLevelFree:
            return [UIImage imageNamed:@"love-lyndir.button.grey.png"];
        case LLLoveLevelLoved:
            return [UIImage imageNamed:@"love-lyndir.button.green.png"];
        case LLLoveLevelAwesome:
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
        case LLLoveLevelLoved:
            return [UIImage imageNamed:@"love-lyndir.heart.green.png"];
        case LLLoveLevelAwesome:
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
        case LLLoveLevelLoved:
            return @"Loved";
        case LLLoveLevelAwesome:
            return @"Awesome";
    }

    return nil;
}

- (NSString *)productIdentifierForLevel:(LLLoveLevel)level {

    switch (level) {
        case LLLoveLevelFree:
            return nil;
        case LLLoveLevelLoved:
            return PearlString( @"%@.love.loved", [[NSBundle mainBundle] bundleIdentifier] );
        case LLLoveLevelAwesome:
            return PearlString( @"%@.love.awesome", [[NSBundle mainBundle] bundleIdentifier] );
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
    return [_priceFormatter stringFromNumber:product.price];
}

- (void)sendAppReceipt {

    if ([self sendReceipt:nil]) {
        // We were able to find the receipt in the application bundle.
        return;
    }

    // We weren't able to find the receipt to handle.  Try restoring purchases instead.
    // If this fails to get us the receipt, we'll need the user to explicitly try the purchase again.
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

/**
 * @return YES if the receipt was successfully parsed and sent off to the server.
 */
- (BOOL)sendReceipt:(SKPaymentTransaction *)transaction {

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
        wrn(@"Empty receipt for: %@", transaction);
        return NO;
    }

    // Got a receipt, begin handling it.
    self.receiptHandled = NO;

    NSError *error = nil;
    NSData *requestContent = [NSJSONSerialization dataWithJSONObject:@{ @"receiptB64" : [receipt encodeBase64] }
                                                             options:NSJSONWritingPrettyPrinted error:&error];
    if (!requestContent) {
        wrn(@"Error serializing request: %@", _error = error);
        return NO;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:LL_API_USER @"/lhunath@lyndir.com"]]; // TODO
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"utf-8" forHTTPHeaderField:@"Accept-Charset"];
    [request setHTTPBody:requestContent];
    [request setHTTPMethod:@"PUT"];

    [NSURLConnection sendAsynchronousRequest:request queue:_serverQueue completionHandler:
            ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                @try {
                    if (connectionError) {
                        err(@"Error sending receipt: %@", _error = connectionError);
                        if (!response)
                            return;
                    }

                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    if (httpResponse.statusCode >= 300) {
                        err(@"Unsuccessful response code %@(%d): %@", [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode],
                        httpResponse.statusCode, data);
                        return;
                    }

                    if (![data length]) {
                        err(@"Missing response.");
                        return;
                    }

                    NSError *error_ = nil;
                    NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error_];
                    if (!responseObject) {
                        err(@"Error parsing response: %@", _error = error_);
                        return;
                    }

                    // Success.
                    dbg(@"Successfully submitted receipt, updated user:\n%@", responseObject);
                    self.level = [[responseObject objectForKey:@"loveLevel"] unsignedIntegerValue];
                    self.receiptHandled = YES;
                }
                @finally {
                    [_purchasingActivity cancelAlertAnimated:YES];
                    [self ensureReceiptHandled:YES];
                }
            }];

    return YES;
}

- (void)ensureReceiptHandled:(BOOL)delayedRetry {

    if (self.receiptHandled)
        return;

    if (delayedRetry) {
        dbg(@"Receipt not handled, queuing to submit in 10s");
        dispatch_after( dispatch_time( DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC ),
                dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
                    [self ensureReceiptHandled:NO];
                } );
        return;
    }

    [self sendAppReceipt];
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {

    dbg(@"Response: %@", response);
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
            case SKPaymentTransactionStatePurchasing:
                _purchasingActivity = [PearlAlert showActivityWithTitle:PearlString( @"Purchasing %@",
                        ((SKProduct *)(_products)[transaction.payment.productIdentifier]).localizedTitle )];
                break;
            case SKPaymentTransactionStateFailed:
                err( @"In-App Purchase failed: %@", transaction.error );
                [[NSNotificationCenter defaultCenter] postNotificationName:LLLoveLevelUpdatedNotification object:self];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [_purchasingActivity cancelAlertAnimated:YES];
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
