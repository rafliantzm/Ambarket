import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:ambarket_mobile/features/chat/presentation/providers/chat_provider.dart';
import 'package:ambarket_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:ambarket_mobile/features/chat/domain/models/conversation_model.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockMyConversationsNotifier extends MyConversationsNotifier {
  final List<ConversationModel> _conversations;
  MockMyConversationsNotifier(this._conversations);

  @override
  FutureOr<PaginatedConversationsState> build() {
    return PaginatedConversationsState(conversations: _conversations, hasMore: false);
  }
}

void main() {
  testWidgets('ChatListScreen shows empty state', (WidgetTester tester) async {
    final mockUser = User(
      id: 'user1',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(mockUser),
          myConversationsProvider.overrideWith(() => MockMyConversationsNotifier([])),
        ],
        child: const MaterialApp(
          home: ChatListScreen(),
        ),
      ),
    );

    // Initial loading is skipped because mock resolves synchronously
    await tester.pumpAndSettle();

    expect(find.text('Belum ada pesan.'), findsOneWidget);
  });

  testWidgets('ChatListScreen shows unread badge', (WidgetTester tester) async {
    final mockUser = User(
      id: 'user1',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );

    final chat = ConversationModel(
      id: 'conv1',
      productId: 'prod1',
      buyerId: 'user1',
      sellerId: 'user2',
      lastMessage: 'Hello',
      lastMessageAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(mockUser),
          myConversationsProvider.overrideWith(() => MockMyConversationsNotifier([chat])),
          unreadCountProvider('conv1').overrideWith((ref) => Stream.value(5)),
        ],
        child: const MaterialApp(
          home: ChatListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('5'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
  });
}
