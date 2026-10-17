// Browser-only speech and sound playback. On phones these do nothing and the
// native plugins are used instead.
export 'web_media_stub.dart' if (dart.library.js_interop) 'web_media_web.dart';
