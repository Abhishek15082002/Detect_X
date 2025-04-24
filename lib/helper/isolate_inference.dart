import 'dart:isolate';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class IsolateInference {
  static const String _debugName = "TFLITE_INFERENCE";
  final ReceivePort _receivePort = ReceivePort();
  late Isolate _isolate;
  late SendPort _sendPort;

  SendPort get sendPort => _sendPort;

  Future<void> start() async {
    _isolate = await Isolate.spawn<SendPort>(entryPoint, _receivePort.sendPort,
        debugName: _debugName);
    _sendPort = await _receivePort.first;
  }

  Future<void> close() async {
    _isolate.kill();
    _receivePort.close();
  }

  static void entryPoint(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    await for (final InferenceModel isolateModel in port) {
      try {
        Image? img;
        img = isolateModel.image;

        // resize original image to match model shape.
        Image imageInput = copyResize(
          img!,
          width: 256,
          height: 256,
          // width: isolateModel.inputShape[1],
          // height: isolateModel.inputShape[2],
        );

        final List<List<List<num>>> imageMatrix = List.generate(
          imageInput.height, (y) =>
            List.generate(imageInput.width, (x) {
              final Pixel pixel = imageInput.getPixel(x, y);
              return [pixel.r/256, pixel.g/256, pixel.b/256];
            }),
        );

        // Set tensor input [256, 256, 3]
        final input = [imageMatrix];
        // Set tensor output [1, 1001]
        final output = [List<double>.filled(isolateModel.outputShape[1], 0)];
        // // Run inference
        Interpreter interpreter =
        Interpreter.fromAddress(isolateModel.interpreterAddress);
        interpreter.run(input, output);

        final result = output.first.first;
        var classification = <String, double>{};
        if (result > 0.5) {
          classification[isolateModel.labels[1].split(" ")[1]] = result;
        }
        else{
          classification[isolateModel.labels[0].split(" ")[1]] = 1 - result;
        }
        isolateModel.responsePort.send(classification);
      }catch(e){
        print("Error in isolate: $e");
      }
    }
  }
}

class InferenceModel {
  Image? image;
  int interpreterAddress;
  List<String> labels;
  List<int> inputShape;
  List<int> outputShape;
  late SendPort responsePort;

  InferenceModel(this.image, this.interpreterAddress,
      this.labels, this.inputShape, this.outputShape);
}