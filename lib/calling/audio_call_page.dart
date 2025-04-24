import 'dart:io';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:tencent_trtc_cloud/trtc_cloud.dart';
import 'package:tencent_trtc_cloud/trtc_cloud_def.dart';
import 'package:tencent_trtc_cloud/trtc_cloud_listener.dart';
import 'package:tencent_trtc_cloud/tx_device_manager.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import '../helper/audio_classification_helper.dart';
import 'generate_test_user_sig.dart';

class CustomRemoteInfo {
  int volume = 0;
  int quality = 0;
  final String userId;
  CustomRemoteInfo(this.userId, {this.volume = 0, this.quality = 0});
}

class AudioCallingPage extends StatefulWidget {
  final String roomId;
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
  final audioClassificationResult = ValueNotifier<String>('unknown 0%');

  // Audio classification helper
  AudioClassificationHelper? _audioClassificationHelper;
  bool _modelLoaded = false;

  // Audio recording related variables
  FlutterSoundRecorder? _audioRecorder;
  final int sampleRate = 44100;
  Timer? _classificationTimer;
  FlutterSoundPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    startPushStream();
    _initAudioClassification();
    _initAudioSystem();
  }

  Future<void> _initAudioClassification() async {
    try {
      _audioClassificationHelper = AudioClassificationHelper();
      await _audioClassificationHelper!.initHelper();
      _modelLoaded = true;
      print('TFLite model loaded successfully');
    } catch (e) {
      print('Failed to load TFLite model: $e');
    }
  }

  Future<void> _initAudioSystem() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      print('Microphone permission denied');
      return;
    }

    // Initialize audio recorder
    _audioRecorder = FlutterSoundRecorder();
    await _audioRecorder!.openRecorder();

    // Initialize audio player for potential debugging
    _audioPlayer = FlutterSoundPlayer();
    await _audioPlayer!.openPlayer();

    // Start periodic audio classification
    _startAudioClassification();
  }

  void _startAudioClassification() {
    _classificationTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!_modelLoaded || _audioRecorder == null || _audioClassificationHelper == null) return;

      // Create temporary file for audio sample
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/audio_sample.wav';

      try {
        // Start recording
        await _audioRecorder!.startRecorder(
          toFile: tempPath,
          codec: Codec.pcm16WAV,
          sampleRate: sampleRate,
        );

        // Record for a short duration
        await Future.delayed(const Duration(milliseconds: 500));
        final recordingResult = await _audioRecorder!.stopRecorder();

        if (recordingResult != null) {
          await _processAudioForTFLite(tempPath);
        }
      } catch (e) {
        print('Error recording audio: $e');
      }
    });
  }

  Future<void> _processAudioForTFLite(String audioPath) async {
    try {
      // Read the WAV file
      final File audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        print('Audio file does not exist');
        return;
      }

      // Convert audio to features suitable for TFLite model
      final features = await _extractFeaturesFromAudio(audioFile);
      if (features == null) {
        print('Failed to extract features');
        return;
      }

      // Convert features to Float32List for the helper
      final Float32List inputFeatures = Float32List.fromList(features.expand((x) => x).toList());

      // Run inference using the helper
      final results = await _audioClassificationHelper!.inference(inputFeatures);

      // Process results
      if (results.isNotEmpty) {
        // Find the label with the highest confidence
        String topLabel = '';
        double topConfidence = 0;

        results.forEach((label, confidence) {
          if (confidence > topConfidence) {
            topLabel = label;
            topConfidence = confidence;
          }
        });

        // Update UI with classification result
        audioClassificationResult.value = '$topLabel ${(topConfidence * 100).toStringAsFixed(1)}%';
        print('Audio classified as: $topLabel with confidence: ${topConfidence * 100}%');
      } else {
        print('No recognition results');
      }
    } catch (e) {
      print('Error in audio processing: $e');
    }
  }

  // Helper method to extract audio features
  Future<List<List<double>>?> _extractFeaturesFromAudio(File audioFile) async {
    try {
      // Read WAV file and skip the header (44 bytes for standard WAV)
      final bytes = await audioFile.readAsBytes();
      if (bytes.length <= 44) {
        print('Audio file too small');
        return null;
      }

      // Extract PCM data (skip WAV header)
      final pcmData = bytes.sublist(44);

      // Convert to 16-bit PCM samples (assuming 16-bit audio)
      List<double> samples = [];
      for (int i = 0; i < pcmData.length; i += 2) {
        if (i + 1 < pcmData.length) {
          // Convert two bytes to one 16-bit sample
          int sample = pcmData[i] | (pcmData[i + 1] << 8);
          // Convert to signed value
          if (sample > 32767) sample -= 65536;
          samples.add(sample / 32768.0); // Normalize to [-1.0, 1.0]
        }
      }

      // We'll extract some basic audio features:
      // 1. RMS energy
      // 2. Zero crossing rate
      // 3. Simple energy bands (divide the signal into segments and calculate energy)

      // 1. Calculate RMS energy
      double rmsEnergy = 0;
      for (int i = 0; i < samples.length; i++) {
        rmsEnergy += samples[i] * samples[i];
      }
      rmsEnergy = math.sqrt(rmsEnergy / samples.length);

      // 2. Calculate zero crossing rate
      int zeroCrossings = 0;
      for (int i = 1; i < samples.length; i++) {
        if ((samples[i] >= 0 && samples[i - 1] < 0) ||
            (samples[i] < 0 && samples[i - 1] >= 0)) {
          zeroCrossings++;
        }
      }
      final zeroCrossingRate = zeroCrossings / samples.length;

      // 3. Calculate energy in bands (divide the signal into 10 equal segments)
      List<double> bandEnergies = [];
      final int bandSize = samples.length ~/ 10;

      for (int i = 0; i < 10; i++) {
        int startIdx = i * bandSize;
        int endIdx = (i + 1) * bandSize;
        if (endIdx > samples.length) endIdx = samples.length;

        double bandEnergy = 0;
        for (int j = startIdx; j < endIdx; j++) {
          bandEnergy += samples[j] * samples[j];
        }
        bandEnergy /= (endIdx - startIdx);
        bandEnergies.add(bandEnergy);
      }

      // Combine all features
      List<double> featureVector = [rmsEnergy, zeroCrossingRate, ...bandEnergies];

      // Format as expected by the interpreter (usually a batch of 1)
      return [featureVector];
    } catch (e) {
      print('Error extracting features: $e');
      return null;
    }
  }

  startPushStream() async {
    cloud = (await TRTCCloud.sharedInstance())!;
    TRTCParams params = TRTCParams();
    params.sdkAppId = GenerateTestUserSig.sdkAppId;
    params.roomId = widget.roomId.hashCode;
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
      // case TRTCCloudListener.onError:
      //   break;
      // case TRTCCloudListener.onWarning:
      //   break;
      // case TRTCCloudListener.onEnterRoom:
      //   break;
      // case TRTCCloudListener.onExitRoom:
      //   break;
      // case TRTCCloudListener.onSwitchRole:
      //   break;
      case TRTCCloudListener.onRemoteUserEnterRoom:
        onRemoteUserEnterRoom(params);
        break;
      case TRTCCloudListener.onRemoteUserLeaveRoom:
        onRemoteUserLeaveRoom(params["userId"], params['reason']);
        break;
      // case TRTCCloudListener.onConnectOtherRoom:
      //   break;
      // case TRTCCloudListener.onDisConnectOtherRoom:
      //   break;
      // case TRTCCloudListener.onSwitchRoom:
      //   break;
      // case TRTCCloudListener.onUserVideoAvailable:
      //   break;
      // case TRTCCloudListener.onUserSubStreamAvailable:
      //   break;
      // case TRTCCloudListener.onUserAudioAvailable:
      //   break;
      // case TRTCCloudListener.onFirstVideoFrame:
      //   break;
      // case TRTCCloudListener.onFirstAudioFrame:
      //   break;
      // case TRTCCloudListener.onSendFirstLocalVideoFrame:
      //   break;
      // case TRTCCloudListener.onSendFirstLocalAudioFrame:
      //   break;
      case TRTCCloudListener.onNetworkQuality:
        onNetworkQuality(params);
        break;
      // case TRTCCloudListener.onStatistics:
      //   break;
      // case TRTCCloudListener.onConnectionLost:
      //   break;
      // case TRTCCloudListener.onTryToReconnect:
      //   break;
      // case TRTCCloudListener.onConnectionRecovery:
      //   break;
      // case TRTCCloudListener.onSpeedTest:
      //   break;
      // case TRTCCloudListener.onCameraDidReady:
      //   break;
      // case TRTCCloudListener.onMicDidReady:
      //   break;
      // case TRTCCloudListener.onUserVoiceVolume:
      //   onUserVoiceVolume(params);
      //   break;
      // case TRTCCloudListener.onRecvCustomCmdMsg:
      //   break;
      // case TRTCCloudListener.onMissCustomCmdMsg:
      //   break;
      default:
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
    _classificationTimer?.cancel();
    _audioRecorder?.closeRecorder();
    _audioPlayer?.closePlayer();
    _audioClassificationHelper?.closeInterpreter();
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
    List<CustomRemoteInfo> remoteInfoList = remoteInfoDictionary.values.toList();

    return Stack(children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ValueListenableBuilder<String>(
              valueListenable: audioClassificationResult,
              builder: (context, result, _) {
                if (result.isEmpty) {
                  return const SizedBox();
                }

                final currentLabel = result.split(' ')[0].toLowerCase();
                return Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: currentLabel == "ai" ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
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
                          )
                      ),
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
                      child: const Icon(Ionicons.call, color: Color(0xFFC71E38)),
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