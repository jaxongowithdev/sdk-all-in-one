#import "AllInOneSdkPlugin.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FirebaseAnalytics/FirebaseAnalytics.h>
#import <FirebaseCore/FirebaseCore.h>
#import <TikTokBusinessSDK/TikTokBusiness.h>
#import <TikTokBusinessSDK/TikTokBaseEvent.h>
#import <UIKit/UIKit.h>

static NSString *const kAllInOneFirebaseConfigKey =
    @"all_in_one_sdk_cached_firebase_config";
static NSString *const kAllInOneFacebookConfigKey =
    @"all_in_one_sdk_cached_facebook_config";
static NSString *const kAllInOneTikTokConfigKey =
    @"all_in_one_sdk_cached_tiktok_config";

// Event auto-sent once TikTok SDK init succeeds (hardcoded). Fires on the
// configure call and on cached auto-init at every app launch.
static NSString *const kAllInOneTikTokAutoEvent = @"LaunchAPP";

@implementation AllInOneSdkPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"all_in_one_sdk"
                                  binaryMessenger:[registrar messenger]];
  AllInOneSdkPlugin *instance = [[AllInOneSdkPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
  [instance bootstrapFromCachedConfig];
}

- (void)bootstrapFromCachedConfig {
  NSDictionary *cachedFirebase = [[NSUserDefaults standardUserDefaults]
      dictionaryForKey:kAllInOneFirebaseConfigKey];
  [self configureFirebaseWithDictionary:cachedFirebase];

  NSDictionary *cachedFacebook = [[NSUserDefaults standardUserDefaults]
      dictionaryForKey:kAllInOneFacebookConfigKey];
  [self configureFacebookWithDictionary:cachedFacebook source:@"cached_config"];

  NSDictionary *cachedTikTok = [[NSUserDefaults standardUserDefaults]
      dictionaryForKey:kAllInOneTikTokConfigKey];
  [self configureTikTokWithDictionary:cachedTikTok];
}

- (void)configureFirebaseWithDictionary:(NSDictionary *)args {
  if (![args isKindOfClass:[NSDictionary class]])
    return;

  NSString *googleAppId = args[@"googleAppId"];
  if (![googleAppId isKindOfClass:[NSString class]] || googleAppId.length == 0) {
    googleAppId = args[@"androidGoogleAppId"];
  }
  NSString *gcmSenderId = args[@"gcmSenderId"];
  NSString *apiKey = args[@"apiKey"];
  NSString *projectId = args[@"projectId"];
  NSString *bundleId = args[@"bundleId"];
  NSString *storageBucket = args[@"storageBucket"];

  if (![googleAppId isKindOfClass:[NSString class]] ||
      googleAppId.length == 0 ||
      ![gcmSenderId isKindOfClass:[NSString class]] ||
      gcmSenderId.length == 0 || ![apiKey isKindOfClass:[NSString class]] ||
      apiKey.length == 0 || ![projectId isKindOfClass:[NSString class]] ||
      projectId.length == 0) {
    NSLog(@"[AllInOneSdk] Firebase: skipped (missing "
          @"googleAppId/gcmSenderId/apiKey/projectId)");
    return;
  }

  id analyticsRaw = args[@"isAnalyticsEnabled"];
  BOOL hasAnalyticsFlag = [analyticsRaw isKindOfClass:[NSNumber class]];
  BOOL analyticsEnabled =
      hasAnalyticsFlag ? [((NSNumber *)analyticsRaw) boolValue] : YES;

  if (![FIRApp defaultApp]) {
    FIROptions *options = [[FIROptions alloc] initWithGoogleAppID:googleAppId
                                                      GCMSenderID:gcmSenderId];
    options.APIKey = apiKey;
    options.projectID = projectId;
    if ([bundleId isKindOfClass:[NSString class]] && bundleId.length > 0) {
      options.bundleID = bundleId;
    } else {
      NSString *hostBundleId = [[NSBundle mainBundle] bundleIdentifier];
      if ([hostBundleId isKindOfClass:[NSString class]] &&
          hostBundleId.length > 0) {
        options.bundleID = hostBundleId;
      }
    }
    if ([storageBucket isKindOfClass:[NSString class]] &&
        storageBucket.length > 0) {
      options.storageBucket = storageBucket;
    }
    [FIRApp configureWithOptions:options];
    NSLog(@"[AllInOneSdk] Firebase Core: FIRApp configured (projectId=%@, "
          @"googleAppId=%@)",
          projectId, googleAppId);
  } else {
    NSLog(@"[AllInOneSdk] Firebase Core: FIRApp already exists, skipped "
          @"configure (projectId=%@)",
          projectId);
  }

  if (hasAnalyticsFlag) {
    [FIRAnalytics setAnalyticsCollectionEnabled:analyticsEnabled];
    NSLog(@"[AllInOneSdk] Firebase Analytics: collectionEnabled=%@",
          analyticsEnabled ? @"YES" : @"NO");
  } else {
    [FIRAnalytics setAnalyticsCollectionEnabled:YES];
    NSLog(@"[AllInOneSdk] Firebase Analytics: collectionEnabled=YES (default)");
  }
}

- (BOOL)configureFacebookWithDictionary:(NSDictionary *)args
                                  source:(NSString *)source {
  if (![args isKindOfClass:[NSDictionary class]])
    return NO;

  NSString *appId = args[@"applicationId"];
  if (![appId isKindOfClass:[NSString class]] || appId.length == 0) {
    NSLog(@"[AllInOneSdk] Facebook SDK: skipped (missing applicationId)");
    return NO;
  }

  FBSDKSettings *settings = [FBSDKSettings sharedSettings];
  settings.appID = appId;
  NSLog(@"[AllInOneSdk] Facebook SDK: configuring (applicationId=%@)", appId);

  NSString *clientToken = args[@"clientToken"];
  if ([clientToken isKindOfClass:[NSString class]] && clientToken.length > 0) {
    settings.clientToken = clientToken;
  }

  NSString *displayName = args[@"displayName"];
  if ([displayName isKindOfClass:[NSString class]] && displayName.length > 0) {
    settings.displayName = displayName;
  }

  id autoLog = args[@"autoLogAppEventsEnabled"];
  if ([autoLog isKindOfClass:[NSNumber class]]) {
    BOOL value = [((NSNumber *)autoLog) boolValue];
    settings.autoLogAppEventsEnabled = value;
    NSLog(@"[AllInOneSdk] Facebook SDK: autoLogAppEventsEnabled=%@",
          value ? @"YES" : @"NO");
  } else {
    NSLog(@"[AllInOneSdk] Facebook SDK: autoLogAppEventsEnabled not set "
          @"(value=%@), left unchanged",
          autoLog ?: @"(nil)");
  }

  id advertiser = args[@"advertiserIdCollectionEnabled"];
  if ([advertiser isKindOfClass:[NSNumber class]]) {
    BOOL value = [((NSNumber *)advertiser) boolValue];
    settings.advertiserIDCollectionEnabled = value;
    NSLog(@"[AllInOneSdk] Facebook SDK: advertiserIDCollectionEnabled=%@",
          value ? @"YES" : @"NO");
  } else {
    NSLog(@"[AllInOneSdk] Facebook SDK: advertiserIdCollectionEnabled not set "
          @"(value=%@), left unchanged",
          advertiser ?: @"(nil)");
  }

  @try {
    NSDictionary *probeParameters = @{ @"source" : source ?: @"unknown" };
    [[FBSDKAppEvents shared] logEvent:@"all_in_one_sdk_ready"
                           parameters:probeParameters];
    [[FBSDKAppEvents shared] flush];
    NSLog(@"[AllInOneSdk] Facebook App Event: queued and flushed "
          @"(event=all_in_one_sdk_ready)");
  } @catch (NSException *exception) {
    NSLog(@"[AllInOneSdk] Facebook SDK: ready event could not be queued: %@",
          exception);
    return NO;
  }

  NSLog(@"[AllInOneSdk] Facebook SDK: settings applied (clientTokenSet=%@, "
        @"displayNameSet=%@)",
        (settings.clientToken.length > 0) ? @"YES" : @"NO",
        (settings.displayName.length > 0) ? @"YES" : @"NO");
  return YES;
}

- (void)trackFacebookEvent:(NSString *)eventName
                parameters:(NSDictionary *)parameters {
  if (![eventName isKindOfClass:[NSString class]] || eventName.length == 0) {
    @throw [NSException exceptionWithName:@"AllInOneSdkBadEvent"
                                   reason:@"eventName is required"
                                 userInfo:nil];
  }

  NSMutableDictionary *safeParameters = [NSMutableDictionary dictionary];
  if ([parameters isKindOfClass:[NSDictionary class]]) {
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
      if ([key isKindOfClass:[NSString class]] &&
          ([value isKindOfClass:[NSString class]] ||
           [value isKindOfClass:[NSNumber class]])) {
        safeParameters[key] = value;
      }
    }];
  }
  [[FBSDKAppEvents shared] logEvent:eventName parameters:safeParameters];
  [[FBSDKAppEvents shared] flush];
  NSLog(@"[AllInOneSdk] Facebook App Event: queued and flushed (event=%@)",
        eventName);
}

