import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:convert/convert.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomIcons {
  static const IconData crawl = IconData(0xe001, fontFamily: 'CustomIcons');
}

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
  String temperature = 'Waiting for data...';
  String babyCrying = 'Waiting for data...';
  String babyState = 'Waiting for data...';
  String babyMovement = 'Waiting for data...';
  String speechText = 'Waiting for data...';
  String tempFilePath = '';
  int error = 0;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    fetchDataPeriodically();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await Permission.microphone.request();
    await _recorder.openAudioSession();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _recorder.closeAudioSession();
    super.dispose();
  }

  Future<void> fetchDataPeriodically() async {
    Timer.periodic(Duration(seconds: 1), (timer) {
      fetchData();
    });
  }

  Future<void> fetchData() async {
    const String dataUrl = 'http://192.168.4.1/data';
    try {
      final response = await http.get(Uri.parse(dataUrl));
      if (response.statusCode == 200) {
        final List<String> allValues = response.body.split('\n').where((item) => item.isNotEmpty).toList();
        setState(() {
          temperature = allValues.isNotEmpty ? allValues.last : 'No data yet';
          if (temperature != 'No data yet') {
            List<String> splitValues = temperature.split(',');
            if (splitValues.length >= 5) {
              temperature = splitValues[0];
              babyCrying = splitValues[1];
              babyMovement = splitValues[2];
              babyState = splitValues[3];
              speechText = splitValues[4];
            }
          }
        });
      } else {
        print('Server responded with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to fetch data: $e');
    }
  }

  Future<void> startLiveCall() async {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LiveCallScreen(audioPlayer: AudioPlayer(), filePath: tempFilePath)),
      );
      var response = await http.get(Uri.parse('http://192.168.4.1/livecall'));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        tempFilePath = await convertHexToAudioFile(response.body);
      } else {
        print('Failed to start live call');
      }
    } catch (e) {
      print('Error fetching data: $e');
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
                },
                child: Text('Reset'),
              ),
            ],
          );
        },
      );
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

  Future<void> _recordAudio() async {
    if (!_isRecording && _isInitialized) {
      Directory tempDir = await getTemporaryDirectory();
      tempFilePath = '${tempDir.path}/recorded.wav';
      await _recorder.startRecorder(
        toFile: tempFilePath,
        codec: Codec.pcm16WAV,
      );
      setState(() {
        _isRecording = true;
      });
      await Future.delayed(Duration(seconds: 5));
      await _stopRecording();
    }
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    await _sendAudioData();
  }

  Future<void> _sendAudioData() async {
    try {
      File audioFile = File(tempFilePath);
      List<int> audioBytes = await audioFile.readAsBytes();
      String hexData = hex.encode(audioBytes);
      var response = await http.post(
        Uri.parse('http://192.168.4.1/send'),
        headers: {
          'Content-Type': 'application/octet-stream',
        },
        body: hexData,
      );
      if (response.statusCode == 200) {
        print('Audio data sent successfully');
      } else {
        print('Failed to send audio data');
      }
    } catch (e) {
      print('Error sending audio data: $e');
    }
  }

  Color _getTemperatureColor(String temp) {
    try {
      double temperatureValue = double.parse(temp);
      if (temperatureValue > 38) {
        return Colors.red;
      }
    } catch (e) {}
    return Colors.white;
  }

  Color _getCryingColor(String crying) {
    if (crying.toLowerCase() == 'crying') {
      return Colors.red;
    }
    return Colors.white;
  }

  Color _getMovementColor(String movement) {
    if (movement.toLowerCase() == 'moving') {
      return Colors.red;
    }
    return Colors.white;
  }

  Color _getSpeechTextColor(String speech) {
    if (speech.toLowerCase() != 'none' && speech.toLowerCase() != 'Waiting for data...') {
      return Colors.green;
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Baby Monitor Dashboard'),
      ),
      body: _isInitialized
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  InfoCard(
                    title: "Temperature",
                    value: temperature,
                    icon: Icons.thermostat_outlined,
                    color: _getTemperatureColor(temperature),
                  ),
                  InfoCard(
                    title: "Baby Crying",
                    value: babyCrying,
                    icon: Icons.sentiment_very_dissatisfied,
                    color: _getCryingColor(babyCrying),
                  ),
                  InfoCard(title: "Baby State", value: babyState, icon: Icons.bedroom_baby),
                  InfoCard(
                    title: "Baby Movement",
                    value: babyMovement,
                    icon: CustomIcons.crawl,
                    iconPath: 'assets/images/crawl_icon.png',
                    color: _getMovementColor(babyMovement),
                  ),
                  InfoCard(
                    title: "Speech Text",
                    value: speechText,
                    icon: Icons.record_voice_over_outlined,
                    color: _getSpeechTextColor(speechText),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: ElevatedButton(
                      onPressed: startLiveCall,
                      child: Text('Start Live Call'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Center(
              child: CircularProgressIndicator(),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                audioPlayer.play(DeviceFileSource(filePath));
              },
              child: Text('Listen'),
            ),
            SizedBox(width: 30),
            ElevatedButton(
              onPressed: () async {
                // Call the record function from the parent state
                final babyMonitorState = context.findAncestorStateOfType<_BabyMonitorState>();
                if (babyMonitorState != null) {
                  await babyMonitorState._recordAudio();
                }
              },
              child: Text('Speak'),
            ),
            SizedBox(width: 30),
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
  final IconData icon;
  final String iconPath;
  final Color color;

  const InfoCard({Key? key, required this.title, required this.value, required this.icon, this.iconPath = '', this.color = Colors.white}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      color: color,
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
        leading: iconPath.isEmpty ? Icon(icon) : Image.asset(iconPath),
      ),
    );
  }
}
