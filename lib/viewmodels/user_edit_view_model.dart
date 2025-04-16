import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/user_edit_model.dart';

final editUserViewModelProvider =
    StateNotifierProvider.autoDispose<EditUserViewModel, bool>((ref) {
      return EditUserViewModel();
    });

class EditUserViewModel extends StateNotifier<bool> {
  EditUserViewModel() : super(false);

  Future<void> updateUser(int id, UserEditModel user) async {
    state = true;
    final response = await http.put(
      Uri.parse('https://jsonplaceholder.typicode.com/users/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson(id)),
    );

    state = false;

    if (response.statusCode == 200) {
      print("User updated: ${response.body}");
    } else {
      throw Exception('Failed to update user');
    }
  }
}
