import 'package:blog_app/core/common/widgets/dotted_border_box.dart';
import 'package:blog_app/core/theme/app_pallete.dart';
import 'package:blog_app/features/blog/presentation/widgets/blog_editor.dart';
import 'package:flutter/material.dart';

class AddNewBlogPage extends StatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const AddNewBlogPage(),
      );
  const AddNewBlogPage({super.key});

  @override
  State<AddNewBlogPage> createState() => _AddNewBlogPageState();
}

class _AddNewBlogPageState extends State<AddNewBlogPage> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  List<String> selectedTopics = [];

  @override
  void dispose() {
    super.dispose();
    titleController.dispose();
    contentController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.done_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              DottedBorderBox(
                color: AppPallete.borderColor,
                strokeWidth: 2,
                dashWidth: 8,
                dashGap: 4,
                borderRadius: 10,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 40,
                      ),
                      SizedBox(height: 15),
                      Text(
                        'Select your image',
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      ['Technology', 'Business', 'Programming', 'Entertainment']
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: GestureDetector(
                                onTap: () {
                                  if (selectedTopics.contains(e)) {
                                    selectedTopics.remove(e);
                                  }else {
                                    selectedTopics.add(e);
                                  }
                                  
                                  setState(() {});
                                },
                                child: Chip(
                                  label: Text(e),
                                  color: selectedTopics.contains(e) ? const  MaterialStatePropertyAll(AppPallete.gradient1,) : null, 
                                  side: const BorderSide(
                                    color: AppPallete.borderColor,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
              const SizedBox(height: 10),
              BlogEditor(controller: titleController, hintText: 'Blog title'),
              const SizedBox(height: 10),
              BlogEditor(
                  controller: contentController, hintText: 'Blog content'),
            ],
          ),
        ),
      ),
    );
  }
}
