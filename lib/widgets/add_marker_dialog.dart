// // Show dialog for adding a marker
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:random_user/viewmodels/Google_Maps/map_view_model.dart';

// Future<void> showAddMarkerDialog(
//   BuildContext context,
//   LatLng tappedPoint,
//   MapViewModel mapViewModel,
// ) async {
//   TextEditingController titleController = TextEditingController();
//   TextEditingController snippetController = TextEditingController();

//   return showDialog<void>(
//     context: context,
//     barrierDismissible: false,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         title: const Text('Add Marker'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: titleController,
//               decoration: const InputDecoration(hintText: 'Enter marker title'),
//             ),
//             TextField(
//               controller: snippetController,
//               decoration: const InputDecoration(
//                 hintText: 'Enter marker snippet',
//               ),
//             ),
//           ],
//         ),
//         actions: <Widget>[
//           TextButton(
//             child: const Text('Cancel'),
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//           ),
//           TextButton(
//             child: const Text('Add Marker'),
//             onPressed: () {
//               if (titleController.text.isNotEmpty &&
//                   snippetController.text.isNotEmpty) {
//                 mapViewModel.addMarker(
//                   tappedPoint,
//                   titleController.text,
//                   snippetController.text,
//                 );
//                 Navigator.of(context).pop();
//               }
//             },
//           ),
//         ],
//       );
//     },
//   );
// }
