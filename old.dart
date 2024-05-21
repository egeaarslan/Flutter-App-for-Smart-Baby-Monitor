import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:convert/convert.dart';
//import 'package:restart_app/restart_app.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
void main() {
  runApp(
    Phoenix(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baby Monitor Dashboard',
      home: BabyMonitor(),
    );
  }
}

class BabyMonitor extends StatefulWidget {
  @override
  _BabyMonitorState createState() => _BabyMonitorState();
}

class _BabyMonitorState extends State<BabyMonitor> {
  final AudioPlayer audioPlayer = AudioPlayer();
  String temperature = "Waiting for data...";
  String babyCrying = "Waiting for data...";
  String babyState = "Waiting for data...";
  String babyMovement = "Waiting for data...";
  String speechText = "Waiting for data...";
  String tempFilePath = '';
  int error = 0;
  @override
  void initState() {
    super.initState();
    fetchDataPeriodically();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> fetchDataPeriodically() async {
    Timer.periodic(Duration(seconds: 10), (timer) {
      fetchTemperature();
      fetchCrying();
      fetchMovement();
      fetchSpeech();
    });
  }
  void resetApp() {
    setState(() {
      temperature = "Waiting for data...";
      babyCrying = "Waiting for data...";
      babyState = "Waiting for data...";
      babyMovement = "Waiting for data...";
      speechText = "Waiting for data...";
    });
    error = 0;
    runApp(MyApp());
  }
  Future<void> fetchTemperature() async {
    try {
      var response = await http.get(Uri.parse('http://192.168.4.1/temperature')).timeout(Duration(seconds: 30));
      if (response.statusCode == 200) {
        setState(() {
          temperature = response.body.trim() + " °C";
        });
      }
    } catch (e) {
      if (error == 0) {
        error = 1;
        print('Error fetching temperature: $e');
        // Handle error here, such as presenting a button to reset the app
        showDialog(
          context: context,
          builder: (BuildContext context) {
            
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to fetch data. Would you like to reset the app?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Phoenix.rebirth(context);
                     // Reset the app
                  },
                  child: Text('Reset'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> fetchCrying() async {
    try {
      var response = await http.get(Uri.parse('http://192.168.4.1/crying')).timeout(Duration(seconds: 30));
      if (response.statusCode == 200) {
        setState(() {
          temperature = response.body.trim() + " °C";
        });
      }
    } catch (e) {
      if (error == 0) {
        error = 1;
        print('Error fetching temperature: $e');
        // Handle error here, such as presenting a button to reset the app
        showDialog(
          context: context,
          builder: (BuildContext context) {
            
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to fetch data. Would you like to reset the app?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Phoenix.rebirth(context);
                     // Reset the app
                  },
                  child: Text('Reset'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> fetchMovement() async {
    try {
      var response = await http.get(Uri.parse('http://192.168.4.1/movement')).timeout(Duration(seconds: 30));
      if (response.statusCode == 200) {
        setState(() {
          temperature = response.body.trim() + " °C";
        });
      }
    } catch (e) {
      if (error == 0) {
        error = 1;
        print('Error fetching temperature: $e');
        // Handle error here, such as presenting a button to reset the app
        showDialog(
          context: context,
          builder: (BuildContext context) {
            
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to fetch data. Would you like to reset the app?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    
                    Phoenix.rebirth(context);
                    // Reset the app
                  },
                  child: Text('Reset'),
                ),
              ],
            );
          },
        );
      }
    }
  }


  Future<void> fetchSpeech() async {
    try {
      var response = await http.get(Uri.parse('http://192.168.4.1/speech')).timeout(Duration(seconds: 30));
      if (response.statusCode == 200) {
        setState(() {
          temperature = response.body.trim() + " °C";
        });
      }
    } catch (e) {
      if (error == 0) {
        error = 1; 
        print('Error fetching temperature: $e');
        // Handle error here, such as presenting a button to reset the app
        showDialog(
          context: context,
          builder: (BuildContext context) {
            
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to fetch data. Would you like to reset the app?'),
              actions: <Widget>[
                TextButton(
                  child: Text('Reset'),
                  onPressed: () {
                    
                    Phoenix.rebirth(context);
                    // Reset the app
                  },
                  
                ),
              ],
            );
          },
        );
      }
    }
  }


  Future<void> startLiveCall() async {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LiveCallScreen(audioPlayer: audioPlayer, filePath: tempFilePath)),
    );
    try {
      var response = await http.get(Uri.parse('http://192.168.4.1/livecall'));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        tempFilePath = await convertHexToAudioFile(response.body);
        
      }
    } catch(e) {
      if (error == 0) {
        error = 1;
        print('Error fetching temperature: $e');
        // Handle error here, such as presenting a button to reset the app
        showDialog(
          context: context,
          builder: (BuildContext context) {
            
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to fetch data. Would you like to reset the app?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Phoenix.rebirth(context);
                     // Reset the app
                  },
                  child: Text('Reset'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<String> convertHexToAudioFile(String hexData) async {
    List<int> bytes = hex.decode(hexData);
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = '${tempDir.path}/temp.wav';
    File file = File(tempPath);
    await file.writeAsBytes(bytes);
    return tempPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Baby Monitor Dashboard'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            InfoCard(title: "Temperature", value: temperature),
            InfoCard(title: "Baby Crying", value: babyCrying),
            InfoCard(title: "Baby State", value: babyState),
            InfoCard(title: "Baby Movement", value: babyMovement),
            SpeechTextContainer(speechText: speechText),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: ElevatedButton(
                onPressed: startLiveCall,
                child: Text('Start Live Call'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LiveCallScreen extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final String filePath;

  const LiveCallScreen({Key? key, required this.audioPlayer, required this.filePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Call'),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center the row content
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                audioPlayer.play(DeviceFileSource(filePath));
              },
              child: Text('Listen'),
            ),
            SizedBox(width: 30), // Add space between the buttons
            ElevatedButton(
              onPressed: () {
                // Currently no functionality
              },
              child: Text('Speak'),
            ),
            SizedBox(width: 30), // Add space between the buttons
            ElevatedButton(
              onPressed: () {
                audioPlayer.stop();
                Navigator.pop(context);
              },
              child: Text('End Live Call'),
            ),
          ],
        ),
      ),
    );
  }
}


class InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const InfoCard({Key? key, required this.title, required this.value}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
        leading: Icon(Icons.info_outline),
      ),
    );
  }
}

class SpeechTextContainer extends StatelessWidget {
  final String speechText;

  const SpeechTextContainer({Key? key, required this.speechText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        speechText,
        style: TextStyle(fontSize: 16, color: Colors.black),
      ),
    );
  }
}