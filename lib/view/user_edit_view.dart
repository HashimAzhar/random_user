import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:random_user/viewmodels/user_edit_view_model.dart';
import 'package:random_user/widgets/reusable_form_field.dart';

import '../models/user_model.dart';
import '../models/user_edit_model.dart';

class EditUserView extends ConsumerStatefulWidget {
  final UserModel user;

  const EditUserView({Key? key, required this.user}) : super(key: key);

  @override
  ConsumerState<EditUserView> createState() => _EditUserViewState();
}

class _EditUserViewState extends ConsumerState<EditUserView> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController streetController;
  late TextEditingController suiteController;
  late TextEditingController cityController;
  late TextEditingController zipcodeController;
  late TextEditingController websiteController;
  late TextEditingController companyNameController;
  late TextEditingController companyCatchPhraseController;
  late TextEditingController companyBsController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user.name);
    emailController = TextEditingController(text: widget.user.email);
    phoneController = TextEditingController(text: widget.user.phone);
    streetController = TextEditingController(text: widget.user.address.street);
    suiteController = TextEditingController(text: widget.user.address.suite);
    cityController = TextEditingController(text: widget.user.address.city);
    zipcodeController = TextEditingController(
      text: widget.user.address.zipcode,
    );
    websiteController = TextEditingController(text: widget.user.website);
    companyNameController = TextEditingController(
      text: widget.user.company.name,
    );
    companyCatchPhraseController = TextEditingController(
      text: widget.user.company.catchPhrase,
    );
    companyBsController = TextEditingController(text: widget.user.company.bs);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(editUserViewModelProvider);

    // Form Validation Function
    bool validateForm() {
      if (nameController.text.isEmpty ||
          emailController.text.isEmpty ||
          phoneController.text.isEmpty ||
          streetController.text.isEmpty ||
          suiteController.text.isEmpty ||
          cityController.text.isEmpty ||
          zipcodeController.text.isEmpty ||
          websiteController.text.isEmpty ||
          companyNameController.text.isEmpty ||
          companyCatchPhraseController.text.isEmpty ||
          companyBsController.text.isEmpty) {
        Get.snackbar("Error", "All fields are required");
        return false;
      }
      // Add more specific validation for fields like email or phone number if needed.
      return true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit User')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            CustomFormField(label: 'Name', controller: nameController),
            CustomFormField(label: 'Email', controller: emailController),
            CustomFormField(label: 'Phone', controller: phoneController),
            CustomFormField(label: 'Street', controller: streetController),
            CustomFormField(label: 'Suite', controller: suiteController),
            CustomFormField(label: 'City', controller: cityController),
            CustomFormField(label: 'Zipcode', controller: zipcodeController),
            CustomFormField(label: 'Website', controller: websiteController),
            CustomFormField(
              label: 'Company Name',
              controller: companyNameController,
            ),
            CustomFormField(
              label: 'CatchPhrase',
              controller: companyCatchPhraseController,
            ),
            CustomFormField(
              label: 'Company Bs',
              controller: companyBsController,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  isLoading
                      ? null
                      : () async {
                        if (validateForm()) {
                          final model = UserEditModel(
                            name: nameController.text,
                            email: emailController.text,
                            phone: phoneController.text,
                            street: streetController.text,
                            suite: suiteController.text,
                            city: cityController.text,
                            zipcode: zipcodeController.text,
                            website: websiteController.text,
                            companyName: companyNameController.text,
                            companyCatchPhrase:
                                companyCatchPhraseController.text,
                            companyBs: companyBsController.text,
                          );

                          try {
                            await ref
                                .read(editUserViewModelProvider.notifier)
                                .updateUser(widget.user.id, model);
                            Get.snackbar(
                              "Success",
                              "User updated successfully",
                            );
                            // Optionally, you can navigate back or reset form fields
                            Navigator.pop(context);
                          } catch (e) {
                            Get.snackbar("Error", e.toString());
                          }
                        }
                      },
              child:
                  isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }
}
