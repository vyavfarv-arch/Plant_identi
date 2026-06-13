// lib/views/camera_screen.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_observation_screen.dart';
import '../viewmodels/observation_view_model.dart';

/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Ekran seryjnego zbierania dokumentacji fotograficznej dla nieznanych taksonów.
 * Zapewnia pełnoekranowy podgląd z aparatu urządzenia, dynamiczny licznik zdjęć
 * (limit do 10) oraz boczny przycisk nawigacyjny (FloatingActionButton) kierujący
 * do trybu długiej identyfikacji morfologicznej.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z pliku '../viewmodels/observation_view_model.dart':
 * - Klasa [ObservationViewModel]: Bezpośrednio kontroluje warstwę sprzętową kamery,
 * wyzwala operację takePhoto, pobiera ścieżki zdjęć i sprawdza warunek canTakePhoto.
 * * Z katalogu widoków:
 * - Ekran [AddObservationScreen]: Wywoływany po zebraniu zdjęć w celu przejścia
 * do trybu długiego opisu morfologicznego (forcedQuickMode: false).
 * ============================================================================
 */

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  @override
  void initState() {
    super.initState();
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
          return Stack(children: [Center(child: CameraPreview(vm.controller!)), _buildUI(context, vm)]);
        },
      ),
    );
  }

  Widget _buildUI(BuildContext context, ObservationViewModel vm) {
    return Stack(
      children: [
        Positioned(top: 50, left: 10, child: Row(children: vm.currentPhotoPaths.map((path) => Padding(padding: const EdgeInsets.all(4.0), child: Image.file(File(path), width: 70, height: 70, fit: BoxFit.cover))).toList())),
        Positioned(bottom: 40, left: 0, right: 0, child: Column(children: [Text("Zdjęcia: ${vm.currentPhotoPaths.length} / 10", style: const TextStyle(color: Colors.white)), const SizedBox(height: 20), IconButton(iconSize: 80, icon: const Icon(Icons.camera_alt, color: Colors.white), onPressed: vm.canTakePhoto ? () => vm.takePhoto() : null)])),
        if (vm.currentPhotoPaths.isNotEmpty)
          Positioned(
            bottom: 55, right: 30,
            child: FloatingActionButton(
              backgroundColor: Colors.green,
              // FIX: Przekierowanie do ujednoliconego asystenta w trybie DŁUGIM (forcedQuickMode: false)
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddObservationScreen(forcedQuickMode: false))),
              child: const Icon(Icons.arrow_forward),
            ),
          ),
      ],
    );
  }
}