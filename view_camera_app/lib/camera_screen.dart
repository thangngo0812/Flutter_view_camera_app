import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:view_camera_app/live_view_screen.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isStreaming = false;
  final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();
  }

  @override
  void dispose() {
    _flutterFFmpeg.cancel();
    super.dispose();
  }

  Future<void> _startStreaming() async {
    String outputStreamUrl = 'rtsp://172.17.1.63:8554/android_test';
    //String outputStreamUrl = 'rtsp://10.225.1.113:8554/test';
    String command = '-f lavfi -i anullsrc=r=44100:cl=stereo -f android_camera -input_queue_size 50 -thread_queue_size 50 -video_size 320x240 -i 0:0 -f rtsp -rtsp_transport tcp $outputStreamUrl';

    setState(() {
      _statusMessage = 'Starting stream process...';
      _isStreaming = true; 
    });

    print("Executing FFmpeg command: $command");
    _flutterFFmpeg.execute(command).then((result) {
      if (result == 0) {
        print("FFmpeg process completed successfully.");

      } else {
        print("FFmpeg process failed with result: $result");
        setState(() {
          _statusMessage = "Streaming fail";
          _isStreaming = false;
    });
      }

    }).catchError((error) {
      setState(() {
        _statusMessage = "FFmpeg process encountered an error: $error";
        _isStreaming = false;
      });
    });
  }

  Future<void> _stopStreaming() async {
    _flutterFFmpeg.cancel();
    setState(() {
      _statusMessage = "Stop streaming";
      _isStreaming = false;
    });
  }

  void _goToLiveView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveViewScreen(cameras: widget.cameras),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video Streaming')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _goToLiveView,
              child: Text('Live View'),
            ),
            SizedBox(height: 20),
            Column(
              children: [
                ElevatedButton(
                  onPressed: _isStreaming ? null : _startStreaming,
                  child: Text('Start Streaming'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isStreaming ? _stopStreaming : null,
                  child: Text('Stop Streaming'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(_statusMessage),
          ],
        ),
      ),
    );
  }
}
