//
//  BLEScanner.h
//  BeaconDemo
//
//  Created by L on 2018/3/8.
//  Copyright © 2018年 lkl. All rights reserved.
//

#import <Foundation/Foundation.h>

//MESH传输类型：唤醒回复、地址、交易、红包
#define SERVICE_RESPONSE       @"FFFF"
#define SERVICE_ADDRESS        @"FFBB"
#define SERVICE_TRANSACTION    @"FFAA"
#define SERVICE_LUCKY_MONEY    @"FF99"

@interface BLEScanner : NSObject

@end
