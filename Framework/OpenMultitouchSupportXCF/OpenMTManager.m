//
//  OpenMTManager.m
//  OpenMultitouchSupport
//
//  Created by Takuto Nakamura on 2019/07/11.
//  Copyright © 2019 Takuto Nakamura. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "OpenMTManagerInternal.h"
#import "OpenMTListenerInternal.h"
#import "OpenMTTouchInternal.h"
#import "OpenMTEventInternal.h"
#import "OpenMTInternal.h"

@implementation OpenMTDeviceInfo

- (instancetype)initWithDeviceRef:(MTDeviceRef)deviceRef {
    if (self = [super init]) {
        _deviceRef = deviceRef;
        
        // Get device ID
        uint64_t deviceID;
        OSStatus err = MTDeviceGetDeviceID(deviceRef, &deviceID);
        if (!err) {
            _deviceID = [NSString stringWithFormat:@"%llu", deviceID];
        } else {
            _deviceID = @"Unknown";
        }
        
        // Determine if built-in
        _isBuiltIn = MTDeviceIsBuiltIn ? MTDeviceIsBuiltIn(deviceRef) : YES;
        
        // Get family ID for precise device identification
        int familyID = 0;
        MTDeviceGetFamilyID(deviceRef, &familyID);
        
        // Determine device name based on family ID mapping
        // Reference: https://github.com/JitouchApp/Jitouch-project/blob/3b5018e4bc839426a6ce0917cea6df753d19da10/Application/Gesture.m#L2930
        
        // Normally chaining this many if statements is trolling, but I'm keeping it for documentation purposes
        if (familyID == 98 || familyID == 99 || familyID == 100) {
            // Built-in trackpad (older models)
            _deviceName = @"MacBook Trackpad";
        } else if (familyID == 101) {
            // Retina MacBook Pro trackpad
            _deviceName = @"MacBook Trackpad";
        } else if (familyID == 102) {
            // Retina MacBook with Force Touch trackpad (2015)
            _deviceName = @"MacBook Trackpad";
        } else if (familyID == 103) {
            // Retina MacBook Pro 13" with Force Touch trackpad (2015)
            _deviceName = @"MacBook Trackpad";
        } else if (familyID == 104) {
            // MacBook trackpad variant
            _deviceName = @"MacBook Trackpad";
        } else if (familyID == 105) {
            // MacBook with Touch Bar
            _deviceName = @"Touch Bar";
        } else if (familyID == 109) {
            // M4 Macbook Pro Trackpad
            _deviceName = @"MacBook Trackpad";
        } else if (familyID == 112 || familyID == 113) {
            // Magic Mouse & Magic Mouse 2/3
            _deviceName = @"Magic Mouse";
        } else if (familyID == 128 || familyID == 129 || familyID == 130) {
            // Magic Trackpad, Magic Trackpad 2, Magic Trackpad 3
            _deviceName = @"Magic Trackpad";
        } else {
            // Unknown device - use dimensions to make an educated guess
            int width = 0, height = 0;
            MTDeviceGetSensorSurfaceDimensions(deviceRef, &width, &height);
            
            // Heuristic: trackpads are typically wider than tall and have reasonable dimensions
            // Touch Bar is very wide and narrow (>1000 width, <100 height)
            // Regular trackpads are usually wider than tall but not extremely so
            if (width > 1000 && height < 100) {
                _deviceName = [NSString stringWithFormat:@"Unknown Touch Bar (FamilyID: %d)", familyID];
            } else if (width > height && width > 50 && height > 20) {
                // Likely a trackpad: wider than tall, reasonable dimensions
                _deviceName = [NSString stringWithFormat:@"Unknown Trackpad (FamilyID: %d)", familyID];
            } else {
                // Probably not a trackpad
                _deviceName = [NSString stringWithFormat:@"Unknown Device (FamilyID: %d)", familyID];
            }
        }
    }
    return self;
}

@end

@interface OpenMTManager()

@property (strong, readwrite) NSMutableArray *listeners;
@property (assign, readwrite) MTDeviceRef device;
@property (strong, readwrite) NSArray<OpenMTDeviceInfo *> *availableDeviceInfos;
@property (strong, readwrite) OpenMTDeviceInfo *currentDeviceInfo;

@end

@implementation OpenMTManager

