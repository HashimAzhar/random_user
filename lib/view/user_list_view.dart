import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../viewmodels/user_list_view_model.dart';
import '../viewmodels/user_layout_view_model.dart';

class UserListView extends ConsumerStatefulWidget {
  const UserListView({Key? key}) : super(key: key);

  @override
  _UserListViewState createState() => _UserListViewState();
}

class _UserListViewState extends ConsumerState<UserListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userListViewModelProvider.notifier).fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userListState = ref.watch(userListViewModelProvider);
    final layoutView = ref.watch(userLayoutViewModelProvider);

    ref.listen<LayoutView>(userLayoutViewModelProvider, (_, __) {
      setState(() {}); // Manually trigger a rebuild for layout change
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('User List'),
        actions: [
          IconButton(
            icon: Icon(
              layoutView == LayoutView.listView ? Icons.grid_view : Icons.list,
            ),
            onPressed: () {
              ref.read(userLayoutViewModelProvider.notifier).toggleLayout();
            },
          ),
        ],
      ),
      body: userListState.when(
        data: (users) {
          return layoutView == LayoutView.listView
              ? ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    title: Text(user.name),
                    subtitle: Text(user.email),
                    onTap: () {
                      Get.toNamed('/user-detail', arguments: user);
                    },
                  );
                },
              )
              : Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return InkWell(
                      onTap: () {
                        Get.toNamed('/user-detail', arguments: user);
                      },
                      child: Card(
                        elevation: 5,
                        child: GridTile(
                          header: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.blue,
                            ),
                          ),
                          footer: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(user.email),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stackTrace) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
