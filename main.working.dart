import 'dart:async';
import 'dart:html';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:flutter/material.dart';
//import 'package:permission_handler/permission_handler.dart';

const APP_ID = '36068ca60406491c8c188fc55362fcd8';
const Token =
    '00636068ca60406491c8c188fc55362fcd8IACpcO7+0vCcLExThB0N71EgQjZPSicchPg83FywrRPRvLiT6u4AAAAAEABD/MfDb6FyYgEAAQBvoXJi';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _joined = false;
  int _remoteUid = 0;
  bool _switch = false;
  bool screenSharing = false;
  late final RtcEngine _engine;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    super.dispose();
    _engine.destroy();
  }

  // Init the app
  Future<void> initPlatformState() async {
    //await [Permission.camera, Permission.microphone].request();

    // Create RTC client instance
    RtcEngineContext context = RtcEngineContext(APP_ID);
    _engine = await RtcEngine.createWithContext(context);
    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(ClientRole.Broadcaster);
    // Define event handling logic
    _engine.setEventHandler(RtcEngineEventHandler(
        joinChannelSuccess: (String channel, int uid, int elapsed) {
      print('joinChannelSuccess ${channel} ${uid}');
      setState(() {
        _joined = true;
      });
    }, userJoined: (int uid, int elapsed) {
      print('userJoined ${uid}');
      if (uid == 10) {
        return;
      }
      setState(() {
        _remoteUid = uid;
      });
    }, userOffline: (int uid, UserOfflineReason reason) {
      print('userOffline ${uid}');
      setState(() {
        _remoteUid = 0;
      });
    }));
    // Enable video
    await _engine.enableVideo();
    // Join channel with channel name as 123
    await _engine.joinChannel(Token, 'TEST', null, 0);
  }

  // Start Screenshare
  _startScreenShare() async {
    var windowId = 0;
    final helper = await _engine.getScreenShareHelper();
    print('sharingstarted');
    await helper.disableAudio();
    await helper.enableVideo();
    await helper.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await helper.setClientRole(ClientRole.Broadcaster);
    //helper.startScreenCaptureByScreenRect(Rectangle(
    //x: 0,
    //y: 0,
    //height: window.screen?.width,
    //width: window.screen?.height));

    await helper.startScreenCaptureByWindowId(windowId);
    setState(() {
      screenSharing = true;
    });
    await helper.joinChannel(Token, 'TEST', null, 10);
    print('sharinghappened');
  }

  // Stop Screenshare
  _stopScreenShare() async {
    final helper = await _engine.getScreenShareHelper();
    await helper.destroy().then((value) {
      setState(() {
        screenSharing = false;
      });
    }).catchError((err) {
      print('stopScreenShare $err');
    });
  }

  // Build UI
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter example app'),
        ),
        body: Stack(
          children: [
            Center(
              child: _switch ? _renderRemoteVideo() : _renderLocalPreview(),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _switch = !_switch;
                    });
                  },
                  child: Center(
                    child:
                        _switch ? _renderLocalPreview() : _renderRemoteVideo(),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: screenSharing ? _stopScreenShare : _startScreenShare,
              child: Text('${screenSharing ? 'Stop' : 'Start'} screen share'),
            ),
          ],
        ),
      ),
    );
  }

  // Local preview
  Widget _renderLocalPreview() {
    if (_joined) {
      return RtcLocalView.SurfaceView();
    } else {
      return const Text(
        'Please join channel first',
        textAlign: TextAlign.center,
      );
    }
  }

  // Remote preview
  Widget _renderRemoteVideo() {
    if (_remoteUid != 0) {
      return RtcRemoteView.SurfaceView(
        uid: _remoteUid,
        channelId: "TEST",
      );
    } else {
      return const Text(
        'Please wait remote user join',
        textAlign: TextAlign.center,
      );
    }
  }
}
