// lib/views/reminder_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/reminder_view_model.dart';
import '../models/app_reminder.dart';

class ReminderListScreen extends StatelessWidget {
  const ReminderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Asystent Czasowy"),
          backgroundColor: Colors.amber.shade700,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: "NADCHODZĄCE", icon: Icon(Icons.timer)),
              Tab(text: "ZAKOŃCZONE", icon: Icon(Icons.check_circle)),
            ],
          ),
        ),
        body: Consumer<ReminderViewModel>(
          builder: (context, vm, child) {
            final pending = vm.reminders.where((r) => !r.isCompleted).toList();
            final completed = vm.reminders.where((r) => r.isCompleted).toList();

            return TabBarView(
              children: [
                _buildTimeline(pending, vm, isPending: true),
                _buildTimeline(completed, vm, isPending: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimeline(List<AppReminder> list, ReminderViewModel vm, {required bool isPending}) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          isPending ? "Brak aktywnych minutników i przypomnień." : "Historia przypomnień jest pusta.",
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final reminder = list[index];
        final bool isLast = index == list.length - 1;

        final bool isRecipe = reminder.type == 'RECIPE';
        final Color accentColor = isRecipe ? Colors.purple : Colors.green;
        final IconData icon = isRecipe ? Icons.science : Icons.spa;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kolumna osi czasu (Timeline)
              Column(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: accentColor.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: accentColor, width: 2)),
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                  if (!isLast)
                    Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(width: 16),

              // Kolumna z zawartością przypomnienia
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDateTime(reminder.scheduledTime), style: TextStyle(fontWeight: FontWeight.bold, color: accentColor)),
                              if (isPending)
                                IconButton(
                                  icon: const Icon(Icons.check_circle_outline, color: Colors.grey),
                                  tooltip: "Zaznacz jako wykonane",
                                  onPressed: () => vm.toggleReminderStatus(reminder.id, true),
                                  constraints: const BoxConstraints(), padding: EdgeInsets.zero,
                                )
                              else
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: "Usuń wpis",
                                  onPressed: () => vm.deleteReminder(reminder.id),
                                  constraints: const BoxConstraints(), padding: EdgeInsets.zero,
                                )
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(reminder.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(reminder.body, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Funkcja ładnie formatująca datę
  String _formatDateTime(DateTime dt) {
    final String d = dt.day.toString().padLeft(2, '0');
    final String m = dt.month.toString().padLeft(2, '0');
    final String y = dt.year.toString();
    final String hr = dt.hour.toString().padLeft(2, '0');
    final String min = dt.minute.toString().padLeft(2, '0');
    return "$d.$m.$y  $hr:$min";
  }
}