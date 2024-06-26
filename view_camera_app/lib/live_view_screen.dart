import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class LiveViewScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const LiveViewScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _LiveViewScreenState createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends State<LiveViewScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  CameraDescription? _currentCamera;

  @override
  void initState() {
    super.initState();
    _currentCamera = widget.cameras.first;
    _initializeController(_currentCamera!);
  }

  void _initializeController(CameraDescription camera) {
    _controller = CameraController(camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _switchCamera() async {
    if (widget.cameras.length > 1) {
      _currentCamera = (_currentCamera == widget.cameras.first)
          ? widget.cameras.last
          : widget.cameras.first;
      await _controller.dispose();
      _initializeController(_currentCamera!);
    }
  }

  void _stopLiveView() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: CameraPreview(_controller),
                ),
                Positioned(
                  bottom: 30.0,
                  right: 30.0,
                  child: FloatingActionButton(
                    onPressed: _switchCamera,
                    child: Icon(Icons.switch_camera),
                  ),
                ),
                Positioned(
                  bottom: 30.0,
                  left: 30.0,
                  child: FloatingActionButton(
                    onPressed: _stopLiveView,
                    child: Icon(Icons.stop),
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
