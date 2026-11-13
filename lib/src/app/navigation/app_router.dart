import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/bootstrap/presentation/bootstrap_page.dart';
import '../../features/checkin/presentation/daily_checkin_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/interrupt/presentation/daytime_interrupt_page.dart';
import '../../features/insights/presentation/insights_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/onboarding/presentation/vacuum_mode_page.dart';
import '../../features/restructure/presentation/restructure_hub_page.dart';
import '../../features/restructure/presentation/restructure_setup_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/sos/presentation/sos_page.dart';
import '../../features/vacuum/presentation/vacuum_focus_page.dart';
import '../state/app_controller.dart';
import '../widgets/app_shell.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final controller = ref.watch(appControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.bootstrap,
    refreshListenable: controller,
    redirect: (context, state) {
      final location = state.uri.path;

      if (controller.isInitializing) {
        return location == AppRoutes.bootstrap ? null : AppRoutes.bootstrap;
      }

      if (controller.errorMessage != null) {
        return location == AppRoutes.bootstrap ? null : AppRoutes.bootstrap;
      }

      if (location == AppRoutes.bootstrap) {
        return controller.hasCompletedInitialRestructure
            ? AppRoutes.home
            : AppRoutes.onboarding;
      }

      const unlockedBeforeSetup = {
        AppRoutes.onboarding,
        AppRoutes.vacuumMode,
        AppRoutes.vacuumFocus,
        AppRoutes.restructureSetup,
      };

      if (!controller.hasCompletedInitialRestructure &&
          !unlockedBeforeSetup.contains(location)) {
        return AppRoutes.onboarding;
      }

      if (controller.hasCompletedInitialRestructure &&
          (location == AppRoutes.bootstrap ||
              location == AppRoutes.onboarding ||
              location == AppRoutes.restructureSetup)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.bootstrap,
        builder: (context, state) => const BootstrapPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.vacuumMode,
        builder: (context, state) => const VacuumModePage(),
      ),
      GoRoute(
        path: AppRoutes.vacuumFocus,
        builder: (context, state) => const VacuumFocusPage(),
      ),
      GoRoute(
        path: AppRoutes.restructureSetup,
        builder: (context, state) => const RestructureSetupPage(),
      ),
      GoRoute(
        path: AppRoutes.dailyCheckin,
        builder: (context, state) => const DailyCheckinPage(),
      ),
      GoRoute(
        path: AppRoutes.daytimeInterrupt,
        builder: (context, state) => const DaytimeInterruptPage(),
      ),
      GoRoute(
        path: AppRoutes.sos,
        builder: (context, state) => const SosPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.restructureHub,
                builder: (context, state) => const RestructureHubPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.insights,
                builder: (context, state) => const InsightsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
