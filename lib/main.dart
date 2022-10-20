import 'package:client/hive/adapter/token_adapter.dart';
import 'package:client/repository.dart';
import 'package:client/styles.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const boxName = 'tokens';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(HiveTokensAdapter());
  await Hive.openBox(boxName);
  runApp(const ProviderScope(child: MyApp()));
}

final dioInit = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: AuthPath.home.getPath(),
      connectTimeout: 5000,
      receiveTimeout: 3000,
    ),
  );
});

final dioProvider = Provider<Repository>((ref) {
  return Repository.getInstance(ref.watch(dioInit), Hive.box(boxName));
});

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      themeMode: ThemeMode.dark,
      darkTheme: Styles.seed(isDark: true).getThemeData,
      theme: Styles.seed(isDark: false).getThemeData,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }

  static final GoRouter _router = GoRouter(
    routes: <GoRoute>[
      GoRoute(
        path: Route.home.path,
        builder: (BuildContext context, GoRouterState state) => const Home(),
        routes: <GoRoute>[
          GoRoute(
            path: Route.page2.path,
            builder: (BuildContext context, GoRouterState state) =>
                const SignedPage(),
            routes: [
              GoRoute(
                path: Route.page2ById.path,
                builder: (BuildContext context, GoRouterState state) {
                  final id = state.params['id'] != null;
                  return NestedPage(
                      num: id ? int.parse(state.params['id']!) : null);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final Box box = Hive.box(boxName);
    return SafeArea(
      child: Scaffold(
        //when signed out, rt will be null
        body: box.get(BoxProp.rt.value) != null
            ? const SignedPage()
            : const NoSignedPage(),
      ),
    );
  }
}

class NoSignedPage extends HookConsumerWidget with Seed {
  const NoSignedPage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () async => await ref.watch(dioProvider).signup(),
          child: Text('sign up'.toUpperCase()),
        ),
        ElevatedButton(
          onPressed: () async => await ref
              .watch(dioProvider)
              .signIn()
              .catchError((e) => throw Exception(e.toString()))
              .then((_) => context.go(Route.page2.path)),
          child: Text(
            'sign in'.toUpperCase(),
          ),
        ),
      ],
    );
  }
}

class SignedPage extends HookConsumerWidget {
  const SignedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed: () async => await ref
                  .watch(dioProvider)
                  .signOut()
                  .catchError((e) => throw Exception(e.toString()))
                  .then((_) => context.go(Route.home.path)),
              child: Text(Route.home.getPath()),
            ),
          )
        ],
      ),
    );
  }
}

class NestedPage extends StatelessWidget {
  const NestedPage({super.key, this.num});

  final int? num;
  @override
  Widget build(BuildContext context) {
    //build data with email(get) -> backend, with token, data.findMany({})
    return Scaffold(
      body: Column(
        children: [
          Center(
            child: Text('$num'),
          ),
          ElevatedButton(
            onPressed: () => context.go(Route.home.path),
            child: Text(Route.home.getPath().toUpperCase()),
          ),
        ],
      ),
    );
  }
}

enum Route {
  home(path: '/', text: "home"),
  page2(path: 'page2', text: "page2"),
  page2ById(path: ':id', text: "page2");

  final String path;
  final String text;
  const Route({
    required this.path,
    required this.text,
  });
}

extension PathString on Route {
  String getPath([String? text]) {
    if (text != null) {
      switch (this) {
        default:
          return text;
      }
    } else {
      switch (this) {
        case Route.home:
          return Route.home.text;
        case Route.page2:
          return Route.page2.text;
        case Route.page2ById:
          return Route.page2ById.text;
      }
    }
  }
}
