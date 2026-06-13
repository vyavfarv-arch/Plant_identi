// lib/views/releve_list_map_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/releve_view_model.dart';
import '../viewmodels/search_filter_view_model.dart';
import '../viewmodels/observation_view_model.dart';
import '../services/spatial_service.dart';
import '../services/ecological_matching_service.dart';
import '../models/releve.dart';
import 'releve_details_screen.dart';
import 'releve_map_screen.dart';
import 'area_filter_screen.dart';

class ReleveListMapScreen extends StatefulWidget {
  const ReleveListMapScreen({super.key});

  @override
  State<ReleveListMapScreen> createState() => _ReleveListMapScreenState();
}

class _ReleveListMapScreenState extends State<ReleveListMapScreen> {
  @override
  Widget build(BuildContext context) {
    final releveVm = context.watch<ReleveViewModel>();
    final filterVm = context.watch<SearchFilterViewModel>();
    final obsVm = context.watch<ObservationViewModel>();

    final filteredReleves = releveVm.allReleves.where((r) {
      final h = r.habitat;
      if (h == null) return !filterVm.isAnyAreaFilterActive();

      if (filterVm.areaFilterReleveRank != null && r.type != filterVm.areaFilterReleveRank) return false;
      if (filterVm.areaFilterAreaType != null && h.areaType != filterVm.areaFilterAreaType) return false;
      if (filterVm.areaFilterWaterMovement != null && h.waterMovement != filterVm.areaFilterWaterMovement) return false;
      if (filterVm.areaFilterSlopeAngle != null && h.slopeAngle != filterVm.areaFilterSlopeAngle) return false;
      if (filterVm.areaFilterExposure != null && h.exposure != filterVm.areaFilterExposure) return false;
      if (filterVm.areaFilterHydrologicalContext != null && h.hydrologicalContext != filterVm.areaFilterHydrologicalContext) return false;
      if (filterVm.areaFilterSoilSurfaceCover != null && h.soilSurfaceCover != filterVm.areaFilterSoilSurfaceCover) return false;
      if (filterVm.areaFilterHumanImpact != null && h.humanImpact != filterVm.areaFilterHumanImpact) return false;

      if (h.canopyDensity < filterVm.areaFilterCanopyRange.start || h.canopyDensity > filterVm.areaFilterCanopyRange.end) return false;

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
          IconButton(
            icon: Icon(
              Icons.tune,
              color: filterVm.isAnyAreaFilterActive() ? Colors.orange : null,
            ),
            tooltip: "Filtruj obszary",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AreaFilterScreen()),
            ),
          ),
          if (filterVm.isAnyAreaFilterActive())
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
      body: SafeArea(
        child: Column(
          children: [
            if (filterVm.isAnyAreaFilterActive())
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.orange.shade50,
                width: double.infinity,
                child: Text(
                  "Aktywne filtry siedliska: ${filteredReleves.length} wyników",
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

                  final areaPlants = SpatialService.getPlantsInArea(obsVm.completeObservations, r);
                  bool hasEcologicalAnomaly = false;
                  for (var plant in areaPlants) {
                    final speciesInfo = obsVm.getSpeciesById(plant.speciesId);
                    if (EcologicalMatchingService.isSevereMismatch(r, speciesInfo)) {
                      hasEcologicalAnomaly = true;
                      break;
                    }
                  }

                  List<Releve> subareas = releveVm.allReleves.where((sub) => sub.parentId == r.id).toList();
                  Releve? parentArea = r.parentId != null
                      ? releveVm.allReleves.firstWhere((p) => p.id == r.parentId, orElse: () => r)
                      : null;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    elevation: 2,
                    child: ListTile(
                      leading: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            backgroundColor: r.type == "Obszar" ? Colors.indigo.shade100 : Colors.blue.shade100,
                            child: Icon(r.type == "Obszar" ? Icons.map : Icons.layers,
                                color: r.type == "Obszar" ? Colors.indigo : Colors.blue),
                          ),
                          if (hasEcologicalAnomaly)
                            const Positioned(
                              right: -4,
                              top: -4,
                              child: Icon(Icons.warning_rounded, color: Colors.amber, size: 22),
                            ),
                        ],
                      ),
                      title: Text(r.commonName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Typ: ${r.type} ${r.habitat?.areaType != null ? '(${r.habitat!.areaType})' : ''}"),
                          if (hasEcologicalAnomaly)
                            const Text("⚠️ Konflikt wskaźników siedliska!", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
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
        ),
      ),
    );
  }
}