+ (BOOL)systemSupportsMultitouch {
    return MTDeviceIsAvailable();
}

+ (OpenMTManager *)sharedManager {
    static OpenMTManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = self.new;
    });
    return sharedManager;
}

- (instancetype)init {
    if (self = [super init]) {
        self.listeners = NSMutableArray.new;
        [self enumerateDevices];
        
        [NSWorkspace.sharedWorkspace.notificationCenter addObserver:self selector:@selector(willSleep:) name:NSWorkspaceWillSleepNotification object:nil];
        [NSWorkspace.sharedWorkspace.notificationCenter addObserver:self selector:@selector(didWakeUp:) name:NSWorkspaceDidWakeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    // Release all retained device references
    for (OpenMTDeviceInfo *deviceInfo in self.availableDeviceInfos) {
        if (deviceInfo.deviceRef) {
            CFRelease(deviceInfo.deviceRef);
        }
    }
}

- (void)enumerateDevices {
    NSMutableArray<OpenMTDeviceInfo *> *devices = [NSMutableArray array];
    
    if (MTDeviceCreateList) {
        CFArrayRef deviceList = MTDeviceCreateList();
        if (deviceList) {
            CFIndex count = CFArrayGetCount(deviceList);
            for (CFIndex i = 0; i < count; i++) {
                MTDeviceRef deviceRef = (MTDeviceRef)CFArrayGetValueAtIndex(deviceList, i);
                // Retain the device reference since we'll use it later
                CFRetain(deviceRef);
                OpenMTDeviceInfo *deviceInfo = [[OpenMTDeviceInfo alloc] initWithDeviceRef:deviceRef];
                [devices addObject:deviceInfo];
            }
            CFRelease(deviceList);
        }
    }
    
    // Fallback to default device if no devices found
    if (devices.count == 0 && MTDeviceIsAvailable()) {
        MTDeviceRef defaultDevice = MTDeviceCreateDefault();
        if (defaultDevice) {
            OpenMTDeviceInfo *deviceInfo = [[OpenMTDeviceInfo alloc] initWithDeviceRef:defaultDevice];
            [devices addObject:deviceInfo];
            // Don't release defaultDevice here since we store the reference
        }
    }
    
    self.availableDeviceInfos = [devices copy];
    if (devices.count > 0) {
        self.currentDeviceInfo = devices[0];
    }
}

- (void)makeDevice {
    if (self.currentDeviceInfo && self.currentDeviceInfo.deviceRef) {
        // Use the selected device
        self.device = (MTDeviceRef)self.currentDeviceInfo.deviceRef;
        
        uuid_t guid;
        OSStatus err = MTDeviceGetGUID(self.device, &guid);
        if (!err) {
            uuid_string_t val;
            uuid_unparse(guid, val);
            NSLog(@"GUID: %s", val);
        }
        
        int type;
        err = MTDeviceGetDriverType(self.device, &type);
        if (!err) NSLog(@"Driver Type: %d", type);
        
        uint64_t deviceID;
        err = MTDeviceGetDeviceID(self.device, &deviceID);
        if (!err) NSLog(@"DeviceID: %llu", deviceID);
        
        int familyID;
        err = MTDeviceGetFamilyID(self.device, &familyID);
        if (!err) NSLog(@"FamilyID: %d", familyID);
        
        int width, height;
        err = MTDeviceGetSensorSurfaceDimensions(self.device, &width, &height);
        if (!err) NSLog(@"Surface Dimensions: %d x %d ", width, height);
        
        int rows, cols;
        err = MTDeviceGetSensorDimensions(self.device, &rows, &cols);
        if (!err) NSLog(@"Dimensions: %d x %d ", rows, cols);
        
        bool isOpaque = MTDeviceIsOpaqueSurface(self.device);
        NSLog(isOpaque ? @"Opaque: true" : @"Opaque: false");
        
        // MTPrintImageRegionDescriptors(self.device); work
    }
}

//- (void)handlePathEvent:(OpenMTTouch *)touch {
//    NSLog(@"%@", touch.description);
//}

- (void)handleMultitouchEvent:(OpenMTEvent *)event {
    for (int i = 0; i < (int)self.listeners.count; i++) {
        OpenMTListener *listener = self.listeners[i];
        if (listener.dead) {
            [self removeListener:listener];
            continue;
        }
        if (!listener.listening) {
            continue;
        }
        dispatchResponse(^{
            [listener listenToEvent:event];
        });
    }
}

- (void)startHandlingMultitouchEvents {
    [self makeDevice];
    @try {
        MTRegisterContactFrameCallback(self.device, contactEventHandler); // work
        // MTEasyInstallPrintCallbacks(self.device, YES, NO, NO, NO, NO, NO); // work
        // MTRegisterPathCallback(self.device, pathEventHandler); // work
        // MTRegisterMultitouchImageCallback(self.device, MTImagePrintCallback); // not work
        MTDeviceStart(self.device, 0);
    } @catch (NSException *exception) {
        NSLog(@"Failed Start Handling Multitouch Events");
    }
}

- (void)stopHandlingMultitouchEvents {
    if (!MTDeviceIsRunning(self.device)) { return; }
    @try {
        MTUnregisterContactFrameCallback(self.device, contactEventHandler); // work
        // MTUnregisterPathCallback(self.device, pathEventHandler); // work
        // MTUnregisterImageCallback(self.device, MTImagePrintCallback); // not work
        MTDeviceStop(self.device);
        MTDeviceRelease(self.device);
    } @catch (NSException *exception) {
        NSLog(@"Failed Stop Handling Multitouch Events");
    }
}

- (void)willSleep:(NSNotification *)note {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopHandlingMultitouchEvents];
    });
}

