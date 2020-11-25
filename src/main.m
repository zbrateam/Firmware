#import "Firmware.h"

#include <getopt.h>

#define FIRMWARE_VERSION 6

int main(int argc, char *argv[]) {

    int nocy = 0;
    int nogsc = 0;
    int showhelp = 0;

    struct option longOptions[] = {
        { "nocy", no_argument, 0, 'c' },
        { "nogsc", no_argument, 0, 'g' },
        { "help", no_argument, 0, 'h' },
        { NULL, 0, NULL, 0 }
    };

    int index = 0, opt = 0;

    while ((opt = getopt_long(argc, argv, "cgh", longOptions, &index)) != -1) {
        switch (opt) {
            case 'c':
                nocy = 1;
                break;
            case 'g':
                nogsc = 1;
                break;
            case 'h':
                showhelp = 1;
                break;
         }
    }

    if (showhelp) {
        printf(
            "Usage: %s [OPTION]\n\n"
            "  -c, --nocy   Do not generate the packages starting with cy+\n"
            "  -g, --nogsc  Do not generate the capability packages\n"
            "  -h, --help   Give this help list.\n",
            argv[0]
        );
        return 0;
    }

    NSLog(@"[Firmware] full steam ahead");

    Firmware *firmware = [[Firmware alloc] init];
    [firmware loadInstalledPackages];

    DeviceInfo *device = [DeviceInfo sharedDevice];

    // generate device specific packages

    if (!nogsc)
        [firmware generateCapabilityPackages];


    // generate always needed packages

    NSString *iosVersion = [device getOperatingSystemVersion];

    if (device.ios) {
        [firmware generatePackage:@"firmware" forVersion:iosVersion withDescription:@"almost impressive Apple frameworks" andName:@"iOS Firmware"];
    }

    if (!nocy) {
        NSString *packageName = [@"cy+os." stringByAppendingString:[device getOperatingSystem]];
        [firmware generatePackage:packageName forVersion:iosVersion withDescription:@"virtual operating system dependency"];

        packageName = [@"cy+cpu." stringByAppendingString:device.cpuArchitecture];
        [firmware generatePackage:packageName forVersion:@"0" withDescription:@"virtual CPU dependency"];

        packageName = [@"cy+model." stringByAppendingString:[device getModelName]];
        [firmware generatePackage:packageName forVersion:[device getModelVersion] withDescription:@"virtual model dependency"];

        packageName = [@"cy+kernel." stringByAppendingString:[device getOperatingSystemType]];
        [firmware generatePackage:packageName forVersion:[device getOperatingSystemRelease] withDescription:@"virtual kernel dependency"];

        [firmware generatePackage:@"cy+lib.corefoundation" forVersion:[device getCoreFoundationVersion] withDescription:@"virtual corefoundation dependency"];
    }


    [firmware writePackagesToStatusFile];

    if (device.ios) {
        [firmware setupUserSymbolicLink];

        // write firmware version

        NSError *error;

        NSString *firmwareFile = @"/var/lib/cydia/firmware.ver";
        NSString *firwareVersion = [NSString stringWithFormat:@"%d\n", FIRMWARE_VERSION];

        if (![firwareVersion writeToFile:firmwareFile atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
            [firmware exitWithError:error andMessage:[NSString stringWithFormat:@"Error writing firmware version to %@", firmwareFile]];
        }
    }

    NSLog(@"[Firmware] my work here is done");
    return 0;
}
