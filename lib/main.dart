import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:html' as html;
import 'dart:core';

/// Main class that runs before user authenticated with a webservice(ws).
/// 1. Redirects user to [socket]/login and provides [clientID] as parameter '[socket]/login?clientID=[clientID]'
///
/// 2. after logging in on the ws the ws has to redirect to 'webAppIP/authcallback' and provide a temporary token
/// as parameter 'webAppIP/authcallback?token=...'.
///
/// 3. The App then sends a http-post to '[socket]/login/verify' with "clientID": [clientID], "token": ...;
///
/// 4. expects a bearer token as answer.
///
/// 5. checks the token against '[socket]/login/verify' as http-get with 'Authorization': 'Bearer [BearerToken]' as parameter:
///
/// 6. if http 200 OK continues with the main app.
class WebAuth extends StatelessWidget {
  /// call this in main
  /// ```dart
  /// void main() async {
  ///   runApp(WebAuth(
  ///     socket: 'http://192.168.178.20:4000',
  ///     clientID: 'flutterApp',
  ///     mainApp: MyApp(),
  ///   ));
  /// }
  /// ```'runApp(WebAuth(...));' and provide [socket], [clientID] and [mainApp].
  WebAuth({
    required this.socket,
    required this.clientID,
    required this.mainApp,
  });
  /// Webservice Endpoint e.g. 'http://192.168.0.10:4000'
  String socket;
  /// the ID of the application gets passed to the webservice
  String clientID;
  /// the root widget of the flutter application after successfully authenticating
  Widget mainApp;
  String BearerToken = '';

  /// get Bearer Token from WS
  Future<void> getBearer(BuildContext context) async {
    try {
      final url = Uri.parse('$socket/login/verify');
      final headers = {"Content-type": "application/json"};
      final json =
          '{"clientID": $clientID, "token": ${html.window.localStorage['_tmpToken']}}';
      html.window.localStorage.remove('_tmpToken');
      final response = await http.post(url, headers: headers, body: json);
      BearerToken = response.body;
      html.window.localStorage['bearer'] = BearerToken;
      await testToken(context);
    } catch (e) {
      print(e);
    }
  }
  /// Test the Bearer Token against the WS if it answers 200 it continues else authentication fails
  Future<void> testToken(BuildContext context) async {
    try {
      BearerToken = html.window.localStorage['bearer']!;
      final url = Uri.parse('$socket/login/verify');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $BearerToken',
      };
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        // start 'normal' app
        runApp(mainApp);
      } else {
        BearerToken = '';
        html.window.localStorage.remove('bearer');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Zugriff verweigert!')));
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (html.window.localStorage.containsKey('bearer')) {
      testToken(context);
    }

    return MaterialApp(
      title: 'Login',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      onGenerateRoute: (settings) {
        if (settings.name != null) {
          var uriData = Uri.parse(settings.name!);
          switch (uriData.path) {
            case '/authcallback':
              Map<String, String> _urlParams = uriData.queryParameters;
              _urlParams.forEach((key, value) {
                if (key == 'token')
                  html.window.localStorage['_tmpToken'] = value;
                getBearer(context);
              });
              break;
          }
        }
        return MaterialPageRoute(
            builder: (BuildContext context) => WebAuth(
              socket: this.socket,
              clientID: this.clientID,
              mainApp: this.mainApp,
            ));
      },
      home: Center(
        child: ElevatedButton(
          onPressed: () {
            html.window.open('$socket/login?clientID=$clientID', '_self');
          },
          child: Text('Anmelden'),
        ),
      ),
    );
  }
}

void main() async {
  runApp(WebAuth(
    socket: 'http://192.168.178.20:4000',
    clientID: 'flutterApp',
    mainApp: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter App'),
        ),
        body: Center(
          child: Text('Die Flutter App'),
        ),
      ),
    );
  }
}
