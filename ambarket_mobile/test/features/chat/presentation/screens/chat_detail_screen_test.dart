import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:ambarket_mobile/features/chat/presentation/providers/chat_provider.dart';
import 'package:ambarket_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:ambarket_mobile/features/chat/domain/models/conversation_model.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('ChatDetailScreen shows empty state', (
    WidgetTester tester,
  ) async {
    final mockUser = User(
      id: 'user1',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );

    final mockConversation = ConversationModel(
      id: 'conv1',
      productId: 'prod1',
      buyerId: 'user1',
      sellerId: 'user2',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(mockUser),
          conversationDetailProvider(
            'conv1',
          ).overrideWith((ref) => Future.value(mockConversation)),
          messagesStreamProvider(
            'conv1',
          ).overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: ChatDetailScreen(conversationId: 'conv1'),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Belum ada pesan.\nMulai sapa sekarang!'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('ChatDetailScreen validates empty message', (
    WidgetTester tester,
  ) async {
    final mockUser = User(
      id: 'user1',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );

    final mockConversation = ConversationModel(
      id: 'conv1',
      productId: 'prod1',
      buyerId: 'user1',
      sellerId: 'user2',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(mockUser),
          conversationDetailProvider(
            'conv1',
          ).overrideWith((ref) => Future.value(mockConversation)),
          messagesStreamProvider(
            'conv1',
          ).overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: ChatDetailScreen(conversationId: 'conv1'),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    // Tap send without typing
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump(const Duration(seconds: 1));

    // Type spaces and tap send
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump(const Duration(seconds: 1));

    // Ensure it doesn't clear the field (meaning it returned early)
    // Actually, our code does NOT clear the field if it returns early!
    expect(find.text('   '), findsOneWidget);
  });
}
