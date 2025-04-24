import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:tencent_trtc_cloud/trtc_cloud.dart';
import 'package:tencent_trtc_cloud/trtc_cloud_def.dart';
import 'package:tencent_trtc_cloud/trtc_cloud_listener.dart';
import 'package:tencent_trtc_cloud/trtc_cloud_video_view.dart';
import 'package:tencent_trtc_cloud/tx_device_manager.dart';
// import 'package:tflite_audio/tflite_audio.dart';
import 'generate_test_user_sig.dart';

class VideoCallingPage extends StatefulWidget {
  final int roomId;
  final String userId;
  const VideoCallingPage({Key? key, required this.roomId, required this.userId})
      : super(key: key);

  @override
  VideoCallingPageState createState() => VideoCallingPageState();
}

class VideoCallingPageState extends State<VideoCallingPage> {
  Map<String, String> remoteUidSet = {};
  bool isFrontCamera = true;
  bool isOpenCamera = true;
  int? localViewId;

  bool isMuteLocalAudio = false;
  bool isSpeaker = true;
  late TRTCCloud trtcCloud;

  final isRecording = ValueNotifier<bool>(false);
  Stream<Map<dynamic, dynamic>>? result;

  final String model = 'assets/model.tflite';
  final String label = 'assets/labels.txt';
  final String inputType = 'rawAudio';
  final int sampleRate = 44100;
  final int bufferSize = 11016;
  final int numOfInferences = 5;

  void getResult() async {
    // result = TfliteAudio.startAudioRecognition(
    //   sampleRate: sampleRate,
    //   bufferSize: bufferSize,
    //   numOfInferences: 10000,
    // );
    // result?.listen((_) {}).onDone(() => isRecording.value = false);
  }

  Future<List<String>> fetchLabelList() async {
    List<String> labelList = [];
    await rootBundle.loadString(label).then((q) {
      for (String i in const LineSplitter().convert(q)) {
        labelList.add(i);
      }
    });
    return labelList;
  }

  String showResult(AsyncSnapshot snapshot, String key) =>
      snapshot.hasData ? snapshot.data[key].toString() : '0 ';

  @override
  void initState() {
    super.initState();
    startPushStream();
    // TfliteAudio.loadModel(
    //   inputType: inputType,
    //   model: model,
    //   label: label,
    // );
    // TfliteAudio.setSpectrogramParameters(nMFCC: 40, hopLength: 16384);

    getResult();
  }

  startPushStream() async {
    trtcCloud = (await TRTCCloud.sharedInstance())!;
    TRTCParams params = TRTCParams();
    params.sdkAppId = GenerateTestUserSig.sdkAppId;
    params.roomId = widget.roomId;
    params.userId = widget.userId;
    params.userSig = await GenerateTestUserSig.genTestSig(params.userId);
    trtcCloud.callExperimentalAPI(
        "{\"api\": \"setFramework\", \"params\": {\"framework\": 7, \"component\": 2}}");
    trtcCloud.enterRoom(params, TRTCCloudDef.TRTC_APP_SCENE_VIDEOCALL);
    
    TRTCVideoEncParam encParams = TRTCVideoEncParam();
    encParams.videoResolution = TRTCCloudDef.TRTC_VIDEO_RESOLUTION_640_360;
    encParams.videoBitrate = 550;
    encParams.videoFps = 15;
    trtcCloud.setVideoEncoderParam(encParams);

    trtcCloud.startLocalAudio(TRTCCloudDef.TRTC_AUDIO_QUALITY_SPEECH);
    trtcCloud.registerListener(onTrtcListener);
  }

