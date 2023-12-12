import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  List<Text> list = [];
  bool hasConnection = false;
  Isolate? threadListener;
  Isolate? threadSender;

  @override
  void initState() {
    super.initState();
    final port = ReceivePort();

    // new listener thread
    createBackgroundThread(threadListener, _backgroundListenerTask, port);

    // listen messages in the port and change state to display them
    port.listen((message) {
      setState(() {
        list = [...list, Text(message)];
        hasConnection = true;
      });
    });

    // If no messages has been sent in the past 5 seconds try to reconnect
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!hasConnection) {
        createBackgroundThread(threadListener, _backgroundListenerTask, port);
      } else {
        setState(() {
          hasConnection = false;
        });
      }
    });
  }

  void createBackgroundThread(
      Isolate? thread, Function(SendPort) task, ReceivePort port) async {
    if (thread != null) {
      thread.kill(priority: Isolate.immediate);
    }
    thread = await Isolate.spawn(task, port.sendPort);
  }

  static void _backgroundListenerTask(SendPort port) {
    final channel = WebSocketChannel.connect(Uri.parse('ws://10.0.2.2:8888'));
    StreamSubscription sub = channel.stream.listen((message) {
      port.send(message);
    });
  }

  static void _backgroundSenderTask(SendPort port) {
    final channel = WebSocketChannel.connect(Uri.parse('ws://10.0.2.2:8888'));
    StreamSubscription sub = channel.stream.listen((message) {
      port.send(message);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        brightness: Brightness.dark,
      ),
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Getting...'),
        ),
        body: Center(
          child: ListView(
            children: list,
          ),
        ),
      ),
    );
  }
}
