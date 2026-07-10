import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:ambarket_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:ambarket_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:ambarket_mobile/features/profile/domain/models/profile_model.dart';
import 'package:ambarket_mobile/features/auth/presentation/providers/auth_provider.dart';

void main() {
  testWidgets('ProfileScreen hides Admin Dashboard menu for normal user', (
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentProfileProvider.overrideWith((ref) => mockUser),
          currentUserProvider.overrideWith(
            (ref) => supabase.User(
              id: 'user1',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
          ),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('Admin Dashboard'), findsNothing);
  });

  testWidgets('ProfileScreen shows Admin Dashboard menu for admin user', (
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentProfileProvider.overrideWith((ref) => mockAdmin),
          currentUserProvider.overrideWith(
            (ref) => supabase.User(
              id: 'admin1',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
          ),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );

    await tester.pump();

    // Verify Admin Dashboard menu is visible
    expect(find.text('Admin Dashboard'), findsOneWidget);
    // Verify Admin Badge is visible next to name
    expect(find.text('ADMIN'), findsWidgets);
  });
}
