// lib/views/reminder_list_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/reminder_view_model.dart';
import '../viewmodels/observation_view_model.dart';
import '../viewmodels/search_filter_view_model.dart';
import '../models/app_reminder.dart';
import 'plant_card_view.dart';
import 'add_sought_plant_screen.dart';
/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Interfejs modułu "Asystent Czasowy" podzielony na zakładki "W TOKU" oraz "HISTORIA".
 * Odpowiada za wyświetlanie osi czasu aktywnych alarmów, renderowanie reaktywnego
 * widżetu odliczającego czas (`_CountdownText`), obsługę wyciszeń oraz
 * głębokie powiązania (LongPress) przekierowujące do okazów lub celów poszukiwań.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z pliku '../models/app_reminder.dart':
 * - Klasa [AppReminder]: Model danych sterujący zachowaniem elementów osi czasu.
 * * Z katalogu '../viewmodels/':
 * - Klasa [ReminderViewModel]: Główny zarządca powiadomień, wyciszeń i zmian statusu ukończenia.
 * - Klasa [ObservationViewModel]: Służy do odszukania powiązanego okazu w terenie na bazie id.
 * - Klasa [SearchFilterViewModel]: Służy do odszukania powiązanego celu poszukiwań na bazie id.
 * * Z katalogu widoków:
 * - [PlantCardView]: Wyświetlenie dolnego arkusza powiązanej rośliny.
 * - [AddSoughtPlantScreen]: Przekierowanie do edycji celu poszukiwań.
 * ============================================================================
 */
class ReminderListScreen extends StatelessWidget {
  const ReminderListScreen({super.key});

  void _handleLongPress(BuildContext context, AppReminder reminder) {
    final obsVm = context.read<ObservationViewModel>();
    final filterVm = context.read<SearchFilterViewModel>();

    // 1. Szukamy w Magazynie (Obserwacje)
    try {
      final obs = obsVm.allObservations.firstWhere((o) => o.id == reminder.relatedId || o.speciesId == reminder.relatedId);
      PlantCardView.show(context, obs);
      return;
    } catch (_) {}

    // 2. Szukamy w Poszukiwanych
    try {
      final sought = filterVm.soughtPlants.firstWhere((s) => s.id == reminder.relatedId);
      _showSoughtEditDialog(context, sought);
      return;
    } catch (_) {}

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nie można znaleźć powiązanej rośliny.")));
  }

  void _showSoughtEditDialog(BuildContext context, dynamic sought) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sought.polishName),
        content: const Text("Roślina poszukiwana. Czy chcesz przejść do ekranu edycji?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Anuluj")),
          ElevatedButton(onPressed: () {
            Navigator.pop(ctx);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSoughtPlantScreen()));
          }, child: const Text("EDYTUJ")),
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
          title: const Text("Asystent Czasowy"),
          backgroundColor: Colors.amber.shade800,
          bottom: const TabBar(tabs: [Tab(text: "W TOKU"), Tab(text: "HISTORIA")]),
        ),
        body: SafeArea(child:  Consumer<ReminderViewModel>(
          builder: (context, vm, child) {
            final pending = vm.reminders.where((r) => !r.isCompleted).toList();
            final completed = vm.reminders.where((r) => r.isCompleted).toList();
            return TabBarView(children: [
              _buildTimeline(context, pending, vm, isPending: true),
              _buildTimeline(context, completed, vm, isPending: false),
            ]);
          },
        ),
        ),),
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
        final isUrgent = r.scheduledTime.isBefore(DateTime.now().add(const Duration(hours: 24))) && !r.isCompleted;
        return GestureDetector(
          onLongPress: () => _handleLongPress(context, r),
          child: Card(
            color: isUrgent ? Colors.orange.shade50 : null,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(isRecipe ? Icons.science : Icons.spa, color: isRecipe ? Colors.purple : Colors.green),
              title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold)),

              // SUBTITLE: Kolumna z tekstem i licznikiem
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.body),
                  const SizedBox(height: 5),
                  if (isPending)
                    _CountdownText(
                        targetDate: r.scheduledTime,
                        endDate: r.endDate,
                        type: r.type
                    )
                  else
                    Text("Zakończono: ${_formatDate(r.scheduledTime)}",
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),

              // TRAILING: Przyciski po prawej stronie (wyciszenie i usunięcie/zakończenie)
              trailing: Wrap(
                children: [
                  IconButton(
                    icon: Icon(r.isMuted ? Icons.notifications_off : Icons.notifications_active, color: r.isMuted ? Colors.grey : Colors.amber),
                    onPressed: () => vm.toggleMute(r.id, r.isMuted),
                  ),
                  if (isPending)
                    IconButton(icon: const Icon(Icons.check_circle_outline), onPressed: () => vm.toggleReminderStatus(r.id, true))
                  else
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => vm.deleteReminder(r.id)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) => "${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
}
// ZAKTUALIZOWANY WIDGET ODLICZAJĄCY
class _CountdownText extends StatefulWidget {
  final DateTime targetDate; // Start
  final DateTime? endDate;   // Koniec
  final String type;         // NOWOŚĆ: Typ powiadomienia (RECIPE lub HARVEST)

  const _CountdownText({
    required this.targetDate,
    this.endDate,
    required this.type
  });

  @override
  State<_CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<_CountdownText> {
  late Timer _timer;
  String _label = "";
  String _timeLeft = "";

  @override
  void initState() {
    super.initState();
    _calculate();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => _calculate());
  }

  void _calculate() {
    final now = DateTime.now();
    DateTime activeTarget;

    // 1. Logika przed rozpoczęciem (np. oczekiwanie na start zbiorów lub start minutnika)
    if (now.isBefore(widget.targetDate)) {
      _label = "Pozostały czas: "; // ZMIANA: Uniwersalna etykieta zgodnie z prośbą
      activeTarget = widget.targetDate;
    }
    // 2. Logika w trakcie trwania (tylko dla zbiorów, które mają endDate)
    else if (widget.endDate != null && now.isBefore(widget.endDate!)) {
      _label = widget.type == 'RECIPE' ? "Pozostały czas procesu: " : "Do końca sezonu: ";
      activeTarget = widget.endDate!;
    }
    // 3. Logika po zakończeniu
    else {
      setState(() {
        // ZMIANA: Rozróżnienie komunikatu końcowego
        _timeLeft = widget.type == 'RECIPE' ? "PROCES ZAKOŃCZONY" : "SEZON ZAKOŃCZONY";
        _label = "";
      });
      return;
    }

    final diff = activeTarget.difference(now);
    String time = "${diff.inDays}dni ${diff.inHours % 24}h ${diff.inMinutes % 60}m ${diff.inSeconds % 60}s";
    setState(() => _timeLeft = time);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_label.isNotEmpty)
          Text(_label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
            _timeLeft,
            style: TextStyle(
              // Wizualne wyróżnienie zakończonego procesu
                color: _timeLeft.contains("ZAKOŃCZONY") ? Colors.grey : Colors.deepOrange,
                fontWeight: FontWeight.bold
            )
        ),
      ],
    );
  }
}