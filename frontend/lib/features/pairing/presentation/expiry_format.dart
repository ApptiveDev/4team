/// 초대 숫자를 쓸 수 있는 시각. 예: 9월 26일 오후 9:10
///
/// 초대 화면과 공유 문구가 같이 쓴다.
String formatExpiry(DateTime time) {
  final local = time.toLocal();
  final period = local.hour < 12 ? '오전' : '오후';
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.month}월 ${local.day}일 $period $hour12:$minute';
}
