// lib/views/area_filter_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habitat_info.dart';
import '../viewmodels/search_filter_view_model.dart';
import '../viewmodels/releve_view_model.dart'; // DODANO: Obsługa pobierania listy płatów
import 'filtered_areas_map_screen.dart'; // DODANO: Nawigacja do poligonów na mapie

/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Ekran zaawansowanego filtrowania parametrów środowiskowych i glebowych płatów.
 * Zaktualizowany o podwójną akcję wykonawczą: zatwierdzenie filtrów dla widoku
 * listy oraz bezpośrednie przejście do wizualizacji satelitarnej dopasowanych poligonów.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z pliku '../models/habitat_info.dart':
 * - Klasa [HabitatInfo]: Dostarcza statyczne opcje słownikowe do zasilenia kontrolek UI.
 * * Z pliku '../viewmodels/search_filter_view_model.dart':
 * - Klasa [SearchFilterViewModel]: Służy do odczytu i aplikowania ustawionych filtrów.
 * * Z pliku '../viewmodels/releve_view_model.dart':
 * - Klasa [ReleveViewModel]: Wykorzystywana do pobrania pełnej puli płatów przed mapowaniem.
 * * Z katalogu widoków:
 * - Ekran [FilteredAreasMapScreen]: Otwierany po kliknięciu dedykowanego przycisku mapy.
 * ============================================================================
 */
class AreaFilterScreen extends StatefulWidget {
  const AreaFilterScreen({super.key});

  @override
  State<AreaFilterScreen> createState() => _AreaFilterScreenState();
}

class _AreaFilterScreenState extends State<AreaFilterScreen> {
  String? _tmpAreaType, _tmpWater, _tmpSlope, _tmpExposure, _tmpHydro, _tmpCover, _tmpImpact, _tmpRank;
  List<String> _tmpSubstrates = [];
  RangeValues _tmpPh = const RangeValues(3.0, 9.0);
  RangeValues _tmpCanopy = const RangeValues(1.0, 9.0);

