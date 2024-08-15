import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:camera/camera.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:flutter/cupertino.dart';
// import 'package:process_run/process_run.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_camera_v1_3/pages/screenstopvideo.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
// import 'package:photo_manager/photo_manager.dart';

/// Camera example home widget.
class CameraExampleHome extends StatefulWidget {
  /// Default Constructor
  const CameraExampleHome({super.key});

  @override
  State<CameraExampleHome> createState() {
    return _CameraExampleHomeState();
  }
}

class GlobalVariables {
  static final GlobalVariables _instance = GlobalVariables._internal();

  int nuevoTiempo = 5;
  int tiempoCaptura = 5;
  int calidadSeleccionada = 720;
  int fpsSeleccionado = 30;
  String nuevoFiltro = 'Ninguno';
  String combinacionSeleccionada = 'Normal-Atras-Lenta';

  factory GlobalVariables() {
    return _instance;
  }

  GlobalVariables._internal();
}

void _logError(String code, String? message) {
  // ignore: avoid_print
  print('Error: $code${message == null ? '' : '\nError Message: $message'}');
}

class _CameraExampleHomeState extends State<CameraExampleHome>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? controller;
  XFile? imageFile;
  XFile? videoFile;
  VideoPlayerController? videoController;
  VoidCallback? videoPlayerListener;
  bool enableAudio = true;
  late AnimationController _flashModeControlRowAnimationController;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;
  // Counting pointers (number of user fingers on screen)
  int _pointers = 0;
  // Declaración de variables para el temporizador
  late Timer _timer;
  int _secondsElapsed = 0;
  late Timer _recordTimer;
  String _countdownText = ''; // Variable para almacenar el texto del contador
  //Variables para el uso y seleccion de musica 
  final audioPlayer = AudioPlayer();
  String UMusic = '';
  String UMarco = '';
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _marco = TextEditingController();
  // final TextEditingController _video2 = TextEditingController();
  // final TextEditingController _video3 = TextEditingController();
  //Variables para el cambio de la duracion de grabación del video original
  var ListaTiempos = ['5', '10', '15'];
  String? dropdownValue = '5';
  int? intValue;
  bool isPlaying = false;
  //Variables para el cambio de tiempo en que se tomara el video
  var Temporizador = ['3', '5', '8'];
  int? nuevoT;
  String? TemporizadorNormal = '5';
  //Variables para el cambio de resolucion del video generado
  var Calidades = ['480', '720', '1080', '2160'];
  String? calidadB = '720';
  int? nuevaCal;
  //Variables para el cambio de velocidad de fps en el video generado
  var Fpss = ['30', '120', '240'];
  String? fpsB = '30';
  int? nuevoFps;
  //Variables para cambio de secuencia de reproduccion de videos generados
  var tiposCombinacion = [
    'Normal-Lenta-Normal',
    'Normal-Atras-Lenta',
    'Normal-Rapida-Lenta',
    'Rapida-Lenta-Normal',
    'Normal-Atras-Lenta-Rapida',
    'Normal-Rapida-Atras-Rapida-Lenta'
  ];
  String combinacionB = 'Normal-Atras-Lenta';
  //Variables para cambio de filtro en la generacion de videos
  var filtros = ['Ninguno', 'Verde', 'Rojo', 'Verde total', 'Azul total', 'Rojo claro', 'Verde claro', 'Azul claro'];
  String flB = 'Ninguno';
  int? nuevoFil;
  //Variables para pruebas de cambio de marco png en el video generado
  // final String marco1path = "assets/images/marco1.png";

  // late VideoPlayerController _video1path;
  


  @override
  void initState() {
    super.initState();
    // _video1path = VideoPlayerController.asset('assets/videos/prueba1.mp4')
    //   ..initialize().then((_) {
    //     setState(() {
    //       _video1path.play();
    //     });
    //   });
    // Inicializar el temporizador
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
    WidgetsBinding.instance.addObserver(this);

    _flashModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    // Cancelar el temporizador cuando el widget se elimine
    _recordTimer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _flashModeControlRowAnimationController.dispose();
    _timer.cancel(); // Cancelar el temporizador al salir de la pantalla
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCameraController(cameraController.description);
    }
  }

  ///inicio de la app
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: Color.fromARGB(255, 108, 17, 119),
        child: SingleChildScrollView(
            child: Container(
          color: Color.fromARGB(255, 108, 17, 119),
          child: Column(
            children: [
              // Text('el contenido de la variable es $UMusic'),
              AppBar(
                title: Text(
                  'Configuraciones',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.oswald(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 28.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                backgroundColor: Color.fromARGB(255, 209, 41, 109),
              ),

              //Apartado de tiempo de captura de la fotografia
              // Image.asset(marco1path),
              const Card(
                color: Color.fromARGB(255, 209, 41, 109),
                margin: const EdgeInsets.all(12.0),
                child: Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Text(
                    "Tiempo de captura",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontFamily: 'GoogleFonts',
                      fontSize: 18.0,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
              ),

              Container(
                width: 250,
                height: 50,
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: DropdownButton(
                    items: Temporizador.map((String item) {
                      return DropdownMenuItem(value: item, child: Text(item));
                    }).toList(),
                    onChanged: (String? nuevoTiempo) {
                      setState(() {
                        TemporizadorNormal = nuevoTiempo!;
                        nuevoT = int.parse(TemporizadorNormal!);
                        GlobalVariables().tiempoCaptura = nuevoT!;
                      });
                    },
                    value: TemporizadorNormal,
                    underline:
                        SizedBox(), // Opcional: Eliminar la línea de subrayado
                  ),
                ),
              ),

              //Apartado de duracion de la grabacion

              const Card(
                color: Color.fromARGB(255, 209, 41, 109),
                margin: const EdgeInsets.all(12.0),
                child: Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Text(
                    "Tiempo de video",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontFamily: 'GoogleFonts',
                      fontSize: 18.0,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
              ),
              Container(
                width: 250,
                height: 50,
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: DropdownButton(
                    items: ListaTiempos.map((String item) {
                      return DropdownMenuItem(value: item, child: Text(item));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        dropdownValue = newValue!;
                        intValue = int.parse(dropdownValue!);
                        GlobalVariables().nuevoTiempo = intValue!;
                      });
                    },
                    value: dropdownValue,
                    underline:
                        SizedBox(), // Opcional: Eliminar la línea de subrayado
                  ),
                ),
              ),

              //Apartado de seleccion de musica de fondo

              const Card(
                color: Color.fromARGB(255, 209, 41, 109),
                margin: const EdgeInsets.all(12.0),
                child: Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Text(
                    "Musica de fondo",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontFamily: 'GoogleFonts',
                      fontSize: 18.0,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
              ),

              Container(
                child: Center(
                  child: ElevatedButton(
                    child: Text('Seleccionar'),
                    onPressed: () {
                      setAudio();
                    },
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: TextField(
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                  controller: _controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: ('Musica seleccionada'),
                    labelStyle:
                        TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                    suffixIcon: IconButton(
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      color: Colors.white,
                      onPressed: () async {
                        await playPauseAudio();
                      },
                    ),
                    icon: IconButton(onPressed: 
                    (){
                      quitAudio();
                    }, 
                    icon: Icon(Icons.close),
                    color: Colors.white,
                    ),
                  ),
                  readOnly: true,
                ),
              ),

              // Container(
              //   child: Center(
              //     child: ElevatedButton(
              //       child: Text('Seleccionar video'),
              //       onPressed: () {
              //         setVideo1();
              //       },
              //     ),
              //   ),
              // ),

              // Padding(
              //   padding: EdgeInsets.all(16.0),
              //   child: TextField(
              //     style: TextStyle(
              //       color: Color.fromARGB(255, 255, 255, 255),
              //     ),
              //     controller: _video1,
              //     decoration: InputDecoration(
              //       border: OutlineInputBorder(),
              //       labelText: ('Video 1 seleccionado'),
              //       labelStyle:
              //           TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              //     ),
              //     readOnly: true,
              //   ),
              // ),

              // Container(
              //   child: Center(
              //     child: ElevatedButton(
              //       child: Text('Seleccionar video 2'),
              //       onPressed: () {
              //         setVideo2();
              //       },
              //     ),
              //   ),
              // ),

              // Padding(
              //   padding: EdgeInsets.all(16.0),
              //   child: TextField(
              //     style: TextStyle(
              //       color: Color.fromARGB(255, 255, 255, 255),
              //     ),
              //     controller: _video2,
              //     decoration: InputDecoration(
              //       border: OutlineInputBorder(),
              //       labelText: ('Video 2 seleccionado'),
              //       labelStyle:
              //           TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              //     ),
              //     readOnly: true,
              //   ),
              // ),

              // Container(
              //   child: Center(
              //     child: ElevatedButton(
              //       child: Text('Seleccionar video 3'),
              //       onPressed: () {
              //         setVideo3();
              //       },
              //     ),
              //   ),
              // ),

              // Padding(
              //   padding: EdgeInsets.all(16.0),
              //   child: TextField(
              //     style: TextStyle(
              //       color: Color.fromARGB(255, 255, 255, 255),
              //     ),
              //     controller: _video3,
              //     decoration: InputDecoration(
              //       border: OutlineInputBorder(),
              //       labelText: ('Video 3 seleccionado'),
              //       labelStyle:
              //           TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              //     ),
              //     readOnly: true,
              //   ),
              // ),

              // Container(
              //   child: Center(
              //     child: ElevatedButton(
              //       child: Text('Seleccionar'),
              //       onPressed: () {
              //         setAudio();
              //       },
              //     ),
              //   ),
              // ),
              // Padding(
              //   padding: EdgeInsets.all(16.0),
              //   child: TextField(
              //     style: TextStyle(
              //       color: Color.fromARGB(255, 255, 255, 255),
              //     ),
              //     controller: _controller,
              //     decoration: InputDecoration(
              //       border: OutlineInputBorder(),
              //       labelText: ('Musica seleccionada'),
              //       labelStyle:
              //           TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              //       suffixIcon: IconButton(
              //         icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              //         color: Colors.white,
              //         onPressed: () async {
              //           await playPauseAudio();
              //         },
              //       ),
              //     ),
              //     readOnly: true,
              //   ),
              // ),

              //Apartado de seleccion de calidad de video

              const Card(
                color: Color.fromARGB(255, 209, 41, 109),
                margin: const EdgeInsets.all(12.0),
                child: Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Text(
                    "Calidad de video",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontFamily: 'GoogleFonts',
                      fontSize: 18.0,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
              ),

              Container(
                width: 250,
                height: 50,
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: DropdownButton(
                    items: Calidades.map((String item) {
                      return DropdownMenuItem(value: item, child: Text(item));
                    }).toList(),
                    onChanged: (String? nuevaCalidad) {
                      setState(() {
                        calidadB = nuevaCalidad!;
                        nuevaCal = int.parse(calidadB!);
                        GlobalVariables().calidadSeleccionada = nuevaCal!;
                      });
                    },
                    value: calidadB,
                    underline:
                        SizedBox(), // Opcional: Eliminar la línea de subrayado
                  ),
                ),
              ),

              //Apartado de seleccion de FPS's

              const Card(
                color: Color.fromARGB(255, 209, 41, 109),
                margin: const EdgeInsets.all(12.0),
                child: Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Text(
                    "Velocidad de FPS's",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontFamily: 'GoogleFonts',
                      fontSize: 18.0,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
              ),

              Container(
                width: 250,
                height: 50,
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: DropdownButton(
                    items: Fpss.map((String item) {
                      return DropdownMenuItem(value: item, child: Text(item));
                    }).toList(),
                    onChanged: (String? FpsN) {
                      setState(() {
                        fpsB = FpsN!;
                        nuevoFps = int.parse(fpsB!);
                        GlobalVariables().fpsSeleccionado = nuevoFps!;
                      });
                    },
                    value: fpsB,
                    underline:
                        SizedBox(), // Opcional: Eliminar la línea de subrayado
                  ),
                ),
              ),

              //Apartado de seleccion de tipo de combinacion de videos
              
              // Image.asset(
              //   'assets/images/marco1.png',
              //   fit: BoxFit.cover,
              // ),
              const Card(
                color: Color.fromARGB(255, 209, 41, 109),
                margin: const EdgeInsets.all(12.0),
                child: Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Text(
                    "Tipo de combinación",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontFamily: 'GoogleFonts',
                      fontSize: 18.0,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
              ),

              Container(
                width: 250,
                height: 50,
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: DropdownButton(
                    isExpanded: true,
                    items: tiposCombinacion.map((String item) {
                      return DropdownMenuItem(value: item, child: Text(item));
                    }).toList(),
                    // hint: Text('Seleccione una opción'),
                    onChanged: (String? combinacionN) {
                      setState(() {
                        combinacionB = combinacionN!;
                        GlobalVariables().combinacionSeleccionada =
                            combinacionB;
                      });
                    },
                    value: combinacionB,
                    underline:
                        SizedBox(), // Opcional: Eliminar la línea de subrayado
                  ),
                ),
              ),

              //Tipos de filtro

              const Card(
                color: Color.fromARGB(255, 209, 41, 109),
                margin: const EdgeInsets.all(12.0),
                child: Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Text(
                    "Filtro de video",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontFamily: 'GoogleFonts',
                      fontSize: 18.0,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
              ),

              Container(
                width: 250,
                height: 50,
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: DropdownButton(
                    items: filtros.map((String item) {
                      return DropdownMenuItem(value: item, child: Text(item));
                    }).toList(),
                    onChanged: (String? nuevoFilt) {
                      setState(() {
                        flB = nuevoFilt!;
                        GlobalVariables().nuevoFiltro = flB;
                      });
                    },
                    value: flB,
                    underline:
                        SizedBox(), // Opcional: Eliminar la línea de subrayado
                  ),
                ),
              ),

              const Card(
                color: Color.fromARGB(255, 209, 41, 109),
                margin: const EdgeInsets.all(12.0),
                child: Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Text(
                    "Marco de video",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontFamily: 'GoogleFonts',
                      fontSize: 18.0,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
              ),

              Container(
                child: Center(
                  child: ElevatedButton(
                    child: Text('Seleccionar marco'),
                    onPressed: () {
                      setMarco();
                    },
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: TextField(
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                  controller: _marco,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: ('Marco seleccionado'),
                    labelStyle:
                        TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                    suffixIcon: IconButton(onPressed: 
                    (){
                      quitMarco();
                    }, 
                    icon: Icon(Icons.close),
                    color: Colors.white,
                    ),
                  ),
                  readOnly: true,
                ),
              ),


            ],
          ),
        )),
      ),

      //Diseño de la pantalla principal de la aplicacion

      appBar: AppBar(
        title: Text(
          'Cámara 360',
          textAlign: TextAlign.center,
          style: GoogleFonts.oswald(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 28.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              CupertinoIcons.archivebox_fill,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VideoListScreen()),
              );
            },
          )
        ],
        
        backgroundColor: const Color.fromARGB(
            255, 108, 17, 119), // Cambio de color de fondo de la AppBar
        centerTitle: true, // Centra el título en la AppBar
      ),

      //Apartado de la previsualizacion de la camara

      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 209, 41, 109),
                border: Border.all(
                  color:
                      controller != null && controller!.value.isRecordingVideo
                          ? Colors.redAccent
                          : const Color.fromARGB(255, 108, 17, 119),
                  width: 10.0,
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Center(
                      child: _cameraPreviewWidget(),
                    ),
                  ),
                  if (controller != null && controller!.value.isRecordingVideo)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          '${(_secondsElapsed ~/ 60).toString().padLeft(2, '0')}:${(_secondsElapsed % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.white, // Cambio de color a blanco
                            fontSize: 30.0,
                          ),
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: Text(
                        _countdownText,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 60.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _captureControlRowWidget(),
        ],
      ),
    );
  }

  //función para detener automáticamente la grabación después de 8 segundos
  void stopRecordingAutomatically() {
    onStopButtonPressed();
    _resetTimer(); // Reiniciar el temporizador para futuras grabaciones
  }

  /// Muestra la vista previa de la cámara (o un mensaje si la vista previa no está disponible).
  Widget _cameraPreviewWidget() {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return const Text(
        'Elije una cámara',
        style: TextStyle(
          color: Colors.white,
          fontSize: 28.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return Listener(
        onPointerDown: (_) => _pointers++,
        onPointerUp: (_) => _pointers--,
        child: CameraPreview(
          controller!,
          child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
            );
          }),
        ),
      );
    }
  }

  ///calcula nivel de scala
  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> playPauseAudio() async {
    if (UMusic != null) {
      if (isPlaying) {
        await audioPlayer.pause();
        setState(() {
          isPlaying = false;
        });
      } else {
        await audioPlayer.play(DeviceFileSource(UMusic!));
        setState(() {
          isPlaying = true;
        });
      }
    }
  }

  Future<void> quitAudio() async{
    if (UMusic != null) {
      await audioPlayer.pause();
        setState(() {
          isPlaying = false;
        });
      UMusic = '';
      _controller.text = '';
    }else{
      showInSnackBar('No hay una música seleccionada.');
    }
  }

  Future<void> quitMarco() async{
    if (UMarco != null) {
      UMarco = '';
      _marco.text = '';
    }else{
      showInSnackBar('No hay un marco seleccionado.');
    }
  }

  /// actualizaciones de zoom
  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (controller == null || _pointers != 2) {
      return;
    }

    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await controller!.setZoomLevel(_currentScale);
  }

  // Future setAudio() async {
  //   if (await Permission.storage.request().isGranted) {
  //     await audioPlayer.setReleaseMode(ReleaseMode.loop);

  //     final result = await FilePicker.platform.pickFiles(
        // type: FileType.custom,
        // allowedExtensions: [
        //   'mp3',
        //   'wav',
        //   'm4a',
        //   'flac'
        // ], // Extensiones de archivos de audio permitidos
        // allowMultiple: true,
  //     );

  //     if (result != null && result.files.isNotEmpty) {
  //       final randomIndex = Random().nextInt(result.files.length);
  //       final randomFile = result.files[randomIndex];

  //       if (randomFile.path != null) {
  //         final file = File(randomFile.path!);
  //         setState(() {
  //           UMusic = file.path;
  //           _controller.text = file.path.split('/').last;
  //         });
  //         await audioPlayer.setSourceDeviceFile(file.path);
  //       }
  //     }
  //   }
  // }


