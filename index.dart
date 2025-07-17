import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendario de Hábitos',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const CalendarPage(),
    );
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final DateTime _now = DateTime.now();
  late DateTime _firstDayOfMonth;
  late int _daysInMonth;
  Map<String, List<bool>> _habitData = {};
  String? _expandedDay;

  @override
  void initState() {
    super.initState();
    _firstDayOfMonth = DateTime(_now.year, _now.month, 1);
    _daysInMonth = DateTime(_now.year, _now.month + 1, 0).day;
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('habitData');
    if (storedData != null) {
      setState(() {
        _habitData = Map<String, List<bool>>.from(
          json.decode(storedData).map(
            (key, value) => MapEntry(key, List<bool>.from(value)),
          ),
        );
      });
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('habitData', json.encode(_habitData));
  }

  void _toggleHabit(String dayKey, int index) {
    setState(() {
      _habitData.putIfAbsent(dayKey, () => [false, false, false]);
      _habitData[dayKey]![index] = !_habitData[dayKey]![index];
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> dayWidgets = [];
    final int startWeekday = _firstDayOfMonth.weekday % 7; // Sunday = 0

    for (int i = 0; i < startWeekday; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }

    for (int day = 1; day <= _daysInMonth; day++) {
      final String key = DateFormat('yyyy-MM-dd').format(DateTime(_now.year, _now.month, day));
      final habits = _habitData[key] ?? [false, false, false];

      final isExpanded = _expandedDay == key;
      dayWidgets.add(GestureDetector(
        onTap: () {
          setState(() {
            _expandedDay = isExpanded ? null : key;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isExpanded ? Colors.teal.shade50 : Colors.white,
            border: Border.all(color: Colors.teal.shade100),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text('$day', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final color = [Colors.blue, Colors.orange, Colors.green][index];
                  return GestureDetector(
                    onTap: () => _toggleHabit(key, index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: habits[index] ? color : Colors.transparent,
                        border: Border.all(color: color, width: 2),
                      ),
                    ),
                  );
                }),
              ),
              if (isExpanded) ...[
                const SizedBox(height: 8),
                _habitLabel(habits[0], '8000 pasos', Colors.blue, () => _toggleHabit(key, 0)),
                _habitLabel(habits[1], '5 frutas/verduras', Colors.orange, () => _toggleHabit(key, 1)),
                _habitLabel(habits[2], 'Ejercicio de fuerza', Colors.green, () => _toggleHabit(key, 2)),
              ]
            ],
          ),
        ),
      ));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Calendario de Hábitos')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 7,
          children: dayWidgets,
        ),
      ),
    );
  }

  Widget _habitLabel(bool done, String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 6),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? color : Colors.transparent,
              border: Border.all(color: color, width: 2),
            ),
          ),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
