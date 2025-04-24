import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'home/audio_upload_screen.dart';
import 'home/call.dart';
import 'home/image_upload_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final List<Map<String, dynamic>> _navigationItems = [
    {
      "icon": Iconsax.call,
      "icon_shadow": Iconsax.call5,
      "name": "Call",
    },
    {
      "icon": Iconsax.microphone,
      "icon_shadow": Iconsax.microphone5,
      "name": "Audio",
    },
    {
      "icon": Iconsax.image,
      "icon_shadow": Iconsax.image5,
      "name": "Image",
    },
  ];
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Detect X', style: Theme.of(context).textTheme.titleLarge,),
        backgroundColor: Colors.white,
        actions: [
          IconButton(onPressed: (){
            FirebaseAuth.instance.signOut();
          }, icon: const Icon(Iconsax.logout5)),
          const SizedBox(width: 16),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: [
        CallPage(),
        AudioUploadScreen(),
        ImageUploadScreen(),
      ]),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.only(top: 12, bottom: MediaQuery.of(context).padding.bottom / 3 + 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _navigationItems
              .mapIndexed<Widget>((idx, item) => GestureDetector(
            onTap: () => setState(() => _selectedIndex = idx),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                        Icon(
                          item["icon_shadow"],
                          color: _selectedIndex == idx
                              ? Colors.blue.withAlpha(64)
                              : Colors.transparent,
                          size: 24,
                        ),
                      Icon(
                        item["icon"],
                        color: _selectedIndex == idx ? Theme.of(context).colorScheme.onSurface
                            : Colors.grey,
                        size: 24,
                      )
                    ],
                  ),
                  Text(
                    item["name"],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _selectedIndex == idx
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.grey),
                  )
                ],
              ),
            ),
          ))
              .toList(),
        ),
      ),
    );
  }
}
