import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firechat_kit/firechat_kit.dart';

void main() {
  const MethodChannel channel = MethodChannel('firechat_kit');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await FirechatKit.platformVersion, '42');
  });
}
