#import "ABI23_0_0RCTInspectorDevServerHelper.h"

#if ABI23_0_0RCT_DEV

#import <ABI23_0_0jschelpers/ABI23_0_0JSCWrapper.h>
#import <UIKit/UIKit.h>

#import "ABI23_0_0RCTDefines.h"
#import "ABI23_0_0RCTInspectorPackagerConnection.h"

using namespace facebook::ReactABI23_0_0;

static NSString *const kDebuggerMsgDisable = @"{ \"id\":1,\"method\":\"Debugger.disable\" }";

static NSString *getDebugServerHost(NSURL *bundleURL)
{
  NSString *host = [bundleURL host];
  if (!host) {
    host = @"localhost";
  }

  // Inspector Proxy is run on a separate port (from packager).
  NSNumber *port = @8082;

  // this is consistent with the Android implementation, where http:// is the
  // hardcoded implicit scheme for the debug server. Note, packagerURL
  // technically looks like it could handle schemes/protocols other than HTTP,
  // so rather than force HTTP, leave it be for now, in case someone is relying
  // on that ability when developing against iOS.
  return [NSString stringWithFormat:@"%@:%@", host, port];
}

static NSURL *getInspectorDeviceUrl(NSURL *bundleURL)
{
  NSString *escapedDeviceName = [[[UIDevice currentDevice] name] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  NSString *escapedAppName = [[[NSBundle mainBundle] bundleIdentifier] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/inspector/device?name=%@&app=%@",
                                                        getDebugServerHost(bundleURL),
                                                        escapedDeviceName,
                                                        escapedAppName]];
}


@implementation ABI23_0_0RCTInspectorDevServerHelper

ABI23_0_0RCT_NOT_IMPLEMENTED(- (instancetype)init)

static NSMutableDictionary<NSString *, ABI23_0_0RCTInspectorPackagerConnection *> *socketConnections = nil;

static void sendEventToAllConnections(NSString *event)
{
  for (NSString *socketId in socketConnections) {
    [socketConnections[socketId] sendEventToAllConnections:event];
  }
}

+ (void)disableDebugger
{
  sendEventToAllConnections(kDebuggerMsgDisable);
}

+ (void)connectForContext:(JSGlobalContextRef)context
            withBundleURL:(NSURL *)bundleURL
{
  if (!isCustomJSCPtr(context)) {
    return;
  }

  NSURL *inspectorURL = getInspectorDeviceUrl(bundleURL);

  // Note, using a static dictionary isn't really the greatest design, but
  // the packager connection does the same thing, so it's at least consistent.
  // This is a static map that holds different inspector clients per the inspectorURL
  if (socketConnections == nil) {
    socketConnections = [NSMutableDictionary new];
  }

  NSString *key = [inspectorURL absoluteString];
  ABI23_0_0RCTInspectorPackagerConnection *connection = socketConnections[key];
  if (!connection) {
    connection = [[ABI23_0_0RCTInspectorPackagerConnection alloc] initWithURL:inspectorURL];
    socketConnections[key] = connection;
    [connection connect];
  }
}

@end

#endif
