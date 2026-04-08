import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_vm.dart';
import 'classification_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  @override
  void initState() {
    super.initState();
    // Inicjalizuj aparat po wejściu na ekran
    Future.microtask(() => context.read<ObservationViewModel>().init());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<ObservationViewModel>(
        builder: (context, vm, child) {
          if (vm.isInitializing || vm.controller == null || !vm.controller!.value.isInitialized) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          return Stack(
            children: [
              Center(child: CameraPreview(vm.controller!)),
              // UI miniaturek i przycisków...
              _buildUI(context, vm),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUI(BuildContext context, ObservationViewModel vm) {
    return Stack(
      children: [
        Positioned(
          top: 50,
          left: 10,
          child: Row(
            children: vm.currentPhotoPaths.map((path) => Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.file(File(path), width: 70, height: 70, fit: BoxFit.cover),
            )).toList(),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Text("Zdjęcia: ${vm.currentPhotoPaths.length} / 3", style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              IconButton(
                iconSize: 80,
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: vm.canTakePhoto ? () => vm.takePhoto() : null,
              ),
            ],
          ),
        ),
        if (vm.currentPhotoPaths.isNotEmpty)
          Positioned(
            bottom: 55,
            right: 30,
            child: FloatingActionButton(
              backgroundColor: Colors.green,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassificationScreen())),
              child: const Icon(Icons.arrow_forward),
            ),
          ),
      ],
    );
  }
}