// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../controller/documents_scanner.dart';
//
//
// class DocumentScannerPage extends StatelessWidget {
//   const DocumentScannerPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<DocumentProvider>(context);
//
//     return Scaffold(
//       appBar: AppBar(title: const Text("Document Scanner")),
//       body: Column(
//         children: [
//           const SizedBox(height: 20),
//
//           ElevatedButton(
//             onPressed: provider.isScanning ? null : provider.scanDocument,
//             child: provider.isScanning
//                 ? const CircularProgressIndicator(color: Colors.white)
//                 : const Text("Scan Document"),
//           ),
//
//           const SizedBox(height: 20),
//
//           const Text(
//             "Saved Files",
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//
//           const Divider(),
//
//           Expanded(
//             child: ListView.builder(
//               itemCount: provider.savedFiles.length,
//               itemBuilder: (context, index) {
//                 return ListTile(
//                   leading: const Icon(Icons.insert_drive_file),
//                   title: Text(provider.savedFiles[index]),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
