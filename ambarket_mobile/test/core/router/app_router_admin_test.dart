import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ambarket_mobile/core/router/app_router.dart';
import 'package:ambarket_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:ambarket_mobile/features/profile/domain/models/profile_model.dart';
import 'package:ambarket_mobile/features/auth/presentation/providers/auth_provider.dart';

void main() {
  testWidgets('Non-admin user trying to access /admin redirects to /', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockUser = ProfileModel(
      id: 'user1',
      name: 'Normal User',
      role: 'user',
      createdAt: DateTime.now(),
    );

    final mockSession = supabase.Session(
      accessToken: 'token',
      tokenType: 'bearer',
      user: supabase.User(
        id: 'user1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => Stream.value(
            supabase.AuthState(supabase.AuthChangeEvent.signedIn, mockSession),
          ),
        ),
        currentProfileProvider.overrideWith((ref) => mockUser),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, child) {
            final router = ref.watch(appRouterProvider);
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );

    await tester.pump();

    // Get the router directly from the container
    final router = container.read(appRouterProvider);

    // Try to navigate to admin
    router.go('/admin');
    await tester.pump();

    // Verify it redirects back to / (HomeScreen) or stays at /
    final lastMatch = router.routerDelegate.currentConfiguration.last;
    final location = lastMatch.matchedLocation;

    expect(location, isNot(equals('/admin')));
  });

  testWidgets('Admin user trying to access /admin succeeds', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockAdmin = ProfileModel(
      id: 'admin1',
      name: 'Admin User',
      role: 'admin',
      createdAt: DateTime.now(),
    );

    final mockSession = supabase.Session(
      accessToken: 'token',
      tokenType: 'bearer',
      user: supabase.User(
        id: 'admin1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => Stream.value(
            supabase.AuthState(supabase.AuthChangeEvent.signedIn, mockSession),
          ),
        ),
        currentProfileProvider.overrideWith((ref) => mockAdmin),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, child) {
            final router = ref.watch(appRouterProvider);
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );

    await tester.pump();

    // Get the router directly from the container
    final router = container.read(appRouterProvider);

    // Try to navigate to admin
    router.go('/admin');
    await tester.pump();

    // Verify the redirect logic didn't kick us out
    final lastMatch = router.routerDelegate.currentConfiguration.last;
    final location = lastMatch.matchedLocation;

    expect(location, equals('/admin'));
  });
}
