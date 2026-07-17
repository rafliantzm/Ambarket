import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:ambarket_mobile/features/chat/presentation/providers/chat_provider.dart';
import 'package:ambarket_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:ambarket_mobile/features/chat/domain/models/conversation_model.dart';
import 'package:ambarket_mobile/features/chat/domain/models/message_model.dart';

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

  testWidgets('ChatDetailScreen toggles composer action based on text', (
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

    expect(find.byIcon(Icons.emoji_emotions_outlined), findsNothing);
    expect(find.byIcon(Icons.attach_file_rounded), findsOneWidget);
    expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsNothing);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();

    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsNothing);
    expect(find.text('   '), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Halo');
    await tester.pump();

    expect(find.byIcon(Icons.send_rounded), findsOneWidget);
  });

  testWidgets('ChatDetailScreen keeps messages visible when keyboard is open', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final mockUser = User(
      id: 'user1',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: now.toIso8601String(),
    );

    final mockConversation = ConversationModel(
      id: 'conv1',
      productId: 'prod1',
      buyerId: 'user1',
      sellerId: 'user2',
      createdAt: now,
      updatedAt: now,
    );

    final messages = [
      MessageModel(
        id: 'msg1',
        conversationId: 'conv1',
        senderId: 'user2',
        receiverId: 'user1',
        message: 'Halo dari penjual',
        isRead: true,
        createdAt: now,
      ),
      MessageModel(
        id: 'msg2',
        conversationId: 'conv1',
        senderId: 'user1',
        receiverId: 'user2',
        message: 'Halo dari pembeli',
        isRead: true,
        createdAt: now.add(const Duration(minutes: 1)),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(mockUser),
          conversationDetailProvider(
            'conv1',
          ).overrideWith((ref) => Future.value(mockConversation)),
          messagesStreamProvider(
            'conv1',
          ).overrideWith((ref) => Stream.value(messages)),
        ],
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 760),
            viewInsets: EdgeInsets.only(bottom: 320),
          ),
          child: const MaterialApp(
            home: ChatDetailScreen(conversationId: 'conv1'),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Halo dari penjual'), findsOneWidget);
    expect(find.text('Halo dari pembeli'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('ChatDetailScreen renders document attachment messages', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final mockUser = User(
      id: 'user1',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: now.toIso8601String(),
    );

    final mockConversation = ConversationModel(
      id: 'conv1',
      productId: 'prod1',
      buyerId: 'user1',
      sellerId: 'user2',
      createdAt: now,
      updatedAt: now,
    );

    final attachment = ChatAttachment(
      type: 'document',
      url: 'https://example.com/warranty.pdf',
      fileName: 'kartu-garansi.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 12 * 1024,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(mockUser),
          conversationDetailProvider(
            'conv1',
          ).overrideWith((ref) => Future.value(mockConversation)),
          messagesStreamProvider('conv1').overrideWith(
            (ref) => Stream.value([
              MessageModel(
                id: 'msg1',
                conversationId: 'conv1',
                senderId: 'user2',
                receiverId: 'user1',
                message: attachment.toMessagePayload(),
                isRead: true,
                createdAt: now,
              ),
            ]),
          ),
        ],
        child: const MaterialApp(
          home: ChatDetailScreen(conversationId: 'conv1'),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('kartu-garansi.pdf'), findsOneWidget);
    expect(find.text('Dokumen - 12 KB'), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
  });
}
