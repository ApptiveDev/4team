import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:life_record/core/widgets/audio_playback_card.dart';

// 네이티브 코덱 대신 위젯의 요청·취소·재시도 동작을 검증한다.
class FakePlayer extends AudioPlayer {
  final states = StreamController<PlayerState>.broadcast();
  final errors = StreamController<PlayerException>.broadcast();
  final urls = <String>[];
  final assets = <String>[];
  bool active = false;
  int plays = 0;
  int pauses = 0;
  bool released = false;
  Object? loadError;
  Completer<void>? loadGate;
  Completer<void>? playGate;
  @override
  bool get playing => active;
  @override
  ProcessingState get processingState => ProcessingState.ready;
  @override
  Stream<PlayerState> get playerStateStream => states.stream;
  @override
  Stream<PlayerException> get errorStream => errors.stream;
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Duration? get duration => const Duration(seconds: 5);
  @override
  Future<Duration?> setUrl(
    String url, {
    Map<String, String>? headers,
    Duration? initialPosition,
    bool preload = true,
    dynamic tag,
  }) async {
    urls.add(url);
    await loadGate?.future;
    if (loadError != null) throw loadError!;
    return duration;
  }

  @override
  Future<Duration?> setAsset(
    String assetPath, {
    String? package,
    bool preload = true,
    Duration? initialPosition,
    dynamic tag,
  }) async {
    assets.add(assetPath);
    return duration;
  }

  @override
  Future<void> play() async {
    plays++;
    active = true;
    states.add(PlayerState(true, ProcessingState.ready));
    await playGate?.future;
  }

  @override
  Future<void> pause() async {
    pauses++;
    active = false;
    states.add(PlayerState(false, ProcessingState.ready));
  }

  @override
  Future<void> dispose() async {
    released = true;
    await states.close();
    await errors.close();
    await super.dispose();
  }
}

