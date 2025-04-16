import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_user/models/user_model.dart';

class UserDetailViewModel extends AutoDisposeNotifier<String> {
  @override
  String build() {
    // Initial state is empty string
    return '';
  }

  void selectUserDetail(UserModel user, String userField) {
    state = switch (userField) {
      'name' => 'My name is ${user.name}',
      'email' => 'My email is ${user.email}',
      'phone' => 'My phone number is ${user.phone}',
      'company' => 'I work at ${user.company.name}',
      _ => 'No detail available for this field',
    };
  }
}

final userDetailViewModelProvider =
    NotifierProvider.autoDispose<UserDetailViewModel, String>(
      UserDetailViewModel.new,
    );
