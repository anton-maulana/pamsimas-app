class LoginModel {
  final String username;
  final String password;

  const LoginModel({
    required this.username,
    required this.password,
  });

  factory LoginModel.fromForm(Map<String, dynamic> form) {
    return LoginModel(
      username: form['username'] as String,
      password: form['password'] as String,
    );
  }
}
