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

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _departmentController = TextEditingController();
  final _detailController = TextEditingController();
  bool _isPasswordVisible = false;
  final _fullNameController = TextEditingController(); // thêm dòng này

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
              Navigator.of(context).pushReplacementNamed(LoginScreen);
              break;
            case AuthStatus.failure:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.errorMessage ?? 'Đăng ký thất bại')),
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
                      Hero(
  tag: 'appLogo',
  child: Image.asset(
    'assets/logo.png',
    height: height * 0.15,
  ),
),

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
                  constraints: BoxConstraints(maxWidth: 450),
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
                          'Đăng ký tài khoản',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF002856),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                            'Họ và tên', _fullNameController, Icons.person),
                        const SizedBox(height: 16),
                        _buildTextField('Tên đăng nhập', _usernameController,
                            Icons.person_outline),
                        const SizedBox(height: 16),
                        _buildPasswordField('Mật khẩu', _passwordController),
                        const SizedBox(height: 16),
                        _buildPasswordField(
                            'Nhập lại mật khẩu', _confirmPasswordController),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _departmentController.text.isNotEmpty
                              ? _departmentController.text
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Phòng ban',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.apartment),
                          ),
                          items: [
                            'Ban Tham Mưu',
                            'Ban Chính Trị',
                            'Ban HC-KT',
                          ].map((dept) {
                            return DropdownMenuItem<String>(
                              value: dept,
                              child: Text(dept),
                            );
                          }).toList(),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Vui lòng chọn phòng ban'
                              : null,
                          onChanged: (value) {
                            setState(() {
                              _departmentController.text = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                            'Đơn vị', _detailController, Icons.business),
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
                                context.read<AuthBloc>().add(RegisterSubmitted(
                                      username: _usernameController.text.trim(),
                                      password: _passwordController.text.trim(),
                                      department:
                                          _departmentController.text.trim(),
                                      detail: _detailController.text.trim(),
                                      fullname: _fullNameController.text.trim(),
                                    ));
                              }
                            },
                            child: const Text('Đăng ký',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Đã có tài khoản?"),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pushNamed(LoginScreen),
                              child: const Text("Đăng nhập",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            )
                          ],
                        )
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

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      onFieldSubmitted: (_) {
  if (_formKey.currentState!.validate()) {
    context.read<AuthBloc>().add(RegisterSubmitted(
                                      username: _usernameController.text.trim(),
                                      password: _passwordController.text.trim(),
                                      department:
                                          _departmentController.text.trim(),
                                      detail: _detailController.text.trim(),
                                      fullname: _fullNameController.text.trim(),
                                    ));
  }
},
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Vui lòng nhập $label' : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      obscureText: !_isPasswordVisible,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập $label';
        } else if (label == 'Nhập lại mật khẩu' &&
            value != _passwordController.text) {
          return 'Mật khẩu không khớp';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ),
    );
  }
}
