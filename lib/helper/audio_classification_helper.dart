import 'dart:convert';

import 'package:flutter/services.dart';
// import 'package:tflite_audio/tflite_audio.dart';

class TFLiteModel{
  final String model = 'assets/model.tflite';
  final String label = 'assets/labels.txt';
  final String inputType = 'rawAudio';
  final int sampleRate = 44100;
  final int bufferSize = 11016;
  final int numOfInferences = 10000;

  Stream<Map<dynamic, dynamic>>? result;

  void init(){
    // TfliteAudio.loadModel(
    //   inputType: inputType,
    //   model: model,
    //   label: label,
    // );
    //
    // TfliteAudio.setSpectrogramParameters(nMFCC: 40, hopLength: 16384);
  }

  // Stream<Map<dynamic, dynamic>> getResult() {
  //   return TfliteAudio.startAudioRecognition(
  //     sampleRate: sampleRate,
  //     bufferSize: bufferSize,
  //     numOfInferences: numOfInferences,
  //   );
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
}