import 'dart:ui';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:volume_controller/volume_controller.dart';

import '../core/constants/size_constants.dart';
import '../core/extension/size_extension.dart';
import '../core/init/notifier/audio_process_notifier.dart';
import '../widgets/album_widget.dart';
import '../widgets/blur_widget.dart';
import '../widgets/next_song_button_widget.dart';
import '../widgets/pause_button_widget.dart';
import '../widgets/play_button_widget.dart';
import '../widgets/previous_song_button_widget.dart';

class ControlPanelView extends StatefulWidget {
  final int selectedIndex;
  final List<SongInfo> songInfo;

  const ControlPanelView({Key key, @required this.songInfo, @required this.selectedIndex}) : super(key: key);

  @override
  _ControlPanelViewState createState() => _ControlPanelViewState();
}

class _ControlPanelViewState extends State<ControlPanelView> {
  AudioProcessNotifier _audioProcessNotifier;
  double _setVolumeValue = 0;

  @override
  void initState() {
    super.initState();
    VolumeController().getVolume().then((volume) {
      setState(() {
        _setVolumeValue = volume;
      });
    });
    _audioProcessNotifier = AudioProcessNotifier(songList: widget.songInfo, selectedIndex: widget.selectedIndex);
  }

  @override
  void dispose() {
    _audioProcessNotifier.dispose();
    VolumeController().removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: Container(
        height: context.getHeight,
        color: Theme.of(context).backgroundColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: appBar(),
              ),
            ),
            BlurBackgroundWidget(
              songInfo: widget.songInfo[widget.selectedIndex],
            ),
            blurFilter(),
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [SongArtworkWidget(songInfo: widget.songInfo[widget.selectedIndex]), songTextSection()],
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: context.paddingAllLow,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: context.paddingOnlyBottom(SizeConstants.LOW_VALUE),
                        child: volumeControl(),
                      ),
                      Padding(
                        padding: context.paddingOnlyBottom(SizeConstants.MEDIUM_VALUE),
                        child: _buildProgessBar(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildPreviousMusicButton(),
                          buildPlayOrPauseMusicButton(),
                          buildNextMusicButton(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  volumeControl() {
    return Row(
      children: [
        Flexible(
          child: Slider(
            activeColor: Theme.of(context).accentColor,
            inactiveColor: Colors.white30,
            min: 0,
            max: 1,
            onChanged: (double value) {
              _setVolumeValue = value;
              VolumeController().setVolume(_setVolumeValue);
              setState(() {});
            },
            value: _setVolumeValue,
          ),
        ),
        IconButton(
          onPressed: () {
            VolumeController().getVolume().then((volume) {
              if (volume > 0)
                VolumeController().muteVolume();
              else
                VolumeController().setVolume(0.33);
            });
          },
          icon: Icon(
            Icons.volume_off,
            color: Theme.of(context).accentColor,
          ),
        ),
      ],
    );
  }

  appBar() {
    return Row(
      children: [
        Expanded(
            child: Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back),
          ),
        )),
        Spacer()
      ],
    );
  }

  blurFilter() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
      child: Container(
        decoration: BoxDecoration(color: Colors.black87.withOpacity(0.1)),
      ),
    );
  }

  songTextSection() => Container(
      padding: context.paddingAllMedium,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Column(
          children: <Widget>[
            Text(
              widget.songInfo[widget.selectedIndex].title,
              style: Theme.of(context).textTheme.headline6,
              maxLines: 3,
              textAlign: TextAlign.center,
            ),
            Text(
              widget.songInfo[widget.selectedIndex].artist,
              style: Theme.of(context).textTheme.caption,
              maxLines: 1,
            ),
          ],
        ),
      ]));

  _buildProgessBar() {
    return ValueListenableBuilder<ProgressBarState>(
      valueListenable: _audioProcessNotifier.progressNotifier,
      builder: (_, value, __) => ProgressBar(
        thumbColor: Theme.of(context).accentColor,
        baseBarColor: Theme.of(context).primaryColorLight,
        progressBarColor: Theme.of(context).accentColor,
        progress: value.current,
        buffered: value.buffered,
        total: value.total,
        onSeek: _audioProcessNotifier.seek,
      ),
    );
  }

  buildPreviousMusicButton() {
    return PreviousSongButtonWidget(
        size: context.getHeight,
        onTap: () async {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => ControlPanelView(
              songInfo: widget.songInfo,
              selectedIndex: widget.selectedIndex != 0 ? widget.selectedIndex - 1 : widget.songInfo.length - 1,
            ),
          ));
        });
  }

  buildPlayOrPauseMusicButton() {
    return ValueListenableBuilder<ButtonState>(
      valueListenable: _audioProcessNotifier.buttonNotifier,
      builder: (context, value, child) {
        switch (value) {
          case ButtonState.paused:
            return PlayButtonWidget(size: context.getHeight, onTap: _audioProcessNotifier.play);
            break;
          case ButtonState.playing:
            return PauseButtonWidget(size: context.getHeight, onTap: _audioProcessNotifier.pause);
            break;
          default:
        }

        return PauseButtonWidget(
            size: context.getHeight,
            onTap: () async {
              _audioProcessNotifier.pause();
              setState(() {});
            });
      },
    );
  }

  buildNextMusicButton() {
    return NextSongButtonWidget(
        size: context.getHeight,
        onTap: () async {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => ControlPanelView(
              songInfo: widget.songInfo,
              selectedIndex: widget.selectedIndex != widget.songInfo.length - 1 ? widget.selectedIndex + 1 : 0,
            ),
          ));
        });
  }
}
