import 'package:get/get.dart';
import 'package:random_user/models/user_model.dart';
import 'package:random_user/view/GoogleMaps/map_screen.dart';
import 'package:random_user/view/user_list_view.dart';
import 'package:random_user/view/user_detail_view.dart';
import 'package:random_user/view/user_edit_view.dart';

class AppRoutes {
  static const userList = '/user-list';
  static const userDetail = '/user-detail';
  static const editUser = '/edit-user';
  static const mapScreen = '/map';

  static final pages = [
    GetPage(name: userList, page: () => const UserListView()),
    GetPage(
      name: userDetail,
      page: () {
        final user = Get.arguments as UserModel;
        return UserDetailView(user: user);
      },
    ),
    GetPage(
      name: editUser,
      page: () {
        final user = Get.arguments as UserModel;
        return EditUserView(user: user);
      },
    ),
    GetPage(name: mapScreen, page: () => const MapScreen()),
  ];
}
