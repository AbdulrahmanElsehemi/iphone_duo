// Checks an app for what iphone_duo needs, from the app's own folder:
//
//   dart run iphone_duo:doctor
//
// Exits with 1 when something is missing that keeps the package from
// working, 0 otherwise. Reads files only; it changes nothing.
import 'dart:io';

var _failed = false;

void _ok(String message) => stdout.writeln('  ✓ $message');

void _warn(String message, [String? fix]) {
  stdout.writeln('  ! $message');
  if (fix != null) stdout.writeln('    $fix');
}

void _fail(String message, String fix) {
  _failed = true;
  stdout.writeln('  ✗ $message');
  stdout.writeln('    $fix');
}

/// Every Dart file under `lib/`, as one string.
String _dartSource() {
  final lib = Directory('lib');
  if (!lib.existsSync()) return '';
  final buffer = StringBuffer();
  for (final file in lib.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      buffer.writeln(file.readAsStringSync());
    }
  }
  return buffer.toString();
}

/// The strings of [key]'s array in an `Info.plist`.
List<String> _plistArray(String plist, String key) {
  final match = RegExp(
    '<key>${RegExp.escape(key)}</key>\\s*<array>(.*?)</array>',
    dotAll: true,
  ).firstMatch(plist);
  if (match == null) return const [];
  return [
    for (final string in RegExp(
      '<string>(.*?)</string>',
    ).allMatches(match.group(1)!))
      string.group(1)!,
  ];
}

void _checkPubspec() {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    _fail(
      'No pubspec.yaml here.',
      "Run this from the app's own folder.",
    );
    return;
  }
  if (RegExp(r'^\s+iphone_duo:', multiLine: true)
      .hasMatch(pubspec.readAsStringSync())) {
    _ok('iphone_duo is in pubspec.yaml.');
  } else {
    _fail(
      'iphone_duo is not in pubspec.yaml.',
      'flutter pub add iphone_duo',
    );
  }
}

void _checkInfoPlist() {
  final file = File('ios/Runner/Info.plist');
  if (!file.existsSync()) {
    _warn('No ios/Runner/Info.plist: the iOS checks are skipped.');
    return;
  }
  final plist = file.readAsStringSync();
  final phone = _plistArray(plist, 'UISupportedInterfaceOrientations');
  const landscape = [
    'UIInterfaceOrientationLandscapeLeft',
    'UIInterfaceOrientationLandscapeRight',
  ];
  if (landscape.every(phone.contains)) {
    _ok("Info.plist lets the iPhone turn on its side: the open Duo can.");
  } else {
    _fail(
      "Info.plist keeps the iPhone upright, so the open Duo never turns on "
          'its side.',
      'Add UIInterfaceOrientationLandscapeLeft and ...LandscapeRight to '
          'UISupportedInterfaceOrientations. DuoScope keeps phones upright '
          'itself (lockPhonesUpright).',
    );
  }
  if (plist.contains('UIRequiresFullScreen')) {
    _warn(
      'Info.plist sets UIRequiresFullScreen.',
      'The iPad and the Duo then never give the app a window of another '
          'size; leave it out unless the app needs it.',
    );
  }
}

void _checkSource(String source) {
  if (source.isEmpty) return;
  if (source.contains('DuoScope(')) {
    _ok('DuoScope is in the app.');
  } else {
    _fail(
      'No DuoScope in lib/: the package never hears from iOS.',
      'MaterialApp(builder: (context, child) => DuoScope(child: child!))',
    );
  }
  if (source.contains('KeyboardAboveFold(')) {
    _ok('KeyboardAboveFold keeps fields above the fold.');
  } else {
    _warn(
      'No KeyboardAboveFold: on the Duo open upright, a field can sit on '
          'the fold while typing.',
      'DuoScope(child: KeyboardAboveFold(child: child!))',
    );
  }
  if (source.contains('NoVerticalBar(')) {
    final storyboard = File('ios/Runner/Base.lproj/Main.storyboard');
    final runner = Directory('ios/Runner');
    var native = storyboard.existsSync() &&
        storyboard.readAsStringSync().contains('DuoFlutterViewController');
    if (!native && runner.existsSync()) {
      native = runner.listSync(recursive: true).any(
            (file) =>
                file is File &&
                file.path.endsWith('.swift') &&
                file.readAsStringSync().contains('DuoFlutterViewController'),
          );
    }
    if (native) {
      _ok("NoVerticalBar has the plugin's view controller.");
    } else {
      _fail(
        "NoVerticalBar is used, but the app's root is not a "
            'DuoFlutterViewController, so iOS never hears it.',
        'In Main.storyboard, set the Flutter view controller\'s class to '
            'DuoFlutterViewController (see the README, NoVerticalBar).',
      );
    }
  }
}

void _checkXcode() {
  ProcessResult result;
  try {
    result = Process.runSync('xcodebuild', ['-version']);
  } on ProcessException {
    _warn('No Xcode found: the iOS SDK is not checked.');
    return;
  }
  final match =
      RegExp(r'Xcode (\d+)\.(\d+)').firstMatch(result.stdout.toString());
  if (match == null) return;
  final major = int.parse(match.group(1)!);
  final minor = int.parse(match.group(2)!);
  final version = '$major.$minor';
  if (major > 27 || (major == 27 && minor >= 1)) {
    _ok('Xcode $version builds in the hinge, the fold and the column.');
  } else {
    _warn(
      'Xcode $version: the hinge, the fold and the column\'s side need the '
          'iOS 27.1 SDK, and are left out of this build.',
      'Without them the package goes by the safe area alone. Build with '
          'Xcode 27.1 or later.',
    );
  }
}

void main() {
  stdout.writeln('iphone_duo doctor');
  _checkPubspec();
  _checkInfoPlist();
  _checkSource(_dartSource());
  if (Platform.isMacOS) _checkXcode();
  stdout.writeln(
    _failed ? '\nSome of it needs fixing (✗).' : '\nReady for the iPhone Duo.',
  );
  exitCode = _failed ? 1 : 0;
}
