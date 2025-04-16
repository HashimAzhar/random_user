import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:random_user/models/user_model.dart';

class UserListViewModel extends AsyncNotifier<List<UserModel>> {
  @override
  Future<List<UserModel>> build() async {
    return fetchUsers();
  }

  Future<List<UserModel>> fetchUsers() async {
    final String _url = 'https://jsonplaceholder.typicode.com/users';
    final response = await http.get(Uri.parse(_url));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((user) => UserModel.fromJson(user)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }
}

// Correct provider declaration
final userListViewModelProvider =
    AsyncNotifierProvider<UserListViewModel, List<UserModel>>(
      UserListViewModel.new, // Using the constructor directly
    );
