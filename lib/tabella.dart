import 'dart:math';

import 'package:flutter/material.dart';
import 'package:michelino/main.dart';

class CustomTable extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => TableState();
}

class TableState extends State<CustomTable> {
  static const List<String> _giorni = [
    "Ore",
    "Lun",
    "Mar",
    "Mer",
    "Gio",
    "Ven"
  ];
  static const List<String> _ore = [
    "8:30-9:00",
    "9:00-10:00",
    "10:00-11:00",
    "11:00-12:00",
    "12:00-13:30",
    "14:30",
    "16:00",
    "17:00"
  ];

  /*static const List<List<String>> _lezioni = [
     ["", "REL", "REL", "REL", ""],
     ["", "REL", "REL", "REL", ""],
     ["STO", "ETN", "", "STO", ""],
     ["", "ETRU", "ETRU", "ETN", ""],
     ["", "", "", "", ""],
     ["ETN", "", "STO", "", ""],
     ["ETRU", "", "", "", ""],
     ["","","","",""],

   ];*/

  static const Map<String, List<String>> _lezioni = {
    "8:30-9:00": ["", "REL", "REL", "REL", ""],
    "9:00-10:00": ["DIR", "REL\nALG", "REL\nALG", "REL\nDIR", "FIS"],
    "10:00-11:00": ["DIR\nSTO", "ALG\nETN", "ALG", "DIR\nSTO", "FIS"],
    "11:00-12:00": ["STO\nSIS", "ETN\nSIS", "ING", "STO\nING", "DIR"],
    "12:00-13:30": ["SIS", "SIS\nETRU", "ING\nETRU", "ING\nETN", "DIR"],
    "13:30-14:30": ["", "", "", "", ""],
    "14:30-15:00": ["ETN", "ALG", "STO\nLIN", "SIS", ""],
    "15:00-16:00": ["ETN\nALG", "ALG", "STO\nLIN", "SIS", ""],
    "16:00-17:00": ["ETRU\nALG", "LIN", "FIS", "SIS", ""],
    "17:00-18:00": ["ETRU", "LIN", "FIS", "", ""]
  };

  static const Map<String, List<String>> _lezioniMichi = {
    "8:00-9:00": ["", "", "", "", ""],
    "9:00-10:00": ["DIR", "ALG", "ALG", "DIR", "FIS"],
    "10:00-11:00": ["DIR", "ALG", "ALG", "DIR", "FIS"],
    "11:00-12:00": ["SIS", "SIS", "ING", "ING", "DIR"],
    "12:00-13:00": ["SIS", "SIS", "ING", "ING", "DIR"],
    "13:00-14:00": ["", "", "", "", ""],
    "14:00-15:00": ["", "ALG", "LIN", "SIS", ""],
    "15:00-16:00": ["ALG", "ALG", "LIN", "SIS", ""],
    "16:00-17:00": ["ALG", "LIN", "FIS", "SIS", ""],
    "17:00-18:00": ["", "LIN", "FIS", "", ""]
  };
  static const Map<String, List<String>> _lezioniAry = {
    "8:30-9:00": ["", "REL", "REL", "REL", ""],
    "9:00-10:00": ["", "REL", "REL", "REL", ""],
    "10:15-11:00": ["STO", "ETN", "", "STO", ""],
    "11:00-11:45": ["STO", "ETN", "", "STO", ""],
    "12:00-13:30": ["", "ETRU", "ETRU", "ETN", ""],
    "13:30-14:30": ["", "", "", "", ""],
    "14:30-15:00": ["ETN", "", "STO", "", ""],
    "15:00-16:00": ["ETN", "", "STO", "", ""],
    "16:15-17:00": ["ETRU", "", "", "", ""],
    "17:00-17:45": ["ETRU", "", "", "", ""]
  };

  static const List<String> _materieMichi = [
    "ALG",
    "DIR",
    "FIS",
    "ING",
    "LIN",
    "SIS"
  ];
  static const List<String> _materieAry = ["ETN", "ETRU", "REL", "STO"];

  static const Map<String, MaterialColor> _sfondiMaterie = {
    "ALG": Colors.blue,
    "DIR": Colors.cyan,
    "FIS": Colors.amber,
    "ING": Colors.deepOrange,
    "LIN": Colors.deepPurple,
    "SIS": Colors.green,
    "ETN": Colors.blue,
    "ETRU": Colors.green,
    "REL": Colors.amber,
    "STO": Colors.red
  };

  bool _vista = michi;

