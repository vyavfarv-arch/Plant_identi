// lib/models/has_ellenberg_profile.dart
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