  onTrtcListener(type, params) async {
    switch (type) {
      case TRTCCloudListener.onRemoteUserLeaveRoom:
        onRemoteUserLeaveRoom(params["userId"], params['reason']);
        break;
      case TRTCCloudListener.onUserVideoAvailable:
        onUserVideoAvailable(params["userId"], params['available']);
        break;
      /*case TRTCCloudListener.onUserSubStreamAvailable:
        break;
      case TRTCCloudListener.onError:
        break;
      case TRTCCloudListener.onWarning:
        break;
      case TRTCCloudListener.onEnterRoom:
        break;
      case TRTCCloudListener.onExitRoom:
        break;
      case TRTCCloudListener.onSwitchRole:
        break;
      case TRTCCloudListener.onRemoteUserEnterRoom:
        break;
      case TRTCCloudListener.onConnectOtherRoom:
        break;
      case TRTCCloudListener.onDisConnectOtherRoom:
        break;
      case TRTCCloudListener.onSwitchRoom:
        break;
      case TRTCCloudListener.onUserAudioAvailable:
        break;
      case TRTCCloudListener.onFirstVideoFrame:
        break;
      case TRTCCloudListener.onFirstAudioFrame:
        break;
      case TRTCCloudListener.onSendFirstLocalVideoFrame:
        break;
      case TRTCCloudListener.onSendFirstLocalAudioFrame:
        break;
      case TRTCCloudListener.onNetworkQuality:
        break;
      case TRTCCloudListener.onStatistics:
        break;
      case TRTCCloudListener.onConnectionLost:
        break;
      case TRTCCloudListener.onTryToReconnect:
        break;
      case TRTCCloudListener.onConnectionRecovery:
        break;
      case TRTCCloudListener.onSpeedTest:
        break;
      case TRTCCloudListener.onCameraDidReady:
        break;
      case TRTCCloudListener.onMicDidReady:
        break;
      case TRTCCloudListener.onUserVoiceVolume:
        break;
      case TRTCCloudListener.onRecvCustomCmdMsg:
        break;
      case TRTCCloudListener.onMissCustomCmdMsg:
        break;
      case TRTCCloudListener.onRecvSEIMsg:
        break;
      case TRTCCloudListener.onStartPublishing:
        break;
      case TRTCCloudListener.onStopPublishing:
        break;
      case TRTCCloudListener.onStartPublishCDNStream:
        break;
      case TRTCCloudListener.onStopPublishCDNStream:
        break;
      case TRTCCloudListener.onSetMixTranscodingConfig:
        break;
      case TRTCCloudListener.onMusicObserverStart:
        break;
      case TRTCCloudListener.onMusicObserverPlayProgress:
        break;
      case TRTCCloudListener.onMusicObserverComplete:
        break;
      case TRTCCloudListener.onSnapshotComplete:
        break;
      case TRTCCloudListener.onScreenCaptureStarted:
        break;
      case TRTCCloudListener.onScreenCapturePaused:
        break;
      case TRTCCloudListener.onScreenCaptureResumed:
        break;
      case TRTCCloudListener.onScreenCaptureStoped:
        break;
      case TRTCCloudListener.onDeviceChange:
        break;
      case TRTCCloudListener.onTestMicVolume:
        break;
      case TRTCCloudListener.onTestSpeakerVolume:
        break;*/
      default: break;
    }
  }

  onRemoteUserLeaveRoom(String userId, int reason) {
    setState(() {
      if (remoteUidSet.containsKey(userId)) {
        remoteUidSet.remove(userId);
      }
    });
  }

  onUserVideoAvailable(String userId, bool available) {
    if (available) {
      setState(() {
        remoteUidSet[userId] = userId;
      });
    }
    if (!available && remoteUidSet.containsKey(userId)) {
      setState(() {
        remoteUidSet.remove(userId);
      });
    }
  }

  destroyRoom() async {
    await trtcCloud.stopLocalAudio();
    await trtcCloud.stopLocalPreview();
    await trtcCloud.exitRoom();
    trtcCloud.unRegisterListener(onTrtcListener);
    await TRTCCloud.destroySharedInstance();
  }

