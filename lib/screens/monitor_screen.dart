import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uv_exposure_app/services/uv_data_service.dart';
import 'package:uv_exposure_app/model/model.dart';
import 'package:uv_exposure_app/widgets/custom_infobox.dart';
import 'package:audioplayers/audioplayers.dart';

class MonitorScreen extends StatefulWidget {
  final double spf;
  final String skinType;
  late final Model model;

  MonitorScreen({super.key, required this.spf, required this.skinType}) {
    model = Model(spf, skinType);
  }

  @override
  _MonitorScreenState createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  late Timer _timer;
  int _secondsElapsed = 0;
  late int _safeExposureTime;
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _currentUVIndex = 0.0;
  late int _remainingSafeExposureTime;
  late String _acumulatedExposure;

  @override
  void initState() {
    super.initState();
    fetchUVData().then((uvData) {
      setState(() {
        _currentUVIndex = uvData['indiceUV'];
      });
    }).catchError((e) {
      debugPrint('Error fetching UV data: \$e');
    });
    _safeExposureTime = widget.model.initialSafeExposureTime(_currentUVIndex);
    _remainingSafeExposureTime = _safeExposureTime;
    _acumulatedExposure =
        widget.model.getAcumulatedExposure().toStringAsFixed(2);
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      fetchUVData().then((uvData) {
        setState(() {
          _currentUVIndex = uvData['indiceUV'];
        });
      }).catchError((e) {
        debugPrint('Error fetching UV data: \$e');
      });
      setState(() {
        _secondsElapsed++;
        widget.model.exposureAcumulator(_currentUVIndex, 1);
        _safeExposureTime =
            widget.model.safeExposureTime(_secondsElapsed, _currentUVIndex);
        _remainingSafeExposureTime = _safeExposureTime - _secondsElapsed;
        _acumulatedExposure =
            widget.model.getAcumulatedExposure().toStringAsFixed(2);
      });

      if (widget.model.getAcumulatedExposure() >= 100 ||
          _remainingSafeExposureTime <= 0) {
        _remainingSafeExposureTime = 0;
        _playAlarm();
      }
    });
  }

  void _playAlarm() async {
    await _audioPlayer.play(AssetSource('assets/audio/alarm.mp3'));
  }

  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  Color _getColorByExposure() {
    if (widget.model.getAcumulatedExposure() <= 50) {
      return Color.lerp(Colors.green, Colors.yellow,
          widget.model.getAcumulatedExposure() / 50)!;
    } else {
      return Color.lerp(Colors.yellow, Colors.red,
          (widget.model.getAcumulatedExposure() - 50) / 50)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFFFCE26),
        title: const Text(
          'SUNSENSE',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirm'),
                  content: const Text(
                      'Monitoring will be restarted. Are you sure you want to go back?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Dismiss the dialog
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Confirm'),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: CustomInfoBox(
                      title: 'Safe Exposure Time',
                      info: _formatTime(_remainingSafeExposureTime),
                      infoColor: _getColorByExposure())),
              Center(
                  child: CustomInfoBox(
                      title: 'Accumulated Exposure',
                      info: "$_acumulatedExposure %",
                      infoColor: _getColorByExposure())),
              Center(
                  child: CustomInfoBox(
                      title: 'Global UV Index',
                      info: _currentUVIndex.toStringAsFixed(0),
                      infoColor: Colors.black)),
            ],
          ),
        ),
      ),
    );
  }
}
