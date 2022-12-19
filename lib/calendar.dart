import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import "package:table_calendar/table_calendar.dart";

class CalendarWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => CalendarState();
}

class CalendarState extends State<CalendarWidget> {
  DateFormat format = DateFormat("yyyy-MM-dd");
  DateTime scelto = DateTime.now();
  DateTime selezionato = DateTime.now();
  CalendarFormat formato = CalendarFormat.month;
  Map<String, List<String>> info = {};
  List<String> giornoScelto = [];
  FirebaseDatabase database = FirebaseDatabase.instance;
  TextEditingController controller = TextEditingController();
  @override
  void initState() {
    database.ref("calendario").onValue.listen((event) {
      Map<dynamic, dynamic> valori =
          (event.snapshot.value ?? {}) as Map<dynamic, dynamic>;
      if (mounted) {
        setState(() {
          valori.forEach((key, value) {
            List<String> b = [];
            value.forEach((e) {
              b.add(e as String);
            });
            info[key as String] = b;
          });
          giornoScelto = info[format.format(selezionato)] ?? [];
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(format.format(scelto)),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () => showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                        title: const Text("Aggiungi un evento"),
                        content: TextField(
                          controller: controller,
                        ),
                        actions: [
                          TextButton(
                              onPressed: () {
                                if (controller.value.text.isNotEmpty) {
                                  giornoScelto.add(controller.value.text);

                                  database
                                      .ref(
                                          "calendario/${format.format(selezionato)}")
                                      .set(giornoScelto);
                                }
                                controller.clear();
                                Navigator.pop(context);
                              },
                              child: const Text("OK")),
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Annulla"))
                        ]),
                  ),
              icon: const Icon(Icons.add)),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            calendarStyle: const CalendarStyle(
              todayDecoration:
                  BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
              selectedDecoration:
                  BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
              holidayDecoration: BoxDecoration(
                  border: Border.symmetric(
                      vertical: BorderSide(color: Colors.red),
                      horizontal: BorderSide(color: Colors.red)),
                  shape: BoxShape.circle),
              holidayTextStyle: TextStyle(color: Colors.red),
            ),
            holidayPredicate: (day) => (day.day == 1 && day.month == 8) || (day.day == 27 && day.month == 2) || (day.day == 13 && day.month == 7),
            focusedDay: scelto,
            firstDay: DateTime(2022, 8, 1),
            lastDay: DateTime(3000),
            calendarFormat: formato,
            onFormatChanged: (format) => setState(() {
              formato = format;
            }),
            selectedDayPredicate: (day) => isSameDay(selezionato, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                print("$selectedDay $focusedDay");
                scelto = focusedDay;
                selezionato = selectedDay;
                giornoScelto = info[format.format(selezionato)] ?? [];
              });
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.separated(
                itemBuilder: (context, index) => ListTile(
                  title: Text(
                    giornoScelto[index],
                    textAlign: TextAlign.center,
                  ),
                  trailing: IconButton(
                    onPressed: () {
                      giornoScelto.removeAt(index);
                      database
                          .ref("calendario/${format.format(selezionato)}")
                          .set(giornoScelto);
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ),
                itemCount: giornoScelto.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const Divider(),
              ),
            ),
          )
        ],
      ),
    );
  }
}
