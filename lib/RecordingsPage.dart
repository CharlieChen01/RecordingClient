import 'dart:async';

import 'package:client/UploadService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'UploadService.dart';

class RecordingsPage extends StatefulWidget {
  @override
  _RecordingsPageState createState() => _RecordingsPageState();
}

class _RecordingsPageState extends State<RecordingsPage> {
  late FlutterSoundRecorder _recorder;
  late FlutterSoundPlayer _player;
  late StreamSubscription<RecordingDisposition> _recorderSubscription;
  bool _isRecording = false;
  List<String> _recordings = [];
  int _maxLength = 3600;
  String _recordDuration = '';
  late String _filePath;


  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _recorder.openRecorder();
    _player = FlutterSoundPlayer();
    _loadRecordings();
  }

  void _loadRecordings() async {
    // final directory = await getApplicationDocumentsDirectory();
    final directory = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${directory.path}/FlutterRec');
    print("Recording Directory: " + '${directory.path}/FlutterRec');
    if (!recordingsDir.existsSync()) {
      recordingsDir.createSync(); // If the directory does not exist, then create it.
    }
    recordingsDir.list().listen((file) {
      setState(() {
        if (!_recordings.contains(file.path)) {
          _recordings.add(file.path);
          print('FlutterRec: ' + file.path);
        }
      });
    });
  }

  void _toggleRecording() async {
    if (_isRecording) {
      await _recorder.stopRecorder();
      // await _recorder.closeRecorder();
      setState(() {
        _isRecording = false;
      });
      _loadRecordings();
      UploadService.uploadFile(File(_filePath));
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/FlutterRec');
      if (!recordingsDir.existsSync()) {
        recordingsDir.createSync();
      }

      final status = await Permission.microphone.request();
      if (status.isGranted) {
        print('已获得录音权限');
        // 在这里执行录音操作
        String fileName = DateFormat('yyyyMMddHHmmss').format(DateTime.now().toUtc());
        _filePath = '${recordingsDir.path}/${fileName}.aac';
        await _recorder.startRecorder(toFile: _filePath);
        setState(() {
          _isRecording = true;
        });
      } else {
        print('未获得录音权限');
      }


    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recording'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _recordings.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('${_recordings[index]}'),
                  onTap: () {
                    // Play record
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _toggleRecording,
            child: Text(_isRecording ? 'Stop Record' : 'Start Record'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    // _cancelRecorderSubscriptions();
    // _releaseFlauto();
    _player.closePlayer();
    super.dispose();
  }

  Future<bool> getPermissionStatus() async {
    Permission permission = Permission.microphone;
    //granted 通过，denied 被拒绝，permanentlyDenied 拒绝且不在提示
    PermissionStatus status = await permission.status;
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      requestPermission(permission);
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    } else if (status.isRestricted) {
      requestPermission(permission);
    } else {}
    return false;
  }

  void requestPermission(Permission permission) async {
    PermissionStatus status = await permission.request();
    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }


  /// 取消录音监听
  void _cancelRecorderSubscriptions() {
    if (_recorderSubscription != null) {
      _recorderSubscription!.cancel();
      // _recorderSubscription = null;
    }
  }

  /// 释放录音
  Future<void> _releaseFlauto() async {
    try {
      await _recorder.closeRecorder();
    } catch (e) {}
  }

  /// 判断文件是否存在
  Future<bool> _fileExists(String path) async {
    return await File(path).exists();
  }

  _startRecorder() async {
    try {
      //获取麦克风权限
      await getPermissionStatus().then((value) async {
        if (!value) {
          return;
        }
        //用户允许使用麦克风之后开始录音
        Directory tempDir = await getTemporaryDirectory();
        var time = DateTime.now().millisecondsSinceEpoch;
        String path = '${tempDir.path}/$time${ext[Codec.aacADTS.index]}';

        //这里我录制的是aac格式的，还有其他格式
        await _recorder.startRecorder(
          toFile: path,
          codec: Codec.aacADTS,
          bitRate: 8000,
          numChannels: 1,
          sampleRate: 8000,
        );

        /// 监听录音
        _recorderSubscription = _recorder.onProgress!.listen((e) {
          var date = DateTime.fromMillisecondsSinceEpoch(
              e.duration.inMilliseconds,
              isUtc: true);
          var txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
          //设置了最大录音时长
          if (date.second >= _maxLength) {
            _stopRecorder();
            return;
          }
          setState(() {
            //更新录音时长
            _recordDuration = txt.substring(1, 5);
          });
        });
        setState(() {
          //更新录音状态和录音文件路径
          _isRecording = true;
          _filePath = path;
        });
      });
    } catch (err) {
      setState(() {
        _stopRecorder();
        _isRecording = false;
        _cancelRecorderSubscriptions();
      });
    }
  }

  /// 结束录音
  _stopRecorder() async {
    try {
      await _recorder!.stopRecorder().then((value) {
        _cancelRecorderSubscriptions();
      });
    } catch (err) {}
    setState(() {
      _isRecording = false;
      // _isRecording = RecordPlayState.record;
    });
  }
}
