//
//  MainPresenter.m
//  MMLanScanDemo
//
//  Created by Michael Mavris on 04/11/2016.
//  Copyright © 2016 Miksoft. All rights reserved.
//

#import "MainPresenter.h"
#import "LANProperties.h"
#import "MMLANScanner.h"
#import "MMDevice.h"

//#import "React/RCTAlertManager.h"
#import "React/RCTLog.h"

@interface MainPresenter()<MMLANScannerDelegate>

@property (nonatomic,weak)id <MainPresenterDelegate> delegate;
@property(nonatomic,strong)MMLANScanner *lanScanner;
@property(nonatomic,assign,readwrite)BOOL isScanRunning;
@property(nonatomic,assign,readwrite)float progressValue;
@end

@implementation MainPresenter {
    NSMutableArray *connectedDevicesMutable;
}

/******
BEGIN REACT STUFF
******/

RCT_EXPORT_MODULE(MyLanScan);
  
RCT_EXPORT_METHOD(setup) {
  //self = [super init];
  RCTLogInfo(@"\n\nSetting up MMLanScan...\n\n");
  printf("\n\nSetting up MMLanScan...\n\n");
  if (self) {
    
    self.isScanRunning=NO;
    
    //self.delegate=delegate;
    
    self.lanScanner = [[MMLANScanner alloc] initWithDelegate:self];
    //self.lanScanner = [[MMLANScanner alloc] initWithBridge:bridge];
  }
}
  
RCT_EXPORT_METHOD(startScan:(RCTResponseSenderBlock)callback) {
  if (!self.isScanRunning) {
    printf("\n\nRegular log: Starting MMLanScan...\n\n");
    RCTLogInfo(@"\n\nRCT log: Starting MMLanScan...");
    [self startNetworkScan:callback];
  }
}
  
RCT_EXPORT_METHOD(stopScan) {
  if (self.isScanRunning) {
    printf("\n\nRegular log: Stopping MMLanScan...\n\n");
    RCTLogInfo(@"\n\nRCT log: Stopping MMLanScan...\n\n");
    [self stopNetworkScan];
  }
}
  
/******
END REACT STUFF
******/
  
#pragma mark - Init method
//Initialization with delegate
-(instancetype)initWithDelegate:(id <MainPresenterDelegate>)delegate {

    self = [super init];
    
    if (self) {
        
        self.isScanRunning=NO;
       
        self.delegate=delegate;
        
        self.lanScanner = [[MMLANScanner alloc] initWithDelegate:self];
    }
    
    return self;
}

#pragma mark - Button Actions
//This method is responsible for handling the tap button action on MainVC. In case the scan is running and the button is tapped it will stop the scan
  
-(void)scanButtonClicked {
    
    //Checks if is already scanning
    if (self.isScanRunning) {
        
        [self stopNetworkScan];
    }
    else {
        // Commented out b/c I needed to add an arg to startNetworkScan
        //[self startNetworkScan];
    }
}
  
-(void)startNetworkScan:(RCTResponseSenderBlock)callback {
    self.isScanRunning=YES;
    
    connectedDevicesMutable = [[NSMutableArray alloc] init];
    
  [self.lanScanner start:callback];
};
   

-(void)stopNetworkScan {
    
    [self.lanScanner stop];
    
    self.isScanRunning=NO;
}

#pragma mark - SSID
//Getting the SSID string using LANProperties
-(NSString*)ssidName {

    return [NSString stringWithFormat:@"SSID: %@",[LANProperties fetchSSIDInfo]];
};

#pragma mark - MMLANScannerDelegate methods
//The delegate methods of MMLANScanner
-(void)lanScanDidFindNewDevice:(MMDevice*)device{
    
    //Check if the Device is already added
    if (![connectedDevicesMutable containsObject:device]) {

        [connectedDevicesMutable addObject:device];
    }
    
    NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"ipAddress" ascending:YES];
    
    //Updating the array that holds the data. MainVC will be notified by KVO
    self.connectedDevices = [connectedDevicesMutable sortedArrayUsingDescriptors:@[valueDescriptor]];
}

-(void)lanScanDidFinishScanningWithStatus:(MMLanScannerStatus)status cbPass:(RCTResponseSenderBlock)callbackToJS{
   
    self.isScanRunning=NO;
    //Checks the status of finished. Then call the appropriate method
    if (status == MMLanScannerStatusFinished) {
        
        [self.delegate mainPresenterIPSearchFinished];
      
        /*
        for(MMDevice *device in connectedDevicesMutable) {
            printf("IP: %s, MAC: %s, Host: %s, Subnet: %s, Brand: %s\n", [device.ipAddress UTF8String],[device.macAddress UTF8String],[device.hostname UTF8String],[device.subnetMask UTF8String],[device.brand UTF8String]);
        }
        printf("Done. %lu\n", connectedDevicesMutable.count);
        */
    }
    else if (status==MMLanScannerStatusCancelled) {
       
        [self.delegate mainPresenterIPSearchCancelled];
    }
  // Create JSON style string array of devices to return to JS
  NSMutableArray *stringArray = [[NSMutableArray alloc] init];
  for(MMDevice *device in connectedDevicesMutable) {
    NSString *temp = device.description;
    [stringArray addObject:temp];
  }
  callbackToJS(@[[NSNull null], stringArray]);
}

-(void)lanScanProgressPinged:(float)pingedHosts from:(NSInteger)overallHosts {
    
    //Updating the progress value. MainVC will be notified by KVO
    self.progressValue=pingedHosts/overallHosts;
}

-(void)lanScanDidFailedToScan {
   
    self.isScanRunning=NO;

    [self.delegate mainPresenterIPSearchFailed];
}

@end
