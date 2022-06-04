import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vbs_shared/vbs_shared.dart';
import 'package:http/http.dart' as http;

final api = API();

class API {
  String? token;
  String admin = 'none';

  Future <String> sendMessage({required BuildContext context,
    required String path,
    String method = 'get',
    String body  = ''}
    ) async {

    // load the token
    if(token == null) {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      if (token == null) {
        api.token = "";
      } else {
        api.token = token;
      }
    }

    var url =
    Uri.http('localhost:8080', path);
    var response;
    if(method == 'get') {
      response = await http.get(url, headers: {'authorization': token!});
    } else {
      response = await http.post(url, headers: {'authorization': token!}, body: body);
    }
    if(response.statusCode == 403) {
      Navigator.pushNamed(context, '/login');
      throw Exception('You need to log in');
    }
    return response.body;
  }

  Future <List<Group>> loadGroups(context) async {
    var response = await sendMessage(context: context, path: '/groupNames');
    var groups = Group.fromJSONList(response);
    return groups;
  }

  Future <List<Group>> getGroupName(context, int groupID) async {
    var response = await sendMessage(context: context, path: '/getGroupName/$groupID');
    var groups = Group.fromJSONList(response);
    return groups;
  }

  Future<GroupData> loadKids(int groupID, context, Date today) async {
    var response = await sendMessage(context: context, path: '/group/$groupID/${today.makeString()}');
    var kids = GroupData.fromJSONObject(jsonDecode(response));
    return kids;
  }

  Future<List<Kid>> loadAllKids(context) async {
    var response = await sendMessage(context: context, path: '/kidNames');
    List<dynamic> jsonList = jsonDecode(response);
    List<Kid> list = [];
    for(var jsonKid in jsonList) {
      list.add(Kid.fromJSONObject(jsonKid));
    }
    return list;
  }

  Future<List<Kid>> loadSearchKids(context, String search) async {
    var response = await sendMessage(context: context, path: '/kidSearch/$search');
    List<dynamic> jsonList = jsonDecode(response);
    List<Kid> list = [];
    for(var jsonKid in jsonList) {
      list.add(Kid.fromJSONObject(jsonKid));
    }
    return list;
  }

  Future updateAttendance(context, Attendance attendance) async {
    var response = await sendMessage(
        context: context,
        method: 'post',
        path: 'updateAttendance',
        body: jsonEncode(attendance.toJSON())
    );
  }

  Future addKid(context, AddKid kid) async {
    var response = await sendMessage(
        context: context,
        method: 'post',
        path: 'addKid',
        body: jsonEncode(kid.toJSON())
    );
  }

  get isLoggedIn {
    if(token == null || token!.isEmpty) {
      return false;
    } else {
      return true;
    }
  }
}

class Date {
  late int year;
  late int month;
  late int day;

  Date({required this.year, required this.month, required this.day});

  String makeString() {
    return '${year.toString()}-${month.toString()}-${day.toString()}';
  }

  Date.today() {
    var now = DateTime.now();
    year = now.year;
    month = now.month;
    day = now.day;
  }
}