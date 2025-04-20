import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:tencent_trtc_cloud/trtc_cloud.dart';
import 'package:tencent_trtc_cloud/trtc_cloud_def.dart';
import 'package:tencent_trtc_cloud/trtc_cloud_listener.dart';
import 'package:tencent_trtc_cloud/tx_device_manager.dart';
// import 'package:tflite_audio/tflite_audio.dart';
import 'generate_test_user_sig.dart';
import 'package:path_provider/path_provider.dart';

class CustomRemoteInfo {
  int volume = 0;
  int quality = 0;
  final String userId;
  CustomRemoteInfo(this.userId, {this.volume = 0, this.quality = 0});
}

class AudioCallingPage extends StatefulWidget {
  final int roomId;
  final String userId;
  const AudioCallingPage({Key? key, required this.roomId, required this.userId})
      : super(key: key);

  @override
  AudioCallingPageState createState() => AudioCallingPageState();
}

class AudioCallingPageState extends State<AudioCallingPage> {
  Map<String, CustomRemoteInfo> remoteInfoDictionary = {};
  Map<String, String> remoteUidSet = {};
  bool isSpeaker = true;
  bool isMuteLocalAudio = false;
  late TRTCCloud cloud;

  final isRecording = ValueNotifier<bool>(false);
  Stream<Map<dynamic, dynamic>>? result;

  final String model = 'assets/model.tflite';
  final String label = 'assets/labels.txt';
  final String inputType = 'rawAudio';
  final int sampleRate = 44100;
  final int bufferSize = 11016;
  final int numOfInferences = 5;

