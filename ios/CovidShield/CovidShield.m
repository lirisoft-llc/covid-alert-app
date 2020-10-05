//
//  CovidShield.m
//  CovidShield
//
//  Created by Sergey Gavrilyuk on 2020-05-15.
//

#import "CovidShield.h"
#import <React/RCTConvert.h>
#import "CovidShield-Swift.h"

@implementation CovidShield
RCT_EXPORT_MODULE();

RCT_REMAP_METHOD(getRandomBytes, randomBytesWithSize:(NSUInteger)size withResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
  int status = errSecSuccess;
  void *buff = malloc(size);
  
  if (buff && ((status = SecRandomCopyBytes(kSecRandomDefault, size, buff)) == errSecSuccess)) {
    NSString *base64encoded = [[[NSData alloc] initWithBytes:buff length:size] base64EncodedStringWithOptions:0];
    resolve(base64encoded);
  } else {
    NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
    reject([NSString stringWithFormat:@"%ld", (long)error.code], error.localizedDescription ,error);
  }
  if(buff) free(buff);
}

RCT_REMAP_METHOD(downloadDiagnosisKeysFile, downloadDiagnosisKeysFileWithURL:(NSString *)url WithResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
//  NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
//  NSURL *taskURL = [RCTConvert NSURL:url];
//  [[session downloadTaskWithURL:taskURL
//              completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//    if (error) {
//      reject([NSString stringWithFormat:@"%ld", (long)error.code], error.localizedDescription ,error);
//      return;
//    }
//    if ([(NSHTTPURLResponse *)response statusCode] != 200) {
//      reject([NSString stringWithFormat:@"%ld", (long)[(NSHTTPURLResponse *)response statusCode]],
//             [NSString stringWithContentsOfURL:location encoding:NSUTF8StringEncoding error:nil], nil);
//      return;
//    }
//    NSURL *temporaryDirectoryURL = [NSURL fileURLWithPath: NSTemporaryDirectory() isDirectory: YES];
//
//    NSURL* destination = [temporaryDirectoryURL URLByAppendingPathComponent: [NSString stringWithFormat:@"%@.zip", [[NSUUID UUID] UUIDString]]];
//
//    [[NSFileManager defaultManager] copyItemAtURL:location toURL:destination error:nil];
//    resolve(destination.path);
//  }] resume];
  
  KeyDownloadManager *manager = KeyDownloadManager.shared;
  [manager downloadKeysWithCompletion:^(NSArray<NSString *> * _Nullable url, NSError * _Nullable error) {
    if (error != nil) {
      reject([NSString stringWithFormat:@"Error downloading keys: %@", error.description], @"", nil);
      return;
    }
    resolve(url);
  }];
}

@end
