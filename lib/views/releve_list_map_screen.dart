// lib/views/releve_list_map_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/releve_view_model.dart';
import '../viewmodels/search_filter_view_model.dart';
import '../models/releve.dart';
import 'releve_details_screen.dart';
import 'releve_map_screen.dart';
import 'area_filter_screen.dart'; // IMPORT NOWEGO EKRANU

/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Ekran modułu "Obszary" zarządzający zarejestrowanymi płatami roślinności.
 * Odpowiada za aplikowanie filtrów środowiskowych, dynamiczne zliczanie i prezentację
 * podobszarów niższej rangi w strukturze hierarchicznej oraz udostępnianie akcji resetu.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z pliku '../models/releve.dart':
 * - Klasa [Releve]: Encja danych reprezentująca pojedynczy rekord płatu na liście.
 * * Z katalogu '../viewmodels/':
 * - Klasa [ReleveViewModel]: Dostarcza kompletną listę płatów oraz wylicza relacje nadrzędne.
 * - Klasa [SearchFilterViewModel]: Służy do pobierania aktywnych filtrów mineralnych i odczynu pH.
 * * Z katalogu widoków:
 * - Ekran [AreaFilterScreen]: Wywoływany w celu konfiguracji zaawansowanych filtrów środowiskowych.
 * - Ekran [ReleveMapScreen]: Służy do przejścia do kreatora rysowania nowego wielokąta.
 * - Ekran [ReleveDetailsScreen]: Otwierany po kliknięciu w kafelek obszaru w celu wejścia w jego głębokie szczegóły.
 * ============================================================================
 */

class ReleveListMapScreen extends StatefulWidget {
  const ReleveListMapScreen({super.key});

  @override
  State<ReleveListMapScreen> createState() => _ReleveListMapScreenState();
}

class _ReleveListMapScreenState extends State<ReleveListMapScreen> {

  // Metoda pomocnicza sprawdzająca, czy jakikolwiek filtr jest aktywny (dla koloru ikony)
  bool _isAnyFilterActive(SearchFilterViewModel vm) {
    return vm.areaFilterType != null ||
        vm.areaFilterCanopy != null ||
        vm.areaFilterWater != null ||
        vm.areaFilterSlope != null ||
        vm.areaFilterSubstrates.isNotEmpty ||
        vm.areaFilterPh.start > 3.1 ||
        vm.areaFilterPh.end < 8.9;
  }

  @override
  Widget build(BuildContext context) {
    final releveVm = context.watch<ReleveViewModel>();
    final filterVm = context.watch<SearchFilterViewModel>();

    // LOGIKA FILTROWANIA LISTY
    final filteredReleves = releveVm.allReleves.where((r) {
      final h = r.habitat;
      if (h == null) return !_isAnyFilterActive(filterVm);

      if (filterVm.areaFilterType != null && r.type != filterVm.areaFilterType) return false;
      if (filterVm.areaFilterWater != null && h.waterMovement != filterVm.areaFilterWater) return false;
      if (filterVm.areaFilterSlope != null && h.slopeAngle != filterVm.areaFilterSlope) return false;

      if (filterVm.areaFilterSubstrates.isNotEmpty) {
        if (!filterVm.areaFilterSubstrates.every((s) => h.substrateType.contains(s))) return false;
      }
      if (h.ph != null) {
        if (h.ph! < filterVm.areaFilterPh.start || h.ph! > filterVm.areaFilterPh.end) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Zarządzanie Obszarami"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // PRZYCISK FILTRA (Zamiast starej mapy)
          IconButton(
            icon: Icon(
              Icons.tune,
              color: _isAnyFilterActive(filterVm) ? Colors.orange : null,
            ),
            tooltip: "Filtruj obszary",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AreaFilterScreen()),
            ),
          ),
          // SZYBKI RESET
          if (_isAnyFilterActive(filterVm))
            IconButton(
              icon: const Icon(Icons.layers_clear_outlined),
              tooltip: "Resetuj filtry",
              onPressed: () => filterVm.resetAreaFilters(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReleveMapScreen())),
        icon: const Icon(Icons.add_location_alt),
        label: const Text("NOWY OBSZAR"),
      ),
      body: SafeArea(child:  Column(
        children: [
          // Pasek informacyjny o aktywnych filtrach
          if (_isAnyFilterActive(filterVm))
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.orange.shade50,
              width: double.infinity,
              child: Text(
                "Aktywne filtry: ${filteredReleves.length} wyników",
                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          Expanded(
            child: filteredReleves.isEmpty
                ? const Center(child: Text("Brak obszarów spełniających kryteria."))
                : ListView.builder(
              itemCount: filteredReleves.length,
              padding: const EdgeInsets.only(bottom: 80),
              itemBuilder: (context, index) {
                final r = filteredReleves[index];

                // Logika zliczania podobszarów i znajdowania rodzica
                List<Releve> subareas = releveVm.allReleves.where((sub) => sub.parentId == r.id).toList();
                Releve? parentArea = r.parentId != null
                    ? releveVm.allReleves.firstWhere((p) => p.id == r.parentId, orElse: () => r)
                    : null;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: r.type == "Obszar" ? Colors.indigo.shade100 : Colors.blue.shade100,
                      child: Icon(r.type == "Obszar" ? Icons.map : Icons.layers,
                          color: r.type == "Obszar" ? Colors.indigo : Colors.blue),
                    ),
                    title: Text(r.commonName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Typ: ${r.type}"),
                        if (r.type == "Obszar" && subareas.isNotEmpty)
                          Text("Podobszary: ${subareas.length}",
                              style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12)),
                        if (r.type == "Podobszar" && parentArea != null && parentArea != r)
                          Text("Należy do: ${parentArea.commonName}",
                              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ReleveDetailsScreen(releve: r)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),),
    );
  }
}