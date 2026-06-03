import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:pamsimas_app/src/core/models/login_model.dart';
import 'package:pamsimas_app/src/theme/app_colors.dart';
import 'error_banner.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormBuilderState> formKey;
  final bool isLoading;
  final String? errorMessage;
  final Function(LoginModel) onLogin;
  final VoidCallback onForgotPassword;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.isLoading,
    required this.errorMessage,
    required this.onLogin,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formKey,
      child: Column(
        children: [
          if (errorMessage != null) ...[
            ErrorBanner(message: errorMessage!),
            const SizedBox(height: 20),
          ],
          FormBuilderTextField(
            name: 'username',
            decoration: const InputDecoration(labelText: 'Username'),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Username wajib diisi' : null,
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'password',
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
            validator: (v) =>
                (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading
                ? null
                : () {
                    if (formKey.currentState?.saveAndValidate() ?? false) {
                      final form = formKey.currentState!.value;
                      final loginModel = LoginModel.fromForm(form);
                      onLogin(loginModel);
                    }
                  },
            child: isLoading
                ? const CircularProgressIndicator()
                : const Text('Masuk'),
          ),
          // TextButton(
          //   onPressed: isLoading ? null : onForgotPassword,
          //   child: const Text('Lupa Password?'),
          // ),
        ],
      ),
    );
  }
}