- (void)configureTikTokWithDictionary:(NSDictionary *)args {
  if (![args isKindOfClass:[NSDictionary class]])
    return;

  NSString *appId = args[@"appId"];
  NSString *tiktokAppId = args[@"tiktokAppId"];
  if (![appId isKindOfClass:[NSString class]] || appId.length == 0 ||
      ![tiktokAppId isKindOfClass:[NSString class]] ||
      tiktokAppId.length == 0) {
    NSLog(@"[AllInOneSdk] TikTok SDK: skipped (missing appId/tiktokAppId)");
    return;
  }

  if ([TikTokBusiness isInitialized]) {
    NSLog(@"[AllInOneSdk] TikTok SDK: already initialized, skipped");
    return;
  }

  NSString *accessToken = args[@"accessToken"];
  TikTokConfig *config = nil;
  if ([accessToken isKindOfClass:[NSString class]] && accessToken.length > 0) {
    config = [TikTokConfig configWithAccessToken:accessToken
                                           appId:appId
                                     tiktokAppId:tiktokAppId];
  } else {
    // Fallback to the deprecated initializer when no access token is supplied.
    config = [[TikTokConfig alloc] initWithAppId:appId tiktokAppId:tiktokAppId];
    NSLog(@"[AllInOneSdk] TikTok SDK: no accessToken, using deprecated init");
  }

  if (config == nil) {
    NSLog(@"[AllInOneSdk] TikTok SDK: config creation failed (check "
          @"appId/tiktokAppId match)");
    return;
  }

  id debugMode = args[@"debugModeEnabled"];
  if ([debugMode isKindOfClass:[NSNumber class]] &&
      [((NSNumber *)debugMode) boolValue]) {
    [config enableDebugMode];
    NSLog(@"[AllInOneSdk] TikTok SDK: debugMode ON");
  }

  id autoTracking = args[@"autoTrackingEnabled"];
  if ([autoTracking isKindOfClass:[NSNumber class]] &&
      ![((NSNumber *)autoTracking) boolValue]) {
    [config disableAutomaticTracking];
    NSLog(@"[AllInOneSdk] TikTok SDK: automatic tracking disabled");
  }

  id tracking = args[@"trackingEnabled"];
  if ([tracking isKindOfClass:[NSNumber class]] &&
      ![((NSNumber *)tracking) boolValue]) {
    [config disableTracking];
    NSLog(@"[AllInOneSdk] TikTok SDK: tracking disabled");
  }

  NSLog(@"[AllInOneSdk] TikTok SDK: initializing (appId=%@, tiktokAppId=%@, "
        @"accessTokenSet=%@)",
        appId, tiktokAppId,
        ([accessToken isKindOfClass:[NSString class]] && accessToken.length > 0)
            ? @"YES"
            : @"NO");
  [TikTokBusiness
          initializeSdk:config
      completionHandler:^(BOOL success, NSError *_Nullable error) {
        if (success) {
          NSLog(@"[AllInOneSdk] TikTok SDK: initialize SUCCESS");
          // Auto-fire one hardcoded event right after init.
          TikTokBaseEvent *autoEvent =
              [[TikTokBaseEvent alloc] initWithEventName:kAllInOneTikTokAutoEvent];
          [TikTokBusiness trackTTEvent:autoEvent];
          NSLog(@"[AllInOneSdk] TikTok SDK: auto event sent (%@)",
                kAllInOneTikTokAutoEvent);
        } else {
          NSLog(@"[AllInOneSdk] TikTok SDK: initialize FAILED: %@", error);
        }
      }];
}

