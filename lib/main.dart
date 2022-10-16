import 'package:demo/hive/adapter/token-adapter.dart';
import 'package:demo/repository.dart';
import 'package:demo/styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(HiveTokensAdapter());
  await Hive.openBox('tokens');
  runApp(const ProviderScope(child: MyApp()));
}

final dioProvider = Provider<Repository>((ref) {
  return Repository.getInstance();
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
        path: '/',
        builder: (BuildContext context, GoRouterState state) => const Home(),
        routes: <GoRoute>[
          GoRoute(
            path: 'page2',
            builder: (BuildContext context, GoRouterState state) =>
                const SignedPage(),
            routes: [
              GoRoute(
                path: ':id',
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
    final Box box = Hive.box('tokens');
    return SafeArea(
      child: Scaffold(
        //when signed out, rt will be null
        body: box.get('rt') != null ? const SignedPage() : const NoSignedPage(),
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
                .then((_) => context.go('/page2')),
            child: Text('sign in'.toUpperCase())),
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
                  .then((_) => context.go('/')),
              child: const Text('out'),
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
              onPressed: () => context.go('/'), child: const Text('go Home')),
        ],
      ),
    );
  }
}
