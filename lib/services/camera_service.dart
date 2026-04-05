import 'package:camera/camera.dart';
// USUNIĘTO: import 'views/form_screen.dart'; – serwis nie musi znać widoków

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  // Inicjalizacja aparatu
  Future<void> initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false, // Opcjonalnie: wyłączenie audio oszczędza zasoby przy samych zdjęciach
      );
      await _controller!.initialize();
    }
  }

  // Zrobienie zdjęcia i zwrócenie ścieżki do niego
  Future<String?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    try {
      final XFile photo = await _controller!.takePicture();
      return photo.path;
    } catch (e) {
      print("Błąd podczas robienia zdjęcia: $e");
      return null;
    }
  }

  void dispose() {
    _controller?.dispose();
  }

  CameraController? get controller => _controller;
}