  @override
  Widget build(BuildContext context) {
    Map<String, List<String>> scelto = _vista ? _lezioniMichi : _lezioniAry;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "Orario ${_vista ? "Michi" : "Ary"}",
            textScaleFactor: 1.5,
          ),
        ),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).backgroundColor,
                        boxShadow: kElevationToShadow[4],
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        for (String i in _giorni)
                          Container(
                            width: i == "Ore" ? 100 : 50,
                            height: 50,
                            alignment: Alignment.center,
                            child: Text(
                              i,
                              textAlign: TextAlign.center,
                            ),
                          )
                      ],
                    ),
                  ),
                ),
                for (String i in scelto.keys)
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: scelto.keys.toList().indexOf(i) % 2 == 0 ? Theme.of(context).backgroundColor.withAlpha(100) : null,
                            border: Border.all(width: .1),
                            /*borderRadius: BorderRadius.only(
                                topLeft: i == scelto.keys.first
                                    ? const Radius.circular(10)
                                    : Radius.zero,
                                bottomLeft: i == scelto.keys.last
                                    ? const Radius.circular(10)
                                    : Radius.zero)*/),
                        alignment: Alignment.center,
                        width: 100,
                        height: 50,
                        child: Text(
                          i,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      for (String j in scelto[i]!)
                        Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: _sfondiMaterie[j] ?? (scelto.keys.toList().indexOf(i) % 2 == 0 ? Theme.of(context).backgroundColor.withAlpha(100) : null),
                              border: Border.all(width: .1),
                              /*borderRadius: BorderRadius.only(
                                  topRight: j == scelto[i]!.last &&
                                          i == scelto.keys.first
                                      ? const Radius.circular(10)
                                      : Radius.zero,
                                  bottomRight: j.hashCode == scelto[i]!.last.hashCode &&
                                          i == scelto.keys.last
                                      ? const Radius.circular(10)
                                      : Radius.zero)*/),
                          width: 50,
                          height: 50,
                          child: Text(
                            j,
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  )
              ],
            ),
          ),
        ),

        /*DataTable(
          horizontalMargin: 0,
          headingRowColor:
              MaterialStatePropertyAll(Theme.of(context).backgroundColor),
          border: TableBorder(
              borderRadius: BorderRadius.circular(10),
              verticalInside:
                  BorderSide(color: Theme.of(context).highlightColor)),
          columns: [
            for (String i in _giorni)
              DataColumn(
                  label: Center(
                      child: Container(
                width: i == "Ore" ? 100 : 50,
                height: 50,
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(color: Theme.of(context).backgroundColor),
                child: Text(
                  i,
                  textAlign: TextAlign.center,
                ),
              )))
          ],
          rows: [
            for (String i in scelto.keys)
              DataRow(
                cells: [
                  DataCell(Center(
                      child: SizedBox(
                    width: 100,
                    child: Text(
                      i,
                      textAlign: TextAlign.center,
                    ),
                  ))),
                  for (String j in scelto[i]!)
                    DataCell(
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                              color: _sfondiMaterie[j],
                              borderRadius: BorderRadius.circular(0)),
                          margin: EdgeInsets.zero,
                          height: 50,
                          alignment: Alignment.center,
                          width: 50,
                          child: Text(
                            j,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      onTap: j != "" ? () => showDialog(
                          context: context,
                          builder: (context) => infoMateria(context, j)) : null,
                    ),
                ],
              )
          ],
          columnSpacing: 4,
          dataRowHeight: 50,
        ),*/
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
              onPressed: () => setState(() {
                    _vista = !_vista;
                  }),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Vedi ${_vista ? "Ary" : "Michi"}"),
              )),
        )
      ],
    );
  }
}

class infoMateria extends AlertDialog {
  final String materia;
  final BuildContext context;

  static const Map<String, List<String>> _info = {
    "ALG": ["Algoritmi e strutture dati", "Pinotti", "6"],
    "DIR": [
      "Diritto dell'informatica e delle Comunicazioni",
      "Florindi-Boiti",
      "4+2"
    ],
    "FIS": ["Fisica Generale", "Tosti", "6"],
    "ING": ["Ingegneria del Software", "Milani", "6"],
    "LIN": ["Linguaggi formali e compilatori", "Carpi", "6"],
    "SIS": ["Sistemi operativi con laboratorio", "Carpi-Rossi", "6+3"],
    "ETN": ["Etnografia", "Minelli", "6"],
    "ETRU": ["Etruscologia", "Rafanelli", "6"],
    "REL": ["Religione e mito nel mondo antico", "Marcattili", "6"],
    "STO": ["Storia contemporanea", "Raspadori", "9"],
  };

  infoMateria(this.context, this.materia, {super.key})
      : super(
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK")),
            ],
            title: Text(_info[materia]![0]),
            content: Text(
                "Prof: ${_info[materia]![1]}\nCFU: ${_info[materia]![2]}"));
}