- (void)handleMethodCall:(FlutterMethodCall *)call
                  result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS "
        stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    return;
  }

  if ([@"configureFacebookSdk" isEqualToString:call.method]) {
    if (![call.arguments isKindOfClass:[NSDictionary class]]) {
      result([FlutterError errorWithCode:@"bad_args"
                                 message:@"configureFacebookSdk expects a map"
                                 details:nil]);
      return;
    }

    NSDictionary *args = (NSDictionary *)call.arguments;
    NSString *appId = args[@"applicationId"];
    if (![appId isKindOfClass:[NSString class]] || appId.length == 0) {
      result([FlutterError errorWithCode:@"bad_app_id"
                                 message:@"applicationId is required"
                                 details:nil]);
      return;
    }
    if (![self configureFacebookWithDictionary:args source:@"api_config"]) {
      result([FlutterError errorWithCode:@"facebook_init_failed"
                                 message:@"Facebook SDK could not initialize or queue its probe event"
                                 details:nil]);
      return;
    }
    [[NSUserDefaults standardUserDefaults]
        setObject:args
           forKey:kAllInOneFacebookConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    result(nil);
    return;
  }

  if ([@"trackFacebookEvent" isEqualToString:call.method]) {
    if (![call.arguments isKindOfClass:[NSDictionary class]]) {
      result([FlutterError errorWithCode:@"bad_args"
                                 message:@"trackFacebookEvent expects a map"
                                 details:nil]);
      return;
    }
    NSDictionary *args = (NSDictionary *)call.arguments;
    NSString *eventName = args[@"eventName"];
    if (![eventName isKindOfClass:[NSString class]] || eventName.length == 0) {
      result([FlutterError errorWithCode:@"bad_args"
                                 message:@"eventName is required"
                                 details:nil]);
      return;
    }
    @try {
      [self trackFacebookEvent:eventName parameters:args[@"parameters"]];
      result(nil);
    } @catch (NSException *exception) {
      NSLog(@"[AllInOneSdk] Facebook trackEvent failed: %@", exception);
      result([FlutterError errorWithCode:@"facebook_event_failed"
                                 message:@"Facebook SDK could not queue the event; call SdkBootstrap.apply first"
                                 details:nil]);
    }
    return;
  }

  if ([@"flushFacebookEvents" isEqualToString:call.method]) {
    @try {
      [[FBSDKAppEvents shared] flush];
      NSLog(@"[AllInOneSdk] Facebook App Events: flush requested");
      result(nil);
    } @catch (NSException *exception) {
      NSLog(@"[AllInOneSdk] Facebook flush failed: %@", exception);
      result([FlutterError errorWithCode:@"facebook_event_failed"
                                 message:@"Facebook SDK could not flush events"
                                 details:nil]);
    }
    return;
  }

  if ([@"configureFirebaseSdk" isEqualToString:call.method]) {
    if (![call.arguments isKindOfClass:[NSDictionary class]]) {
      result([FlutterError errorWithCode:@"bad_args"
                                 message:@"configureFirebaseSdk expects a map"
                                 details:nil]);
      return;
    }
    NSDictionary *args = (NSDictionary *)call.arguments;
    [self configureFirebaseWithDictionary:args];
    [[NSUserDefaults standardUserDefaults]
        setObject:args
           forKey:kAllInOneFirebaseConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    result(nil);
    return;
  }

  if ([@"trackTikTokEvent" isEqualToString:call.method]) {
    if (![call.arguments isKindOfClass:[NSDictionary class]]) {
      result([FlutterError errorWithCode:@"bad_args"
                                 message:@"trackTikTokEvent expects a map"
                                 details:nil]);
      return;
    }
    NSDictionary *args = (NSDictionary *)call.arguments;
    NSString *eventName = args[@"eventName"];
    if (![eventName isKindOfClass:[NSString class]] || eventName.length == 0) {
      result([FlutterError errorWithCode:@"bad_args"
                                 message:@"eventName is required"
                                 details:nil]);
      return;
    }
    if (![TikTokBusiness isInitialized]) {
      NSLog(@"[AllInOneSdk] TikTok trackEvent: skipped (SDK not initialized) "
            @"event=%@",
            eventName);
      result([FlutterError errorWithCode:@"not_initialized"
                                 message:@"TikTok SDK not initialized"
                                 details:nil]);
      return;
    }
    NSString *eventId = args[@"eventId"];
    NSDictionary *properties = args[@"properties"];
    TikTokBaseEvent *event = nil;
    if ([properties isKindOfClass:[NSDictionary class]] && properties.count > 0) {
      event = [[TikTokBaseEvent alloc]
          initWithEventName:eventName
                 properties:properties
                    eventId:([eventId isKindOfClass:[NSString class]] &&
                             eventId.length > 0)
                                ? eventId
                                : nil];
    } else if ([eventId isKindOfClass:[NSString class]] &&
               eventId.length > 0) {
      event = [[TikTokBaseEvent alloc] initWithEventName:eventName
                                                 eventId:eventId];
    } else {
      event = [[TikTokBaseEvent alloc] initWithEventName:eventName];
    }
    [TikTokBusiness trackTTEvent:event];
    NSLog(@"[AllInOneSdk] TikTok trackEvent: %@ (props=%lu)", eventName,
          (unsigned long)(properties.count));
    result(nil);
    return;
  }

  if ([@"flushTikTokEvents" isEqualToString:call.method]) {
    if ([TikTokBusiness isInitialized]) {
      [TikTokBusiness explicitlyFlush];
      NSLog(@"[AllInOneSdk] TikTok: explicitlyFlush called");
    }
    result(nil);
    return;
  }

  if ([@"configureTikTokSdk" isEqualToString:call.method]) {
    if (![call.arguments isKindOfClass:[NSDictionary class]]) {
      result([FlutterError errorWithCode:@"bad_args"
                                 message:@"configureTikTokSdk expects a map"
                                 details:nil]);
      return;
    }
    NSDictionary *args = (NSDictionary *)call.arguments;
    NSString *appId = args[@"appId"];
    NSString *tiktokAppId = args[@"tiktokAppId"];
    if (![appId isKindOfClass:[NSString class]] || appId.length == 0 ||
        ![tiktokAppId isKindOfClass:[NSString class]] ||
        tiktokAppId.length == 0) {
      result([FlutterError errorWithCode:@"bad_args"
                                 message:@"appId and tiktokAppId are required"
                                 details:nil]);
      return;
    }
    [self configureTikTokWithDictionary:args];
    [[NSUserDefaults standardUserDefaults] setObject:args
                                              forKey:kAllInOneTikTokConfigKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    result(nil);
    return;
  }

  result(FlutterMethodNotImplemented);
}

@end
