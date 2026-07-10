import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:ambarket_mobile/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:ambarket_mobile/features/profile/domain/models/profile_model.dart';
import 'package:ambarket_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:ambarket_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Profile Features Tests', () {
    testWidgets('ProfileScreen renders loading and then profile data', (
      WidgetTester tester,
    ) async {
      final mockProfile = ProfileModel(
        id: '123',
        name: 'Test User',
        username: 'testuser',
        role: 'user',
        location: 'Jakarta',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWith((ref) => mockProfile),
            currentUserProvider.overrideWith(
              (ref) => const User(
                id: '123',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: '2026-07-01T00:00:00Z',
                email: 'test@example.com',
              ),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('@testuser'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('Jakarta'), findsOneWidget);
      expect(find.text('Edit Profil'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);
    });

    testWidgets('EditProfileScreen renders form fields', (
      WidgetTester tester,
    ) async {
      final mockProfile = ProfileModel(
        id: '123',
        name: 'Test User',
        username: 'testuser',
        role: 'user',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWith((ref) => mockProfile),
          ],
          child: const MaterialApp(home: EditProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(6));
      expect(find.text('Save Profile'), findsOneWidget);

      // Values should be populated
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('testuser'), findsOneWidget);
    });
  });
}
