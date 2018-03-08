//
//  ViewController.m
//  BeaconDemo
//
//  Created by L on 2018/3/7.
//  Copyright © 2018年 lkl. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <UserNotifications/UserNotifications.h>
#import <CoreBluetooth/CoreBluetooth.h>

NSString * const Beacon_Device_UUID = @"E2C56DB5-DFFB-48D2-B060-D0F5A71096E1";

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate,CLLocationManagerDelegate,UNUserNotificationCenterDelegate,CBPeripheralManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLBeaconRegion *beaconRegion;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *beaconArray;

@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CLBeaconRegion *beaconRegion11;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    //扫描周围的iBeacon
//    [self scanBeacon];
    
    //iOS设备作为iBeacon
    [self startBeacon];
}

/***************iOS设备作为iBeacon start************************/
- (void)startBeacon {
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue() options:@{}];
    //创建beacon区域
    self.beaconRegion11 = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:Beacon_Device_UUID] major:9999 minor:8888 identifier:@"0000"];
}

- (void)hopPayload {
    if ([self.peripheralManager isAdvertising]) {
        [self.peripheralManager stopAdvertising];
    }
    NSDictionary *beaconPeripheraData = [self.beaconRegion11 peripheralDataWithMeasuredPower:@(-50)];
    [_peripheralManager startAdvertising:beaconPeripheraData];
    
//    [NSTimer scheduledTimerWithTimeInterval:arc4random()%2?0.31875f:0.54625 target:self selector:@selector(hopPayload) userInfo:nil repeats:NO];
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

/***************iOS设备作为iBeacon end**************************/

- (void)scanBeacon {
    BOOL availableMonitor = [CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]];
    if (availableMonitor) {
        CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
        switch (authorizationStatus) {
            case kCLAuthorizationStatusNotDetermined:
            {
                NSLog(@"这台设备可以检测到周围的beacon");
                [self.locationManager requestAlwaysAuthorization];
            }
                break;
            case kCLAuthorizationStatusRestricted:
            case kCLAuthorizationStatusDenied:
                NSLog(@"受限制或者拒绝");
                break;
            case kCLAuthorizationStatusAuthorizedAlways:
            case kCLAuthorizationStatusAuthorizedWhenInUse:
                [self startMonitoring];
                break;
        }
    } else {
        NSLog(@"该设备不支持 CLBeaconRegion 区域检测");
    }
    
    [self.view addSubview:self.tableView];
    self.beaconArray = [[NSMutableArray alloc] init];
}

- (void)startMonitoring {
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
    [self.locationManager startMonitoringForRegion:self.beaconRegion];
    
    //authorization
    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
                              if(granted)
                              {
                                  NSLog(@"授权成功");
                              }
                          }];
}

- (void)stopMonitoring {
    [self.locationManager stopMonitoringForRegion:self.beaconRegion];
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status > kCLAuthorizationStatusDenied) {
        [self performSelectorOnMainThread:@selector(startMonitoring) withObject:nil waitUntilDone:NO];
    }
}

- (void)sendLocalNotificationTitle:(NSString *)title msg:(NSString *)msg {
    //regitser
    UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
    content.title = [NSString localizedUserNotificationStringForKey:title?:@"通知" arguments:nil];
    content.body = [NSString localizedUserNotificationStringForKey:msg?:@"你进入了mesh区域" arguments:nil];
//    content.subtitle = [NSString localizedUserNotificationStringForKey:@"打开查看" arguments:nil];
    content.sound = [UNNotificationSound defaultSound];
    
    // Deliver the notification in ten seconds.
    UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
    UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:@"FiveSecond" content:content trigger:trigger];
    
    // Schedule the notification.
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        NSLog(@"添加推送成功 ：%@", error ? [NSString stringWithFormat:@"error : %@", error] : @"success");
    }];
}

#pragma mark - CLLocationManagerDelegate
// 当程序被杀掉之后，进入ibeacon区域，或者在程序运行时锁屏／解锁 会回调此函数
- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    
}

#pragma mark - Monitoring：可以用来在设备进入/退出某个地理区域时获得通知, 使用这种方法可以在应用程序的后台运行时检测 iBeacon，但是只能同时检测 20 个 region 区域，并且不能够推测设备与 iBeacon 的距离。
// Monitoring成功对应回调函数
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(nonnull CLRegion *)region {
    NSLog(@"Monitoring成功");
}

// Monitoring有错误产生时的回调
- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(nullable CLRegion *)region withError:(nonnull NSError *)error {
    NSLog(@"Failed monitoring region: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location manager failed: %@", error);
}

// 设备退出该区域时的回调
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"设备出了你的范围了");
}

// 设备进入该区域时的回调
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSLog(@"设备进入你的范围了");
    NSLog(@"*******enter region:%@",region.identifier);
    if(region)[self sendLocalNotificationTitle:@"mesh唤醒中" msg:@"查看详情"];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    //在应用在前台也展示通知
    completionHandler(UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {
    completionHandler();
}

#pragma mark -- Ranging：可以用来检测某区域内的所有 iBeacons
//manager监测当前进入范围的beacon
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if (self.beaconArray.count) {
        [self.beaconArray removeAllObjects];
    }
    
    for (CLBeacon *beacon in beacons) {
        if (beacon.proximity != CLProximityUnknown) {
            [self.beaconArray addObject:beacon];
        }
    }
    [self.tableView reloadData];
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(nonnull CLBeaconRegion *)region withError:(nonnull NSError *)error {
    
}
#pragma mark - UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.beaconArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CLBeacon *beacon = [self.beaconArray objectAtIndex:indexPath.row];
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    cell.textLabel.text = [NSString stringWithFormat:@"%@",beacon.proximityUUID];
    cell.textLabel.font = [UIFont systemFontOfSize:12.0f];
  
    NSString *str;
    switch (beacon.proximity) {
        case CLProximityNear:
            str = @"近";
            break;
            
        case CLProximityImmediate:
            str = @"超近";
            break;
            
        case CLProximityFar:
            str = @"远";
            break;
            
        case CLProximityUnknown:
            str = @"不见了";
            break;
            
            
        default:
            break;
    }
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"距离:%.2fm  %@  major:%@  minor:%@ RSSI:%ld ",beacon.accuracy,str,beacon.major,beacon.minor,(long)beacon.rssi];
    return cell;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Init
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 20 - 100)];
        _tableView.dataSource = self;
        _tableView.delegate = self;
    }
    return _tableView;
}
- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        //设置期望精确度
        _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (CLBeaconRegion *)beaconRegion {
    if (!_beaconRegion) {
        _beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:Beacon_Device_UUID] identifier:@"0000"];
        _beaconRegion.notifyEntryStateOnDisplay = YES;
    }
    return _beaconRegion;
}

@end
