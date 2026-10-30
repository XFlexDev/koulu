import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const base = 'https://koulu.kreatix.dev/api';
const _tokenKey = 'koulu:token';

String? _token;

Future<String?> loadToken() async {
  _token ??= (await SharedPreferences.getInstance()).getString(_tokenKey);
  return _token;
}

Future<void> _setToken(String? t) async {
  _token = t;
  final p = await SharedPreferences.getInstance();
  if (t == null) {
    await p.remove(_tokenKey);
  } else {
    await p.setString(_tokenKey, t);
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

Future<dynamic> _req(String method, String path, {dynamic body}) async {
  final uri = Uri.parse('$base$path');
  final headers = <String, String>{'content-type': 'application/json'};
  if (_token != null) headers['authorization'] = 'Bearer $_token';
  http.Response r;
  switch (method) {
    case 'POST':
      r = await http.post(uri, headers: headers, body: jsonEncode(body));
      break;
    case 'DELETE':
      r = await http.delete(uri, headers: headers);
      break;
    default:
      r = await http.get(uri, headers: headers);
  }
  if (r.statusCode == 401) {
    await _setToken(null);
    throw ApiException('unauthorized');
  }
  if (r.statusCode >= 400) {
    String msg = 'Virhe ${r.statusCode}';
    try {
      msg = jsonDecode(utf8.decode(r.bodyBytes))['detail'] ?? msg;
    } catch (_) {}
    throw ApiException(msg);
  }
  if (r.body.isEmpty) return null;
  return jsonDecode(utf8.decode(r.bodyBytes));
}

Future<void> login(String url, String user, String pass) async {
  final res = await _req('POST', '/session',
      body: {'url': url, 'username': user, 'password': pass});
  await _setToken(res['token']);
}

Future<void> logout() async {
  try {
    await _req('POST', '/session/logout');
  } catch (_) {}
  await _setToken(null);
}

Future<Map<String, dynamic>> me() async =>
    Map<String, dynamic>.from(await _req('GET', '/me'));

/// date as YYYY-MM-DD; returns {week_start, week_end, days:[{date, weekday:1-7, lessons:[...]}]}
Future<Map<String, dynamic>> schedule(String date) async =>
    Map<String, dynamic>.from(await _req('GET', '/schedule?date=$date'));

/// folders: inbox, sent, archive, drafts, all → {messages:[{id,subject,from,timestamp,unread,folder,replies}]}
Future<List<dynamic>> messages(String folder) async =>
    Map<String, dynamic>.from(await _req('GET', '/messages?folder=$folder'))[
            'messages'] as List<dynamic>? ??
        [];

/// {id,subject,from,timestamp,recipients,html,replies,allow_reply}
Future<Map<String, dynamic>> message(int id) async =>
    Map<String, dynamic>.from(await _req('GET', '/messages/$id'));

Future<void> reply(int id, String body) async =>
    _req('POST', '/messages/$id/reply', body: {'body': body});

Future<void> send(List<Map<String, dynamic>> recipients, String subject,
        String body) async =>
    _req('POST', '/messages',
        body: {'recipients': recipients, 'subject': subject, 'body': body});

/// {recipients:[{id,name,type,n_class}]}
Future<List<dynamic>> recipients() async =>
    Map<String, dynamic>.from(await _req('GET', '/recipients'))['recipients']
            as List<dynamic>? ??
        [];

/// {exams:[{date,time,name,course,teacher,info}]}
Future<List<dynamic>> exams() async =>
    Map<String, dynamic>.from(await _req('GET', '/exams'))['exams']
            as List<dynamic>? ??
        [];

/// {news:[{id,title,date,description,author,sticky,important}]}
Future<List<dynamic>> news() async =>
    Map<String, dynamic>.from(await _req('GET', '/news'))['news']
            as List<dynamic>? ??
        [];

/// {assessments:[{id,start,end,...}]}
Future<List<dynamic>> assessments() async =>
    Map<String, dynamic>.from(await _req('GET', '/assessments'))['assessments']
            as List<dynamic>? ??
        [];

/// {observations:[{id,timestamp,type,description}],allow_excuse,excuses}
Future<Map<String, dynamic>> attendance() async =>
    Map<String, dynamic>.from(await _req('GET', '/attendance'));
