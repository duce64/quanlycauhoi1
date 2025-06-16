// import 'dart:io';
// import 'dart:convert';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutterquiz/configdomain.dart';
// import 'package:flutterquiz/util/constant.dart';

// class ImportFromWordScreen extends StatefulWidget {
//   static const String routeName = '/import-from-word';

//   final int categoryId;
//   final int idQuestionPackage;

//   const ImportFromWordScreen({
//     required this.categoryId,
//     required this.idQuestionPackage,
//   });

//   @override
//   State<ImportFromWordScreen> createState() => _ImportFromWordScreenState();
// }

// class _ImportFromWordScreenState extends State<ImportFromWordScreen> {
//   List<Map<String, dynamic>> previewQuestions = [];
//   bool isLoading = false;
//   String? errorText;

//   Future<void> pickAndUploadWordFile() async {
//     setState(() {
//       isLoading = true;
//       errorText = null;
//       previewQuestions.clear();
//     });

//     try {
//       final result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['docx'],
//       );

//       if (result != null && result.files.single.path != null) {
//         final file = File(result.files.single.path!);
//         final uri = Uri.parse('${AppConstants.baseUrl}/api/questions/upload-word');

//         var request = http.MultipartRequest('POST', uri)
//           ..fields['categoryId'] = widget.categoryId.toString()
//           ..fields['idQuestionPackage'] = widget.idQuestionPackage.toString()
//           ..files.add(await http.MultipartFile.fromPath('file', file.path));

//         final streamedResponse = await request.send();
//         final response = await http.Response.fromStream(streamedResponse);

//         if (response.statusCode == 200) {
//           final data = jsonDecode(response.body);
//           setState(() {
//             previewQuestions = List<Map<String, dynamic>>.from(data['questions']);
//             isLoading = false;
//           });
//         } else {
//           final err = jsonDecode(response.body);
//           setState(() {
//             errorText = err['message'] ?? 'Lỗi không xác định khi phân tích file.';
//             isLoading = false;
//           });
//         }
//       } else {
//         setState(() => isLoading = false);
//       }
//     } catch (e) {
//       setState(() {
//         errorText = 'Lỗi khi tải file: $e';
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> submitQuestions() async {
//     try {
//       final response = await http.post(
//         Uri.parse('${AppConstants.baseUrl}/api/questions/add-questions'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(previewQuestions),
//       );

//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Nhập câu hỏi thành công!')),
//         );
//         Navigator.pop(context, true);
//       } else {
//         final err = jsonDecode(response.body);
//         setState(() => errorText = err['message'] ?? 'Lỗi gửi câu hỏi.');
//       }
//     } catch (e) {
//       setState(() => errorText = 'Lỗi khi gửi: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Nhập câu hỏi từ Word')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             ElevatedButton.icon(
//               icon: const Icon(Icons.upload_file),
//               label: const Text('Chọn file Word (.docx)'),
//               onPressed: isLoading ? null : pickAndUploadWordFile,
//             ),
//             const SizedBox(height: 16),
//             if (isLoading) const CircularProgressIndicator(),
//             if (errorText != null)
//               Text(errorText!, style: const TextStyle(color: Colors.red)),
//             if (previewQuestions.isNotEmpty)
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: previewQuestions.length,
//                   itemBuilder: (_, index) {
//                     final q = previewQuestions[index];
//                     return Card(
//                       margin: const EdgeInsets.symmetric(vertical: 8),
//                       child: Padding(
//                         padding: const EdgeInsets.all(12),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text("📝 Câu hỏi: ${q['question']}"),
//                             Text("✅ Đúng: ${q['correct_answer']}"),
//                             for (var i = 0; i < 3; i++)
//                               Text("❌ Sai ${i + 1}: ${q['incorrect_answers'][i]}"),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             const SizedBox(height: 8),
//             if (previewQuestions.isNotEmpty)
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.save),
//                 label: const Text("Xác nhận & Nhập"),
//                 onPressed: submitQuestions,
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
