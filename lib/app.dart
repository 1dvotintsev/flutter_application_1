import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/collection/collection_screen.dart';
import 'screens/collection/plant_detail_screen.dart';
import 'screens/identify/identify_screen.dart';
import 'screens/identify/identify_result_screen.dart';
import 'screens/add_plant/add_plant_screen.dart';
import 'models/plant_identify_result.dart';
import 'models/species.dart';
import 'screens/species/species_detail_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/rooms_screen.dart';

final _authNotifier = _AuthNotifier();

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: _authNotifier,
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/collection',
            builder: (context, state) => const CollectionScreen(),
          ),
          GoRoute(
            path: '/identify',
            builder: (context, state) => const IdentifyScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/plant/add',
        builder: (context, state) =>
            AddPlantScreen(initialSpecies: state.extra as Species?),
      ),
      GoRoute(
        path: '/plant/:id',
        builder: (context, state) => PlantDetailScreen(
          plantId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/identify/result',
        builder: (context, state) => IdentifyResultScreen(
            result: state.extra as PlantIdentifyResult),
      ),
      GoRoute(
        path: '/species/:id',
        builder: (context, state) => SpeciesDetailScreen(
          speciesId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/rooms',
        builder: (context, state) => const RoomsScreen(),
      ),
    ],
  );
});

class PlantCareApp extends ConsumerWidget {
  const PlantCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'PlantCare',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4CAF50),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

class ScaffoldWithNavBar extends ConsumerWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  static const _tabs = ['/home', '/collection', '/identify', '/profile'];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabs.indexOf(location);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline =
        ref.watch(connectivityStreamProvider).valueOrNull ?? true;

    return Scaffold(
      body: Column(
        children: [
          if (!isOnline)
            Container(
              width: double.infinity,
              color: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Text(
                'Оффлайн-режим',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex(context),
        onTap: (index) => context.go(_tabs[index]),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: 'Сегодня',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.yard),
            label: 'Коллекция',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Определить',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}