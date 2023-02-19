import 'dart:convert';

import 'package:animated_background/animated_background.dart';
import 'package:animations/animations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:michelino/calendar.dart';
import 'package:michelino/lista.dart';
import 'package:michelino/tabella.dart';
import 'firebase_options.dart';
import "package:firebase_database/firebase_database.dart";
import "package:http/http.dart";
import "package:url_launcher/url_launcher.dart";

var flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
const bool michi = bool.fromEnvironment("MICHI");

String altroToken = "";

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.instance.setAutoInitEnabled(true);

  //await setupFlutterNotifications();
  //showFlutterNotification(message);
  //print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //print(Firebase.apps.isEmpty);
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  //print('ENV : ${const bool.fromEnvironment("MICHI")}');

  runApp(const MyApp());
}

class Not extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get getMode => _mode;

  void updateMode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }
}

Not mode = Not();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: mode,
        builder: (context, child) => MaterialApp(
              /*localizationsDelegates: const [GlobalMaterialLocalizations.delegate],
              supportedLocales: [
                const Locale("en", ""),
                const Locale("it", "IT")
              ],*/
              title: 'My Michelino',
              theme: ThemeData(
                  primarySwatch: Colors.teal,
                  appBarTheme: const AppBarTheme(foregroundColor: Colors.black),
                  primaryTextTheme: const TextTheme(
                      headline6: TextStyle(color: Colors.black))),
              darkTheme: ThemeData(
                  brightness: Brightness.dark, primarySwatch: Colors.teal),
              themeMode: mode.getMode,
              home: const MyHomePage(title: 'My Michelino'),
            ));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

