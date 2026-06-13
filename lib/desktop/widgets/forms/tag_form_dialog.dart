import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import 'package:ezbookkeeping_desktop/core/models/tag.dart';

import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';

import 'package:ezbookkeeping_desktop/desktop/providers/tag_provider.dart';

import 'package:ezbookkeeping_desktop/desktop/widgets/common/app_form_field.dart';

import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';



Future<bool?> showTagFormDialog(BuildContext context, {Tag? tag}) {

  return showGlassDialog<bool>(

    context: context,

    builder: (context) => TagFormDialog(tag: tag),

  );

}



class TagFormDialog extends ConsumerStatefulWidget {

  const TagFormDialog({super.key, this.tag});

  final Tag? tag;



  @override

  ConsumerState<TagFormDialog> createState() => _TagFormDialogState();

}



class _TagFormDialogState extends ConsumerState<TagFormDialog> {

  late final TextEditingController _nameController;

  bool _submitting = false;



  @override

  void initState() {

    super.initState();

    _nameController = TextEditingController(text: widget.tag?.name ?? '');

  }



  @override

  void dispose() {

    _nameController.dispose();

    super.dispose();

  }



  Future<void> _submit() async {

    final name = _nameController.text.trim();

    if (name.isEmpty) return;

    setState(() => _submitting = true);

    final service = await ref.read(tagServiceProvider.future);

    final result = widget.tag == null

        ? await service.createTag(name)

        : await service.updateTag(widget.tag!, name);

    if (!mounted) return;

    setState(() => _submitting = false);

    result.when(

      success: (_) {

        refreshTags(ref);

        Navigator.pop(context, true);

      },

      failure: (e) => ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text(e.message)),

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    return GlassAlertDialog(

      title: Text(widget.tag == null ? '添加标签' : '编辑标签'),

      content: AppTextField(

        label: '标签名称',

        controller: _nameController,

        hint: '请输入标签名称',

      ),

      actions: [

        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),

        FilledButton(onPressed: _submitting ? null : _submit, child: Text(widget.tag == null ? '添加' : '保存')),

      ],

    );

  }

}