//   Future setVideo1() async {
//   if (await Permission.storage.request().isGranted) {
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.video, // Filtrar solo archivos de video
//     );

//     if (result != null && result.files.single.path != null) {
//       final file = File(result.files.single.path!);
//       setState(() {
//         // Actualiza la ruta del video seleccionado
//         final videoPath1 = file.path;
//         print('Ruta del video: $videoPath1');
//         _video1.text = file.path.split('/').last;
//       });
//     }
//   }
// }

// Future setVideo2() async {
//   if (await Permission.storage.request().isGranted) {
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.video, // Filtrar solo archivos de video
//     );

//     if (result != null && result.files.single.path != null) {
//       final file = File(result.files.single.path!);
//       setState(() {
//         // Actualiza la ruta del video seleccionado
//         final videoPath2 = file.path;
//         print('Ruta del video: $videoPath2');
//         _video2.text = file.path.split('/').last;
//       });
//     }
//   }
// }

// Future setVideo3() async {
//   if (await Permission.storage.request().isGranted) {
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.video, // Filtrar solo archivos de video
//     );

//     if (result != null && result.files.single.path != null) {
//       final file = File(result.files.single.path!);
//       setState(() {
//         // Actualiza la ruta del video seleccionado
//         final videoPath3 = file.path;
//         print('Ruta del video: $videoPath3');
//         _video3.text = file.path.split('/').last;
//       });
//     }
//   }
// }

  Future setAudio() async {
    if (await Permission.storage.request().isGranted) {
      await audioPlayer.setReleaseMode(ReleaseMode.loop);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'mp3',  
          'wav',
          'm4a',
          'flac'
        ],
        allowMultiple: true,
      );

      if (result != null && result.files.single.path != null) {

        // Obtiene la ruta del archivo

        final file = File(result.files.single.path!);
        setState(() {
          UMusic = file.path;
          _controller.text = file.path.split('/').last;
        });
        await audioPlayer.setSourceDeviceFile(UMusic);
      }
    }
  }

  Future setMarco() async {
    if (await Permission.storage.request().isGranted) {
      await audioPlayer.setReleaseMode(ReleaseMode.loop);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'png'
        ],
        allowMultiple: true,
      );

      if (result != null && result.files.single.path != null) {

        // Obtiene la ruta del archivo

        final file = File(result.files.single.path!);
        setState(() {
          UMarco = file.path;
          _marco.text = file.path.split('/').last;
        });
      }
    }
  }

  // Función para reiniciar el temporizador

  void _resetTimer() {
    setState(() {
      _secondsElapsed = 0;
    });
  }

  ///saca los botones de abajo de cambio de camara y grabar
  Widget _captureControlRowWidget() {
    final CameraController? cameraController = controller;

    return Container(
      color: const Color.fromARGB(255, 108, 17, 119),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: GestureDetector(
                onTap: () {
                  if (_cameras.length > 1) {
                    final currentCamera = controller?.description;
                    final newCamera =
                        _cameras.firstWhere((c) => c != currentCamera);
                    onNewCameraSelected(newCamera);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 209, 41, 109), // Fondo
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.loop,
                    color: Colors.white,
                    size: 50.0,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20.0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: GestureDetector(
                onTap: () {
                  if (cameraController != null &&
                      cameraController.value.isInitialized) {
                    if (cameraController.value.isRecordingVideo) {
                      onStopButtonPressed();
                      _resetTimer();
                    } else {
                      onVideoRecordButtonPressed();
                      _resetTimer();
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: const BoxDecoration(
                    color:
                        Color.fromARGB(255, 209, 41, 109), // Fondo transparente
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    cameraController != null &&
                            cameraController.value.isRecordingVideo
                        ? Icons.stop
                        : Icons.videocam,
                    color: Colors.white,
                    size: 50.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //saca los errores
  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  ///seleccion de camaras
  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      return controller!.setDescription(cameraDescription);
    } else {
      return _initializeCameraController(cameraDescription);
    }
  }

  ///inicializacion de las camaras
  Future<void> _initializeCameraController(
      CameraDescription cameraDescription) async {
    final CameraController cameraController = CameraController(
      cameraDescription,
      kIsWeb ? ResolutionPreset.max : ResolutionPreset.max,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) {
        requestPermissions();
        setState(() {});
      }
      if (cameraController.value.hasError) {
        showInSnackBar(
            'Camera error ${cameraController.value.errorDescription}');
      }
    });

    try {
      await cameraController.initialize();
      await Future.wait(<Future<Object?>>[
        // The exposure mode is currently not supported on the web.

        cameraController
            .getMaxZoomLevel()
            .then((double value) => _maxAvailableZoom = value),
        cameraController
            .getMinZoomLevel()
            .then((double value) => _minAvailableZoom = value),
      ]);
    } on CameraException catch (e) {
      switch (e.code) {
        case 'CameraAccessDenied':
          showInSnackBar('Ha denegado el acceso a la cámara.');
        case 'CameraAccessDeniedWithoutPrompt':
          // iOS only
          showInSnackBar(
              'Vaya a la Configuración de la aplicación para habilitar el acceso a la cámara.');
        case 'CameraAccessRestricted':
          // iOS only
          showInSnackBar('El acceso a la cámara está restringido.');
        case 'AudioAccessDenied':
          showInSnackBar('Has denegado el acceso al audio.');
        case 'AudioAccessDeniedWithoutPrompt':
          // iOS only
          showInSnackBar(
              'Vaya a la Configuración de la aplicación para habilitar el acceso al audio.');
        case 'AudioAccessRestricted':
          // iOS only
          showInSnackBar('El acceso al audio está restringido.');
        default:
          _showCameraException(e);
          break;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  ///inicia la grabacion y actualiza la interfaz
  void onVideoRecordButtonPressed() {
    _startCountdown(GlobalVariables().tiempoCaptura);
  }

  void _startCountdown(int count) {
    if (count >= 0) {
      _countdownText = count == 0 ? 'REC' : count.toString();
      setState(() {});
      Future.delayed(const Duration(seconds: 1), () {
        _startCountdown(count - 1);
      });
    } else {
      startVideoRecording().then((_) {
        _resetTimer();
        if (mounted) {
          setState(() {});
        }
        _recordTimer = Timer(Duration(seconds: GlobalVariables().nuevoTiempo),
            stopRecordingAutomatically);
      });
    }
  }

  void onStopButtonPressed() {
    stopVideoRecording().then((XFile? file) async {
      if (mounted) {
        setState(() {});
        _countdownText = '';
      }
      if (file != null) {
        showInSnackBar('Vídeo grabado en ${file.path}');

        // Obtener el directorio DCIM en el almacenamiento externo

        //Apartado para obtener directorio en dispositivos iOS

        await requestPermissions();

        // Obtener el directorio de documentos
        final directory = await getApplicationDocumentsDirectory();
        final video360Directory = Directory('${directory.path}/video360');

        if (!(await video360Directory.exists())) {
          await video360Directory.create(recursive: true);
        }

        //Final de apartado para obtener directorio en dispositivos iOS

      //Codigo de validacion de directorio de almacenamiento para dispositivos Android 

        // const String dcimDirectoryPath = '/storage/emulated/0/Pictures';
        // Directory dcimDirectory = Directory(dcimDirectoryPath);
        // if (!(await dcimDirectory.exists())) {
        //   // Manejar el caso si el directorio DCIM no existe
        //   print('Error: El directorio Pictures no existe.');
        
        //   return;
        // }

        // // Crear la carpeta video360 dentro de la carpeta Pictures si no existe
        // const String video360DirectoryPath = '$dcimDirectoryPath/video360';
        // Directory video360Directory = Directory(video360DirectoryPath);
        // if (!(await video360Directory.exists())) {
        //   await video360Directory.create(recursive: true);
        // }
        // print('Directorio de la carpeta video360: $video360DirectoryPath');

      //Final de codigo para directorio de almacenamiento de videos para dispositivos Android

        // Copiar el archivo de vídeo a la carpeta video360

        final String newFilePath =
            '${video360Directory.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
        print('Copiando archivo a: $newFilePath');
        await copyAndChangeVideoQuality(newFilePath, UMarco, file.path);

        // Crear una versión en cámara lenta del video

        final String slowMotionFilePath =
            '${video360Directory.path}/${DateTime.now().millisecondsSinceEpoch}_slow.mp4';
        await createSlowMotionVideo(newFilePath, slowMotionFilePath);

        // Crear una versión en reversa del video

        final String reversedVideoPath =
            '${video360Directory.path}/${DateTime.now().millisecondsSinceEpoch}_reversed.mp4';
        await createReversedVideo(newFilePath, reversedVideoPath);

        // Crear una versión rapida del video

        final String fastVideoPath =
            '${video360Directory.path}/${DateTime.now().millisecondsSinceEpoch}_fast.mp4';
        await createFastVideo(newFilePath, fastVideoPath);

        final String mixedNRVideoPath =
            '${video360Directory.path}/${DateTime.now().millisecondsSinceEpoch}_mixedNR.mp4';
        await createMixVideoNR(newFilePath, mixedNRVideoPath);

        final String mixedALRVideoPath =
            '${video360Directory.path}/${DateTime.now().millisecondsSinceEpoch}_mixedALR.mp4';
        await createMixVideoALR(newFilePath, mixedALRVideoPath);

        // Combinar los videos

        final String combinedwoaVideoPath =
            '${video360Directory.path}/${DateTime.now().millisecondsSinceEpoch}_combinedwoa.MP4';

        String comb = GlobalVariables().combinacionSeleccionada;

        switch (comb) {
          case 'Normal-Atras-Lenta':
            await combineVideos(
                newFilePath,
                reversedVideoPath,
                slowMotionFilePath,
                slowMotionFilePath,
                "",
                "",
                combinedwoaVideoPath);
            break;
          case 'Normal-Rapida-Lenta':
            await combineVideos(newFilePath, slowMotionFilePath, fastVideoPath,
                fastVideoPath, "", "", combinedwoaVideoPath);
            break;
          case 'Normal-Lenta-Normal':
            await combineVideos(newFilePath, slowMotionFilePath, newFilePath,
                "", "", "", combinedwoaVideoPath);
            break;
          case 'Rapida-Lenta-Normal':
            await combineVideos(newFilePath, slowMotionFilePath, fastVideoPath,
                fastVideoPath, "", "", combinedwoaVideoPath);
            break;
          case 'Normal-Atras-Lenta-Rapida':
            await combineVideos(newFilePath, slowMotionFilePath,
                reversedVideoPath, fastVideoPath, "", "", combinedwoaVideoPath);
            break;
          case 'Normal-Rapida-Atras-Rapida-Lenta':
            await combineVideos(
                mixedNRVideoPath,
                mixedALRVideoPath,
                mixedNRVideoPath,
                mixedALRVideoPath,
                mixedNRVideoPath,
                mixedALRVideoPath,
                combinedwoaVideoPath);
            break;
          default:
            await combineVideos(newFilePath, reversedVideoPath,
                slowMotionFilePath, fastVideoPath, "", "", combinedwoaVideoPath);
        }

        final String combinedwaVideoPath =
            '${video360Directory.path}/${DateTime.now().millisecondsSinceEpoch}_combinedwa.mp4';
        await combinedwaVideos(combinedwoaVideoPath, UMusic ,combinedwaVideoPath);

        // final String testLocalVideoPath =
        //     '$video360DirectoryPath/${DateTime.now().millisecondsSinceEpoch}_locales.mp4';
        // await testLocalVideos(combinedwoaVideoPath, testLocalVideoPath);

        // Actualizar la galería para que muestre los vídeos
        await File(newFilePath).delete();
        await File(slowMotionFilePath).delete();
        await File(reversedVideoPath).delete();
        await File(fastVideoPath).delete();
        await File(mixedALRVideoPath).delete();
        await File(mixedNRVideoPath).delete();
        _refreshGallery(combinedwoaVideoPath);
        _refreshGallery(combinedwaVideoPath);

        // Abrir la pantalla de la lista de vídeos después de guardar
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VideoListScreen(),
          ),
        );
      }
    });
  }

  //Funcion para combinar los videos combinados con un audio

  Future<void> combinedwaVideos(String combineVideo, String musica ,String combinewaVideo) async {
      final String command =
          '-i $combineVideo -i $musica -c:v copy -c:a aac -map 0:v -map 1:a -shortest $combinewaVideo';
          // '-i $combineVideo -i $UMusic -c:v copy -c:a aac -strict -2 -y $combineVideo';
          // '-i $combineVideo $combinewaVideo';
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        print('Error al crear el video combinado con audio');
      }
    }

    // funcion para combinar los tres videos en uno solo

  Future<void> combineVideos(
      String originalVideoPath,
      String slowMotionVideoPath,
      String reversedVideoPath,
      String fastVideoPath,
      String mixedNRVideoPath,
      String mixedALRVideoPath,
      String outputPath) async {
    String comb = GlobalVariables().combinacionSeleccionada;

    final String command;

    switch (comb) {
      case 'Normal-Atras-Lenta':
        // command = '-i $originalVideoPath -i $slowMotionVideoPath -i $reversedVideoPath -i $UMusic -filter_complex "[0:v][1:v][2:v]concat=n=3:v=1:a=0[outv]" -map "[outv]" -map 3:a -c:v libx264 -c:a aac -shortest -y Hola5.mp4';
        // command = '-i $originalVideoPath -i $slowMotionVideoPath -i $reversedVideoPath -i $UMusic -filter_complex "[0:v][1:v][2:v]concat=n=3:v=1:a=0[outv];[3:a]aresample=async=1:first_pts=0[outa]" -map "[outv]" -map "[outa]" -shortest -y $outputPath';
        // command = '-i $originalVideoPath -i $slowMotionVideoPath -i $reversedVideoPath -i $UMusic -filter_complex "[0:v][1:v][2:v]concat=n=3:v=1:a=0[v];[3:a]atrim=end=19,asetpts=PTS-STARTPTS[a];[v][a]concat=n=1:v=1:a=1[outv][outa]" -map "[outv]" -map "[outa]" -shortest -c:v libx264 -c:a aac -y $outputPath';
        command = '-i $originalVideoPath -i $slowMotionVideoPath -i $reversedVideoPath -filter_complex "[0:v][1:v][2:v]concat=n=3:v=1[outv]" -map "[outv]" -strict -2 -y $outputPath';
        break;
      case 'Normal-Rapida-Lenta':
        command =
            '-i $originalVideoPath -i $fastVideoPath -i $slowMotionVideoPath -filter_complex "[0:v][1:v][2:v]concat=n=3:v=1[outv]" -map "[outv]" -strict -2 -y $outputPath';
        break;
      case 'Normal-Lenta-Normal':
        command =
            '-i $originalVideoPath -i $slowMotionVideoPath -i $originalVideoPath -filter_complex "[0:v][1:v][2:v]concat=n=3:v=1[outv]" -map "[outv]" -strict -2 -y $outputPath';
        // command = '-i $originalVideoPath -i $slowMotionVideoPath -i $originalVideoPath -i $UMusic -filter_complex "[0:v][1:v][2:v]concat=n=3:v=1:a=0[v];[3:a]atrim=end=19,asetpts=PTS-STARTPTS[a];[v][a]concat=n=1:v=1:a=1[outv][outa]" -map "[outv]" -map "[outa]" -shortest -c:v libx264 -preset veryfast -y $outputPath';
        break;
      case 'Rapida-Lenta-Normal':
        command =
            '-i $fastVideoPath -i $slowMotionVideoPath -i $originalVideoPath -filter_complex "[0:v][1:v][2:v]concat=n=3:v=1[outv]" -map "[outv]" -strict -2 -y $outputPath';
        break;
      case 'Normal-Atras-Lenta-Rapida':
        command =
            '-i $originalVideoPath -i $reversedVideoPath -i $slowMotionVideoPath -i $fastVideoPath -filter_complex "[0:v][1:v][2:v][3:v]concat=n=4:v=1[outv]" -map "[outv]" -strict -2 -y $outputPath';
        break;
      case 'Normal-Rapida-Atras-Rapida-Lenta':
        command =
            '-i $mixedNRVideoPath -i $mixedALRVideoPath -filter_complex "[0:v][1:v]concat=n=2:v=1[outv]" -map "[outv]" -strict -2 -y $outputPath';
        break;
      default:
        command =
            '-i $originalVideoPath -i $slowMotionVideoPath -i $reversedVideoPath -filter_complex "[0:v][1:v][2:v]concat=n=3:v=1[outv]" -map "[outv]" -strict -2 -y $outputPath';
        break;
    }

    var session = await FFmpegKit.execute(command);
    var returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      // print('Exito al combinar los videos');
    } else {
      print('Error al combinar los videos');
    }
  }

  //Funcion para la creacion del video en reversa

  Future<void> createReversedVideo(
      String originalFilePath, String reversedFilePath) async {
    // Comando para crear una versión en reversa del video
    final String command = '-i $originalFilePath -vf reverse $reversedFilePath';
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      print('Error al crear el video en reversa');
    }
  }

  //Funcion para crear un video con diferentes animaciones en el mismo de normal a rapido

  Future<void> createMixVideoALR(
      String originalFilePath, String mixedALRFilePath) async {
    int corte = GlobalVariables().nuevoTiempo ~/ 2;

    // Comando para crear una versión en reversa del video
    // final String command = '-i $reversedFilePath -filter_complex "[0:v]split[slow][fast];[slow]trim=start=0:end=$corte,setpts=PTS-STARTPTS, setpts=0.5*[slow_trimmed];[fast]trim=$corte, setpts=2.0*PTS(PTS-STARTPTS)[fast_trimmed]; [slow_trimmed][fast_trimmed]concat=n=2:v=1[outv]"  -map "[outv]" -y $mixedALRFilePath';
    final String command =
        '-i $originalFilePath -filter_complex "[0:v]reverse[rv];[rv]split[slow][fast]; [slow]trim=start=0:end=$corte,setpts=PTS-STARTPTS,setpts=0.5*PTS[slow_trimmed]; [fast]trim=start=$corte,setpts=PTS-STARTPTS,setpts=2.0*PTS[fast_trimmed]; [slow_trimmed][fast_trimmed]concat=n=2:v=1[outv]" -map "[outv]" -y $mixedALRFilePath';
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      print('Error al crear el video mix');
    }
  }

  //Funcion para crear un video con diferentes animaciones en el mismo de normal a rapido

  Future<void> createMixVideoNR(
      String originalFilePath, String mixedNRFilePath) async {
    int corte = GlobalVariables().nuevoTiempo ~/ 2;

    // Comando para crear una versión en reversa del video
    final String command =
        '-i $originalFilePath -filter_complex "[0:v]split[normal][fast];[normal]trim=start=0:end=$corte,setpts=PTS-STARTPTS[normal_trimmed];[fast]trim=$corte,setpts=0.5*(PTS-STARTPTS)[fast_trimmed]; [normal_trimmed][fast_trimmed]concat=n=2:v=1[outv]"  -map "[outv]" -y $mixedNRFilePath';
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      print('Error al crear el video mix');
    }
  }

  //Funcion para la creacion del video en camara rapida

  Future<void> createFastVideo(
      String originalFilePath, String fastFilePath) async {
    // final String command = '-i $originalFilePath -vf "setpts=0.5*PTS" $fastFilePath';

    String comb = GlobalVariables().combinacionSeleccionada;
    late String command;

    // Comando para crear una versión rapida del video
    switch (comb) {
      case 'Normal-Rapida-Lenta':
        command =
            '-i $originalFilePath -vf "reverse, setpts=0.5*PTS" $fastFilePath';
        break;
      case 'Normal-Atras-Lenta-Rapida':
        command =
            '-i $originalFilePath -vf "reverse, setpts=0.5*PTS" $fastFilePath';
        break;
      case 'Rapida-Lenta-Normal':
        command = '-i $originalFilePath -vf "setpts=0.5*PTS" $fastFilePath';
        break;
      default:
        command = '-i $originalFilePath -vf "setpts=0.5*PTS" $fastFilePath';
    }

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      print('Error al crear el video rapido');
    }
  }

  //Funcion para la creacion del video en Camara lenta

  Future<void> createSlowMotionVideo(
      String originalFilePath, String slowMotionFilePath) async {
    // Comando para crear una versión en cámara lenta del video
    // final String command = '-i $originalFilePath -vf "setpts=2.0*PTS" $slowMotionFilePath';

    String comb = GlobalVariables().combinacionSeleccionada;
    late String command;

    // Comando para crear una versión rapida del video
    switch (comb) {
      case 'Normal-Lenta-Normal':
        command =
            '-i $originalFilePath -vf "reverse, setpts=2.0*PTS" $slowMotionFilePath';
        break;
      case 'Rapida-Lenta-Normal':
        command =
            '-i $originalFilePath -vf "reverse, setpts=2.0*PTS" $slowMotionFilePath';
        break;
      case 'Normal-Atras-Lenta-Rapida':
        command =
            '-i $originalFilePath -vf "setpts=2.0*PTS" $slowMotionFilePath';
        break;
      default:
        command =
            '-i $originalFilePath -vf "setpts=2.0*PTS" $slowMotionFilePath';
    }

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      print('Error al crear el video en cámara lenta');
    }
  }

  Future<void> copyAndChangeVideoQuality(String newFilePath, String marco, String sourceFilePath) async {
    int resolucion = GlobalVariables().calidadSeleccionada;
    int fpsS = GlobalVariables().fpsSeleccionado;
    String fil = GlobalVariables().nuevoFiltro;
    String resolutionString;
    late String filtro;
    String command;
    switch (resolucion) {
      case 480:
        resolutionString = '480:640';
        break;
      case 720:
        resolutionString = '720:1280';
        break;
      case 1080:
        resolutionString = '1080:1920';
        break;
      case 2160:
        resolutionString = '2160:3840';
        break;
      default:
        resolutionString = '720:1280';
    }

    //Selección de filtro 

    switch (fil) {
      case 'Ninguno':
        filtro = 'scale=$resolutionString, fps=fps=$fpsS';
        break;
      case 'Verde':
        filtro =
            'scale=$resolutionString, fps=fps=$fpsS, colorchannelmixer=.4:.2:.3:.3:.3:.4:.3:.4:.3:.4:.1:.1:.0:.0:.0:.1';
        break;
      case 'Rojo':
        filtro = 'scale=$resolutionString, fps=fps=$fpsS, lutrgb=g=0:b=0';
        break;
      case 'Verde total':
        filtro = 'scale=$resolutionString, fps=fps=$fpsS, lutrgb=r=0:b=0';
        break;
      case 'Azul total':
        filtro = 'scale=$resolutionString, fps=fps=$fpsS, lutrgb=r=0:g=0';
        break;
      case 'Rojo claro':
        filtro = 'scale=$resolutionString, fps=fps=$fpsS, colorchannelmixer=1:.1:.1:0:0:0:0:.1:.1:.1:0';
        break;
      case 'Verde claro':
        filtro = 'scale=$resolutionString, fps=fps=$fpsS, colorbalance=-0.1:0.2:-0.2:0.1:0.2:-0.2:0.1:0.2:-0.2';
        break;
      case 'Azul claro':
        filtro = 'scale=$resolutionString, fps=fps=$fpsS, colorbalance=-0.4:-0.2:0.2:-0.4:-0.2:0.2:0:0:0.0';
        break;
      default:
        filtro = 'scale=$resolutionString, fps=fps=$fpsS';
    }

    if(UMarco != ''){
      command =
        '-i $sourceFilePath -i $marco -filter_complex "[0:v]$filtro[v];[1:v]format=rgba,scale=$resolutionString[overlay];[v][overlay]overlay=0:0" -pix_fmt yuv420p -strict unofficial -c:v mpeg4 -c:v:1 png $newFilePath';
    }else{
      command = 
        '-i $sourceFilePath -vf "$filtro" -pix_fmt yuv420p -strict unofficial -c:v mpeg4 $newFilePath';
    }
    
        // '-i $sourceFilePath -vf "$filtro" -pix_fmt yuv420p -strict unofficial -c:v mpeg4 $newFilePath';
        // '-i $sourceFilePath -i $marco1path -filte_complex "[0:v]$filtro[v];[1:v]scale=720:-2[bg]; [bg][v]overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2" -pix_fmt yuv420p -strict unofficial $newFilePath';
        // '-i $sourceFilePath -i $marco1path -vf "[0:v][1:v]overlay=5:5, $filtro" -pix_fmt yuv420p -strict unofficial  $newFilePath';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      print('Error al cambiar la resolucion al video original');
    }
  }

  void _refreshGallery(String filePath) {
    if (Platform.isAndroid) {
      // Actualizar la galería en dispositivos Android
      _runCommand('am', [
        'broadcast',
        '-a',
        'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
        '-d',
        'file://$filePath'
      ]);
    } else if (Platform.isIOS) {
      // Actualizar la galería en dispositivos iOS (no se requiere acción adicional)
    }
  }

  Future<void> _runCommand(String executable, List<String> arguments) async {
    await Process.run(executable, arguments);
  }

  Future<void> requestPermissions() async {

    //Esta linea solo es para iOS en caso de usar la aplicacion para Android borrar esta linea 
    final status = await Permission.photos.request();

    //Para Android

    // Verifica si ya se tienen los permisos
    // if (await Permission.storage.isGranted) {
    //   // Los permisos ya están concedidos, no es necesario solicitarlos nuevamente
    //   return;
    // }

    // Solicita los permisos

    // var status = await Permission.storage.request();

    //Final Android

    // Verifica si los permisos fueron concedidos
    if (status.isGranted) {
      // Los permisos fueron concedidos
      print('Permisos concedidos');
    } else {
      // Los permisos fueron denegados
      print('Permisos denegados');
    }
  }

