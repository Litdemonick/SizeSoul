import 'package:flutter_test/flutter_test.dart';
import 'package:sizesoul/core/security/path_policy.dart';
import 'package:sizesoul/features/updates/update_service.dart';

void main() {
  group('sensitive path policy', () {
    for (final path in [
      r'C:\Windows\System32\a.dll',
      r'D:\Windows\a.txt',
      r'C:\Users\A\AppData\Local\a.db',
      r'C:\Program Files\A\app.exe',
      r'D:\$Recycle.Bin\a.txt',
      r'C:\Users\A\.ssh\id_rsa',
      r'D:\repo\.git\config',
      r'C:\pagefile.sys',
      r'\\server\share\file.txt',
      r'\\?\C:\Users\A\file.txt',
      r'C:\Users\A\a.txt:secret',
      r'C:\Users\A\..\x.txt',
      r'C:\Users\A\folder.\x.txt',
      r'C:\Users\A\folder \x.txt',
      'C:/Users/A/file.txt',
    ]) {
      test('rejects $path', () => expect(PathPolicy.reason(path), isNotNull));
    }
    test('allows ordinary local documents', () {
      expect(PathPolicy.reason(r'C:\Users\Alice\Downloads\movie.mp4'), isNull);
      expect(PathPolicy.reason(r'D:\Archive\backup.zip'), isNull);
    });
  });
  group('semantic updates', () {
    test('numeric comparison', () {
      expect(
        ReleaseVersion.parse('v1.10.0')
            .compareTo(ReleaseVersion.parse('1.9.9')),
        1,
      );
      expect(
        ReleaseVersion.parse('1.1.0+2')
            .compareTo(ReleaseVersion.parse('v1.1.0')),
        0,
      );
      expect(
        ReleaseVersion.parse('1.0.0').compareTo(ReleaseVersion.parse('2.0.0')),
        -1,
      );
    });
    test('rejects prereleases and non-version payloads', () {
      for (final value in [
        'v1.0.0-rc1',
        'https://evil.test',
        'v1.0',
        '../1.2.3',
      ]) {
        expect(() => ReleaseVersion.parse(value), throwsFormatException);
      }
    });
  });
}
