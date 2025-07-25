//
//  OpenMTManager.h
//  OpenMultitouchSupport
//
//  Created by Takuto Nakamura on 2019/07/11.
//  Copyright © 2019 Takuto Nakamura. All rights reserved.
//

#ifndef OpenMTManager_h
#define OpenMTManager_h

#import <Foundation/Foundation.h>
#import <OpenMultitouchSupportXCF/OpenMTListener.h>
#import <OpenMultitouchSupportXCF/OpenMTEvent.h>

@interface OpenMTDeviceInfo: NSObject
@property (nonatomic, readonly) NSString *deviceName;
@property (nonatomic, readonly) NSString *deviceID;
@property (nonatomic, readonly) BOOL isBuiltIn;
@end

@interface OpenMTManager: NSObject

+ (BOOL)systemSupportsMultitouch;
+ (OpenMTManager *)sharedManager;

- (NSArray<OpenMTDeviceInfo *> *)availableDevices;
- (BOOL)selectDevice:(OpenMTDeviceInfo *)deviceInfo;
- (OpenMTDeviceInfo *)currentDevice;

- (OpenMTListener *)addListenerWithTarget:(id)target selector:(SEL)selector;
- (void)removeListener:(OpenMTListener *)listener;

- (BOOL)isHapticEnabled;
- (BOOL)setHapticEnabled:(BOOL)enabled;

@end

#endif /* OpenMTManager_h */