  @override
  void initState() {
    super.initState();
    final vm = context.read<SearchFilterViewModel>();
    _tmpAreaType = vm.areaFilterAreaType;
    _tmpWater = vm.areaFilterWaterMovement;
    _tmpSlope = vm.areaFilterSlopeAngle;
    _tmpExposure = vm.areaFilterExposure;
    _tmpHydro = vm.areaFilterHydrologicalContext;
    _tmpCover = vm.areaFilterSoilSurfaceCover;
    _tmpImpact = vm.areaFilterHumanImpact;
    _tmpRank = vm.areaFilterReleveRank;
    _tmpSubstrates = List.from(vm.areaFilterSubstrates);
    _tmpPh = vm.areaFilterPh;
    _tmpCanopy = vm.areaFilterCanopyRange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Filtruj Płaty Terenowe"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _tmpAreaType = _tmpWater = _tmpSlope = _tmpExposure = _tmpHydro = _tmpCover = _tmpImpact = _tmpRank = null;
              _tmpSubstrates.clear();
              _tmpPh = const RangeValues(3.0, 9.0);
              _tmpCanopy = const RangeValues(1.0, 9.0);
            }),
            child: const Text("RESET", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildDropdown("Ranga jednostki", ["Obszar", "Podobszar"], _tmpRank, (v) => setState(() => _tmpRank = v)),
            _buildDropdown("Typ makrosiedliska", HabitatInfo.areaTypeOptions, _tmpAreaType, (v) => setState(() => _tmpAreaType = v)),
            _buildDropdown("Ruch i natlenienie wody", HabitatInfo.waterMovementOptions, _tmpWater, (v) => setState(() => _tmpWater = v)),
            _buildDropdown("Reżim wodno-retencyjny", HabitatInfo.hydrologicalContextOptions, _tmpHydro, (v) => setState(() => _tmpHydro = v)),
            _buildDropdown("Struktura okrywy glebowej", HabitatInfo.soilSurfaceCoverOptions, _tmpCover, (v) => setState(() => _tmpCover = v)),
            _buildDropdown("Antropopresja / Zaburzenia", HabitatInfo.humanImpactOptions, _tmpImpact, (v) => setState(() => _tmpImpact = v)),
            _buildDropdown("Ekspozycja stoku", HabitatInfo.exposureOptions, _tmpExposure, (v) => setState(() => _tmpExposure = v)),
            _buildDropdown("Kąt nachylenia stoku", HabitatInfo.slopeAngleOptions, _tmpSlope, (v) => setState(() => _tmpSlope = v)),

            const Divider(height: 30),
            Text("Zacienienie okapu korony (1-9): ${_tmpCanopy.start.toStringAsFixed(0)} - ${_tmpCanopy.end.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
            RangeSlider(
              values: _tmpCanopy, min: 1.0, max: 9.0, divisions: 8, activeColor: Colors.indigo,
              onChanged: (v) => setState(() => _tmpCanopy = v),
            ),

            const Divider(height: 30),
            const Text("Typ podłoża mineralno-organicznego:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: HabitatInfo.substrateOptions.map((opt) {
                final isSelected = _tmpSubstrates.contains(opt);
                return FilterChip(
                  label: Text(opt), selected: isSelected, selectedColor: Colors.indigo.shade100,
                  onSelected: (s) => setState(() => s ? _tmpSubstrates.add(opt) : _tmpSubstrates.remove(opt)),
                );
              }).toList(),
            ),

            const SizedBox(height: 30),
            Text("Kwasowość / Odczyn pH gleby: ${_tmpPh.start.toStringAsFixed(1)} - ${_tmpPh.end.toStringAsFixed(1)}", style: const TextStyle(fontWeight: FontWeight.bold)),
            RangeSlider(
              values: _tmpPh, min: 3.0, max: 9.0, divisions: 60, activeColor: Colors.indigo,
              onChanged: (v) => setState(() => _tmpPh = v),
            ),
            const SizedBox(height: 40),

            // PIERWSZY PRZYCISK: Filtrowanie dla widoku tradycyjnej listy
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
              onPressed: () { _applyFiltersToViewModel(); Navigator.pop(context); },
              child: const Text("ZASTOSUJ FILTRY", style: TextStyle(fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 12), // Odstęp między przyciskami wykonawczymi

            // DRUGI PRZYCISK: NOWOŚĆ - Aplikowanie kryteriów i natychmiastowy rzut na mapę satelitarną
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15)
              ),
              onPressed: _showOnMap,
              icon: const Icon(Icons.map),
              label: const Text("Pokaż na mapie", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String? value, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: options.contains(value) ? value : null,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _applyFiltersToViewModel() {
    context.read<SearchFilterViewModel>().updateAreaFilters(
      areaType: _tmpAreaType,
      canopyRange: _tmpCanopy,
      waterMovement: _tmpWater,
      slopeAngle: _tmpSlope,
      exposure: _tmpExposure,
      hydrologicalContext: _tmpHydro,
      soilSurfaceCover: _tmpCover,
      humanImpact: _tmpImpact,
      substrates: _tmpSubstrates,
      ph: _tmpPh,
      releveRank: _tmpRank,
    );
  }

  // Akcja filtrująca i przekierowująca bezpośrednio na ekran wielokątów mapy
  void _showOnMap() {
    // 1. Zapisujemy aktualne tymczasowe stany kontrolek do globalnego stanu filtrów
    _applyFiltersToViewModel();

    final releveVm = context.read<ReleveViewModel>();

    // 2. Wyliczamy dopasowane płaty na podstawie identycznej logiki jak w ReleveListMapScreen
    final filtered = releveVm.allReleves.where((r) {
      final h = r.habitat;
      if (h == null) return !_hasAnyActiveFilter();

      if (_tmpRank != null && r.type != _tmpRank) return false;
      if (_tmpAreaType != null && h.areaType != _tmpAreaType) return false;
      if (_tmpWater != null && h.waterMovement != _tmpWater) return false;
      if (_tmpSlope != null && h.slopeAngle != _tmpSlope) return false;
      if (_tmpExposure != null && h.exposure != _tmpExposure) return false;
      if (_tmpHydro != null && h.hydrologicalContext != _tmpHydro) return false;
      if (_tmpCover != null && h.soilSurfaceCover != _tmpCover) return false;
      if (_tmpImpact != null && h.humanImpact != _tmpImpact) return false;

      if (h.canopyDensity < _tmpCanopy.start || h.canopyDensity > _tmpCanopy.end) return false;

      if (_tmpSubstrates.isNotEmpty) {
        if (!_tmpSubstrates.every((s) => h.substrateType.contains(s))) return false;
      }

      if (h.ph != null) {
        if (h.ph! < _tmpPh.start || h.ph! > _tmpPh.end) return false;
      }

      return true;
    }).toList();

    // 3. Sprawdzamy guard czy cokolwiek znaleziono, aby nie otwierać pustej mapy
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Brak obszarów spełniających wybrane kryteria siedliskowe."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 4. Przekierowujemy bezpośrednio na mapę ze skompletowaną listą poligonów
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FilteredAreasMapScreen(filteredAreas: filtered),
      ),
    );
  }

  bool _hasAnyActiveFilter() {
    return _tmpAreaType != null ||
        _tmpCanopy.start > 1.1 || _tmpCanopy.end < 8.9 ||
        _tmpWater != null ||
        _tmpSlope != null ||
        _tmpExposure != null ||
        _tmpHydro != null ||
        _tmpCover != null ||
        _tmpImpact != null ||
        _tmpSubstrates.isNotEmpty ||
        _tmpPh.start > 3.1 || _tmpPh.end < 8.9 ||
        _tmpRank != null;
  }
}