import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/pairing_repository.dart';
import 'expiry_format.dart';

/// 카톡 등으로 보낼 초대 문구. 부모님이 읽고 바로 따라 할 수 있게 쓴다.
String inviteShareMessage(Invitation invitation) {
  final code = invitation.inviteCode;
  final spaced = code.length == 6
      ? '${code.substring(0, 3)} ${code.substring(3)}'
      : code;
  return '[들려줘요] 초대 숫자: $spaced\n'
      '들려줘요 앱을 열고 "부모님"을 고른 뒤 이 숫자 6자리를 입력하시면 저와 연결돼요.\n'
      '(${formatExpiry(invitation.expiresAt)}까지 쓸 수 있어요)';
}

/// 휴대폰의 공유 창을 연다. 테스트에서는 보낸 문구를 기록하는 함수로 바꾼다.
final shareTextProvider = Provider<Future<void> Function(String text)>(
  (ref) =>
      (text) => SharePlus.instance.share(ShareParams(text: text)),
);
