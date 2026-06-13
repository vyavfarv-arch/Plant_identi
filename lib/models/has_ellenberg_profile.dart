// lib/models/has_ellenberg_profile.dart

/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Klasa abstrakcyjna definiująca interfejs profilu ekologicznego. Wymusza
 * obecność właściwości identyfikacyjnych, widełek odczynu pH oraz siedmiu
 * cyfrowych osi wskaźnikowych Ellenberga (L, F, R, N, T, K, S).
 * Służy zapewnieniu polimorfizmu dla struktur poddawanych dopasowaniu matrycowemu.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * - Brak bezpośrednich zależności wewnętrznych. Stanowi podstawowy kontrakt
 * typologiczny w projekcie.
 * ============================================================================
 */

abstract class HasEllenbergProfile {
  String get profileId;
  String get name;
  double? get prefPhMin;
  double? get prefPhMax;

  Map<int, int> get ellenbergL;
  Map<int, int> get ellenbergF;
  Map<int, int> get ellenbergR;
  Map<int, int> get ellenbergN;
  Map<int, int> get ellenbergT;
  Map<int, int> get ellenbergK;
  Map<int, int> get ellenbergS;
}