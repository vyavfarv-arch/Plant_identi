import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_vm.dart';
import 'form_screen.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<ObservationViewModel>(
        builder: (context, vm, child) {
          // 1. Sprawdzamy czy aparat się jeszcze ładuje
          if (vm.isInitializing) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          return Stack(
            children: [
              // 2. Podgląd z aparatu (na cały ekran)
              Center(
                child: CameraPreview(vm.controller!),
              ),

              // 3. Miniaturki zrobionych zdjęć (na górze)
              Positioned(
                top: 50,
                left: 10,
                child: Row(
                  children: vm.currentPhotoPaths.map((path) {
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(File(path), fit: BoxFit.cover),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // 4. Dolny panel sterowania
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      "Zdjęcia: ${vm.currentPhotoPaths.length} / 3",
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: vm.canTakePhoto ? () => vm.takePhoto() : null,
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: vm.canTakePhoto ? Colors.white.withOpacity(0.5) : Colors.grey,
                        ),
                        child: Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: vm.canTakePhoto ? Colors.white : Colors.black26
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 5. Przycisk Dalej (pojawia się gdy mamy min. 1 zdjęcie)
              if (vm.currentPhotoPaths.isNotEmpty)
                Positioned(
                  bottom: 55,
                  right: 30,
                  child: FloatingActionButton(
                    backgroundColor: Colors.green,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FormScreen()),
                      );
                    },
                    child: const Icon(Icons.arrow_forward),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}