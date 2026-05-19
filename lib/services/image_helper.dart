// Conditional export: uses web implementation on web, native on all other platforms
export 'image_helper_native.dart'
    if (dart.library.html) 'image_helper_web.dart';
