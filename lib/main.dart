import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:random_user/route/app_routes.dart';
import 'package:random_user/test_things/maptestplaces/map_screenn.dart';
import 'package:random_user/view/GoogleMaps/search_places_ui.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Random User',
      // initialRoute: AppRoutes.mapScreen,
      // getPages: AppRoutes.pages,
      home: MapScreenn(),
    );
  }
}
