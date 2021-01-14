
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:sound_stream/sound_stream.dart';

void main() {
  runApp(Main());
} 

class Main extends StatefulWidget {
  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {
  RecorderStream _recorder = RecorderStream();
  PlayerStream _player = PlayerStream();

  List<Uint8List> _micChunks = [];
  bool _isRecording = false;
  bool _isPlaying = false;
 
  StreamSubscription _audioStream;
  StreamSubscription _recorderStatus;
  StreamSubscription _playerStatus;

  @override
  void initState() {
    super.initState();
    initPlugin();
  }

  @override
  void dispose() {
    _recorderStatus?.cancel();
    _playerStatus?.cancel();
    _audioStream?.cancel();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlugin() async {
    _recorderStatus = _recorder.status.listen((status) {
      if (mounted)
        setState(() {
          _isRecording = status == SoundStreamStatus.Playing;
        });
    });
    

    //write chunks in the player
    _audioStream = _recorder.audioStream.listen((data) {
      if (_isPlaying) {
        _player.writeChunk(data);
      } else {
         _micChunks.add(data);
      }
    });

    _playerStatus = _player.status.listen((status) {
      if (mounted)
        setState(() {
          _isPlaying = status == SoundStreamStatus.Playing;
        });
    });

    await Future.wait([
      _recorder.initialize(),
      _player.initialize(),
    ]);
  }


  void micClicked() async{
    void _play() async {
      await _player.start();
    // If data stream is available in the arrary
      if (_micChunks.isNotEmpty && _player.runtimeType.hashCode == _micChunks.runtimeType.hashCode) {
        // then iterate through every chunks or data in the array
        for (var data in _micChunks) {
          await _player.writeChunk(data);
        }
        // after finished playing, clear the array 
        _micChunks.clear();
      }
    } 
    //_isRecording ? _recorder.stop : _recorder.start;
    if(_isRecording){
      _recorder.stop();
    } else {
      _recorder.start();
    }

    if(_isPlaying){
      _player.stop();
    } else {
      _play();
    }
    //do something when button is pressed
    
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Mic with loud'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            IconButton( 
              iconSize: 96,
              icon: Icon(_isRecording ? Icons.mic_off : Icons.mic),
              onPressed:  micClicked,
            )
          ],),
        ),
      ),
    );
  }
}











