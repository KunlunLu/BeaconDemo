//
//  AnalogBeaconViewController.m
//  BeaconDemo
//
//  Created by L on 2018/3/9.
//  Copyright © 2018年 lkl. All rights reserved.
//

#import "AnalogBeaconViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NSString * const Beacon_Device_UUID2 = @"E2C56DB5-DFFB-48D2-B060-D0F5A71096E1";

@interface AnalogBeaconViewController () <CBPeripheralManagerDelegate>

@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CLBeaconRegion *beaconRegion11;

@end

@implementation AnalogBeaconViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    //iOS设备作为iBeacon
    [self startBeacon];
}

- (void)startBeacon {
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue() options:@{}];
    //创建beacon区域
    self.beaconRegion11 = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:Beacon_Device_UUID2] major:9999 minor:8888 identifier:@"0000"];
}

- (void)hopPayload {
    if ([self.peripheralManager isAdvertising]) {
        [self.peripheralManager stopAdvertising];
    }
    NSDictionary *beaconPeripheraData = [self.beaconRegion11 peripheralDataWithMeasuredPower:@(-50)];
    [_peripheralManager startAdvertising:beaconPeripheraData];
    
    [NSTimer scheduledTimerWithTimeInterval:arc4random()%2?0.31875f:0.54625 target:self selector:@selector(hopPayload) userInfo:nil repeats:NO];
}

#pragma mark - CBPeripheralManagerDelegate
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    NSLog(@"didUpdateState: peripheralState=%ld", (long)peripheral.state);
    
    if (peripheral.state == CBManagerStatePoweredOn) {
        [self hopPayload];
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(nullable NSError *)error {
    //NSLog(@"didStartAdvertising: peripheral=%@ error=%@", peripheral, error);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