  // void getResult() async {
  //   result = TfliteAudio.startAudioRecognition(
  //     sampleRate: sampleRate,
  //     bufferSize: bufferSize,
  //     numOfInferences: 10000,
  //   );
  //   result?.listen((_) {}).onDone(() => isRecording.value = false);
  // }

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
    //
    // getResult();
  }

  startPushStream() async {
    cloud = (await TRTCCloud.sharedInstance())!;
    TRTCParams params = TRTCParams();
    params.sdkAppId = GenerateTestUserSig.sdkAppId;
    params.roomId = widget.roomId;
    params.userId = widget.userId;
    params.role = TRTCCloudDef.TRTCRoleAnchor;
    params.userSig = await GenerateTestUserSig.genTestSig(params.userId);
    cloud.callExperimentalAPI(
        "{\"api\": \"setFramework\", \"params\": {\"framework\": 7, \"component\": 2}}");
    cloud.enterRoom(params, TRTCCloudDef.TRTC_APP_SCENE_AUDIOCALL);
    cloud.startLocalAudio(TRTCCloudDef.TRTC_AUDIO_QUALITY_SPEECH);
    cloud.enableAudioVolumeEvaluation(1000);

    cloud.registerListener(onTrtcListener);

    Directory d = await getApplicationDocumentsDirectory();
    cloud.startAudioRecording(TRTCAudioRecordingParams(
      filePath: "${d.path}$remoteUidSet.wav",
    ));
  }

  onTrtcListener(type, params) async {
    switch (type) {
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
        onRemoteUserEnterRoom(params);
        break;
      case TRTCCloudListener.onRemoteUserLeaveRoom:
        onRemoteUserLeaveRoom(params["userId"], params['reason']);
        break;
      case TRTCCloudListener.onConnectOtherRoom:
        break;
      case TRTCCloudListener.onDisConnectOtherRoom:
        break;
      case TRTCCloudListener.onSwitchRoom:
        break;
      case TRTCCloudListener.onUserVideoAvailable:
        break;
      case TRTCCloudListener.onUserSubStreamAvailable:
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
        onNetworkQuality(params);
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
        onUserVoiceVolume(params);
        break;
      case TRTCCloudListener.onRecvCustomCmdMsg:
        break;
      case TRTCCloudListener.onMissCustomCmdMsg:
        break;
    }
  }

  destroyRoom() async {
    await cloud.stopLocalAudio();
    await cloud.exitRoom();
    cloud.unRegisterListener(onTrtcListener);
    await TRTCCloud.destroySharedInstance();
  }

  @override
  dispose() {
    destroyRoom();
    super.dispose();
  }

  onRemoteUserEnterRoom(String userId) {
    setState(() {
      remoteUidSet[userId] = userId;
      remoteInfoDictionary[userId] = CustomRemoteInfo(userId);
    });
  }

  onRemoteUserLeaveRoom(String userId, int reason) {
    setState(() {
      if (remoteUidSet.containsKey(userId)) {
        setState(() {
          remoteUidSet.remove(userId);
        });
      }
      if (remoteInfoDictionary.containsKey(userId)) {
        setState(() {
          remoteInfoDictionary.remove(userId);
        });
      }
    });
  }

  onNetworkQuality(params) {
    List<dynamic> list = params["remoteQuality"] as List<dynamic>;
    for (var item in list) {
      int quality = int.tryParse(item["quality"].toString())!;
      if (item['userId'] != null && item['userId'] != "") {
        String userId = item['userId'];
        if (remoteInfoDictionary.containsKey(userId)) {
          setState(() {
            remoteInfoDictionary[userId]!.quality = quality;
          });
        }
      }
    }
  }

  onUserVoiceVolume(params) {
    List<dynamic> list = params["userVolumes"] as List<dynamic>;
    for (var item in list) {
      int volume = int.tryParse(item["volume"].toString())!;
      if (item['userId'] != null && item['userId'] != "") {
        String userId = item['userId'];
        if (remoteInfoDictionary.containsKey(userId)) {
          setState(() {
            remoteInfoDictionary[userId]!.volume = volume;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> remoteUidList = remoteUidSet.values.toList();
    List<CustomRemoteInfo> remoteInfoList =
        remoteInfoDictionary.values.toList();
    return Stack(children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
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
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GridView.builder(
                itemCount: remoteUidList.length,
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  childAspectRatio: 1.5,
                ),
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF242627),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Stack(children: [
                      Positioned(
                          right: 0,
                          child: Icon(
                              remoteInfoList[index].volume > 75 ?
                              Ionicons.volume_high_outline :
                              remoteInfoList[index].volume > 50 ?
                              Ionicons.volume_medium_outline :
                              remoteInfoList[index].volume > 25 ?
                              Ionicons.volume_low_outline :
                              Ionicons.volume_off_outline
                          )),
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Icon(Ionicons.person_circle, size: 64),
                        ],
                      ),
                    ]),
                  );
                },
              ),
            ),
          ),
          const SizedBox(
            height: 45,
          ),
          Container(
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
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () async {
                    TXDeviceManager deviceManager = cloud.getDeviceManager();
                    bool newIsSpeaker = !isSpeaker;
                    if (newIsSpeaker) {
                      deviceManager
                          .setAudioRoute(TRTCCloudDef.TRTC_AUDIO_ROUTE_SPEAKER);
                    } else {
                      deviceManager
                          .setAudioRoute(TRTCCloudDef.TRTC_AUDIO_ROUTE_EARPIECE);
                    }
                    setState(() {
                      isSpeaker = newIsSpeaker;
                    });
                  },
                  child: !isSpeaker ?
                  const Icon(Ionicons.volume_mute_outline, color: Color(0xFFFCFFE7)) :
                  const Icon(Ionicons.volume_medium_outline, color: Color(0xFFFCFFE7)),
                ),
                TextButton(
                  onPressed: () {
                    bool newIsMuteLocalAudio = !isMuteLocalAudio;
                    if (newIsMuteLocalAudio) {
                      cloud.muteLocalAudio(true);
                    } else {
                      cloud.muteLocalAudio(false);
                    }
                    setState(() {
                      isMuteLocalAudio = newIsMuteLocalAudio;
                    });
                  },
                  child: isMuteLocalAudio ?
                  const Icon(Ionicons.mic_off_outline, color: Color(0xFFFCFFE7)) :
                  const Icon(Ionicons.mic_outline, color: Color(0xFFFCFFE7)),
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
        ],
      )
    ]);
  }
}
