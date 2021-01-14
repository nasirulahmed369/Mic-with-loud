import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:sound_stream/sound_stream.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                iconSize: 96.0,
                icon: Icon(_isRecording ? Icons.mic_off : Icons.mic),
                onPressed: _isRecording ? _recorder.stop : _recorder.start,
              ),
              IconButton(
                iconSize: 96.0,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: _isPlaying ? _player.stop : _play,
              ),
            ],
          ),
        ),
      ),
    );
  }
}