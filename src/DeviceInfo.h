#import <Foundation/Foundation.h>

#import <mach-o/arch.h>
#import <sys/sysctl.h>

#import <sys/utsname.h>
#import <sys/types.h>

#ifndef PREFIX
    #define PREFIX @""
#endif

@interface DeviceInfo : NSObject

+ (instancetype)sharedDevice;

@property (readonly) NSString *cpuArchitecture;
@property (readonly) NSString *cpuSubArchitecture;

- (NSString *)getOperatingSystemVersion;    // e.g. 13.3.1
- (NSString *)getModelName;                 // e.g. iPhone7,1   -> iphone
- (NSString *)getModelVersion;              // e.g. iPhone7,1   -> 7.1
- (NSString *)getOperatingSystem;           // *os
- (NSString *)getDPKGDataDirectory;         // /var/lib/dpkg
- (NSDictionary *)getCapabilities;          // filtered mobile gestalt answers to only include capabilites the device actually has
- (NSString *)getCoreFoundationVersion;     // e.g. 1674.11
- (NSString *)getOperatingSystemType;       // e.g. Darwin
- (NSString *)getOperatingSystemRelease;    // e.g. 19.3.0

@end
