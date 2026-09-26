import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class PlaybackSource {
  const PlaybackSource(this.url, {this.expiresAt});
  final String url;
  final DateTime? expiresAt;
}

/// B/C 공용. 만료 URL은 onRefresh로 서버에서 다시 받는다.
/// 사용: AudioPlaybackCard(source: PlaybackSource(url, expiresAt: expiresAt),
///   label: '부모님 목소리 듣기', onRefresh: reloadAudioSource)
/// reloadAudioSource는 today/stories를 재조회해 새 PlaybackSource를 반환한다.
class AudioPlaybackCard extends StatefulWidget {
  const AudioPlaybackCard({
    super.key,
    required this.source,
    this.label = '음성 듣기',
    this.onRefresh,
    this.enabled = true,
  });
  final PlaybackSource source;
  final String label;

  /// 만료 30초 전 또는 재생 오류 후 재시도할 때 호출한다.
  final Future<PlaybackSource> Function()? onRefresh;
  final bool enabled;

  @override
  State<AudioPlaybackCard> createState() => AudioPlaybackCardState();
}

class AudioPlaybackCardState extends State<AudioPlaybackCard>
    with WidgetsBindingObserver {
  final AudioPlayer _player = AudioPlayer();
  late PlaybackSource _source;
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<PlayerException>? _errorSubscription;
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _source = widget.source;
    WidgetsBinding.instance.addObserver(this);
    _stateSubscription = _player.playerStateStream.listen((_) {
      if (mounted) setState(() {});
    });
    _errorSubscription = _player.errorStream.listen((_) => _showError());
  }

  @override
  void didUpdateWidget(AudioPlaybackCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source.url != widget.source.url ||
        oldWidget.source.expiresAt != widget.source.expiresAt) {
      _generation++;
      _source = widget.source;
      _loaded = false;
      _loading = false;
      _error = null;
      unawaited(pause());
    }
    if (!widget.enabled) unawaited(pause());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(pause());
  }

  Future<void> pause() async {
    _generation++;
    if (mounted) setState(() => _loading = false);
    try {
      await _player.pause();
    } catch (_) {
      /* 종료 중 중복 정지 허용 */
    }
  }

  void _showError() {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loaded = false;
      _error = '소리를 불러오지 못했어요. 다시 눌러 주세요.';
    });
  }

  Future<void> _toggle() async {
    if (!widget.enabled || _loading) return;
    final generation = ++_generation;
    if (_player.playing &&
        _player.processingState != ProcessingState.completed) {
      await pause();
      return;
    }
    setState(() {
      _loading = true;
    });
    try {
      final expired =
          _source.expiresAt?.isBefore(
            DateTime.now().add(const Duration(seconds: 30)),
          ) ??
          false;
      if (expired || _error != null) {
        if (widget.onRefresh != null) {
          _source = await widget.onRefresh!();
          _loaded = false;
        } else if (expired) {
          throw StateError('재조회 필요');
        }
      }
      if (!mounted || generation != _generation || !widget.enabled) return;
      if (!_loaded) {
        // 인증 토큰을 signed URL의 외부 호스트로 보내지 않는다.
        final loading = _source.url.startsWith('asset:///')
            ? _player.setAsset(_source.url.substring(9))
            : _player.setUrl(_source.url);
        await loading.timeout(const Duration(seconds: 20));
        if (!mounted || generation != _generation || !widget.enabled) return;
        _loaded = true;
      }
      if (!mounted || generation != _generation || !widget.enabled) return;
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      if (!mounted || generation != _generation || !widget.enabled) return;
      setState(() {
        _loading = false;
        _error = null;
      });
      // play()는 재생이 끝나야 완료되므로 버튼 동작에서 기다리지 않는다.
      unawaited(_player.play().catchError((Object _) => _showError()));
    } catch (_) {
      if (generation == _generation) _showError();
    }
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stateSubscription?.cancel());
    unawaited(_errorSubscription?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  String _time(Duration value) =>
      '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final playing =
        _player.playing && _player.processingState != ProcessingState.completed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.label, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: widget.enabled && !_loading ? _toggle : null,
              icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              label: Text(
                _loading
                    ? '소리 불러오는 중'
                    : playing
                    ? '잠시 멈추기'
                    : _error != null
                    ? '다시 듣기'
                    : '듣기',
              ),
            ),
            StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, snapshot) => Text(
                '${_time(snapshot.data ?? Duration.zero)} / ${_time(_player.duration ?? Duration.zero)}',
                textAlign: TextAlign.center,
              ),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }
}
