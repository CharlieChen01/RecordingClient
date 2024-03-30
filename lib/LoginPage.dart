import 'package:client/RecordingsPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late String _email, _password;
  late String _accessToken, _refreshToken;
  void _submit() async {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      // Future<void> _login() async {
        // 在这里执行登录逻辑
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': _email,
          'password': _password,
        }),
      );

      if (response.statusCode == 200) {
        // 如果服务器返回了成功的响应，解析Token并进行导航等操作
        final Map<String, dynamic> data = json.decode(response.body);
        // 使用data['token']来获取Token
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        print('_accessToken: $_accessToken, _refreshToken: $_refreshToken');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RecordingsPage()),
        );
      } else {
        // 如果服务器未返回成功响应，则抛出异常
        throw Exception('Failed to login');
      }
      // }

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            TextFormField(
              onSaved: (value) => _email = value ?? '',
              validator: (value) {
                if (value != null && value.isEmpty) {
                  return 'Please input Email';
                }
                return null;
              },
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextFormField(
              obscureText: true,
              onSaved: (value) => _password = value ?? '',
              validator: (value) {
                if (value != null && value.isEmpty) {
                  return 'Please input password';
                }
                return null;
              },
              decoration: InputDecoration(labelText: 'Password'),
            ),
            ElevatedButton(
              onPressed: _submit,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}