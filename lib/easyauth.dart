import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'dart:math';

class Token {
  Token.fromJSON(String data) {
    access_token = jsonDecode(data)['access_token'].toString();
    refreshToken = jsonDecode(data)['refresh_token'].toString();
    scope = jsonDecode(data)['scope'].toString();
    tokenType = jsonDecode(data)['token_type'].toString();
    expirationDate =
        DateTime.now().add(Duration(seconds: jsonDecode(data)['expires_in']));
  }

  String access_token = '';
  DateTime expirationDate = DateTime.now();
  String refreshToken = '';
  String scope = '';
  String tokenType = '';
}

class Authenticator {
  Authenticator({
    required this.authURI,
    required this.tokenURI,
    required this.callbackURI,
    this.errorCallback,
    this.clientSecret = '',
    this.responseType = 'code',
    this.accessType = 'online',
    this.grandType = 'authorization_code',
    this.clientID = 'MyFlutterApp',
    this.scope = '',
    this.BearerToken,
  });

  /// Endpoint on ws for login mask
  final String authURI;

  /// Endpoint on ws for exchanging code for token
  final String tokenURI;

  /// request scope
  String scope;
  String clientSecret;

  /// only change if you know what ur doing
  String responseType = 'code';

  /// only change if you know what ur doing
  String accessType;

  /// only change if you know what ur doing
  String grandType;

  /// return address of the login callback
  final String callbackURI;

  void Function(String message)? errorCallback;

  /// ID of the Web App
  String clientID;

  String _state = '';
  String _code = '';
  Token? BearerToken;

  /// it is posible to code data into state for after the redirect
  /// gets echoed by ws to client on redirect
  /// - for now random string (length 50 chars)
  void _generateState() {
    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random _rnd = Random();
    String getRandomString(int length) =>
        String.fromCharCodes(Iterable.generate(
            length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

    //_state = getRandomString(50);
    _state = 'hzi5hlyewjd';
  }

  /// generates the redirect uri with the oauth2 params
  String _generateAuthCodeUri() {
    _generateState();
    html.window.sessionStorage['_state'] = _state;

    return '$authURI'
        '?scope=${Uri.encodeComponent(scope)}&'
        'access_type=$accessType&'
        'response_type=$responseType&'
        'redirect_uri=${Uri.encodeComponent(callbackURI)}&'
        'client_id=$clientID&'
        'state=$_state';
  }

  /// Starts the authentication process. Redirects to login page and handles the
  /// oAuth2 process
  void invokeAuthorisation() {
    html.window.sessionStorage.remove('_state');
    String redirectUri = _generateAuthCodeUri();
    // ToDo: change
    html.window.open(redirectUri, '_self');
  }

  /// needs to be placed inside ```onGenerateRoute: (settings) {}``` and listens to
  /// authorization callback
  void authRedirectCallback(String url) {
    //RouteSettings settings) {
    print('authRedirectCallback');
    var uriData = Uri.parse(url);
    // is oAuth2 callback?
    print('ss ${uriData.path}');
    if (uriData.path == '${Uri.parse(callbackURI).path}') {
      if (html.window.sessionStorage.containsKey('_state')) {
        if (_state == '') _state = html.window.sessionStorage['_state']!;
        html.window.sessionStorage.remove('_state');
      }
      // read query params
      Map<String, String> _urlParams = uriData.queryParameters;
      print(_urlParams);
      // missing state= or code=
      if (_urlParams.containsKey('code') == false ||
          _urlParams.containsKey('state') == false) {
        if (errorCallback != null)
          errorCallback!('Auth failed - code or state missing');
        return;
      }
      if (_urlParams['state'].toString() == _state) {
        _code = _urlParams['code']!;
        _getBearerToken();
        print('Auth worked!');
      } else {
        if (errorCallback != null)
          errorCallback!('Status miss match! Login might be compromised!');
        return;
      }
    }
  }

  /// exchanges the code for a bearer token
  void _getBearerToken() async {
    final url = Uri.parse('$tokenURI');
    final headers = {
      'Content-type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json'
    };
    // todo: redirect_uri ???!!!
    final requestBody =
        'client_id=$clientID&client_secret=$clientSecret&code=$_code&grand_type=$grandType';

    // generate bearer token from api answer
    final response = await http.post(url, headers: headers, body: requestBody);
    BearerToken = Token.fromJSON(response.body);
    html.window.localStorage['Bearer'] = BearerToken.toString();
  }

  /// is the authentication is done and valid
  bool status() {
    // no token
    if (BearerToken == null) return false;
    // token expired
    if (BearerToken!.expirationDate.isAfter(DateTime.now()) == false)
      return false;
    // no bearer token
    if (BearerToken!.tokenType != 'Bearer') return false;
    return true;
  }
}
