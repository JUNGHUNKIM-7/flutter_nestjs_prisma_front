import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class Repository {
  Repository._instance();
  factory Repository.getInstance() => Repository._instance();

  final Dio dio = Dio(
    BaseOptions(
      connectTimeout: 5000,
      receiveTimeout: 3000,
    ),
  );
  static const _root = "http://10.0.2.2:3000";
  static const _auth = "http://10.0.2.2:3000/auth";
  static final Box _box = Hive.box('tokens');
  static Options _getOptions(String type, Box box) {
    switch (type) {
      case 'at':
        return Options(headers: {"authorization": box.get('at')});
      case 'rt':
        return Options(headers: {"authorization": box.get('rt')});
      default:
        throw Exception('invalid');
    }
  }

  Response? _response;
  static final debugData = {"email": "test10@email.com", "password": "testpwd"};

  void _catchDioErr(VoidCallback f) {
    try {
      f();
    } on DioError catch (e) {
      throw e.message.toString();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  //@public
  Future<void> signup() async {
    _catchDioErr(
      () async {
        _response = await dio
            .post(
          '$_auth/signup',
          data: debugData,
        )
            .whenComplete(() {
          _setToken();
        });
      },
    );
  }

  //@public
  Future<void> signIn() async {
    _catchDioErr(() async {
      _response = await dio
          .post(
        '$_auth/signin',
        data: debugData,
      )
          .whenComplete(() {
        _setToken();
      });
    });
  }

  Future<void> _deleteAll() async {
    _catchDioErr(() async {
      await dio.post('$_auth/debug', options: _getOptions('at', _box));
    });
  }

  Future<void> signOut() async {
    if (_box.get('at') != null) {
      _catchDioErr(() async {
        await _timeChecker();
        _response = await dio
            .post('$_auth/signout', options: _getOptions('at', _box))
            .whenComplete(() {
          _deleteAll();
          _box.delete('rt');
        });

        if (_response?.statusCode == 200) {
          // go navigate home
        }
      });
    }
  }

  Future<void> refreshToken() async {
    if (_box.get('rt') != null) {
      _catchDioErr(() async {
        _response = await dio
            .post('$_auth/refresh', options: _getOptions('rt', _box))
            .whenComplete(() => _setToken());
        if (_response?.statusCode == 200) {}
      });
    }
  }

  Future<void> _timeChecker() async {
    final String old = _box.get('updatedAt');
    final DateTime deadline =
        DateTime.parse(old).add(const Duration(minutes: 13));
    final DateTime now = DateTime.now();

    // now < deadline(old + 10min) == -1
    // refresh => now == deadline(0) or now > deadline(1)
    switch (now.compareTo(deadline)) {
      case -1:
        return;
      default:
        await refreshToken();
    }
  }

  void _setToken() {
    final res = _response?.data.toString();
    if (res != null && res.isNotEmpty) {
      final subStr = res.split(',');
      final at = subStr.first.split(':').last.trim();
      final rt = subStr[1].split(':').last.trim();
      final updatedAt = subStr.last.split(' ').last.replaceAll('}', '');

      _box.put('at', "Bearer $at");
      _box.put('rt', "Bearer $rt");
      _box.put('updatedAt', updatedAt);
    }
  }
}
