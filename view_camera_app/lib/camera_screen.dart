import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show basename;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _selectedVideo;
  bool _isStreaming = false;
  final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();

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
    if (_selectedVideo == null) {
      print('No video selected.');
      return;
    }

    String outputStreamUrl = 'rtsp://10.225.1.113:8554/mypath';
    //String outputStreamUrl = 'rtsp://172.17.1.63:8554/test_stream'
    String command = '-re -stream_loop -1 -i ${_selectedVideo!.path} -c copy -f rtsp -rtsp_transport tcp  $outputStreamUrl';



    print("Executing FFmpeg command: $command");
    _flutterFFmpeg.execute(command).then((result) {
      if (result == 0) {
        print("FFmpeg process completed successfully.");
      } else {
        print("FFmpeg process failed with result: $result");
        setState(() {
          _isStreaming = false;
    });
      }
    }).catchError((error) {
      print("FFmpeg process encountered an error: $error");
    });

    setState(() {
      _isStreaming = true;
    });
  }

  Future<void> _stopStreaming() async {
    _flutterFFmpeg.cancel();
    setState(() {
      _isStreaming = false;
    });
  }

  Future<void> _selectVideo() async {
    if (_isStreaming) {
      print('Cannot select new video while streaming.');
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedVideo = File(pickedFile.path);
      });
      print('Selected video: ${basename(_selectedVideo!.path)}');
    } else {
      print('No video selected.');
    }
  }

  void _goToLiveView() {

  }

  void _clearSelectedVideo() {
    if (_isStreaming) {
      print('Cannot clear selected video while streaming.');
      return;
    }

    setState(() {
      _selectedVideo = null;
    });
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
            _selectedVideo == null
                ? ElevatedButton(
                    onPressed: _selectVideo,
                    child: Text('Select Video'),
                  )
                : Column(
                    children: [
                      Text('Selected Video: ${basename(_selectedVideo!.path)}'),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isStreaming ? null : _startStreaming,
                        child: Text('Start Streaming'),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isStreaming ? _stopStreaming : null,
                        child: Text('Stop Streaming'),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _clearSelectedVideo,
                        child: Text('Clear Selected Video'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
