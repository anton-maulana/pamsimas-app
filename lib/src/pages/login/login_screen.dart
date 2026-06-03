import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:pamsimas_app/src/core/models/login_model.dart';
import 'package:pamsimas_app/src/core/services/auth_service.dart';
import 'package:pamsimas_app/src/pages/login/fogot_password_sheet.dart';
import 'package:pamsimas_app/src/shared/main_navigation.dart';
import 'package:pamsimas_app/src/theme/app_colors.dart';
import 'error_banner.dart';
import 'login_form.dart';
import 'logo_section.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  String? _errorMessage;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin(LoginModel loginModel) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.login(loginModel);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Login gagal, periksa username/password atau koneksi.';
      });
    }
  }

  void _onForgotPassword() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ForgotPasswordSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.bgGrey,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 48),
                const LogoSection(),
                const SizedBox(height: 40),
                LoginForm(
                  formKey: _formKey,
                  isLoading: _isLoading,
                  errorMessage: _errorMessage,
                  onLogin: _onLogin,
                  onForgotPassword: _onForgotPassword,
                ),
                const SizedBox(height: 24),
                Text(
                  'PAMSIMAS © ${DateTime.now().year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
