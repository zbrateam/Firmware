#import <Foundation/Foundation.h>

#ifndef MAINTAINER
    #define MAINTAINER @"Steve Jobs <steve@apple.com>"
#endif

#ifdef DEBUG
    #define DEBUGLOG(str, ...) do { \
        NSLog(@str, ##__VA_ARGS__); \
    } while(0)
#else
    #define DEBUGLOG(str, ...)
#endif

@interface Firmware : NSObject

- (void)exitWithError:(NSError *)error andMessage:(NSString *)message;
- (void)loadInstalledPackages;
- (void)generatePackage:(NSString *)package forVersion:(NSString *)version withDescription:(NSString *)description;
- (void)generatePackage:(NSString *)package forVersion:(NSString *)version withDescription:(NSString *)description andName:(NSString *)name;
- (void)generateCapabilityPackages;
- (void)writePackagesToStatusFile;
- (void)setupUserSymbolicLink;

@end
