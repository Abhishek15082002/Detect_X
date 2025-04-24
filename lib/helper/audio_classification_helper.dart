/*
 * Copyright 2023 The TensorFlow Authors. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *             http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class AudioClassificationHelper {
  static const _modelPath = 'assets/models/model.tflite';
  static const _labelsPath = 'assets/models/labels.txt';

  late Interpreter _interpreter;
  late final List<String> _labels;
  late Tensor _inputTensor;
  late Tensor _outputTensor;

  Future<void> initHelper() async {
    await _loadLabels();
    await _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      final options = InterpreterOptions();
      // Load model from assets
      _interpreter = await Interpreter.fromAsset(_modelPath, options: options);

      _inputTensor = _interpreter.getInputTensors().first;
      log('Input tensor shape: ${_inputTensor.shape}');
      _outputTensor = _interpreter.getOutputTensors().first;
      log('Output tensor shape: ${_outputTensor.shape}');
      log('Interpreter loaded successfully');
    } catch (e) {
      log('Error loading model: $e');
      rethrow;
    }
  }

  // Load labels from assets
  Future<void> _loadLabels() async {
    try {
      final labelTxt = await rootBundle.loadString(_labelsPath);
      _labels = labelTxt.split('\n').where((label) => label.isNotEmpty).toList();
      log('Labels loaded: ${_labels.length}');
    } catch (e) {
      log('Error loading labels: $e');
      rethrow;
    }
  }

  Future<Map<String, double>> processAudioFile(String filePath) async {
    try {
      // Convert audio to WAV format with correct parameters
      // final wavFile = await _convertAudioToWav(filePath);

      // Extract features from WAV
      final features = await _extractAudioFeatures(filePath);

      // Run inference
      return await inference(features);
    } catch (e) {
      log('Error processing audio file: $e');
      rethrow;
    }
  }

  Future<Float32List> _extractAudioFeatures(String wavFilePath) async {
    // This is a simplified approach. In a real application,
    // you might need more sophisticated audio feature extraction.

    // Read WAV file
    final file = File(wavFilePath);
    final bytes = await file.readAsBytes();

    // Skip WAV header (typically 44 bytes)
    const headerSize = 44;

    // Process based on your model's input requirements
    // This is an example and needs to be adjusted based on your specific model
    final int sampleCount = (bytes.length - headerSize) ~/ 2; // 16-bit samples
    final Float32List features = Float32List(_inputTensor.shape[1]);

    // Fill features array (simplified example)
    // In a real application, you would implement proper feature extraction
    // such as MFCC, spectrograms, etc.
    int featureLength = features.length;
    for (int i = 0; i < featureLength; i++) {
      if (i < sampleCount) {
        // Convert 16-bit PCM to float
        final int idx = headerSize + i * 2;
        final int sample = bytes[idx] | (bytes[idx + 1] << 8);
        // Convert to float in range [-1, 1]
        features[i] = (sample.toSigned(16) / 32768.0);
      } else {
        features[i] = 0.0;
      }
    }

    return features;
  }

  Future<Map<String, double>> inference(Float32List input) async {
    try {
      // Reshape input if necessary to match the model's expected input shape
      final inputShape = _inputTensor.shape;

      // Prepare output tensor
      final outputSize = _outputTensor.shape.last;
      final output = List<List<double>>.filled(
          1,
          List<double>.filled(outputSize, 0.0)
      );

      // Run inference
      _interpreter.run([input], output);

      // Process results
      final Map<String, double> classification = {};
      for (int i = 0; i < _labels.length && i < outputSize; i++) {
        classification[_labels[i].split(" ")[0]] = output[0][i];
      }

      return classification;
    } catch (e) {
      log('Inference error: $e');
      rethrow;
    }
  }

  void closeInterpreter() {
    _interpreter.close();
  }
}
