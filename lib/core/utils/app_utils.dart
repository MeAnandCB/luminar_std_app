import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class AppUtils {
  static Future<String?> getAccessKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
}