bool inviato = false;

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  FirebaseDatabase database = FirebaseDatabase.instance;
  List<String> oggi = [];
  Map<String, List<String>> totale = {};

  String stato = "idle";
  Map<String, String> stati = {
    "pc": "al pc",
    "idle": "a non fare niente",
    "food": "mangiando",
    "sleep": "dormendo",
    "love": "pensando alla sua Bubi",
    "music": "ascoltando la musica",
  };
  String nomeOggi = DateFormat("yyyy-MM-dd").format(DateTime.now());

  String messaggio = "";
  bool visualizzaNotifica = false;
  String linkCanzone = "";

  void controllaMusica() async {
    do {
      var risposta = await get(
          Uri.parse("https://michelevantaggi.altervista.org/michelino/spoti/"));
      //print(risposta.body);
      var canzone = jsonDecode(risposta.body);
      if (canzone != null && (stato == "idle" || stato == "music")) {
        if (mounted) {
          setState(() {
            stati["music"] = "ascoltando ${canzone["item"]["name"]}";
            linkCanzone = canzone["item"]["uri"];
            stato = "music";
          });
        }
        await Future.delayed(const Duration(seconds: 5));
      }
    } while (stato == "music" || stato == "idle");
  }

  void gestisciMessaggi(RemoteMessage message) {
    //ScaffoldMessenger.of(context).hideCurrentSnackBar();
    print("Messaggio ricevuto, stato: $stato");

    /*ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(message.notification?.body ?? "Hai ricevuto un bacino!")));*/
    if (mounted) {
      setState(() {
        visualizzaNotifica = true;
        messaggio = message.notification?.body ?? "Hai ricevuto un bacino!";
      });
    }
    //inviato = false;
  }

  @override
  void initState() {
    database.setPersistenceEnabled(true);
    database.ref("stato").onValue.listen((event) {
      if (mounted) {
        setState(() {
          stato = event.snapshot.value as String;
          if (stato == "sleep") {
            mode.updateMode(ThemeMode.dark);
          } else {
            mode.updateMode(ThemeMode.system);
          }
          controllaMusica();
        });
      }
    });
    database.ref("calendario/$nomeOggi").onValue.listen((event) {
      if (mounted) {
        setState(() {
          oggi.clear();
          for (var element in ((event.snapshot.value ?? []) as List<Object?>)) {
            if (element != null) {
              oggi.add(element as String);
            }
          }
        });
      }
    });

    FirebaseMessaging.instance.getToken().then(
        (value) => database.ref("token_${michi ? "michi" : "ary"}").set(value));
    database
        .ref("token_${michi ? "ary" : "michi"}")
        .get()
        .then((value) => altroToken = (value.value as String));

    FirebaseMessaging.instance.subscribeToTopic("michelino");

    flutterLocalNotificationsPlugin.cancelAll();

    FirebaseMessaging.instance.getInitialMessage().then((value) {
      if (value != null) {
        gestisciMessaggi(value);
      }
    });

    FirebaseMessaging.onMessageOpenedApp
        .listen((RemoteMessage message) => gestisciMessaggi(message));
    FirebaseMessaging.onMessage
        .listen((RemoteMessage message) => gestisciMessaggi(message));

    super.initState();
  }

  Map<DateTime, List<String>> eventi = {};
  TextEditingController controller = TextEditingController();

  var particle = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  ParticleOptions opt = ParticleOptions(
    image: Image.asset("immagini/emoji.png"),
    minOpacity: .5,
    maxOpacity: 1,
    spawnOpacity: 1,
    spawnMinRadius: 4,
    spawnMaxRadius: 20,
  );

  @override
  Widget build(BuildContext context) {
    //print(stato);
    return PageTransitionSwitcher(
      transitionBuilder: (Widget child, Animation<double> primaryAnimation,
          Animation<double> secondaryAnimation) {
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.scaled,
          child: child,
        );
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(widget.title),
          centerTitle: true,
          actions: null,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: AnimatedBackground(
          vsync: this,
          behaviour: stato == "love"
              ? RandomParticleBehaviour(paint: particle, options: opt)
              : EmptyBehaviour(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView(children: [
                Center(
                    child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                      child: Image(
                        image: AssetImage("immagini/riccio_$stato.gif"),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Card(
                          elevation: 100,
                          margin: const EdgeInsets.symmetric(horizontal: 0),
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(15))),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (stato == "music") {
                                      launchUrl(Uri.parse(linkCanzone),
                                          mode: LaunchMode
                                              .externalNonBrowserApplication);
                                    }
                                  },
                                  child: Text(
                                    "Il tuo michelino in questo momento sta ${stati[stato]}",
                                    textScaleFactor: 1.5,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                if (michi)
                                  DropdownButton(
                                    items: [
                                      for (String i in stati.keys)
                                        DropdownMenuItem(
                                          value: i,
                                          child: Text(i),
                                        )
                                    ],
                                    onChanged: (value) =>
                                        database.ref("stato").set(value),
                                    value: stato,
                                  ),
                                michi
                                    ? Row(
                                        children: [
                                          ButtonAzione(
                                              info: "",
                                              testo: "Invia un bacino"),
                                          ButtonAzione(
                                              info:
                                                  "?body=Il tuo Michelino è in viaggio",
                                              testo: "Invia partenza"),
                                          ButtonAzione(
                                            info:
                                                "?body=Il tuo Michelino è arrivato",
                                            testo: "Invia arrivato",
                                          ),
                                        ],
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: ButtonAzione(
                                            info: "", testo: "Invia un bacino"),
                                      ),
                                const Divider(),
                                Expanded(
                                  child: CustomList(
                                      titolo: ListTile(
                                          onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const CalendarWidget())),
                                          leading: IconButton(
                                              onPressed: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const CalendarWidget()));
                                              },
                                              icon: const Icon(
                                                  Icons.calendar_month)),
                                          title: const Text(
                                            "I piani di oggi",
                                            textScaleFactor: 1.5,
                                            textAlign: TextAlign.center,
                                          ),
                                          trailing: IconButton(
                                              onPressed: () => showDialog(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                            title: const Text(
                                                                "Aggiungi un evento"),
                                                            content: TextField(
                                                              controller:
                                                                  controller,
                                                            ),
                                                            actions: [
                                                          TextButton(
                                                              onPressed: () {
                                                                if (controller
                                                                    .value
                                                                    .text
                                                                    .isNotEmpty) {
                                                                  oggi.add(
                                                                      controller
                                                                          .value
                                                                          .text);

                                                                  //print(oggi);
                                                                  database
                                                                      .ref(
                                                                          "calendario/$nomeOggi")
                                                                      .set(
                                                                          oggi);
                                                                }
                                                                controller
                                                                    .clear();
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              child: const Text(
                                                                  "OK")),
                                                          TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context),
                                                              child: const Text(
                                                                  "Annulla"))
                                                        ]),
                                                  ),
                                              icon: const Icon(Icons.add))),
                                      context: context,
                                      giornoScelto: oggi,
                                      selezionato: DateTime.now()),
                                ),
                                /*Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ListView.separated(
                                    itemBuilder: (BuildContext context, int index) {
                                      return ListTile(
                                        title: Text(
                                          oggi[index],
                                          textAlign: TextAlign.center,
                                        ),
                                        trailing: IconButton(
                                          onPressed: () {
                                            oggi.removeAt(index);
                                            database
                                                .ref("calendario/$nomeOggi")
                                                .set(oggi);
                                          },
                                          icon:
                                              const Icon(Icons.remove_circle_outline),
                                        ),
                                      );
                                    },
                                    separatorBuilder:
                                        (BuildContext context, int index) {
                                      return const Divider();
                                    },
                                    itemCount: oggi.length,
                                  ),
                                ),
                              )*/
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                )),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CustomTable(),
                )

              ]),
              Positioned(
                top: 10,
                child: AnimatedOpacity(
                  opacity: visualizzaNotifica ? 1 : 0,
                  duration: const Duration(seconds: 1),
                  onEnd: () {
                    if (mounted) {
                      setState(() {
                        //print(stato);
                        visualizzaNotifica = false;
                      });
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        "immagini/emoji.png",
                        width: 300,
                        fit: BoxFit.fill,
                      ),
                      SizedBox(
                          width: 200,
                          child: Text(
                            messaggio,
                            textAlign: TextAlign.center,
                            textScaleFactor: 2,
                          )),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

/*
class ButtonAzione extends OutlinedButton {
  static bool _mostraInviato = false;
  ButtonAzione({super.key, required String info, required String testo,})
      : super(
            onPressed: () {
              //print("http://michelevantaggi.altervista.org/michelino/${info.isNotEmpty ? "$info&" : "?" }${altroToken.isNotEmpty ? "token=$altroToken" : ""}");
              get(Uri.parse(
                      "http://michelevantaggi.altervista.org/michelino/${info.isNotEmpty ? "$info&" : "?"}${altroToken.isNotEmpty ? "&token=$altroToken" : ""}"))
                  .then((value) {
                if(value.body == "true") {

                  _mostraInviato = true;
                  Future.delayed(const Duration(seconds: 2), () {
                    _mostraInviato = false;
                  },);
                }else{
                  print(value.body);
                }
              });

              //risposta.then((value) {print(value.body);});
              //inviato = !michi;

              if (testo == "Invia partenza") {
                launchUrl(
                    mode: LaunchMode.externalNonBrowserApplication,
                    Uri.parse("spotify:open"));
              }
            },
            child: Padding(
              padding: michi
                  ? const EdgeInsets.all(0)
                  : const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: _mostraInviato ? const Icon(Icons.check) : Text(
                testo,
                textScaleFactor: michi ? null : 1.3,
              ),
            ));
}
*/
class ButtonAzione extends StatefulWidget {
  final String info;
  final String testo;

  ButtonAzione({
    super.key,
    required this.info,
    required this.testo,
  });

  @override
  State<StatefulWidget> createState() => StatoAzione();
}

class StatoAzione extends State<ButtonAzione> {
  bool _mostraInviato = false;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
        onPressed: () {
          //print("http://michelevantaggi.altervista.org/michelino/${info.isNotEmpty ? "$info&" : "?" }${altroToken.isNotEmpty ? "token=$altroToken" : ""}");
          print("inviato");
          get(Uri.parse(
                  "http://michelevantaggi.altervista.org/michelino/${widget.info.isNotEmpty ? "${widget.info}&" : "?"}${altroToken.isNotEmpty ? "&token=$altroToken" : ""}"))
              .then((value) {
            if (value.body == "true") {
              if (mounted) {
                setState(() {
                  _mostraInviato = true;
                });
              }
              Future.delayed(
                const Duration(seconds: 2),
                () {
                  if (mounted) {
                    setState(() {
                      _mostraInviato = false;
                    });
                  }
                },
              );
            } else {
              print(value.body);
            }
          });

          //risposta.then((value) {print(value.body);});
          //inviato = !michi;

          if (widget.testo == "Invia partenza") {
            launchUrl(
                mode: LaunchMode.externalNonBrowserApplication,
                Uri.parse("spotify:open"));
          }
        },
        child: Padding(
          padding: michi
              ? const EdgeInsets.all(0)
              : const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: _mostraInviato
              ? const Icon(Icons.check)
              : Text(
                  widget.testo,
                  textScaleFactor: michi ? null : 1.3,
                ),
        ));
  }
}
