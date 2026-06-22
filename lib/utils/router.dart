import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/auth/login_page.dart';
import '../pages/home.dart';
import '../pages/chat_room.dart';
import '../pages/group_chat_room.dart';
import '../pages/video_call.dart';
import '../pages/group_video_call.dart';
import '../pages/video_translate_modal.dart';
import '../pages/call_detail_page.dart';
import '../pages/contact_detail_page.dart';
import '../pages/group_detail_page.dart';

class _AuthNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;
  _AuthNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange
        .listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _authNotifier = _AuthNotifier();

final appRouter = GoRouter(
  initialLocation: '/login',
  refreshListenable: _authNotifier,
  redirect: (context, state) {
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    final goingToLogin = state.matchedLocation == '/login';
    if (!isLoggedIn && !goingToLogin) return '/login';
    if (isLoggedIn && goingToLogin) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (ctx, state) => const LoginPage()),
    GoRoute(path: '/home', builder: (ctx, state) => const HomePage()),
    GoRoute(
      path: '/chat/:chatId',
      builder: (ctx, state) => ChatRoomPage(chatId: state.pathParameters['chatId']!),
    ),
    GoRoute(
      path: '/group/:chatId',
      builder: (ctx, state) => GroupChatRoomPage(chatId: state.pathParameters['chatId']!),
    ),
    GoRoute(
      path: '/call/:chatId',
      builder: (ctx, state) {
        final q = state.uri.queryParameters;
        return VideoCallPage(
          chatId: state.pathParameters['chatId']!,
          isVideo: q['type'] != 'voice',
          isCaller: q['mode'] != 'callee',
          callRoomId: q['roomId'] ?? '',
          remoteUserId: q['remoteUserId'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/group-call/:chatId',
      builder: (ctx, state) => GroupVideoCallPage(chatId: state.pathParameters['chatId']!),
    ),
    GoRoute(
      path: '/video-translate/:messageId',
      builder: (ctx, state) => VideoTranslateModalPage(
        messageId: state.pathParameters['messageId']!,
        chatId: state.uri.queryParameters['chatId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/call-detail/:callId',
      builder: (ctx, state) => CallDetailPage(callId: state.pathParameters['callId']!),
    ),
    GoRoute(
      path: '/contact-detail/:userId',
      builder: (ctx, state) => ContactDetailPage(userId: state.pathParameters['userId']!),
    ),
    GoRoute(
      path: '/group-detail/:chatId',
      builder: (ctx, state) => GroupDetailPage(chatId: state.pathParameters['chatId']!),
    ),
  ],
);
