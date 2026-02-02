#import "FaceRegistry.h"

static NSMutableDictionary<NSString *, NSData *> *registry;

@implementation FaceRegistry

+ (void)initialize {
  if (!registry) registry = [NSMutableDictionary dictionary];
}

+ (NSString *)filePath {
  NSString *dir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
  return [dir stringByAppendingPathComponent:@"ArcFaceRegistryV1.json"];
}

+ (void)load {
  NSData *data = [NSData dataWithContentsOfFile:[self filePath]];
  if (!data) return;

  NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
  NSDictionary *items = json[@"items"];
  [registry removeAllObjects];

  [items enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *b64, BOOL *stop) {
    NSData *d = [[NSData alloc] initWithBase64EncodedString:b64 options:0];
    if (d) registry[key] = d;
  }];
}

+ (void)persist {
  NSMutableDictionary *items = [NSMutableDictionary dictionary];
  for (NSString *key in registry) {
    items[key] = [registry[key] base64EncodedStringWithOptions:0];
  }

  NSDictionary *root = @{@"version": @1, @"items": items};
  NSData *data = [NSJSONSerialization dataWithJSONObject:root options:0 error:nil];
  [data writeToFile:[self filePath] atomically:YES];
}

+ (void)upsert:(NSString *)userId feature:(NSData *)feature {
  registry[userId] = feature;
  [self persist];
}

+ (NSData *)featureForUser:(NSString *)userId {
  return registry[userId];
}

@end
