import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

class TransactionImagePreview extends ConsumerWidget {
  const TransactionImagePreview({
    super.key,
    required this.relativePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String relativePath;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(transactionImageServiceProvider);

    return FutureBuilder<String>(
      future: service.resolveAbsolutePath(relativePath),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _placeholder(width: width, height: height);
        }

        final file = File(snapshot.data!);
        if (!file.existsSync()) {
          return _placeholder(width: width, height: height);
        }

        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _placeholder(width: width, height: height),
        );
      },
    );
  }

  Widget _placeholder({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      color: AppColors.panelBackground,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.textHint.withValues(alpha: 0.5),
      ),
    );
  }
}
