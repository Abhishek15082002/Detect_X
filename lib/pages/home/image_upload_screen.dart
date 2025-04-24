import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img_lib;

import '../../helper/image_classification_helper.dart';

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  String? _fileName;
  File? _imageFile;
  ImageClassificationHelper? _imageClassificationHelper;
  bool _isModelLoading = false;
  Map<String, double> _classificationResults = {};
  bool _isProcessing = false;
  late FilePicker _picker;

  @override
  void initState() {
    super.initState();
    _loadModel();
    _picker = FilePicker.platform;
  }

  Future<void> _loadModel() async {
    setState(() {
      _isModelLoading = true;
    });

    _imageClassificationHelper = ImageClassificationHelper();
    await _imageClassificationHelper!.initHelper();

    setState(() {
      _isModelLoading = false;
    });
  }

  void _pickImageFile() async {
    FilePickerResult? result = await _picker.pickFiles(type: FileType.image);

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _fileName = result.files.single.name;
        _imageFile = File(result.files.single.path!);
        _classificationResults = {};
      });

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image selected: $_fileName")),
        );
      }

      _classifyImage();
    }
  }

  Future<void> _classifyImage() async {
    if (_imageFile == null || _imageClassificationHelper == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Read and decode the image file
      final imageBytes = await _imageFile!.readAsBytes();
      final image = img_lib.decodeImage(imageBytes);

      if (image != null) {
        // Run inference
        final results = await _imageClassificationHelper!.inferenceImage(image);
        print(results);

        setState(() {
          _classificationResults = results;
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error classifying image: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _imageClassificationHelper?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Upload Image"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFfbc2eb), Color(0xFFa6c1ee)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 120),
                if (_isModelLoading)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text("Loading TensorFlow model...",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                else
                  Card(
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.white,
                    child: InkWell(
                      onTap: _pickImageFile,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 300,
                        height: 120,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 40, color: Colors.purple),
                            SizedBox(width: 16),
                            Text(
                              "Choose Image File",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 30),

                if (_fileName != null)
                  Text(
                    "Selected File: $_fileName",
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 20),

                if (_imageFile != null)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(32),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _imageFile!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                const SizedBox(height: 30),

                if (_isProcessing)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text("Classifying image...",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                else if (_classificationResults.isNotEmpty)
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white.withAlpha(200),
                    child: Container(
                      width: 300,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Classification Results:",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._classificationResults.entries
                              .toList()
                              .map((entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                Text(
                                  "${(entry.value * 100).toStringAsFixed(1)}%",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Extension to sort entries by value
extension ListExtension<T> on List<T> {
  List<T> sortedBy<K extends Comparable<K>>(K Function(T) keyOf) {
    final List<T> copy = List.from(this);
    copy.sort((a, b) => keyOf(a).compareTo(keyOf(b)));
    return copy;
  }
}