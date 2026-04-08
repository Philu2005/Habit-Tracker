import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final String selectedViewMode;

  const SettingsPage({super.key, required this.selectedViewMode});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String mode;

  @override
  void initState() {
    super.initState();
    mode = widget.selectedViewMode == 'month' ? 'month' : 'day';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Standardansicht',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'day',
                      icon: Icon(Icons.view_day),
                      label: Text('Tag'),
                    ),
                    ButtonSegment<String>(
                      value: 'month',
                      icon: Icon(Icons.calendar_month),
                      label: Text('Monat'),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (v) =>
                      setState(() => mode = v.isEmpty ? 'day' : v.first),
                ),
                const SizedBox(height: 12),
                Text(
                  mode == 'month'
                      ? 'Monatsansicht aktiv: Kalender mit Fortschrittsdots'
                      : 'Tagesansicht aktiv: Fokus auf Aufgabenliste',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(mode),
            icon: const Icon(Icons.check),
            label: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}
