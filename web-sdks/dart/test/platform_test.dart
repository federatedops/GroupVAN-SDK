import 'package:flutter_test/flutter_test.dart';
import 'package:groupvan/src/platform/platform.dart';

void main() {
  // These tests run on the Dart VM, exercising the dart.library.io branch —
  // the same one iOS/Android builds compile.
  group('io platform', () {
    test('has no page origin or URL', () {
      expect(platform.origin, isNull);
      expect(platform.currentUrl, isNull);
    });

    test('redirect is unsupported', () {
      expect(
        () => platform.redirect('https://example.com'),
        throwsUnsupportedError,
      );
    });
  });
}
