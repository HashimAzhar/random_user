import 'package:flutter_riverpod/flutter_riverpod.dart';

// Enum for layout view type (ListView or GridView)
enum LayoutView { listView, gridView }

class UserLayoutViewModel extends StateNotifier<LayoutView> {
  UserLayoutViewModel() : super(LayoutView.listView); // Default to ListView

  // Method to toggle between ListView and GridView
  void toggleLayout() {
    state =
        state == LayoutView.listView
            ? LayoutView.gridView
            : LayoutView.listView;
  }
}

// Declare a provider for the layout view
final userLayoutViewModelProvider =
    StateNotifierProvider<UserLayoutViewModel, LayoutView>((ref) {
      return UserLayoutViewModel();
    });
