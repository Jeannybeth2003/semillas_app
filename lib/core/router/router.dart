import 'package:go_router/go_router.dart';
import 'package:semillas_app/views/screens/curiara_travel_screen.dart';
import 'package:semillas_app/views/screens/ebook_screen.dart';
import 'package:semillas_app/views/screens/grandfather_screen.dart';
import 'package:semillas_app/views/screens/start_screen.dart';
import 'package:semillas_app/views/screens/village_screen.dart';
import 'package:semillas_app/views/screens/creation_screen.dart';

class AppRoutes {
  static const String start = '/';
  static const String village = '/village';
  static const String curiaraTravel = '/curiara-travel';
  static const String grandfather = '/grandfather';
  static const String ebook = '/ebook';
  static const String creation = '/creation';

  static final GoRouter router = GoRouter(
    initialLocation: start,
    routes: [
      GoRoute(
        path: '/creation',
        builder: (context, state) => const CreationScreen(),
      ),
      GoRoute(
        path: '/village/:leader/:village',
        builder: (context, state) {
          final leader = state.pathParameters['leader'] ?? 'Invitado';
          final village = state.pathParameters['village'] ?? 'Mi Aldea';
          return VillageScreen(leaderName: leader, villageName: village);
        },
      ),
      GoRoute(
        path: '/',
        name: 'start',
        builder: (context, state) => const StartScreen(),
      ),
      GoRoute(
        path: village,
        name: 'village',
        builder:
            (context, state) =>
                const VillageScreen(leaderName: '', villageName: ''),
      ),
      GoRoute(
        path: curiaraTravel,
        name: 'curiara-travel',
        builder: (context, state) => const CuriaraTravelScreen(),
      ),
      GoRoute(
        path: grandfather,
        name: 'grandfather',
        builder: (context, state) => const GrandfatherScreen(),
      ),
      GoRoute(
        path: ebook,
        name: 'ebook',
        builder: (context, state) => const EbookScreen(),
      ),
    ],
  );
}
