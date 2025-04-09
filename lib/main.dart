import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

Future<void> _messageHandler(RemoteMessage message) async {
  print('background message ${message.notification!.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_messageHandler);
  final fcmToken = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $fcmToken");
  runApp(MessagingTutorial());
}

class MessagingTutorial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Messaging',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(title: 'Firebase Messaging'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late FirebaseMessaging messaging;
  String? notificationText;
  List<Notification> notifications = [];
  @override
  void initState() {
    super.initState();
    messaging = FirebaseMessaging.instance;
    messaging.subscribeToTopic("messaging");
    messaging.getToken().then((value) {
      print(value);
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      print("message recieved");
      print(event.notification!.body);
      print(event.data);
      setState(() {
        notifications.add(
          Notification(body: event.notification!.body, data: event.data),
        );
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          String text = "Not Important Notification";
          if (event.data.containsKey("importance") &&
              event.data["importance"] == "True") {
            text = "Important Notification";
            FlutterRingtonePlayer().playNotification();
          }
          return AlertDialog(
            title: Text(text),
            content: Text(event.notification!.body!),
            actions: [
              TextButton(
                child: Text("Okay"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Message clicked!');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title!)),
      body: Center(
        child: Column(
          children: [
            Text("Messaging Tutorial"),
            Expanded(
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder:
                    (context, index) => NotificationTile(notifications[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  const NotificationTile(this.notification, {super.key});
  final Notification notification;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        color: notification.isImportant ? Colors.red : Colors.blue,
        child: Column(
          children: [
            Text(notification.body ?? ""),
            Text(notification.data.toString()),
          ],
        ),
      ),
    );
  }
}

class Notification {
  String? body;
  Map<String, dynamic> data;
  bool get isImportant =>
      data.containsKey("importance") && data["importance"] == "True";
  Notification({required this.body, required this.data});
}
