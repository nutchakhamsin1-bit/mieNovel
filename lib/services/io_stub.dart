// Stub for dart:io on web platform
// This provides empty stubs so the code compiles on web,
// but these should never be called at runtime on web.

class File {
  final String path;
  const File(this.path);
  Future<File> writeAsBytes(List<int> bytes) async => this;
  bool existsSync() => false;
  Future<bool> exists() async => false;
  String get uri => path;
}

class Directory {
  final String path;
  const Directory(this.path);
  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
}

abstract class FileSystemEntity {
  String get path;
}
