import 'dart:io';

void main() {
  final laPath = _findLineAwesomeFile();
  final la = File(laPath).readAsStringSync();
  final iconDataByName = <String, String>{};
  for (final match
      in RegExp(r'static const IconData (\w+)').allMatches(la)) {
    iconDataByName[match.group(1)!] = match.group(1)!;
  }

  String? cssToDart(String css) {
    final isBrand = css.startsWith('lab ');
    final raw = css.replaceFirst(RegExp(r'la[bs] la-'), '').replaceAll('-', '_');
    if (iconDataByName.containsKey(raw)) return raw;
    if (!isBrand && iconDataByName.containsKey('${raw}_solid')) {
      return '${raw}_solid';
    }
    return null;
  }

  final constantsFile =
      File('lib/core/constants/icon_constants.dart').readAsStringSync();
  final cssClasses = <String>{};
  for (final match
      in RegExp(r"'las [^']+'|'lab [^']+'").allMatches(constantsFile)) {
    cssClasses.add(match.group(0)!.replaceAll("'", ''));
  }

  final buffer = StringBuffer('''
import 'package:flutter/widgets.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

/// Maps ezBookkeeping Line Awesome CSS classes to Flutter [IconData].
const Map<String, IconData> kLineAwesomeCssIconMap = {
''');

  final missing = <String>[];
  for (final css in cssClasses.toList()..sort()) {
    final dartName = cssToDart(css);
    if (dartName == null) {
      missing.add(css);
      continue;
    }
    buffer.writeln("  '$css': LineAwesomeIcons.$dartName,");
  }

  buffer.writeln('''};

IconData lineAwesomeIconFromCssClass(String cssClass, {IconData? fallback}) {
  return kLineAwesomeCssIconMap[cssClass] ??
      fallback ??
      LineAwesomeIcons.shapes_solid;
}

IconData lineAwesomeIconFromCssClasses(
  Iterable<String> cssClasses, {
  IconData? fallback,
}) {
  for (final cssClass in cssClasses) {
    final icon = kLineAwesomeCssIconMap[cssClass];
    if (icon != null) return icon;
  }
  return fallback ?? LineAwesomeIcons.shapes_solid;
}
''');

  File('lib/desktop/constants/line_awesome_icon_resolver.dart')
      .writeAsStringSync(buffer.toString());

  stdout.writeln('Generated ${cssClasses.length - missing.length} icons');
  if (missing.isNotEmpty) {
    stdout.writeln('Missing ${missing.length}:');
    for (final css in missing) {
      stdout.writeln('  $css');
    }
    exitCode = 1;
  }
}

String _findLineAwesomeFile() {
  final env = Platform.environment['LOCALAPPDATA'];
  if (env != null) {
    final path =
        '$env\\Pub\\Cache\\hosted\\pub.dev\\line_awesome_flutter-3.0.1\\lib\\line_awesome_flutter.dart';
    if (File(path).existsSync()) return path;
  }
  throw StateError('line_awesome_flutter package not found');
}