  @override
  dispose() {
    destroyRoom();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<String> remoteUidList = remoteUidSet.values.toList();
    bool showMessage = false;
    return Stack(
      alignment: Alignment.topLeft,
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: remoteUidList.isEmpty?
          TRTCCloudVideoView(
            key: const ValueKey("LocalView"),
            viewType: TRTCCloudDef.TRTC_VideoView_TextureView,
            onViewCreated: (viewId) async {
              setState(() {
                localViewId = viewId;
              });
              trtcCloud.startLocalPreview(isFrontCamera, viewId);
            },
          ):
          TRTCCloudVideoView(
            key: ValueKey('RemoteView_${remoteUidList[0]}'),
            viewType: TRTCCloudDef.TRTC_VideoView_TextureView,
            onViewCreated: (viewId) async {
              trtcCloud.startRemoteView(remoteUidList[0],
                  TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_SMALL, viewId);
            },
          ),
        ),
        Positioned(
          right: 16,
          top: 16,
          width: 72,
          height: 370,
          child: GridView.builder(
            itemCount: remoteUidList.length,
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 0.6,
            ),
            itemBuilder: (BuildContext context, int index) {
              String userId = remoteUidList[index];
              return ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 72,
                  minWidth: 72,
                  maxHeight: 120,
                  minHeight: 120,
                ),
                child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: remoteUidList.length == 1?
                  TRTCCloudVideoView(
                    key: const ValueKey("LocalView"),
                    viewType: TRTCCloudDef.TRTC_VideoView_TextureView,
                    onViewCreated: (viewId) async {
                      setState(() {
                        localViewId = viewId;
                      });
                      trtcCloud.startLocalPreview(isFrontCamera, viewId);
                    },
                  ):
                  TRTCCloudVideoView(
                    key: ValueKey('RemoteView_$userId'),
                    viewType: TRTCCloudDef.TRTC_VideoView_TextureView,
                    onViewCreated: (viewId) async {
                      trtcCloud.startRemoteView(userId,
                          TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_SMALL, viewId);
                    },
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          height: 80,
          bottom: 0,
          width: MediaQuery.of(context).size.width,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF2B3467),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              )
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    bool newIsFrontCamera = !isFrontCamera;
                    TXDeviceManager deviceManager =
                        trtcCloud.getDeviceManager();
                    deviceManager.switchCamera(newIsFrontCamera);
                    setState(() => isFrontCamera = newIsFrontCamera);
                  },
                  child: const Icon(Ionicons.camera_reverse, color: Color(0xFFFCFFE7)),
                ),
                TextButton(
                  onPressed: () {
                    bool newIsOpenCamera = !isOpenCamera;
                    if (newIsOpenCamera) {
                      trtcCloud.startLocalPreview(isFrontCamera, localViewId);
                    } else {
                      trtcCloud.stopLocalPreview();
                    }
                    setState(() {
                      isOpenCamera = newIsOpenCamera;
                    });
                  },
                  child: isOpenCamera ?
                  const Icon(Ionicons.videocam, color: Color(0xFFFCFFE7),) :
                  const Icon(Ionicons.videocam_off, color: Color(0xFFFCFFE7),),
                ),
                TextButton(
                  onPressed: () {
                    bool newIsMuteLocalAudio = !isMuteLocalAudio;
                    trtcCloud.muteLocalAudio(newIsMuteLocalAudio);
                    setState(() {
                      isMuteLocalAudio = newIsMuteLocalAudio;
                    });
                  },
                  child:  isMuteLocalAudio ?
                  const Icon(Ionicons.mic_off, color: Color(0xFFFCFFE7)) :
                  const Icon(Ionicons.mic, color: Color(0xFFFCFFE7)),
                ),
                TextButton(
                  onPressed: () {
                    TXDeviceManager deviceManager =
                    trtcCloud.getDeviceManager();
                    bool newIsSpeaker = !isSpeaker;
                    if (newIsSpeaker) {
                      deviceManager.setAudioRoute(
                          TRTCCloudDef.TRTC_AUDIO_ROUTE_SPEAKER);
                    } else {
                      deviceManager.setAudioRoute(
                          TRTCCloudDef.TRTC_AUDIO_ROUTE_EARPIECE);
                    }
                    setState(() {
                      isSpeaker = newIsSpeaker;
                    });
                  },
                  child: isSpeaker ?
                  const Icon(Ionicons.volume_mute, color: Color(0xFFFCFFE7),) :
                  const Icon(Ionicons.volume_medium, color: Color(0xFFFCFFE7),),
                ),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Transform.rotate(
                      angle: 135 * (3.14 / 180),
                      child:const Icon(Ionicons.call, color: Color(0xFFC71E38)),
                    )
                ),
              ],
            ),
          ),
        ),
        Positioned(
          height: 40,
          width: 40,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<Map<dynamic, dynamic>>(
              stream: result,
              builder: (BuildContext context,
              AsyncSnapshot<Map<dynamic, dynamic>> inferenceSnapshot) {
                return FutureBuilder(
                  future: fetchLabelList(),
                  builder: (BuildContext context, AsyncSnapshot<List<String>> labelSnapshot) {
                    if (inferenceSnapshot.connectionState == ConnectionState.active ||
                        inferenceSnapshot.connectionState == ConnectionState.done) {
                      String currentLabel = showResult(
                          inferenceSnapshot, 'recognitionResult').split(" ")[1];
                      return Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: currentLabel == "ai" ? Colors.red : Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }
                    return const SizedBox();
                  });
              },
            ),
          ),
        ),
        showMessage ?
        Positioned(
          bottom: 64,
          height: 200,
            child: Column(children: [
          Container(
            margin: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 32,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF242424),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(width: MediaQuery.of(context).size.width - 32,child:Padding(
              padding: const EdgeInsets.all(32),
              child: Column(children: [
                const Text("We detected AI in the incoming voice.", style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    decoration: TextDecoration.none
                )),
                Row(mainAxisAlignment: MainAxisAlignment.end,children: [
                  ElevatedButton(
                    onPressed: () => setState(() => showMessage = false),
                    child: const Text("Dismiss"),
                  ),
                ]),
              ])
            ),
          ))
        ])) : const SizedBox()
      ],
    );
  }
}
