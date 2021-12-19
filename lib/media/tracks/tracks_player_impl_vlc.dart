import 'dart:async';

import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/foundation.dart';
import 'package:quiet/extension.dart';
import 'package:quiet/repository.dart';

import 'track_list.dart';
import 'tracks_player.dart';

extension _SecondsToDuration on double {
  Duration toDuration() {
    return Duration(milliseconds: (this * 1000).round());
  }
}

class TracksPlayerImplVlc extends TracksPlayer {
  TracksPlayerImplVlc() {
    _player.playbackStream.listen((event) {
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      _onPlaybackStateChanged.notifyListeners();
      if (event.isCompleted) {
        skipToNext();
      }
    });
  }

  final _player = Player(
    id: 0,
    commandlineArguments: ['--no-video'],
  );

  var _trackList = const TrackList.empty();

  @override
  Duration? get bufferedPosition => _player.bufferingProgress.toDuration();

  @override
  Track? get current => _current.value;

  @override
  Duration? get duration => _player.position.duration;

  @override
  Future<Track?> getNextTrack() async {
    final index = _trackList.tracks.cast().indexOf(current);
    if (index == -1) {
      return _trackList.tracks.firstOrNull;
    }
    final nextIndex = index + 1;
    if (nextIndex >= _trackList.tracks.length) {
      return null;
    }
    return _trackList.tracks[nextIndex];
  }

  @override
  Future<Track?> getPreviousTrack() async {
    final index = _trackList.tracks.cast().indexOf(current);
    if (index == -1) {
      return _trackList.tracks.lastOrNull;
    }
    final previousIndex = index - 1;
    if (previousIndex < 0) {
      return null;
    }
    return _trackList.tracks[previousIndex];
  }

  @override
  Future<void> insertToNext(Track track) async {
    final index = _trackList.tracks.cast().indexOf(current);
    if (index == -1) {
      return;
    }
    final nextIndex = index + 1;
    if (nextIndex >= _trackList.tracks.length) {
      _trackList.tracks.add(track);
    } else {
      final next = _trackList.tracks[nextIndex];
      if (next != track) {
        _trackList.tracks.insert(nextIndex, track);
      }
    }
    // TODO notify track list changed.
  }

  @override
  bool get isBuffering => false;

  @override
  bool get isPlaying => _player.playback.isPlaying;

  final _onPlaybackStateChanged = ChangeNotifier();

  @override
  Listenable get onPlaybackStateChanged => _onPlaybackStateChanged;

  final _current = ValueNotifier<Track?>(null);

  @override
  Listenable get onTrackChanged => _current;

  @override
  Future<void> pause() async {
    _player.pause();
  }

  @override
  Future<void> play() async {
    _player.play();
  }

  @override
  Future<void> playFromMediaId(int trackId) async {
    stop();
    final item = _trackList.tracks.firstWhereOrNull((t) => t.id == trackId);
    if (item != null) {
      _playTrack(item);
    }
  }

  @override
  double get playbackSpeed => _player.general.rate;

  @override
  Duration? get position => _player.position.position;

  @override
  RepeatMode get repeatMode => RepeatMode.all;

  @override
  Future<void> seekTo(Duration position) async {
    _player.seek(position);
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    _player.setRate(speed);
  }

  @override
  Future<void> setRepeatMode(RepeatMode repeatMode) async {
    // TODO
  }

  @override
  void setTrackList(TrackList trackList) {
    stop();
    _trackList = trackList;
  }

  @override
  Future<void> setVolume(double volume) async {
    _player.setVolume(volume);
  }

  @override
  Future<void> skipToNext() async {
    final next = await getNextTrack();
    if (next != null) {
      _playTrack(next);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    final previous = await getPreviousTrack();
    if (previous != null) {
      _playTrack(previous);
    }
  }

  @override
  Future<void> stop() async {
    _player.stop();
  }

  @override
  TrackList get trackList => _trackList;

  @override
  double get volume => _player.general.volume;

  void _playTrack(Track track) {
    scheduleMicrotask(() async {
      final url = await neteaseRepository!.getPlayUrl(track.id);
      if (url.isError) {
        debugPrint('Failed to get play url: ${url.asError!.error}');
        return;
      }
      if (_current.value != track) {
        // skip play. since the track is changed.
        return;
      }
      _player.open(Media.network(url.asValue!.value), autoStart: true);
    });
    _current.value = track;
  }
}
