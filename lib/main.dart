import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart' as us;

import 'package:oauth2/easyauth.dart';

import 'dart:core';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  us.setPathUrlStrategy();
  runApp(MyApp());
}

class MissingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter App'),
      ),
      body: Center(
        child: Text('404 not found'),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyApp();
}

class _MyApp extends State<MyApp> {
  Authenticator authenticator = new Authenticator(
    authURI: 'https://accounts.google.com/o/oauth2/auth',
    tokenURI: 'https://oauth2.googleapis.com/token',
    callbackURI: 'http://127.0.0.1/callback',
    errorCallback: (message) {
      print(message);
    },
    clientID:
    '435227925555-nnn5dfj2fn2mmsp9a68o3oqatlpsgupk.apps.googleusercontent.com',
    clientSecret: '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',
    scope: 'https://www.googleapis.com/auth/spreadsheets',
  );

  @override
  void initState() {
    super.initState();

    authenticator.authRedirectCallback(Uri.base.toString());
    print(Uri.parse(Uri.base.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyFlutterAppOAuthTest',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      onGenerateRoute: (settings) {
        //authenticator.authRedirectCallback(settings);
        return MaterialPageRoute(builder: (context) => MyApp());
      },
      home: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Flutter App'),
          ),
          body: Center(
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    authenticator.invokeAuthorisation();
                  },
                  child: Text('Login'),
                ),
                ElevatedButton(
                  onPressed: () {
                    String m = 'not authed!';
                    if (authenticator.status()) m = 'Authed';
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(m)));
                  },
                  child: Text('Status'),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
