import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:michelino/lista.dart';
import "package:table_calendar/table_calendar.dart";

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({super.key});

  @override
  State<StatefulWidget> createState() => CalendarState();
}

class CalendarState extends State<CalendarWidget> {
  DateFormat format = DateFormat("yyyy-MM-dd");
  DateTime focus = DateTime.now();
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
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text("${[
          "Gennaio",
          "Febbraio",
          "Marzo",
          "Aprile",
          "Maggio",
          "Giugno",
          "Luglio",
          "Agosto",
          "Settembre",
          "Ottobre",
          "Novembre",
          "Dicembre"
        ][focus.month - 1]} ${focus.year}"),
        //centerTitle: true,

        actions: [
          Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.teal),
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.fromLTRB(16, 8, 4, 8),
            child: IconButton(
              onPressed: () => setState(() {
                focus = focus.subtract(const Duration(days: 30));
              }),
              icon: const Icon(Icons.chevron_left),
            ),
          ),
          Container(
            decoration: BoxDecoration(
                color: Colors.teal, borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.fromLTRB(4, 8, 16, 8),
            child: IconButton(
              onPressed: () => setState(() {
                focus = focus.add(const Duration(days: 30));
              }),
              icon: const Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TableCalendar(
              onPageChanged: (focusedDay) => setState(() {
                focus = focusedDay;
              }),
              //locale: Localizations.localeOf(context).languageCode,
              headerVisible: false,
              startingDayOfWeek: StartingDayOfWeek.monday,
              daysOfWeekHeight: 40,
              daysOfWeekStyle: DaysOfWeekStyle(
                  weekendStyle: const TextStyle(color: Color(0xFF4F4F4F)),
                  dowTextFormatter: (date, locale) =>
                      ["L", "M", "M", "G", "V", "S", "D"][date.weekday - 1],
                  decoration: BoxDecoration(
                      boxShadow: kElevationToShadow[4],
                      color: Theme.of(context).backgroundColor,
                      borderRadius: BorderRadius.circular(10))),
              headerStyle: HeaderStyle(
                formatButtonDecoration: BoxDecoration(
                    color: Colors.transparent.withAlpha(20),
                    borderRadius: BorderRadius.circular(15)),
                titleTextFormatter: (date, locale) => "${[
                  "Gennaio",
                  "Febbraio",
                  "Marzo",
                  "Aprile",
                  "Maggio",
                  "Giugno",
                  "Luglio",
                  "Agosto",
                  "Settembre",
                  "Ottobre",
                  "Novembre",
                  "Dicembre"
                ][date.month - 1]} ${date.year}",
              ),
              calendarStyle: StileCalendario(),
              holidayPredicate: (day) =>
                  (day.day == 1 && day.month == 8) ||
                  (day.day == 27 && day.month == 2) ||
                  (day.day == 13 && day.month == 7),
              focusedDay: focus,
              firstDay: DateTime(2022, 8, 1),
              lastDay: DateTime(3000),
              availableCalendarFormats: const {
                CalendarFormat.month: "Mese",
                CalendarFormat.week: "Settimana"
              },
              calendarFormat: formato,
              onFormatChanged: (format) => setState(() {
                formato = format;
              }),
              selectedDayPredicate: (day) => isSameDay(selezionato, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  //print("$selectedDay $focusedDay");
                  focus = focusedDay;
                  selezionato = selectedDay;
                  giornoScelto = info[format.format(selezionato)] ?? [];
                });
              },
              eventLoader: (day) => info[format.format(day)] ?? [],
              calendarBuilders: CalendarBuilders(
                  dowBuilder: (context, day) => Center(
                          child: Text(
                        ["L", "M", "M", "G", "V", "S", "D"][day.weekday - 1],
                        textScaleFactor:
                            day.weekday == DateTime.now().weekday ? 1.3 : 1,
                      ))),
            ),
          ),
          Expanded(
            child: Card(
                elevation: 10,
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(15))),
                child: CustomList(
                  giornoScelto: giornoScelto,
                  context: context,
                  titolo: Theme(
                    data: ThemeData(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        brightness: Theme.of(context).brightness),
                    child: ListTile(
                      onTap: () => setState(() {
                        focus = selezionato;
                      }),
                      title: Text(
                        "${[
                          "Lunedì",
                          "Martedì",
                          "Mercoledì",
                          "Giovedì",
                          "Venerdì",
                          "Sabato",
                          "Domenica"
                        ][selezionato.weekday - 1]} ${selezionato.day}/${selezionato.month}/${selezionato.year}",
                        textScaleFactor: 1.3,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Theme(
                        data: Theme.of(context),
                        child: IconButton(
                            onPressed: () => showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                      title: const Text("Aggiungi un evento"),
                                      content: SizedBox(
                                        width: 1000,
                                        child: TextField(
                                          controller: controller,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                            onPressed: () {
                                              if (controller
                                                  .value.text.isNotEmpty) {
                                                giornoScelto
                                                    .add(controller.value.text);

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
                                            onPressed: () {
                                              controller.clear();
                                              Navigator.pop(context);
                                            },
                                            child: const Text("Annulla"))
                                      ]),
                                ),
                            icon: const Icon(Icons.add)),
                      ),
                    ),
                  ),
                  selezionato: selezionato,
                )),
          )
        ],
      ),
    );
  }
}

class StileCalendario extends CalendarStyle {
  StileCalendario()
      : super(
          markerDecoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.teal,
              boxShadow: kElevationToShadow[1]
              //border: Border(bottom: BorderSide(color: Colors.teal)),
              //borderRadius: BorderRadius.all(Radius.circular(1))
              ),
          markersMaxCount: 10,
          todayDecoration: BoxDecoration(
              color: Colors.teal,
              shape: BoxShape.circle,
              boxShadow: kElevationToShadow[4]),
          selectedDecoration: BoxDecoration(
              color: Colors.purple,
              shape: BoxShape.circle,
              boxShadow: kElevationToShadow[4]),
          outsideTextStyle: const TextStyle(color: Color(0xFF5A5A5A)),
          weekendTextStyle: const TextStyle(),
          holidayDecoration: const BoxDecoration(
              border: Border.symmetric(
                  vertical: BorderSide(color: Colors.red),
                  horizontal: BorderSide(color: Colors.red)),
              shape: BoxShape.circle),
          holidayTextStyle: const TextStyle(color: Colors.red),
        );
}
