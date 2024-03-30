
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class UploadService {
  static Future<void> uploadFile(File file) async {
    final url = Uri.parse('http://10.0.2.2:8080/upload'); // 替换为您的后端URL
    final request = http.MultipartRequest('POST', url);

    // 添加文件到请求
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    // 发送请求
    final response = await request.send();

    if (response.statusCode == 200) {
      print('文件上传成功！');
    } else {
      print('文件上传失败：${response.reasonPhrase}');
    }
  }

  // void _openFileExplorer() async {
  //   final result = await FilePicker.platform.pickFiles(
  //     type: FileType.custom,
  //     allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
  //   );
  //
  //   if (result != null) {
  //     // 获取选定的文件
  //     final file = result.files.single;
  //     // 现在您可以将文件上传到后端
  //     // ...
  //   }
  // }

}
