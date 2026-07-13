import 'web_favicon_updater_stub.dart'
    if (dart.library.html) 'web_favicon_updater_web.dart';

void updateWebFavicon(String faviconUrl) => updateWebFaviconImpl(faviconUrl);
