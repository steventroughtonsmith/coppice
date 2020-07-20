//
//  GetMetadataForFile.m
//  CoppiceSpotlight
//
//  Created by Martin Pilkington on 20/07/2020.
//Copyright © 2020 M Cubed Software. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>
#import "CoppiceSpotlight-Swift.h"

Boolean GetMetadataForFile(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile);

//==============================================================================
//
//  Get metadata attributes from document files
//
//  The purpose of this function is to extract useful information from the
//  file formats for your document, and set the values into the attribute
//  dictionary for Spotlight to include.
//
//==============================================================================

Boolean GetMetadataForFile(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile)
{
    Boolean ok = FALSE;
    @autoreleasepool {
        ok = [FileImporter importFileAt:(__bridge NSString *)pathToFile attributes:(__bridge  NSMutableDictionary *)attributes];
    }
    
    // Return the status
    return ok;
}
