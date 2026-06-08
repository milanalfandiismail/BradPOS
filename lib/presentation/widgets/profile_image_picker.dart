import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

/// Picks an image from gallery, copies to app documents dir, and returns local path.
/// Returns null if user cancels or error occurs.
Future<String?> pickProfileImage(BuildContext context) async {
  try {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (image == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final localPath =
        '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
    await File(image.path).copy(localPath);
    return localPath;
  } catch (e) {
    return null;
  }
}
