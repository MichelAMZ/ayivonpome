import 'browser_environment_stub.dart'
    if (dart.library.js_interop) 'browser_environment_web.dart'
    as platform;

Map<String, String> readBrowserEnvironment() =>
    platform.readBrowserEnvironment();