- (void)didWakeUp:(NSNotification *)note {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self startHandlingMultitouchEvents];
    });
}

// Public Functions
- (NSArray<OpenMTDeviceInfo *> *)availableDevices {
    return self.availableDeviceInfos;
}

- (BOOL)selectDevice:(OpenMTDeviceInfo *)deviceInfo {
    if (![self.availableDeviceInfos containsObject:deviceInfo]) {
        return NO;
    }
    
    // Stop current device if running
    BOOL wasRunning = self.device && MTDeviceIsRunning(self.device);
    if (wasRunning) {
        [self stopHandlingMultitouchEvents];
    }
    
    // Switch to new device
    self.currentDeviceInfo = deviceInfo;
    
    // Restart if it was running
    if (wasRunning) {
        [self startHandlingMultitouchEvents];
    }
    
    return YES;
}

- (OpenMTDeviceInfo *)currentDevice {
    return self.currentDeviceInfo;
}

- (OpenMTListener *)addListenerWithTarget:(id)target selector:(SEL)selector {
    __block OpenMTListener *listener = nil;
    dispatchSync(dispatch_get_main_queue(), ^{
        if (!self.class.systemSupportsMultitouch) { return; }
        listener = [[OpenMTListener alloc] initWithTarget:target selector:selector];
        if (self.listeners.count == 0) {
            [self startHandlingMultitouchEvents];
        }
        [self.listeners addObject:listener];
    });
    return listener;
}

- (void)removeListener:(OpenMTListener *)listener {
    dispatchSync(dispatch_get_main_queue(), ^{
        [self.listeners removeObject:listener];
        if (self.listeners.count == 0) {
            [self stopHandlingMultitouchEvents];
        }
    });
}

// Utility Tools C Language
static void dispatchSync(dispatch_queue_t queue, dispatch_block_t block) {
    if (!strcmp(dispatch_queue_get_label(queue), dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL))) {
        block();
        return;
    }
    dispatch_sync(queue, block);
}

static void dispatchResponse(dispatch_block_t block) {
    static dispatch_queue_t responseQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        responseQueue = dispatch_queue_create("com.kyome.openmt", DISPATCH_QUEUE_SERIAL);
    });
    dispatch_sync(responseQueue, block);
}

static void contactEventHandler(MTDeviceRef eventDevice, MTTouch eventTouches[], int numTouches, double timestamp, int frame) {
    NSMutableArray *touches = [NSMutableArray array];
    
    for (int i = 0; i < numTouches; i++) {
        OpenMTTouch *touch = [[OpenMTTouch alloc] initWithMTTouch:&eventTouches[i]];
        [touches addObject:touch];
    }
    
    OpenMTEvent *event = OpenMTEvent.new;
    event.touches = touches;
    event.deviceID = *(int *)eventDevice;
    event.frameID = frame;
    event.timestamp = timestamp;
    
    [OpenMTManager.sharedManager handleMultitouchEvent:event];
}

@end
