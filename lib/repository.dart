import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class Repository {
  final Dio _dio;
  final Box _box;

  Repository._instance({
    required Dio dio,
    required Box box,
  })  : _dio = dio,
        _box = box;

  factory Repository.getInstance(Dio dio, Box box) =>
      Repository._instance(dio: dio, box: box);

  static Options _getOptions(BoxProps token, Box box) {
    switch (token) {
      case BoxProps.at:
        return Options(headers: {"authorization": box.get(BoxProps.at.value)});
      case BoxProps.rt:
        return Options(headers: {"authorization": box.get(BoxProps.rt.value)});
      default:
        throw Exception('invalid');
    }
  }

  Response? _response;
  static const int minDelta = 13;
  static final debugData = {"email": "test10@email.com", "password": "testpwd"};

  void _catchDioErr(VoidCallback f) {
    try {
      f();
    } on DioError catch (e) {
      throw "Err from Dio: ${e.message.toString()}";
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  //@public
  Future<void> signup() async {
    _catchDioErr(
      () async {
        _response = await _dio
            .post(
          AuthPath.signup.getPath(),
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
      _response = await _dio
          .post(
        AuthPath.signin.getPath(),
        data: debugData,
      )
          .whenComplete(() {
        _setToken();
      });
    });
  }

  Future<void> _deleteAll() async {
    _catchDioErr(() async {
      await _dio.post(
        AuthPath.debug.getPath(),
        options: _getOptions(BoxProps.at, _box),
      );
    });
  }

  Future<void> signOut() async {
    if (_box.get(BoxProps.at.value) != null) {
      _catchDioErr(() async {
        await _timeChecker();
        _response = await _dio
            .post(
          AuthPath.signout.getPath(),
          options: _getOptions(BoxProps.at, _box),
        )
            .whenComplete(() {
          _deleteAll();
          _box.delete(BoxProps.rt.value);
        });
      });
    }
  }

  Future<void> refreshToken() async {
    if (_box.get(BoxProps.rt.value) != null) {
      _catchDioErr(() async {
        _response = await _dio
            .post(
              AuthPath.refresh.getPath(),
              options: _getOptions(BoxProps.rt, _box),
            )
            .whenComplete(() => _setToken());
      });
    }
  }

  Future<void> _timeChecker() async {
    final String old = _box.get(BoxProps.updatedAt.value);
    final DateTime deadline =
        DateTime.parse(old).add(const Duration(minutes: minDelta));
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

      _box.put(BoxProps.at.value, "Bearer $at");
      _box.put(BoxProps.rt.value, "Bearer $rt");
      _box.put(BoxProps.updatedAt.value, updatedAt);
    }
  }
}

enum BoxProps {
  at(value: 'at'),
  rt(value: 'rt'),
  updatedAt(value: 'updatedAt');

  final String value;

  const BoxProps({
    required this.value,
  });
}

enum AuthPath {
  home(path: ""),
  signup(path: "signup"),
  signin(path: "signin"),
  signout(path: "signout"),
  refresh(path: "refresh"),
  debug(path: "debug");

  final String path;

  const AuthPath({
    required this.path,
  });
}

extension PathMaker on AuthPath {
  String getPath() {
    const String root = "http://10.0.2.2:3000/auth";
    switch (this) {
      case AuthPath.home:
        return root;
      case AuthPath.signup:
        return '$root/${AuthPath.signup.path}';
      case AuthPath.signin:
        return '$root/${AuthPath.signin.path}';
      case AuthPath.signout:
        return '$root/${AuthPath.signout.path}';
      case AuthPath.refresh:
        return '$root/${AuthPath.refresh.path}';
      case AuthPath.debug:
        return '$root/${AuthPath.debug.path}';
    }
  }
}
