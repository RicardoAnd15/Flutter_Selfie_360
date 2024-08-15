import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart'; 

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _VideoListScreenState createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  late List<Map<String, dynamic>> _videos = [];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void dispose() {
    for (var video in _videos) {
      final controller = video['controller'] as VideoPlayerController?;
      controller?.dispose();
    }
    super.dispose();
  }

  Future<void> _loadVideos() async {
    //Acceso a directorio de videos en iOS
    final directory = await getApplicationDocumentsDirectory();
    final directoryV = Directory('${directory.path}/video360');
    final files = await directoryV

    //Acceso a directorio de videos en Android
    // final directory = Directory('/storage/emulated/0/Pictures/video360/');
    // final files = await directory
        .list()
        .where((entity) => entity is File)
        .cast<File>()
        .toList();

    final videos = await Future.wait(files.map((file) async {
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      return {
        'file': file,
        'controller': controller,
      };
    }));

    setState(() {
      _videos = videos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 209, 41, 109),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 108, 17, 119),
        title: Text(
          'Videos Grabados',
          textAlign: TextAlign.center,
          style: GoogleFonts.oswald(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 28.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: _videos.isEmpty
          ? const Center(child: Text('No hay videos grabados'))
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Tres videos por fila
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                final video = _videos[index];
                return VideoPreview(
                  controller: video['controller'] as VideoPlayerController,
                  file: video['file'] as File,
                );
              },
            ),
    );
  }
}

class VideoPreview extends StatefulWidget {
  final VideoPlayerController controller;
  final File file;

  const VideoPreview({super.key, required this.controller, required this.file});

  @override
  // ignore: library_private_types_in_public_api
  _VideoPreviewState createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late Future<void> _initializeVideoPlayerFuture;
  late bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayerFuture = widget.controller.initialize();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void stopVideo() {
    if (_isPlaying) {
      widget.controller.pause();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: SizedBox(
              width: MediaQuery.of(context).size.width *
                  0.9, // 90% del ancho de la pantalla
              height: MediaQuery.of(context).size.height *
                  0.7, // 70% de la altura de la pantalla
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: widget.controller.value.aspectRatio,
                      child: VideoPlayer(widget.controller),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_isPlaying) {
                            widget.controller.pause();
                          } else {
                            widget.controller.play();
                          }
                          setState(() {
                            _isPlaying = !_isPlaying;
                          });
                        },
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          stopVideo(); // Detener la reproducción del video
                          Navigator.of(context).pop(); // Cerrar el modal
                        },
                        child: const Text('Cerrar'),
                      ),
                      IconButton(
                        onPressed: () {
                          final xFile = XFile(widget.file.path);
                          Share.shareXFiles([xFile]);
                        }, 
                        icon : Icon(Icons.share),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return AspectRatio(
              aspectRatio: widget.controller.value.aspectRatio,
              child: VideoPlayer(widget.controller),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
