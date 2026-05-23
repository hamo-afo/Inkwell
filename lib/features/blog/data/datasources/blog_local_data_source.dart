import 'package:blog_app/features/blog/data/models/blog_model.dart';
import 'package:hive/hive.dart';

abstract interface class BlogLocalDataSource {
  void uploadLocalBlogs({required List<BlogModel> blogs});
  List<BlogModel> loadBlogs();
}

class BlogLocalDataSourceImpl implements BlogLocalDataSource {
  final Box box;
  BlogLocalDataSourceImpl(this.box);
  @override
  List<BlogModel> loadBlogs() {
    final List<BlogModel> blogs = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value == null) continue;
      if (value is Map) {
        blogs.add(BlogModel.fromJson(Map<String, dynamic>.from(value)));
      }
    }
    return blogs;
  }

  @override
  void uploadLocalBlogs({required List<BlogModel> blogs}) {
    box.clear();
    for (int i = 0; i < blogs.length; i++) {
      box.put(i.toString(), blogs[i].toJson());
    }
  }
}

class InMemoryBlogLocalDataSource implements BlogLocalDataSource {
  final List<BlogModel> _store = [];

  @override
  List<BlogModel> loadBlogs() {
    return List<BlogModel>.from(_store);
  }

  @override
  void uploadLocalBlogs({required List<BlogModel> blogs}) {
    _store.clear();
    _store.addAll(blogs);
  }
}
