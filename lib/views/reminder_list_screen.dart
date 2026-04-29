// lib/views/reminder_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/reminder_view_model.dart';
import '../viewmodels/observation_view_model.dart';
import '../viewmodels/search_filter_view_model.dart';
import '../models/app_reminder.dart';
import '../views/plant_card_view.dart';
import '../views/add_sought_plant_screen.dart'; // Zakładając, że chcesz edytować przez ten ekran

class ReminderListScreen extends StatelessWidget {
  const ReminderListScreen({super.key});

  void _handleLongPress(BuildContext context, AppReminder reminder) {
    if (reminder.type != 'HARVEST') return;

    final obsVm = context.read<ObservationViewModel>();
    final filterVm = context.read<SearchFilterViewModel>();

    // 1. Sprawdzamy czy to roślina z Magazynu
    final obs = obsVm.allObservations.cast<dynamic>().firstWhere(
            (o) => o.id == reminder.relatedId || o.speciesId == reminder.relatedId,
        orElse: () => null
    );

    if (obs != null) {
      PlantCardView.show(context, obs);
      return;
    }

    // 2. Sprawdzamy czy to roślina Poszukiwana
    final sought = filterVm.soughtPlants.firstWhere(
            (s) => s.id == reminder.relatedId,
        orElse: () => throw "Nie znaleziono danych rośliny"
    );

    // Dla poszukiwanej pokazujemy dialog z opcją edycji
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sought.polishName),
        content: Text("To jest roślina poszukiwana. Czy chcesz edytować jej parametry?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Zamknij")),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                // Tutaj można by dodać ekran edycji poszukiwanej, na razie otwieramy kreator (możesz to rozbudować)
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSoughtPlantScreen()));
              },
              child: const Text("EDYTUJ")
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Terminarz Zielarza"),
          backgroundColor: Colors.amber.shade800,
          bottom: const TabBar(
            tabs: [Tab(text: "PLANOWANE"), Tab(text: "HISTORIA")],
          ),
        ),
        body: Consumer<ReminderViewModel>(
          builder: (context, vm, child) {
            final pending = vm.reminders.where((r) => !r.isCompleted).toList();
            final completed = vm.reminders.where((r) => r.isCompleted).toList();
            return TabBarView(
              children: [
                _buildTimeline(context, pending, vm, isPending: true),
                _buildTimeline(context, completed, vm, isPending: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, List<AppReminder> list, ReminderViewModel vm, {required bool isPending}) {
    if (list.isEmpty) return const Center(child: Text("Brak przypomnień."));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final r = list[index];
        final isRecipe = r.type == 'RECIPE';

        return GestureDetector(
          onLongPress: () => _handleLongPress(context, r),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: Icon(isRecipe ? Icons.science : Icons.calendar_today, color: isRecipe ? Colors.purple : Colors.green),
              title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${r.body}\nData: ${_formatDate(r.scheduledTime)}"),
              trailing: isPending
                  ? IconButton(icon: const Icon(Icons.check), onPressed: () => vm.toggleReminderStatus(r.id, true))
                  : IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => vm.deleteReminder(r.id)),
              isThreeLine: true,
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) => "${dt.day}.${dt.month}.${dt.year} o ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
}