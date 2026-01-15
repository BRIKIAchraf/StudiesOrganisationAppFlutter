import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../config/api_config.dart';

class FileService {
  Future<String?> pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        File file = File(result.files.single.path!);
        return await uploadFile(file);
      } else {
        // User canceled the picker
        return null;
      }
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }

  Future<String?> uploadFile(File file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/upload'), // Note: adjust base url without /api suffix if needed or keep standard
      );
      
      // Fix baseUrl issue if needed, ApiConfig usually has /api. 
      // If ApiConfig.baseUrl is http://10.0.2.2:3000/api
      // Then endpoint is correct.

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['url'];
      } else {
        print('Upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }
}
