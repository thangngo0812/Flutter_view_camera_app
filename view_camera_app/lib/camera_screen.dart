import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'live_view_screen.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();
  final FlutterFFmpegConfig _flutterFFmpegConfig = FlutterFFmpegConfig();
  bool _isStreaming = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _flutterFFmpegConfig.enableLogCallback((log) {
      print("FFmpeg log: $log");
    });
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) {
      print('No camera is available');
      return;
    }

    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller?.initialize();
      setState(() {});
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _startStreaming() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      print('Camera is not initialized.');
      return;
    }

    _controller!.startImageStream((CameraImage image) async {
      // Thực hiện stream trực tiếp từ camera mà không cần lưu file tạm thời
      // Giả sử bạn đã chuyển đổi CameraImage sang định dạng phù hợp

      final command = '-f rawvideo -pixel_format nv21 -video_size ${image.width}x${image.height} -i - '
          '-f rtsp -rtsp_transport tcp rtsp://171.244.206.227:554/mypath';

      _flutterFFmpeg.execute(command).then((rc) {
        print("FFmpeg process exited with rc $rc");
        if (rc != 0) {
          print("FFmpeg process exited with an error.");
        } else {
          print("FFmpeg process completed successfully.");
        }
      }).catchError((error) {
        print("FFmpeg execution failed with error: $error");
      });
    });

    setState(() {
      _isStreaming = true;
    });
  }

  Future<void> _stopStreaming() async {
    await _controller?.stopImageStream();
    _flutterFFmpeg.cancel();
    setState(() {
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
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text('Camera Control')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _goToLiveView,
              child: Text('Live View'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isStreaming ? null : _startStreaming,
              child: Text('Start'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isStreaming ? _stopStreaming : null,
              child: Text('Stop'),
            ),
          ],
        ),
      ),
    );
  }
}
