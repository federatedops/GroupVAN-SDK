import 'platform_interface.dart';
import 'platform_stub.dart'
    if (dart.library.js_interop) 'platform_web.dart'
    if (dart.library.io) 'platform_io.dart' as impl;

export 'platform_interface.dart';

/// The active platform implementation, selected at compile time.
final GroupVanPlatform platform = impl.createPlatform();
