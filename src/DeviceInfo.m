#import "DeviceInfo.h"
#import "MobileGestalt.h"

#import <mach-o/arch.h>
#import <sys/sysctl.h>

#import <sys/utsname.h>
#import <sys/types.h>

@implementation DeviceInfo {
    struct utsname _systemInfo;
    NSString *_model;
}

+ (instancetype)sharedDevice {
    static DeviceInfo *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DeviceInfo alloc] init];
        [sharedInstance initCpuArchitecture];
        [sharedInstance initCpuSubArchitecture];
        uname(&(sharedInstance->_systemInfo));
        [sharedInstance initModel];
    });
    return sharedInstance;
}

- (void)exitWithError:(NSError *)error andMessage:(NSString *)message {
    NSLog(@"[Firmware] %@", message);
    if (error) {
        NSLog(@"[Firmware] Error: %@", error);
    }
    exit(1);
}

- (void)initCpuArchitecture {
    cpu_type_t type;
    size_t size = sizeof(type);

    NXArchInfo const *ai;
    char *cpu = NULL;
    if (sysctlbyname("hw.cputype", &type, &size, NULL, 0) == 0 && (ai = NXGetArchInfoFromCpuType(type, CPU_SUBTYPE_MULTIPLE)) != NULL) {
        cpu = (char *)ai->name;
    } else {
        [self exitWithError:nil andMessage:@"Error getting cpu architecture"];
    }

    self->_cpuArchitecture = [NSString stringWithCString:cpu encoding:NSUTF8StringEncoding];

    NXFreeArchInfo(ai);
}

- (void)initCpuSubArchitecture {
    cpu_subtype_t subtype;
    size_t size = sizeof(subtype);

    NSString *cpu;
    if (sysctlbyname("hw.cpusubtype", &subtype, &size, NULL, 0) == 0) {
        switch (subtype) {
            case CPU_SUBTYPE_ARM_V6:
                cpu = @"armv6";
                break;
            case CPU_SUBTYPE_ARM_V7:
                cpu = @"armv7";
                break;
            case CPU_SUBTYPE_ARM_V7S:
                cpu = @"armv7s";
                break;
            case CPU_SUBTYPE_ARM_V7K:
                cpu = @"armv7k";
                break;
            case CPU_SUBTYPE_ARM64_ALL:
                cpu = @"arm64";
                break;
            case CPU_SUBTYPE_ARM64_V8:
                cpu = @"arm64v8";
                break;
            case CPU_SUBTYPE_ARM64E:
                cpu = @"arm64e";
                break;
            case CPU_SUBTYPE_X86_64_ALL:
                cpu = @"x86_64";
                break;
            default:
                cpu = @"Unknown";
        }
    } else {
        [self exitWithError:nil andMessage:@"Error getting cpu sub-architecture"];
    }

    self->_cpuSubArchitecture = cpu;
}

- (void)initModel {
#if (TARGET_OS_IPHONE)
        self->_model = [NSString stringWithCString:self->_systemInfo.machine encoding:NSUTF8StringEncoding];
#else
        size_t size;
        char *model;

        sysctlbyname("hw.model", NULL, &size, NULL, 0);
        model = malloc(size);
        sysctlbyname("hw.model", model, &size, NULL, 0);

        self->_model = [NSString stringWithCString:model encoding:NSUTF8StringEncoding];
        free(model);
#endif
}

- (NSRegularExpression *)regexWithPattern:(NSString *)pattern {
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];

    if (!regex) {
        [self exitWithError:error andMessage:[NSString stringWithFormat:@"Error parsing regex: '%@'", pattern]];
    }

    return regex;
}

- (NSString *)getOperatingSystemVersion {
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSString *versionString;
    if (version.patchVersion != 0) {
        versionString = [NSString stringWithFormat:@"%d.%d.%d", (int)version.majorVersion, (int)version.minorVersion, (int)version.patchVersion];
    } else {
        versionString = [NSString stringWithFormat:@"%d.%d", (int)version.majorVersion, (int)version.minorVersion];
    }
    return versionString;
}

- (NSString *)getModelName {
    NSRegularExpression *nameRegex = [self regexWithPattern:@"([A-Za-z]+)"];

    NSRange match = [nameRegex firstMatchInString:self->_model options:0 range:NSMakeRange(0, self->_model.length)].range;

    return [[self->_model substringWithRange:match] lowercaseString];
}

- (NSString *)getModelVersion {
    NSRegularExpression *versionRegex = [self regexWithPattern:@"([0-9]+,[0-9]+)"];

    NSRange match = [versionRegex firstMatchInString:self->_model options:0 range:NSMakeRange(0, self->_model.length)].range;

    return [[self->_model substringWithRange:match] stringByReplacingOccurrencesOfString:@"," withString:@"."];
}

- (NSString *)getOperatingSystem {
#if (TARGET_OS_IOS)
    return @"iphoneos";
#elif (TARGET_OS_TV)
    return @"appletvos";
#elif (TARGET_OS_WATCH)
    return @"watchos";
#elif (TARGET_OS_OSX) 
    return @"macos";
#else
    return @"unknown";
#endif
}

- (NSString *)getDPKGDataDirectory {
    return [NSString stringWithFormat:@"/%@/var/lib/dpkg", PREFIX];
}

- (NSDictionary *)getCapabilities {
    NSRegularExpression *numberRegex = [self regexWithPattern:@"^[0-9]+$"];
    NSRegularExpression *uppercaseRegex = [self regexWithPattern:@"([A-Z])"];

    NSDictionary *gestaltAnswers = [[MobileGestalt new] gestaltAnswers];
    NSMutableDictionary *capabilities = [NSMutableDictionary dictionaryWithCapacity:gestaltAnswers.count];
    NSString *zero = @"0";
    NSString *prefixString = @"-";
    NSString *template = @"-$1";

    for (NSString *name in gestaltAnswers) {
        NSString *value = [gestaltAnswers valueForKey:name];

        if (![value isEqualToString:zero]
            && [numberRegex firstMatchInString:value options:0 range:NSMakeRange(0, value.length)]) {

            NSString *modifiedName = [[uppercaseRegex stringByReplacingMatchesInString:name
                                                                                options:0
                                                                                range:NSMakeRange(0, name.length)
                                                                            withTemplate:template]
                                        lowercaseString];

            if ([modifiedName hasPrefix:prefixString]) {
                [capabilities setObject:value forKey:[modifiedName substringFromIndex:1]];
            } else {
                [capabilities setObject:value forKey:modifiedName];
            }
        }
    }

    return capabilities;
}

- (NSString *)getCoreFoundationVersion {
    return [NSString stringWithFormat:@"%.2f", kCFCoreFoundationVersionNumber];
}

- (NSString *)getOperatingSystemType {
    return [[NSString stringWithCString:self->_systemInfo.sysname encoding:NSUTF8StringEncoding] lowercaseString];
}

- (NSString *)getOperatingSystemRelease {
    return [NSString stringWithCString:self->_systemInfo.release encoding:NSUTF8StringEncoding];
}

@end
