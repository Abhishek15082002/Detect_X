import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'isolate_inference.dart';

class ImageClassificationHelper {
  static const modelPath = 'assets/models/image.tflite';
  static const labelsPath = 'assets/models/image_labels.txt';

  late final Interpreter interpreter;
  late final List<String> labels;
  late final IsolateInference isolateInference;
  late Tensor inputTensor;
  late Tensor outputTensor;

  // Load model
  Future<void> _loadModel() async {
    final options = InterpreterOptions();

    // Use XNNPACK Delegate
    if (Platform.isAndroid) {
      options.addDelegate(XNNPackDelegate());
    }

    // Use Metal Delegate
    if (Platform.isIOS) {
      options.addDelegate(GpuDelegate());
    }

    // Load model from assets
    interpreter = await Interpreter.fromAsset(modelPath, options: options);

    // Get tensor input shape
    inputTensor = interpreter.getInputTensors().first;

    // Get tensor output shape
    outputTensor = interpreter.getOutputTensors().first;

    log('Interpreter loaded successfully');
  }

  // Load labels from assets
  Future<void> _loadLabels() async {
    final labelTxt = await rootBundle.loadString(labelsPath);
    labels = labelTxt.split('\n');
  }

  Future<void> initHelper() async {
    await _loadLabels();
    await _loadModel();
    isolateInference = IsolateInference();
    await isolateInference.start();
  }

  Future<Map<String, double>> _inference(InferenceModel inferenceModel) async {
    try {
      ReceivePort responsePort = ReceivePort();
      isolateInference.sendPort
          .send(inferenceModel..responsePort = responsePort.sendPort);

      // get inference result
      var results = await responsePort.first;
      return results;
    }catch(e){
      print("Error inference: $e");
      return {};
    }
  }

  // inference still image
  Future<Map<String, double>> inferenceImage(Image image) async {
    try {
      var isolateModel = InferenceModel(
          image,
          interpreter.address,
          labels,
          inputTensor.shape,
          outputTensor.shape
      );
      return _inference(isolateModel);
    }catch(e){
      print("Error inference: $e");
      return {};
    }
  }

  Future<void> close() async => await isolateInference.close();
}