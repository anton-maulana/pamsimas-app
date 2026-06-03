import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:pamsimas_app/src/theme/app_colors.dart';

class ForgotPasswordSheet extends StatefulWidget {
  const ForgotPasswordSheet({super.key});

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _submitted = false;

  Future<void> _onKirim() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: _submitted
          ? const Text('Permintaan terkirim!')
          : FormBuilder(
              key: _formKey,
              child: Column(
                children: [
                  FormBuilderTextField(
                    name: 'telepon',
                    decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _onKirim,
                    child: const Text('Kirim Permintaan'),
                  ),
                ],
              ),
            ),
    );
  }
}
