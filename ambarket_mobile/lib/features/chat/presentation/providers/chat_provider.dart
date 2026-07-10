import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/conversation_model.dart';
import '../../domain/models/message_model.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/repositories/supabase_chat_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return SupabaseChatRepository(ref.watch(supabaseClientProvider));
});

class PaginatedConversationsState {
  final List<ConversationModel> conversations;
  final bool hasMore;

  PaginatedConversationsState({
    required this.conversations,
    required this.hasMore,
  });
}

class MyConversationsNotifier
    extends AsyncNotifier<PaginatedConversationsState> {
  static const int _limit = 30;
  int _offset = 0;

  @override
  FutureOr<PaginatedConversationsState> build() async {
    return _fetchInitial();
  }

  Future<PaginatedConversationsState> _fetchInitial() async {
    _offset = 0;
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return PaginatedConversationsState(conversations: [], hasMore: false);
    }

    final repo = ref.watch(chatRepositoryProvider);
    final conversations = await repo.fetchMyConversations(
      user.id,
      offset: _offset,
      limit: _limit,
    );
    return PaginatedConversationsState(
      conversations: conversations,
      hasMore: conversations.length == _limit,
    );
  }

  Future<void> fetchMore() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore || state.isLoading) {
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return;
    }

    state = const AsyncLoading();
    try {
      _offset += _limit;
      final repo = ref.read(chatRepositoryProvider);
      final newConversations = await repo.fetchMyConversations(
        user.id,
        offset: _offset,
        limit: _limit,
      );

      state = AsyncData(
        PaginatedConversationsState(
          conversations: [...currentState.conversations, ...newConversations],
          hasMore: newConversations.length == _limit,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final myConversationsProvider =
    AsyncNotifierProvider<MyConversationsNotifier, PaginatedConversationsState>(
      () {
        return MyConversationsNotifier();
      },
    );

final conversationDetailProvider = FutureProvider.family
    .autoDispose<ConversationModel, String>((ref, conversationId) async {
      final repo = ref.watch(chatRepositoryProvider);
      return repo.fetchConversationDetail(conversationId);
    });

final messagesStreamProvider = StreamProvider.family
    .autoDispose<List<MessageModel>, String>((ref, conversationId) {
      final repo = ref.watch(chatRepositoryProvider);
      return repo.watchMessages(conversationId);
    });

final unreadCountProvider = StreamProvider.family.autoDispose<int, String>((
  ref,
  conversationId,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);

  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchUnreadCount(conversationId, user.id);
});

final totalUnreadChatCountProvider = StreamProvider.autoDispose<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);

  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchTotalUnreadCount(user.id);
});

final chatActionControllerProvider =
    AsyncNotifierProvider<ChatActionController, void>(() {
      return ChatActionController();
    });

class ChatActionController extends AsyncNotifier<void> {
  late final ChatRepository _repo;

  @override
  FutureOr<void> build() {
    _repo = ref.watch(chatRepositoryProvider);
  }

  Future<ConversationModel> createOrGetConversation(
    String productId,
    String buyerId,
    String sellerId, {
    String? offerId,
  }) async {
    state = const AsyncLoading();
    try {
      final conv = await _repo.createOrGetConversation(
        productId,
        buyerId,
        sellerId,
        offerId: offerId,
      );
      ref.invalidate(myConversationsProvider);
      state = const AsyncData(null);
      return conv;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<ConversationModel> createOrGetConversationFromOffer(
    String offerId,
  ) async {
    state = const AsyncLoading();
    try {
      final conv = await _repo.createOrGetConversationFromOffer(offerId);
      ref.invalidate(myConversationsProvider);
      state = const AsyncData(null);
      return conv;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> sendMessage(
    String conversationId,
    String receiverId,
    String message,
  ) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Silakan login terlebih dahulu.');

      await _repo.sendMessage(conversationId, user.id, receiverId, message);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> markAsRead(String conversationId) async {
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      await _repo.markConversationAsRead(conversationId, user.id);
    } catch (e) {
      // Background action, do not disrupt UI
    }
  }
}
