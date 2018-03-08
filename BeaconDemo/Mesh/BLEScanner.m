//
//  BLEScanner.m
//  BeaconDemo
//
//  Created by L on 2018/3/8.
//  Copyright © 2018年 lkl. All rights reserved.
//

#import "BLEScanner.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface BLEScanner ()<CBPeripheralManagerDelegate>
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@end

@implementation BLEScanner

static BLEScanner* bleScanner = nil;

+ (instancetype)share {
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        bleScanner = [[super allocWithZone:NULL] init];
    }) ;
    return bleScanner ;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [BLEScanner share] ;
}

- (id)copyWithZone:(struct _NSZone *)zone {
    return [BLEScanner share] ;
}

- (CBPeripheralManager *)peripheralManager {
    if(!_peripheralManager)
        _peripheralManager= [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];

    return _peripheralManager;
}


- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBManagerStatePoweredOn) {
        NSLog(@"蓝牙已开");
        // 根据SERVICE_UUID来扫描外设，如果不设置SERVICE_UUID，则无法扫描到后台广播
        NSMutableArray *scanUUIDs = [NSMutableArray arrayWithObjects:[CBUUID UUIDWithString:SERVICE_RESPONSE],[CBUUID UUIDWithString:SERVICE_RESPONSE],[CBUUID UUIDWithString:SERVICE_ADDRESS],[CBUUID UUIDWithString:SERVICE_TRANSACTION],[CBUUID UUIDWithString:SERVICE_LUCKY_MONEY], nil];

        [central scanForPeripheralsWithServices:scanUUIDs options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
    }
    if(central.state == CBManagerStateUnsupported) {
        NSLog(@"该设备不支持蓝牙");
    }
    if (central.state == CBManagerStatePoweredOff) {
        NSLog(@"蓝牙已关闭");
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {
    NSString *userid = peripheral.identifier.UUIDString;

    NSLog(@"%@扫描数据：%@",userid,advertisementData);

    NSArray *advUUIDs = [advertisementData valueForKey:@"kCBAdvDataServiceUUIDs"];
    if (advUUIDs.count == 0) {
        advUUIDs = [advertisementData valueForKey:@"kCBAdvDataHashedServiceUUIDs"];
    }
}

@end
