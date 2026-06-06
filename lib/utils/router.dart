import 'package:go_router/go_router.dart';
import '../pages/launch1.dart';
import '../pages/launch2.dart';
import '../pages/launch3.dart';
import '../pages/home.dart';
import '../pages/chat_room.dart';
import '../pages/group_chat_room.dart';
import '../pages/video_call.dart';
import '../pages/group_video_call.dart';
import '../pages/video_translate_modal.dart';
import '../pages/call_detail_page.dart';
import '../pages/contact_detail_page.dart';
import '../pages/group_detail_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (ctx, state) => const Launch1Page()),
    GoRoute(path: '/launch2', builder: (ctx, state) => const Launch2Page()),
    GoRoute(path: '/launch3', builder: (ctx, state) => const Launch3Page()),
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
      builder: (ctx, state) => VideoCallPage(
        chatId: state.pathParameters['chatId']!,
        isVideo: state.uri.queryParameters['type'] != 'voice',
      ),
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
      builder: (ctx, state) => ContactDetailPage(
        userId: state.pathParameters['userId']!,
        chatId: state.uri.queryParameters['chatId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/group-detail/:chatId',
      builder: (ctx, state) => GroupDetailPage(chatId: state.pathParameters['chatId']!),
    ),
  ],
);
