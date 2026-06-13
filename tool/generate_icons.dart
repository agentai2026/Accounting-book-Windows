import 'dart:io';

import 'package:image/image.dart';
import 'package:path/path.dart' as p;

/// 从 assets/icons/app_icon.png 生成 Windows 可用的标准 .ico
void main(List<String> args) {
  final root = args.isNotEmpty ? args.first : Directory.current.path;
  final pngPath = p.join(root, 'assets', 'icons', 'app_icon.png');
  final exeIcoPath =
      p.join(root, 'windows', 'runner', 'resources', 'app_icon.ico');
  final trayIcoPath = p.join(root, 'assets', 'icons', 'tray.ico');
  final runnerRcPath = p.join(root, 'windows', 'runner', 'Runner.rc');

  if (!File(pngPath).existsSync()) {
    stderr.writeln('Missing PNG: $pngPath');
    exit(1);
  }

  final source = decodeImage(File(pngPath).readAsBytesSync());
  if (source == null) {
    stderr.writeln('Failed to decode PNG: $pngPath');
    exit(1);
  }

  _writeMultiSizeIco(
    source: source,
    outputPath: exeIcoPath,
    sizes: const [16, 32, 48, 64, 128, 256],
  );
  _writeMultiSizeIco(
    source: source,
    outputPath: trayIcoPath,
    sizes: const [16, 32, 48],
  );
  _touchRunnerRc(runnerRcPath);

  stdout.writeln('  $exeIcoPath');
  stdout.writeln('  $trayIcoPath');
  stdout.writeln('Icon generation done (Dart/image).');
}

void _writeMultiSizeIco({
  required Image source,
  required String outputPath,
  required List<int> sizes,
}) {
  final dir = Directory(p.dirname(outputPath));
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  final container = Image(width: source.width, height: source.height);
  container.frames = [
    for (final size in sizes) copyResize(source, width: size, height: size),
  ];

  File(outputPath).writeAsBytesSync(encodeIco(container));
}

void _touchRunnerRc(String runnerRcPath) {
  final file = File(runnerRcPath);
  if (!file.existsSync()) return;

  final stamp = DateTime.now().toUtc().toIso8601String();
  var content = file.readAsStringSync();
  content = content.replaceFirst(
    RegExp(r'// icon_generated_at: [^\r\n]+'),
    '// icon_generated_at: $stamp',
  );
  file.writeAsStringSync(content, flush: true);
  stdout.writeln('  Runner.rc timestamp -> $stamp');
}
