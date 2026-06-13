import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    this.onChanged,
    this.hintText = '搜索...',
    this.controller,
  });

  final ValueChanged<String>? onChanged;
  final String hintText;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textHint),
        prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 20),
        filled: true,
        fillColor: AppColors.panelBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
    );
  }
}