// Función para obtener el directorio de la carpeta DCIM/Camera
  Future<Directory?> getCameraDirectory() async {
    final Directory? externalDirectory = await getExternalStorageDirectory();
    if (externalDirectory != null) {
      final String cameraDirectoryPath =
          '${externalDirectory.path}/DCIM/Camera';
      final Directory cameraDirectory = Directory(cameraDirectoryPath);
      if (!(await cameraDirectory.exists())) {
        await cameraDirectory.create(recursive: true);
      }
      return cameraDirectory;
    } else {
      return null;
    }
  }

  ///toma video
  Future<void> startVideoRecording() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      showInSnackBar('Error: Seleccione una cámara primero.');
      return;
    }

    if (cameraController.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return;
    }

    try {
      await cameraController.startVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return;
    }
  }

  Future<XFile?> stopVideoRecording() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isRecordingVideo) {
      return null;
    }

    try {
      return cameraController.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

/*sigue normal despues de este comentario */

  ///excepciones de la camara
  void _showCameraException(CameraException e) {
    _logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }
}

/// CameraApp is the Main Application.
class CameraApp extends StatelessWidget {
  /// Default Constructor
  const CameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CameraExampleHome(),
    );
  }
}

List<CameraDescription> _cameras = <CameraDescription>[];

Future<void> main() async {
  // Busca las cámaras disponibles antes de inicializar la aplicación.
  try {
    WidgetsFlutterBinding.ensureInitialized();
    _cameras = await availableCameras();
  } on CameraException catch (e) {
    _logError(e.code, e.description);
  }
  runApp(const CameraApp());
}
