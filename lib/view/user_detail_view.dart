import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_user/models/user_model.dart';
import 'package:random_user/viewmodels/user_detail_view_model.dart';

class UserDetailView extends ConsumerWidget {
  final UserModel user;

  const UserDetailView({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print("UserDetailView is rebuilding for user: ${user.name}");

    // Get the current detail text
    final detailText = ref.watch(userDetailViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("User Details"),
        backgroundColor: Colors.blue[400],
        elevation: 0,
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Hero(
              tag: 'user-avatar-${user.id}',
              child: CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(
                  'https://img.freepik.com/free-photo/bohemian-man-with-his-arms-crossed_1368-3542.jpg?t=st=1744723493~exp=1744727093~hmac=5551bf38ae8500cc051b24b09b33e3ced7e78abc0cb7eaa3c28bfc15725e6e79&w=996',
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Simplified text display - no more async handling
            Text(
              detailText,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 20,
              children: [
                _iconBox(Icons.person_outline, "name", ref),
                _iconBox(Icons.email_outlined, "email", ref),
                _iconBox(Icons.phone_android_outlined, "phone", ref),
                _iconBox(Icons.business_outlined, "company", ref),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Get.toNamed('/edit-user', arguments: user),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[400],
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Edit Details',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon, String userField, WidgetRef ref) {
    return InkWell(
      onTap:
          () => ref
              .read(userDetailViewModelProvider.notifier)
              .selectUserDetail(user, userField),
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.blue[50],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue[100]!),
        ),
        child: Icon(icon, color: Colors.blue[400]),
      ),
    );
  }
}
