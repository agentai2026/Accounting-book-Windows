import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import 'package:ezbookkeeping_desktop/core/models/book.dart';

import 'package:ezbookkeeping_desktop/desktop/providers/book_provider.dart';

import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';

import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_form_field.dart';

import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';



Future<bool?> showBookFormDialog(BuildContext context, {Book? book}) {

  return showGlassDialog<bool>(

    context: context,

    builder: (context) => BookFormDialog(book: book),

  );

}



class BookFormDialog extends ConsumerStatefulWidget {

  const BookFormDialog({super.key, this.book});

  final Book? book;



  @override

  ConsumerState<BookFormDialog> createState() => _BookFormDialogState();

}



class _BookFormDialogState extends ConsumerState<BookFormDialog> {

  late final TextEditingController _nameController;

  late String _color;

  bool _submitting = false;



  static const _colors = ['#C07C4D', '#3BA99C', '#6B8CAE', '#E05D5D', '#8B7EC8'];



  @override

  void initState() {

    super.initState();

    _nameController = TextEditingController(text: widget.book?.name ?? '');

    _color = widget.book?.color ?? _colors.first;

  }



  @override

  void dispose() {

    _nameController.dispose();

    super.dispose();

  }



  Color _parseColor(String hex) {

    final value = hex.replaceFirst('#', '');

    return Color(int.parse('FF$value', radix: 16));

  }



  Future<void> _submit() async {

    setState(() => _submitting = true);

    final service = await ref.read(bookServiceProvider.future);

    final result = widget.book == null

        ? await service.createBook(name: _nameController.text, color: _color)

        : await service.updateBook(widget.book!, name: _nameController.text, color: _color);

    if (!mounted) return;

    setState(() => _submitting = false);

    result.when(

      success: (_) {

        refreshBooks(ref);

        Navigator.pop(context, true);

      },

      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))),

    );

  }



  @override

  Widget build(BuildContext context) {

    return GlassAlertDialog(

      title: Text(widget.book == null ? '添加账本' : '编辑账本'),

      content: SizedBox(

        width: 400,

        child: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            AppTextField(

              label: '账本名称',

              controller: _nameController,

              hint: '请输入账本名称',

            ),

            const SizedBox(height: 16),

            const AppFieldLabel(text: '颜色'),

            const SizedBox(height: 8),

            Wrap(

              spacing: 8,

              children: _colors.map((hex) {

                final selected = _color == hex;

                return InkWell(

                  onTap: () => setState(() => _color = hex),

                  child: Container(

                    width: 32,

                    height: 32,

                    decoration: BoxDecoration(

                      color: _parseColor(hex),

                      shape: BoxShape.circle,

                      border: Border.all(color: selected ? AppColors.textPrimary : Colors.transparent, width: 2),

                    ),

                  ),

                );

              }).toList(),

            ),

          ],

        ),

      ),

      actions: [

        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),

        FilledButton(onPressed: _submitting ? null : _submit, child: Text(widget.book == null ? '添加' : '保存')),

      ],

    );

  }

}


