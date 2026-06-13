import 'package:camera/camera.dart';

/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Sterownik warstwy sprzętowej aparatu fotograficznego. Zapewnia poprawną
 * inicjalizację kontrolera wideo, dba o zwalnianie zasobów pamięci (dispose)
 * przy rekonfiguracji, wymusza format kompresji graficznej JPEG i przechwytuje
 * surowe zdjęcia dokumentujące detale morfologiczne okazów.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * - Brak bezpośrednich importów innych plików wewnętrznych z /lib. Usługa
 * niskopoziomowa dostarczająca ścieżki plików bezpośrednio do ViewModelu obserwacji.
 * ============================================================================
 */
class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  // Inicjalizacja aparatu
  Future<void> initCamera() async {
    // ZAMKNIJ istniejący kontroler przed nową inicjalizacją
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }

    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg, // Wymuszenie formatu pomaga na niektórych urządzeniach
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