import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';

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
  int thread = 0;

  @override
  void initState() {
    super.initState();
    final port = ReceivePort();

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
        setState(() {
          thread++;
        });
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

  static void _backgroundListenerTask(SendPort port) async {
    final serverAddress = (await InternetAddress.lookup('10.0.2.2')).first;
    final clientSocket = await RawDatagramSocket.bind(
        serverAddress.type == InternetAddressType.IPv6
            ? InternetAddress.anyIPv6
            : InternetAddress.anyIPv4,
        4444);
    final ntpQuery = Uint8List(48);
    ntpQuery[0] = 0x23; // See RFC 5905 7.3

    // starts connection
    clientSocket.send(ntpQuery, serverAddress, 8888);

    clientSocket.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = clientSocket.receive();
        if (datagram != null) {
          port.send(String.fromCharCodes(datagram.data));
        }
      }
    });
  }

  static void _backgroundSenderTask(SendPort port) {}

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