void main() {
  late FakePlayer player;
  setUp(() => player = FakePlayer());
  const fresh = PlaybackSource('https://example.test/fresh.m4a');
  PlaybackSource expired() =>
      PlaybackSource('https://example.test/old.m4a', expiresAt: DateTime(2000));
  Future<void> mount(
    WidgetTester tester, {
    PlaybackSource source = fresh,
    Future<PlaybackSource> Function()? refresh,
    bool enabled = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AudioPlaybackCard(
            source: source,
            onRefresh: refresh,
            enabled: enabled,
            playerFactory: () => player,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets('만료된 주소는 갱신한 주소로 한 번만 재생한다', (tester) async {
    var refreshes = 0;
    await mount(
      tester,
      source: expired(),
      refresh: () async {
        refreshes++;
        return fresh;
      },
    );
    await tester.tap(find.text('듣기'));
    await tester.pump();
    expect(refreshes, 1);
    expect(player.urls, [fresh.url]);
    expect(player.plays, 1);
    await close(tester);
    expect(player.released, isTrue);
  });
  testWidgets('갱신 실패 후 재시도하면 재생한다', (tester) async {
    var refreshes = 0;
    await mount(
      tester,
      source: expired(),
      refresh: () async {
        if (++refreshes == 1) throw StateError('network');
        return fresh;
      },
    );
    await tester.tap(find.text('듣기'));
    await tester.pump();
    expect(player.urls, isEmpty);
    expect(find.textContaining('소리를 불러오지 못했어요'), findsOneWidget);
    await tester.tap(find.text('다시 듣기'));
    await tester.pump();
    expect(player.plays, 1);
    expect(refreshes, 2);
    await close(tester);
  });
  testWidgets('재생 주소 로딩 실패 후 새 주소를 받아 재시도한다', (tester) async {
    player.loadError = StateError('load');
    var refreshes = 0;
    await mount(
      tester,
      refresh: () async {
        refreshes++;
        return const PlaybackSource('https://example.test/retry');
      },
    );
    await tester.tap(find.text('듣기'));
    await tester.pump();
    player.loadError = null;
    await tester.tap(find.text('다시 듣기'));
    await tester.pump();
    expect(refreshes, 1);
    expect(player.urls.last, 'https://example.test/retry');
    expect(player.plays, 1);
    await close(tester);
  });
  testWidgets('갱신 중 연속 탭은 요청을 중복하지 않는다', (tester) async {
    final gate = Completer<PlaybackSource>();
    var calls = 0;
    await mount(
      tester,
      source: expired(),
      refresh: () {
        calls++;
        return gate.future;
      },
    );
    await tester.tap(find.text('듣기'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(calls, 1);
    gate.complete(fresh);
    await tester.pump();
    expect(player.plays, 1);
    await close(tester);
  });
  testWidgets('갱신이 끝나지 않으면 20초 뒤 재시도를 제공한다', (tester) async {
    final gate = Completer<PlaybackSource>();
    await mount(tester, source: expired(), refresh: () => gate.future);
    await tester.tap(find.text('듣기'));
    await tester.pump(const Duration(seconds: 21));
    expect(find.text('다시 듣기'), findsOneWidget);
    expect(player.plays, 0);
    gate.complete(fresh);
    await tester.pump();
    expect(player.plays, 0);
    await close(tester);
  });
  testWidgets('백그라운드로 가면 정지하고 복귀해도 자동 재생하지 않는다', (tester) async {
    await mount(tester);
    await tester.tap(find.text('듣기'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(player.active, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(player.plays, 1);
    await close(tester);
  });
  testWidgets('로딩 중 비활성화되면 늦게 완료되어도 재생하지 않는다', (tester) async {
    player.loadGate = Completer<void>();
    await mount(tester);
    await tester.tap(find.text('듣기'));
    await tester.pump();
    await mount(tester, enabled: false);
    player.loadGate!.complete();
    await tester.pump();
    expect(player.plays, 0);
    await close(tester);
  });
  testWidgets('화면 종료 후 도착한 갱신 결과는 재생하지 않는다', (tester) async {
    final gate = Completer<PlaybackSource>();
    await mount(tester, source: expired(), refresh: () => gate.future);
    await tester.tap(find.text('듣기'));
    await tester.pump();
    await close(tester);
    gate.complete(fresh);
    await tester.pump();
    expect(player.urls, isEmpty);
    expect(player.plays, 0);
  });
  testWidgets('source 교체 후 오래된 갱신 결과가 새 주소를 덮어쓰지 않는다', (tester) async {
    final gate = Completer<PlaybackSource>();
    await mount(tester, source: expired(), refresh: () => gate.future);
    await tester.tap(find.text('듣기'));
    await tester.pump();
    await mount(
      tester,
      source: const PlaybackSource('https://example.test/new-answer'),
    );
    gate.complete(fresh);
    await tester.pump();
    await tester.tap(find.text('듣기'));
    await tester.pump();
    expect(player.urls, ['https://example.test/new-answer']);
    await close(tester);
  });
  testWidgets('이전 재생의 늦은 오류는 교체된 카드에 표시하지 않는다', (tester) async {
    player.playGate = Completer<void>();
    await mount(tester);
    await tester.tap(find.text('듣기'));
    await tester.pump();
    await mount(
      tester,
      source: const PlaybackSource('https://example.test/next'),
    );
    player.playGate!.completeError(StateError('old playback'));
    await tester.pump();
    expect(find.textContaining('소리를 불러오지 못했어요'), findsNothing);
    await close(tester);
  });
  testWidgets('asset 주소는 네트워크 대신 asset으로 로드한다', (tester) async {
    await mount(
      tester,
      source: const PlaybackSource('asset:///audio/question.wav'),
    );
    await tester.tap(find.text('듣기'));
    await tester.pump();
    expect(player.assets, ['audio/question.wav']);
    expect(player.urls, isEmpty);
    await close(tester);
  });
}
