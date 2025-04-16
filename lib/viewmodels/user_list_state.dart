import 'package:random_user/models/user_model.dart';

class UserListState {
  final List<UserModel> users;
  final bool isLoading;
  final String error;
  final String selectedUserDetail; // Add the field for the selected user detail

  UserListState({
    this.users = const [],
    this.isLoading = false,
    this.error = '',
    this.selectedUserDetail = '', // Initialize the selected user detail
  });

  UserListState copyWith({
    List<UserModel>? users,
    bool? isLoading,
    String? error,
    String?
    selectedUserDetail, // Add the optional parameter for selected user detail
  }) {
    return UserListState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedUserDetail:
          selectedUserDetail ??
          this.selectedUserDetail, // Copy the selected user detail if provided
    );
  }
}
