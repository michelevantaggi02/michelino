import 'package:animated_background/animated_background.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:michelino/calendar.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import "package:firebase_database/firebase_database.dart";
import "package:http/http.dart";

var flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void showFlutterNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  if (notification != null && android != null && !kIsWeb) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          // TODO add a proper drawable resource to android, for now using
          //      one that already exists in example app.
          icon: 'notification',
        ),
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);

  await setupFlutterNotifications();
  //showFlutterNotification(message);
  print("Handling a background message: ${message.messageId}");
}

late AndroidNotificationChannel channel;

bool isFlutterLocalNotificationsInitialized = false;

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
    'This channel is used for important notifications.', // description
    importance: Importance.high,

  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Create an Android Notification Channel.
  ///
  /// We use this channel in the `AndroidManifest.xml` file to override the
  /// default FCM channel to enable heads up notifications.
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,

  );
  isFlutterLocalNotificationsInitialized = true;
}


  void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print(Firebase.apps.isEmpty);
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  runApp(const MyApp());
}

class Not extends ChangeNotifier{

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get getMode => _mode;

  void updateMode(ThemeMode mode){
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
    return AnimatedBuilder(animation: mode, builder: (context, child) => MaterialApp(
        title: 'My Michelino',
        theme: ThemeData(
          primarySwatch: Colors.teal,
        ),
        darkTheme: ThemeData.dark(),
        themeMode: mode.getMode,
        home: const MyHomePage(title: 'My Michelino'),)
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin{
  FirebaseDatabase database = FirebaseDatabase.instance;
  List<String> oggi = [];
  Map<String, List<String>> totale = {};

  String stato = "idle";
  Map<String, String> stati = {
    "pc": "al pc",
    "idle": "a non fare niente",
    "food": "mangiando",
    "sleep": "dormendo",
    "love" : "pensando alla sua Bubi",
  };
  String nomeOggi = DateFormat("yyyy-MM-dd").format(DateTime.now());

  bool inviato = false;

  @override
  void initState() {

    database.ref("stato").onValue.listen((event) {
      if (mounted) {
        setState(() {
          stato = event.snapshot.value as String;
          if(stato == "sleep"){
            mode.updateMode(ThemeMode.dark);
          }else{
            mode.updateMode(ThemeMode.system);
          }
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

    FirebaseMessaging.instance.subscribeToTopic("michelino");
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if(!inviato) {
        ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(message.notification?.body ?? "Hai ricevuto un bacino!")));
      }
      inviato = false;
    });

    super.initState();
  }

  Map<DateTime, List<String>> eventi = {};
  TextEditingController controller = TextEditingController();

  var particle = Paint()
    ..style = PaintingStyle.stroke
  ..strokeWidth=1.0;
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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          /*DropdownButton(items: [
            for(String i in stati.keys)
              DropdownMenuItem(value: i,child: Text(i),)

          ], onChanged: (value) => database.ref("stato").set(value),
          value: stato,)*/
        ],

      ),
      body: AnimatedBackground(
        vsync: this,
        behaviour: stato == "love" ? RandomParticleBehaviour(paint: particle, options: opt): EmptyBehaviour(),
        child: Center(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Image(
                          image: AssetImage("immagini/riccio_$stato.gif"),
                        ),
                      ),
                      Text(
                        "Il tuo michelino in questo momento sta ${stati[stato]}",
                        textScaleFactor: 1.5,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              ElevatedButton(onPressed: (){
                    get(Uri.parse("http://michelevantaggi.altervista.org/michelino/"));
                    inviato = true;

                }, child: const Text("Invia un bacino")),
              const Divider(),
              ListTile(
                  leading: IconButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CalendarWidget()));
                      },
                      icon: const Icon(Icons.calendar_month)),
                  title: const Text(
                    "I piani di oggi",
                    textScaleFactor: 1.5,
                    textAlign: TextAlign.center,
                  ),
                  trailing: IconButton(
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
                                          oggi.add(controller.value.text);

                                          print(oggi);
                                          database
                                              .ref("calendario/$nomeOggi")
                                              .set(oggi);
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
                      icon: const Icon(Icons.add))),
              Expanded(
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
                            database.ref("calendario/$nomeOggi").set(oggi);
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return const Divider();
                    },
                    itemCount: oggi.length,
                  ),
                ),
              )
            ],
          ),
        )),
      ),
    );
  }
}
