import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:music_player/music_player.dart';
import 'package:music_player/src/player/player_channel.dart';
import 'package:quiet/component/netease/counter.dart';
import 'package:quiet/component/netease/netease.dart';
import 'package:quiet/component/player/player.dart';
import 'package:quiet/pages/account/account.dart';
import 'package:scoped_model/scoped_model.dart';

import 'repository/mock.dart';

///配置一些通用用于测试的Widget上下文
class TestContext extends StatelessWidget {
  final Widget child;

  final MockLoginState account = MockLoginState();

  final likedSong = MockLikedSongList();

  TestContext({Key key, this.child}) : super(key: key) {
    when(account.isLogin).thenReturn(false);
    when(likedSong.ids).thenReturn([]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Material(
          child: ScopedModel<UserAccount>(
        model: account,
        child: ScopedModel<Counter>(
          model: Counter(account, null, null),
          child: ScopedModel<LikedSongList>(
            model: likedSong,
            child: ScopedModel<QuietModel>(
              model: _TestQuietModel(),
              child: DisableBottomController(child: child),
            ),
          ),
        ),
      )),
    );
  }
}

class _TestQuietModel extends Model implements QuietModel {
  @override
  MusicPlayer player = _FakerPlayer();
}

class _FakerPlayer extends ValueNotifier<MusicPlayerValue> with MediaControllerCallback implements MusicPlayer {
  _FakerPlayer() : super(MusicPlayerValue.none());

  @override
  MediaMetadata get metadata => null;

  @override
  get onServiceConnected => null;

  @override
  PlayList get playList => PlayList.empty();

  @override
  Future<void> playWithList(PlayList playList, {MediaMetadata metadata}) {
    return null;
  }

  @override
  PlaybackInfo get playbackInfo => null;

  @override
  PlaybackState get playbackState => PlaybackState.none();

  @override
  noSuchMethod(Invocation invocation) {
    //do nothing.
  }

  @override
  TransportControls get transportControls => const _FakeTransportControl();
}

class _FakeTransportControl implements TransportControls {
  const _FakeTransportControl();

  @override
  noSuchMethod(Invocation invocation) {
    //do nothing.
  }
}
