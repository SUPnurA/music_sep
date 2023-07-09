import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PlaybackScreen extends StatefulWidget {
  const PlaybackScreen({Key? key}) : super(key: key);

  @override
  _PlaybackScreenState createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> {
  late AudioPlayer _vocalsPlayer;
  late AudioPlayer _drumsPlayer;
  late AudioPlayer _bassPlayer;
  late AudioPlayer _otherPlayer;
  bool _isPlaying = false;
  String _currentTrack = '';

  late String _vocalsUrl = '';
  late String _drumsUrl = '';
  late String _bassUrl = '';
  late String _otherUrl = '';

  double _vocalsDuration = 0;
  double _vocalsPosition = 0;
  double _drumsDuration = 0;
  double _drumsPosition = 0;
  double _bassDuration = 0;
  double _bassPosition = 0;
  double _otherDuration = 0;
  double _otherPosition = 0;

  bool _vocalsIsPlaying = false;
  bool _drumsIsPlaying = false;
  bool _bassIsPlaying = false;
  bool _otherIsPlaying = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _vocalsPlayer = AudioPlayer();
    _drumsPlayer = AudioPlayer();
    _bassPlayer = AudioPlayer();
    _otherPlayer = AudioPlayer();
    _loadAudioFiles();
  }

  void _playVocals() {
    if (_vocalsIsPlaying) {
      _vocalsPlayer.pause();
      setState(() {
        _vocalsIsPlaying = false;
      });
    } else {
      _vocalsPlayer.resume();
      setState(() {
        _vocalsIsPlaying = true;
      });
    }
  }

  void _playDrums() {
    if (_drumsIsPlaying) {
      _drumsPlayer.pause();
      setState(() {
        _drumsIsPlaying = false;
      });
    } else {
      _drumsPlayer.resume();
      setState(() {
        _drumsIsPlaying = true;
      });
    }
  }

  void _playBass() {
    if (_bassIsPlaying) {
      _bassPlayer.pause();
      setState(() {
        _bassIsPlaying = false;
      });
    } else {
      _bassPlayer.resume();
      setState(() {
        _bassIsPlaying = true;
      });
    }
  }

  void _playOther() {
    if (_otherIsPlaying) {
      _otherPlayer.pause();
      setState(() {
        _otherIsPlaying = false;
      });
    } else {
      _otherPlayer.resume();
      setState(() {
        _otherIsPlaying = true;
      });
    }
  }

  Future<void> _downloadAudioFile(String url, String filename) async {
    final response = await http.get(Uri.parse(url));
    final bytes = response.bodyBytes;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
  }

  Future<void> _loadAudioFiles() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
          Uri.parse('http://35.200.137.165/playback-urls'));
      final json = jsonDecode(response.body);

      _vocalsUrl = json['vocalsurl'] ?? '';
      _drumsUrl = json['drumsurl'] ?? '';
      _bassUrl = json['bassurl'] ?? '';
      _otherUrl = json['otherurl'] ?? '';

      await _downloadAudioFile(_vocalsUrl, 'vocals.mp3');
      await _downloadAudioFile(_drumsUrl, 'drums.mp3');
      await _downloadAudioFile(_bassUrl, 'bass.mp3');
      await _downloadAudioFile(_otherUrl, 'other.mp3');

      final vocalsFile = File(
          '${(await getApplicationDocumentsDirectory()).path}/vocals.mp3');
      final drumsFile = File(
          '${(await getApplicationDocumentsDirectory()).path}/drums.mp3');
      final bassFile = File(
          '${(await getApplicationDocumentsDirectory()).path}/bass.mp3');
      final otherFile = File(
          '${(await getApplicationDocumentsDirectory()).path}/other.mp3');

      await _vocalsPlayer.setUrl(vocalsFile.path);
      await _drumsPlayer.setUrl(drumsFile.path);
      await _bassPlayer.setUrl(bassFile.path);
      await _otherPlayer.setUrl(otherFile.path);

      final vocalsDuration = await _vocalsPlayer.getDuration();
      final drumsDuration = await _drumsPlayer.getDuration();
      final bassDuration = await _bassPlayer.getDuration();
      final otherDuration = await _otherPlayer.getDuration();

      setState(() {
        _vocalsDuration = vocalsDuration.toDouble();
        _drumsDuration = drumsDuration.toDouble();
        _bassDuration = bassDuration.toDouble();
        _otherDuration = otherDuration.toDouble();
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading audio files: $e'),
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playback Screen'),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _currentTrack,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: _playVocals,
                  icon: Icon(_vocalsIsPlaying
                      ? Icons.pause
                      : Icons.play_arrow),
                ),
                IconButton(
                  onPressed: _playDrums,
                  icon: Icon(_drumsIsPlaying
                      ? Icons.pause
                      : Icons.play_arrow),
                ),
                IconButton(
                  onPressed: _playBass,
                  icon: Icon(_bassIsPlaying
                      ? Icons.pause
                      : Icons.play_arrow),
                ),
                IconButton(
                  onPressed: _playOther,
                  icon: Icon(_otherIsPlaying
                      ? Icons.pause
                      : Icons.play_arrow),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Text('Vocals'),
                Text('Drums'),
                Text('Bass'),
                Text('Other'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(_vocalsPosition.toString()),
                Text(_drumsPosition.toString()),
                Text(_bassPosition.toString()),
                Text(_otherPosition.toString()),
              ],
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Slider(
                    value: _vocalsPosition,
                    min: 0,
                    max: _vocalsDuration,
                    onChanged: (value) {
                      setState(() {
                        _vocalsPosition = value;
                      });
                      _vocalsPlayer.seek(Duration(milliseconds: value.round()));
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Slider(
                    value: _drumsPosition,
                    min: 0,
                    max: _drumsDuration,
                    onChanged: (value) {
                      setState(() {
                        _drumsPosition = value;
                      });
                      _drumsPlayer.seek(Duration(milliseconds: value.round()));
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Slider(
                    value: _bassPosition,
                    min: 0,
                    max: _bassDuration,
                    onChanged: (value) {
                      setState(() {
                        _bassPosition = value;
                      });
                      _bassPlayer.seek(Duration(milliseconds: value.round()));
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Slider(
                    value: _otherPosition,
                    min: 0,
                    max: _otherDuration,
                    onChanged: (value) {
                      setState(() {
                        _otherPosition = value;
                      });
                      _otherPlayer.seek(Duration(milliseconds: value.round()));
                    },
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _isLoading = true;
                });
                await _loadAudioFiles();
                setState(() {
                  _isLoading = false;
                });
              },
              child: const Text('Reload Audio Files'),
            ),
          ],
        ),
      ),
    );
  }
}
