import 'dart:async';

import 'package:auto_orientation/auto_orientation.dart';
import 'package:chewie/src/chewie_player.dart';
import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/material_progress_bar.dart';
import 'package:chewie/src/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class MaterialControls extends StatefulWidget {
  const MaterialControls({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MaterialControlsState();
  }
}

class _MaterialControlsState extends State<MaterialControls> {
  VideoPlayerValue _latestValue;
  double _latestVolume;
  bool _hideStuff = true;
  Timer _hideTimer;
  Timer _showTimer;
  Timer _showAfterExpandCollapseTimer;
  bool _dragging = false;
  String subtitle = "";

  final barHeight = 36.0;
  final marginSize = 5.0;
  final exbarHeight = 36.0;

  VideoPlayerController controller;
  ChewieController chewieController;

  static Orientation prevOrientation;


  @override
  Widget build(BuildContext context) {
    bool isSmallerDevice = false;

    double width = MediaQuery.of(context).size.width;
    if (width < 330.0) {
      isSmallerDevice = true;
    }

    if (chewieController.showSubtitle) {
      String newSubtitle = controller.value.subtitle;
      if (subtitle != newSubtitle) {
        subtitle = newSubtitle;
      }
    }
    if (_latestValue.hasError) {
      return chewieController.errorBuilder != null
          ? chewieController.errorBuilder(
              context,
              chewieController.videoPlayerController.value.errorDescription,
            )
          : Center(
              child: Icon(
                Icons.error,
                color: Colors.white,
                size: 42,
              ),
            );
    }

    return GestureDetector(
      onTap: () => _cancelAndRestartTimer(),
      child: AbsorbPointer(
        absorbing: _hideStuff,
        child: Column(
          children: <Widget>[
            _latestValue != null &&
                        !_latestValue.isPlaying &&
                        _latestValue.duration == null ||
                    _latestValue.isBuffering
                ? const Expanded(
                    child: const Center(
                      child: const CircularProgressIndicator(),
                    ),
                  )
                : _buildHitArea(),
            Stack(
              alignment: AlignmentDirectional.bottomCenter,
              children: <Widget>[
                chewieController.showSubtitle && this.subtitle != ""
                    ? Container(
                        padding:
                            EdgeInsets.only(bottom: 2.0, left: 2.0, right: 2.0),
                        margin: EdgeInsets.only(bottom: 12.0),
                        color: Colors.black.withOpacity(0.7),
                        child: Text(
                          this.subtitle,
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ))
                    : Container(),
                _buildBottomBar(context, isSmallerDevice),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _showTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final _oldController = chewieController;
    chewieController = ChewieController.of(context);
    controller = chewieController.videoPlayerController;

    if (_oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  AnimatedOpacity _buildBottomBar(
    BuildContext context,
    bool isSmallerDevice,
  ) {
    final iconColor = Theme.of(context).textTheme.button.color;
    var orientation = MediaQuery.of(context).orientation;
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        height:  barHeight + exbarHeight,
        color: Color(0xA6ffffff),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              height: exbarHeight,
              // color: Colors.yellow,
              alignment: Alignment.bottomLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(),
                  _buildRewindButton(isSmallerDevice),
                  _buildFastRewindButton(isSmallerDevice),
                  Container(),
                  Container(),
                  _buildFastForwardButton(isSmallerDevice),
                  _buildForwardButton(isSmallerDevice),
                  Container(),
                  Container(),
                ],
              ),
            ),
            Container(
              height: barHeight,
              child: Row(
                children: <Widget>[
                  _buildPlayPause(controller),
                  chewieController.isLive
                      ? Expanded(child: const Text('LIVE'))
                      : _buildPosition(iconColor),
                  chewieController.isLive
                      ? const SizedBox()
                      : _buildProgressBar(),
                  chewieController.allowMuting
                      ? _buildMuteButton(controller)
                      : Container(),
                  //if (controller.subtitleSource != null || controller.value.subtitleList.length >0 )_buildCCButton(chewieController),
                  _buildCCButton(chewieController),
                  chewieController.allowFullScreen
                      ? _buildExpandButton(orientation)
                      : Container(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  GestureDetector _buildRewindButton(bool isSmallerDevice) {
    return GestureDetector(
      onTap: () {
        print("Rewind Button is clicked.");
        Duration moment = controller.value.position - Duration(seconds: 10);
        controller.seekTo(moment.compareTo(Duration(seconds: 0)) > 0
            ? moment
            : Duration(seconds: 0));
        _restartTimer();
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: Container(
          height: barHeight,
          alignment: Alignment.bottomLeft,
          margin: EdgeInsets.only(
              left: isSmallerDevice ? 0.0 : 8.0,
              right: isSmallerDevice ? 0.0 : 4.0),
          padding: EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Icon(
            Icons.arrow_back_ios,
          ),
        ),
      ),
    );
  }

  GestureDetector _buildFastRewindButton(bool isSmallerDevice) {
    return GestureDetector(
      onTap: () {
        print("Fast Rewind Button is clicked.");
        Duration moment = controller.value.position - Duration(seconds: 60);
        controller.seekTo(moment.compareTo(Duration(seconds: 0)) > 0
            ? moment
            : Duration(seconds: 0));
        _restartTimer();
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: Container(
          height: barHeight,
          alignment: Alignment.bottomLeft,
          margin: EdgeInsets.only(
              left: isSmallerDevice ? 0.0 : 8.0,
              right: isSmallerDevice ? 0.0 : 4.0),
          padding: EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Icon(
            Icons.fast_rewind,
          ),
        ),
      ),
    );
  }

  GestureDetector _buildFastForwardButton(bool isSmallerDevice) {
    return GestureDetector(
      onTap: () {
        print("Fast Forward Button is clicked.");
        controller.seekTo(controller.value.position + Duration(seconds: 60));
        _restartTimer();
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: Container(
          height: barHeight,
          alignment: Alignment.bottomLeft,
          margin: EdgeInsets.only(
              left: isSmallerDevice ? 0.0 : 8.0,
              right: isSmallerDevice ? 0.0 : 4.0),
          padding: EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Icon(
            Icons.fast_forward,
          ),
        ),
      ),
    );
  }

  GestureDetector _buildForwardButton(bool isSmallerDevice) {
    return GestureDetector(
      onTap: () {
        print("Forward Button is clicked.");
        controller.seekTo(controller.value.position + Duration(seconds: 10));
        _restartTimer();
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: Container(
          height: barHeight,
          alignment: Alignment.bottomLeft,
          margin: EdgeInsets.only(
              left: isSmallerDevice ? 0.0 : 8.0,
              right: isSmallerDevice ? 0.0 : 4.0),
          padding: EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Icon(
            Icons.arrow_forward_ios,
          ),
        ),
      ),
    );
  }

  GestureDetector _buildExpandButton(Orientation orientation) {
    print("orientation now $orientation");
    return GestureDetector(
      onTap: () {
        _onExpandCollapse(orientation);
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: Container(
          height: barHeight,
          margin: EdgeInsets.only(right: 12.0),
          padding: EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Center(
            child: Icon(
              chewieController.isFullScreen
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen,
            ),
          ),
        ),
      ),
    );
  }

  void minimizeFullScreen() {
    var isIos = Theme.of(context).platform == TargetPlatform.iOS;
    if (!chewieController.isFullScreen) {
      Navigator.of(context).pop();
      SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
      if (prevOrientation == Orientation.portrait) {
        AutoOrientation.portraitAutoMode();
      } else {
        AutoOrientation.fullAutoMode();
      }
    }
  }

  Expanded _buildHitArea() {
    return Expanded(
      child: GestureDetector(
        onTap: _latestValue != null && _latestValue.isPlaying
            ? _cancelAndRestartTimer
            : () {
                _playPause();

                setState(() {
                  _hideStuff = true;
                });
              },
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: AnimatedOpacity(
              opacity:
                  _latestValue != null && !_latestValue.isPlaying && !_dragging
                      ? 1.0
                      : 0.0,
              duration: Duration(milliseconds: 300),
              child: GestureDetector(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).dialogBackgroundColor,
                    borderRadius: BorderRadius.circular(48.0),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(Icons.play_arrow, size: 32.0),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildMuteButton(
    VideoPlayerController controller,
  ) {
    return GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();
        if (_latestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: ClipRect(
          child: Container(
            child: Container(
              height: barHeight,
              padding: EdgeInsets.only(
                left: 8.0,
                right: 8.0,
              ),
              child: Icon(
                (_latestValue != null && _latestValue.volume > 0)
                    ? Icons.volume_up
                    : Icons.volume_off,
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildCCButton(
    ChewieController chewieController,
  ) {
    return GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();
        chewieController.showSubtitle = !chewieController.showSubtitle;
        /*if (!controller.value.subtitleList.isEmpty && chewieController.showSubtitle == true) {
          if (controller.value.subtitleList.length == 1) {
            controller.setSubtitles(
                controller.value.subtitleList[0].trackIndex,
                controller.value.subtitleList[0].groupIndex
            );
          }
        }*/
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: ClipRect(
          child: Container(
            child: Container(
              height: barHeight,
              padding: EdgeInsets.only(
                left: 8.0,
                right: 8.0,
              ),
              child: Icon(
                Icons.closed_caption,
                color: chewieController.showSubtitle
                    ? Colors.black
                    : Colors.blueGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildPlayPause(VideoPlayerController controller) {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: EdgeInsets.only(left: 8.0, right: 4.0),
        padding: EdgeInsets.only(
          left: 12.0,
          right: 12.0,
        ),
        child: Icon(
          controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }

  Widget _buildPosition(Color iconColor) {
    var strTime = "";
    if (chewieController.isDVR) {
      strTime = _latestValue != null &&
              _latestValue.metadata != null &&
              _latestValue.metadata != ""
          ? _latestValue.metadata.substring(11, 19)
          : "";
    } else if (chewieController.startTime != null) {
      final position = _latestValue != null && _latestValue.position != null
          ? _latestValue.position
          : Duration.zero;
      final currentTime = chewieController.startTime.add(position);
      strTime =
          "${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}:${currentTime.second.toString().padLeft(2, '0')}";
    } else {
      final position = _latestValue != null && _latestValue.position != null
          ? _latestValue.position
          : Duration.zero;
      final duration = _latestValue != null && _latestValue.duration != null
          ? _latestValue.duration
          : Duration.zero;
      strTime = "${formatDuration(position)} / ${formatDuration(duration)}";
    }

    return Padding(
      padding: EdgeInsets.only(right: 24.0),
      child: Text(
        strTime,
        style: TextStyle(
          fontSize: 14.0,
        ),
      ),
    );
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      _hideStuff = false;
    });
  }

  void _restartTimer() {
    if (controller.value.isPlaying) {
      _hideTimer?.cancel();
      _startHideTimer();
    }
  }

  Future<Null> _initialize() async {
    controller.addListener(_updateState);

    _updateState();

    if ((controller.value != null && controller.value.isPlaying) ||
        chewieController.autoPlay) {
      _startHideTimer();
    }

    _showTimer = Timer(Duration(milliseconds: 200), () {
      setState(() {
        _hideStuff = false;
      });
    });
  }

//  void _onExpandCollapse() {
////    setState(() {
////      _hideStuff = true;
////
////      chewieController.toggleFullScreen();
////      _showAfterExpandCollapseTimer = Timer(Duration(milliseconds: 300), () {
////        setState(() {
////          _cancelAndRestartTimer();
////        });
////      });
////    });
////  }

  void _onExpandCollapse(Orientation orientation) {
    setState(() {
      _hideStuff = true;
      _showAfterExpandCollapseTimer = Timer(Duration(milliseconds: 300), () {
        setState(() {
          _cancelAndRestartTimer();
        });
      });
      if (!chewieController.isFullScreen) {
       prevOrientation = orientation;
      }
      print(
          "isFullScreen_prevOrientation : ${chewieController.isFullScreen} ${prevOrientation}");
      chewieController.toggleFullScreen();
    });
    minimizeFullScreen();
  }

  void _playPause() {
    setState(() {
      if (controller.value.isPlaying) {
        _hideStuff = false;
        _hideTimer?.cancel();
        controller.pause();
      } else {
        _cancelAndRestartTimer();

        if (!controller.value.initialized) {
          controller.initialize().then((_) {
            controller.play();
          });
        } else {
          controller.play();
        }
      }
    });
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _updateState() {
    setState(() {
      _latestValue = controller.value;
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: 20.0),
        child: MaterialVideoProgressBar(
          controller,
          onDragStart: () {
            setState(() {
              _dragging = true;
            });

            _hideTimer?.cancel();
          },
          onDragEnd: () {
            setState(() {
              _dragging = false;
            });

            _startHideTimer();
          },
          colors: chewieController.materialProgressColors ??
              ChewieProgressColors(
                  playedColor: Theme.of(context).accentColor,
                  handleColor: Theme.of(context).accentColor,
                  bufferedColor: Theme.of(context).backgroundColor,
                  backgroundColor: Theme.of(context).disabledColor),
        ),
      ),
    );
  }
}
