import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final doctor = File('bin/doctor.dart').absolute.path;
  // A test runs in flutter_tester, under the SDK's bin/cache: its dart is
  // in its bin.
  final engine = Platform.resolvedExecutable;
  final dart = '${engine.substring(0, engine.indexOf('/bin/cache/'))}/bin/dart';

  /// An app in a folder of its own, with [files] in it.
  Future<ProcessResult> run(Map<String, String> files) async {
    final app = await Directory.systemTemp.createTemp('iphone_duo_doctor');
    addTearDown(() => app.delete(recursive: true));
    for (final MapEntry(key: path, value: text) in files.entries) {
      final file = File('${app.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsString(text);
    }
    return Process.run(
      dart,
      [doctor],
      workingDirectory: app.path,
    );
  }

  const pubspec = 'name: app\ndependencies:\n  iphone_duo: ^0.6.0\n';
  String plist(List<String> orientations) => '''
<plist><dict>
<key>UISupportedInterfaceOrientations</key>
<array>${orientations.map((o) => '<string>$o</string>').join()}</array>
</dict></plist>''';
  const app = '''
MaterialApp(builder: (context, child) =>
    DuoScope(child: KeyboardAboveFold(child: child!)));
''';

  test('an app set up for the Duo passes', () async {
    final result = await run({
      'pubspec.yaml': pubspec,
      'ios/Runner/Info.plist': plist([
        'UIInterfaceOrientationPortrait',
        'UIInterfaceOrientationLandscapeLeft',
        'UIInterfaceOrientationLandscapeRight',
      ]),
      'lib/app.dart': app,
    });
    expect(result.stdout, isNot(contains('✗')));
    expect(result.exitCode, 0);
  });

  test('an iPhone kept upright, and no DuoScope, fail', () async {
    final result = await run({
      'pubspec.yaml': pubspec,
      'ios/Runner/Info.plist': plist(['UIInterfaceOrientationPortrait']),
      'lib/app.dart': 'MaterialApp();',
    });
    expect(result.stdout, contains('keeps the iPhone upright'));
    expect(result.stdout, contains('No DuoScope'));
    expect(result.exitCode, 1);
  });
}
