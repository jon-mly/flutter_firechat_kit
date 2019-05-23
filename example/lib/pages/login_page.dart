import 'package:flutter/material.dart';

import 'package:firechat_kit/firechat_kit.dart';

import 'chatrooms_list_page.dart';

class LoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _login() async {
    String accountId = _controller.text;
    if (accountId.length < 3)
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("The Account ID should at least have 3 characters"),
      ));
    else
      await FirechatKit.instance
          .login(userId: accountId)
          .then((FirechatCurrentUser user) => _presentChatroomsPage())
          .catchError((e) => print(e))
          .whenComplete(() => print("Login process ended"));
  }

  void _presentChatroomsPage() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ChatroomsListPage()));
  }

  Widget _buildAccountIdTextField() {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: "Enter an Account ID",
      ),
    );
  }

  Widget _buildLoginButton() {
    return RaisedButton(
      color: Colors.white,
      onPressed: _login,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.play_for_work,
            color: Colors.teal,
            size: 25.0,
          ),
          Padding(
            padding: EdgeInsets.only(left: 20.0),
          ),
          Text(
            "CONNECT",
            style: TextStyle(color: Colors.teal, fontSize: 16.0),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.teal,
      padding: EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            "FirechatKit",
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 40.0),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 20.0),
          ),
          Text(
            "Example application",
            style: TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.white,
                fontSize: 20.0),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 20.0),
          ),
          _buildAccountIdTextField(),
          Padding(
            padding: EdgeInsets.only(bottom: 20.0),
          ),
          _buildLoginButton()
        ],
      ),
    );
  }
}
