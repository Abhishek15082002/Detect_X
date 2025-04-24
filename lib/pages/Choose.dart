import 'package:flutter/material.dart';

import 'audio_upload_screen.dart';
import 'image_upload_screen.dart';

class Choose extends StatefulWidget {
  const Choose({super.key});

  @override
  ChooseState createState() => ChooseState();
}

class ChooseState extends State<Choose> {
  void _onCardTapped(String courseName) {
    if (courseName == "Audio Detection") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AudioUploadScreen()),
      );
    } else if (courseName == "Image Detection") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ImageUploadScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/BackGround.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // 🔰 DetectX Logo
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 100,
                  width: 300,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 10),
              const Text(
                "Start Detecting",
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              // 🔉 Audio Detection Card
              GestureDetector(
                onTap: () => _onCardTapped("Audio Detection"),
                child: _buildDetectionCard(
                  imagePath: 'assets/audioSymbol.png',
                  label: "Audio",
                ),
              ),

              // 🖼 Image Detection Card
              GestureDetector(
                onTap: () => _onCardTapped("Image Detection"),
                child: _buildDetectionCard(
                  imagePath: 'assets/imageSymbol.png',
                  label: "Image",
                ),
              ),

              const Spacer(),

              // ⬇ Bottom Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomButton(Icons.history, "History", () {
                      // TODO: Implement history screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("History clicked")),
                      );
                    }),
                    _buildBottomButton(Icons.more_horiz, "More", () {
                      // TODO: Implement more options
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("More clicked")),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionCard({required String imagePath, required String label}) {
    return Card(
      elevation: 12,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/login.png'),
            fit: BoxFit.cover,
            opacity: 0.2,
          ),
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Image side
            Container(
              width: 130,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.contain,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            // Text side
            Expanded(
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade400),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      icon: Icon(icon, size: 24),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      onPressed: onTap,
    );
  }
}