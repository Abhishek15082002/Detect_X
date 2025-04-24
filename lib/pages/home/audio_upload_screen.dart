import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../helper/audio_classification_helper.dart';

class AudioUploadScreen extends StatefulWidget {
  const AudioUploadScreen({super.key});

  @override
  State<AudioUploadScreen> createState() => _AudioUploadScreenState();
}

class _AudioUploadScreenState extends State<AudioUploadScreen> {
  String? _fileName;
  String? _filePath;
  bool _isProcessing = false;
  Map<String, double>? _classificationResults;
  final AudioClassificationHelper _classificationHelper = AudioClassificationHelper();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeClassifier();
  }

  Future<void> _initializeClassifier() async {
    try {
      await _classificationHelper.initHelper();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to initialize classifier: $e")),
        );
      }
    }
  }

  void _pickAudioFile() async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Classifier is still initializing, please wait...")),
      );
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _fileName = result.files.single.name;
        _filePath = result.files.single.path;
        _classificationResults = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Audio selected: $_fileName")),
        );
      }
    }
  }

  Future<void> _classifyAudio() async {
    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an audio file first")),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final results = await _classificationHelper.processAudioFile(_filePath!);

      if (mounted) {
        setState(() {
          _classificationResults = results;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Classification failed: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    _classificationHelper.closeInterpreter();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Audio Classifier"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFa1c4fd), Color(0xFFc2e9fb)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: Colors.white,
                  child: InkWell(
                    onTap: _pickAudioFile,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 300,
                      height: 120,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file, size: 40, color: Colors.blueAccent),
                          SizedBox(width: 16),
                          Text(
                            "Choose Audio File",
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
                if (_fileName != null)
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _classifyAudio,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "Classify Audio",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                const SizedBox(height: 40),
                if (_classificationResults != null && _classificationResults!.isNotEmpty)
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      width: 300,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Classification Results:",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 15),
                          ..._getTopResults(),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _getTopResults() {
    if (_classificationResults == null) return [];

    // Sort results by confidence (descending)
    final sortedEntries = _classificationResults!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Display top 5 results
    return sortedEntries.take(5).map((entry) {
      final confidence = (entry.value * 100).toStringAsFixed(1);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                entry.key,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              "$confidence%",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String resultToString (String s) => switch(s){
    '0' => 'Background',
    '1' => 'Human',
    '2' => 'AI',
    _ => throw 'No such field exists',
  };
}
