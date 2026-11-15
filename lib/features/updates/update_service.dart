import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ReleaseVersion implements Comparable<ReleaseVersion> {
  final int major, minor, patch;
  const ReleaseVersion(this.major, this.minor, this.patch);
  static ReleaseVersion parse(String value) {
    final match = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)(?:\+\d+)?$')
        .firstMatch(value);
    if (match == null) throw const FormatException('Versión estable no válida');
    return ReleaseVersion(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }

  @override
  int compareTo(ReleaseVersion other) {
    for (final delta in [
      major - other.major,
      minor - other.minor,
      patch - other.patch,
    ]) {
      if (delta != 0) return delta.sign;
    }
    return 0;
  }

  @override
  String toString() => '$major.$minor.$patch';
}

class UpdateService {
  static const repository = 'https://github.com/Litdemonick/SizeSoul';
  Future<PackageInfo> installed() => PackageInfo.fromPlatform();
  Future<ReleaseVersion?> latest() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12);
    try {
      final request = await client.getUrl(
        Uri.https(
          'api.github.com',
          '/repos/Litdemonick/SizeSoul/releases/latest',
        ),
      );
      request.followRedirects = false;
      request.headers.set(HttpHeaders.userAgentHeader, 'SizeSoul-desktop');
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github+json',
      );
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        throw HttpException(
          'GitHub respondió ${response.statusCode}. Inténtalo más tarde.',
        );
      }
      final buffer = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 15))) {
        buffer.addAll(chunk);
        if (buffer.length > 1024 * 1024) {
          throw const FormatException('Respuesta demasiado grande');
        }
      }
      final json = jsonDecode(utf8.decode(buffer)) as Map<String, dynamic>;
      if (json['draft'] != false || json['prerelease'] != false) return null;
      return ReleaseVersion.parse(json['tag_name'] as String);
    } finally {
      client.close(force: true);
    }
  }

  Future<void> openReleases() async {
    if (!await launchUrl(
      Uri.parse('$repository/releases'),
      mode: LaunchMode.externalApplication,
    )) {
      throw StateError('No se pudo abrir el navegador.');
    }
  }
}
