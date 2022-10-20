import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class Repository {
  Response? _response;
  final Dio _dio;
  final Box _box;

  Repository._instance({
    required Dio dio,
    required Box box,
  })  : _dio = dio,
        _box = box;

  factory Repository.getInstance(Dio dio, Box box) =>
      Repository._instance(dio: dio, box: box);

  static Options _getOptions(BoxProp token, Box box) {
    switch (token) {
      case BoxProp.at:
        return Options(headers: {"authorization": box.get(BoxProp.at.value)});
      case BoxProp.rt:
        return Options(headers: {"authorization": box.get(BoxProp.rt.value)});
      default:
        throw Exception('invalid');
    }
  }

  static const int minDelta = 13;
  static const debugData = {"email": "test10@email.com", "password": "testpwd"};

  FutureOr<void> _catchDioErr(VoidCallback f) {
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
    await _catchDioErr(
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
    await _catchDioErr(() async {
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
    await _catchDioErr(() async {
      await _dio.post(
        AuthPath.debug.getPath(),
        options: _getOptions(BoxProp.at, _box),
      );
    });
  }

  Future<void> signOut() async {
    if (_box.get(BoxProp.at.value) != null) {
      await _catchDioErr(() async {
        await _timeChecker();
        _response = await _dio
            .post(
          AuthPath.signout.getPath(),
          options: _getOptions(BoxProp.at, _box),
        )
            .whenComplete(() async {
          await Future.wait([
            _deleteAll(), //for debug
            _box.delete(BoxProp.rt.value),
          ]);
        });
      });
    }
  }

  Future<void> refreshToken() async {
    if (_box.get(BoxProp.rt.value) != null) {
      await _catchDioErr(() async {
        _response = await _dio
            .post(
              AuthPath.refresh.getPath(),
              options: _getOptions(BoxProp.rt, _box),
            )
            .whenComplete(() => _setToken());
      });
    }
  }

  Future<void> _timeChecker() async {
    final String old = _box.get(BoxProp.updatedAt.value);
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

  FutureOr<void> _setToken() async {
    final res = _response?.data.toString();
    if (res != null && res.isNotEmpty) {
      final subStr = res.split(',');
      final at = subStr.first.split(':').last.trim();
      final rt = subStr[1].split(':').last.trim();
      final updatedAt = subStr.last.split(' ').last.replaceAll('}', '');

      await Future.wait([
        _box.put(BoxProp.at.value, "Bearer $at"),
        _box.put(BoxProp.rt.value, "Bearer $rt"),
        _box.put(BoxProp.updatedAt.value, updatedAt),
      ]);
    }
  }
}

enum BoxProp {
  at(value: 'at'),
  rt(value: 'rt'),
  updatedAt(value: 'updatedAt');

  final String value;

  const BoxProp({
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
