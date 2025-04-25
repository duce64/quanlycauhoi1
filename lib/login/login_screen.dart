import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterquiz/blocs/auth/auth_bloc.dart';
import 'package:flutterquiz/blocs/auth/auth_event.dart';
import 'package:flutterquiz/blocs/auth/auth_state.dart';
import 'package:flutterquiz/login/app_colors.dart';
import 'package:flutterquiz/login/app_icons.dart';
import 'package:flutterquiz/login/app_styles.dart';
import 'package:flutterquiz/login/responsive_widget.dart';
import 'package:flutterquiz/util/router_path.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          switch (state.status) {
            case AuthStatus.success:
              Navigator.of(context).pushReplacementNamed(DashBoardScreen);
              break;
            case AuthStatus.failure:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'Đăng nhập thất bại'),
                ),
              );
              break;
            default:
              break;
          }
        },
        child: Row(
          children: [
            if (!ResponsiveWidget.isSmallScreen(context))
              Expanded(
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: Color(0xFF002856),
                    image: DecorationImage(
                      image: AssetImage('assets/pkkq.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/logo.png', height: height * 0.15),
                      const SizedBox(height: 20),
                      Text(
                        'HỆ THỐNG QUẢN LÝ CÂU HỎI',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đăng nhập',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF002856),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _usernameController,
                          onChanged: (value) => context
                              .read<AuthBloc>()
                              .add(AuthUsernameChanged(value)),
                          decoration: InputDecoration(
                            labelText: 'Tên đăng nhập',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập tên đăng nhập';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          onChanged: (value) => context
                              .read<AuthBloc>()
                              .add(AuthPasswordChanged(value)),
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock_outline),
                            suffixIcon: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                    begin: 0, end: _isPasswordVisible ? 1 : 0),
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                builder: (context, value, child) {
                                  final rotation = sin(value * pi) * 0.1;
                                  return Transform.rotate(
                                    angle: rotation,
                                    child: AnimatedCrossFade(
                                      duration: Duration(milliseconds: 200),
                                      crossFadeState: _isPasswordVisible
                                          ? CrossFadeState.showSecond
                                          : CrossFadeState.showFirst,
                                      firstChild: Icon(Icons.visibility_off,
                                          color: Colors.grey),
                                      secondChild: Icon(Icons.visibility,
                                          color: Colors.green),
                                      firstCurve: Curves.easeIn,
                                      secondCurve: Curves.easeOut,
                                      sizeCurve: Curves.easeInOut,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập mật khẩu';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF002856),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                final authBloc = context.read<AuthBloc>();
                                authBloc.add(LoginSubmitted(
                                  _usernameController.text.trim(),
                                  _passwordController.text.trim(),
                                ));
                              }
                            },
                            child: Text(
                              'Đăng nhập',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Chưa có tài khoản?"),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                    RegisterScreen); // <-- tên route màn đăng ký
                              },
                              child: Text(
                                "Đăng ký",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
