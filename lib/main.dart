import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

import 'playback_screen.dart';

void main() {
  runApp(
    MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const UploadScreen(),
        '/playback_screen': (context) => const PlaybackScreen(),
      },
    ),
  );
}

class UploadScreen extends StatefulWidget {
  const UploadScreen({Key? key}) : super(key: key);
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  String? _selectedFilePath;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _selectFile() async {
    final status = await Permission.storage.status;
    if (!status.isGranted) {
      if (await Permission.storage.shouldShowRequestRationale) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This app needs permission to access your device storage.'),
          ),
        );
      }
      final result = await Permission.storage.request();
      if (result != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied'),
          ),
        );
        return;
      }
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      if (result != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error selecting file'),
        ),
      );
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No file selected'),
        ),
      );
      return;
    }

    const url = 'http://35.200.137.165/split-audio';
    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..files.add(await http.MultipartFile.fromPath('file', _selectedFilePath!));
    setState(() {
      _isUploading = true;
    });
    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final parsedResponse = json.decode(responseBody);
        Navigator.pushNamed(
          context,
          '/playback_screen',
          arguments: {
            'tracks': {
              'vocals': parsedResponse['vocals'],
              'bass': parsedResponse['bass'],
              'drums': parsedResponse['drums'],
              'other': parsedResponse['other'],
            },
          },
        );// Debug print to check if navigation was successful
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error uploading file'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error uploading file!'),
        ),
      );
    }
    setState(() {
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Audio'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome! Please select an audio file to upload:',
              style: TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            TextButton(
              onPressed: _selectFile,
              child: const Text('Select File'),
            ),
            const SizedBox(height: 16.0),
            _selectedFilePath != null
                ? Text('Selected file: $_selectedFilePath')
                : Container(),
            const SizedBox(height: 16.0),
            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _uploadFile,
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}
