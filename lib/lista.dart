import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomList extends StatelessWidget {
  final Widget titolo;
  final BuildContext context;
  final List<String> giornoScelto;
  final DateTime selezionato;

  CustomList(
      {super.key, required this.titolo,
      required this.context,
      required this.giornoScelto,
      required this.selezionato});

  final TextEditingController controller = TextEditingController();
  final DateFormat format = DateFormat("yyyy-MM-dd");
  final FirebaseDatabase database = FirebaseDatabase.instance;

  void editGiorno(int index) {
    controller.text = giornoScelto[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.all(16),
        title: const Text("Modifica nota"),
        content: SizedBox(
          width: 1000,
          child: TextField(
            controller: controller,
          ),
        ),
        actions: [
          ElevatedButton(
              style: const ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll(Colors.red)),
              onPressed: () {
                giornoScelto.removeAt(index);
                database
                    .ref("calendario/${format.format(selezionato)}")
                    .set(giornoScelto);
                Navigator.pop(context);
              },
              child: const Text("ELIMINA")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Annulla")),
          TextButton(
              onPressed: () {
                giornoScelto[index] = controller.text;
                database
                    .ref("calendario/${format.format(selezionato)}")
                    .set(giornoScelto);
                Navigator.pop(context);
              },
              child: const Text("Aggiorna"))
        ],
        actionsAlignment: MainAxisAlignment.spaceBetween,
      ),
    ).then((value) => controller.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
            child: Center(child: titolo),
          ),
          Expanded(
            child: ListView.separated(
              itemBuilder: (context, index) => ListTile(
                onTap: () => editGiorno(index),
                title: Text(
                  giornoScelto[index],
                  textAlign: TextAlign.center,
                ),
                /*trailing: IconButton(
                            onPressed: () {
                              giornoScelto.removeAt(index);
                              database
                                  .ref(
                                      "calendario/${format.format(selezionato)}")
                                  .set(giornoScelto);
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                          ),*/
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                tileColor: Theme.of(context).backgroundColor,
              ),
              itemCount: giornoScelto.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(),
            ),
          ),
        ],
      ),
    );
  }
}
