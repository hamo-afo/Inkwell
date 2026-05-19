import 'dart:io';

import 'package:blog_app/core/common/cubit/app_user/app_user_cubit.dart';
import 'package:blog_app/core/common/widgets/dotted_border_box.dart';
import 'package:blog_app/core/common/widgets/loader.dart';
import 'package:blog_app/core/theme/app_pallete.dart';
import 'package:blog_app/core/utils/pick_image.dart';
import 'package:blog_app/core/utils/show_snackbar.dart';
import 'package:blog_app/features/blog/presentation/bloc/blog_bloc.dart';
import 'package:blog_app/features/blog/presentation/pages/blog_page.dart';
import 'package:blog_app/features/blog/presentation/widgets/blog_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddNewBlogPage extends StatefulWidget {
  static route() =>
      MaterialPageRoute(builder: (context) => const AddNewBlogPage());
  const AddNewBlogPage({super.key});

  @override
  State<AddNewBlogPage> createState() => _AddNewBlogPageState();
}

class _AddNewBlogPageState extends State<AddNewBlogPage> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final List<String> availableTopics = [
    'Business',
    'Technology',
    'Programming',
    'Entertainment',
  ];

  List<String> selectedTopics = [];
  File? image;

  void selectImage() async {
    final pickedImage = await pickImage();
    if (pickedImage != null) {
      setState(() => image = pickedImage);
    }
  }

  void uploadBlog() {
    if (formKey.currentState!.validate() &&
        selectedTopics.isNotEmpty &&
        image != null) {
      final posterId =
          (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;
      context.read<BlogBloc>().add(
            BlogUpload(
              posterId: posterId,
              title: titleController.text.trim(),
              content: contentController.text.trim(),
              image: image!,
              topics: selectedTopics,
            ),
          );
    } else {
      if (selectedTopics.isEmpty)
        showSnackBar(context, 'Please select at least one category');
      if (image == null) showSnackBar(context, 'Please select an image');
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: uploadBlog, icon: const Icon(Icons.done_rounded)),
        ],
      ),
      body: BlocConsumer<BlogBloc, BlogState>(
        listener: (context, state) {
          if (state is BlogFailure) showSnackBar(context, state.error);
          if (state is BlogUploadSuccess)
            Navigator.pushAndRemoveUntil(
                context, BlogPage.route(), (route) => false);
        },
        builder: (context, state) {
          if (state is BlogLoading) return const Loader();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image selector / preview
                    image != null
                        ? GestureDetector(
                            onTap: selectImage,
                            child: SizedBox(
                              width: double.infinity,
                              height: 150,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(image!, fit: BoxFit.cover),
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: selectImage,
                            child: DottedBorderBox(
                              color: AppPallete.borderColor,
                              strokeWidth: 2,
                              dashWidth: 8,
                              dashGap: 4,
                              borderRadius: 10,
                              child: Container(
                                height: 150,
                                width: double.infinity,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.folder_open, size: 40),
                                    SizedBox(height: 13),
                                    Text('Select your image',
                                        style: TextStyle(fontSize: 15)),
                                  ],
                                ),
                              ),
                            ),
                          ),

                    const SizedBox(height: 20),

                    // Chips row (squarish with rounded edges)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: availableTopics.map((topic) {
                          final isSelected = selectedTopics.contains(topic);
                          return Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: GestureDetector(
                              onTap: () => setState(() {
                                if (isSelected)
                                  selectedTopics.remove(topic);
                                else
                                  selectedTopics.add(topic);
                              }),
                              child: Container(
                                constraints:
                                    const BoxConstraints(minHeight: 40),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppPallete.gradient1
                                      : AppPallete.backgroundColor
                                          .withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppPallete.gradient1
                                        : AppPallete.borderColor,
                                    width: 1.6,
                                  ),
                                ),
                                child: Text(
                                  topic,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppPallete.whiteColor
                                        : AppPallete.whiteColor
                                            .withOpacity(0.78),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    BlogEditor(
                        controller: titleController, hintText: 'Blog title'),
                    const SizedBox(height: 10),
                    BlogEditor(
                        controller: contentController,
                        hintText: 'Blog content'),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
