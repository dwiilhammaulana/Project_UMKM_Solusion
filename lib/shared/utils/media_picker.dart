import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_providers.dart';

abstract class MediaPickerService {
  Future<String?> pickImagePath();
}

class SupabaseStorageMediaPickerService implements MediaPickerService {
  SupabaseStorageMediaPickerService(this._client);

  final SupabaseClient _client;
  static const _mediaBucket = 'app-media';

  @override
  Future<String?> pickImagePath() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      lockParentWindow: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }

    try {
      final pickedFile = result.files.single;
      final bytes = pickedFile.bytes ?? await _readPickedFileBytes(pickedFile);
      if (bytes == null) {
        return null;
      }

      final ownerUserId = await _resolveOwnerUserId();
      final extension = _safeImageExtension(pickedFile.name);
      final objectPath = [
        ownerUserId,
        'uploads',
        'image_${DateTime.now().microsecondsSinceEpoch}$extension',
      ].join('/');

      await _client.storage.from(_mediaBucket).uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '31536000',
              contentType: _contentTypeForExtension(extension),
              upsert: true,
            ),
          );

      return _client.storage.from(_mediaBucket).getPublicUrl(objectPath);
    } finally {
      await _clearPickerTemporaryFiles();
    }
  }

  Future<String> _resolveOwnerUserId() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Sesi login tidak ditemukan. Silakan login ulang.');
    }

    try {
      final ownerUserId = await _client.rpc('current_store_owner_user_id');
      if (ownerUserId is String && ownerUserId.trim().isNotEmpty) {
        return ownerUserId.trim();
      }
    } on PostgrestException {
      // Older databases may not have the team-owner helper yet.
    }
    return userId;
  }

  Future<Uint8List?> _readPickedFileBytes(PlatformFile pickedFile) async {
    final sourcePath = pickedFile.path;
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      return null;
    }
    return File(sourcePath).readAsBytes();
  }

  String _safeImageExtension(String sourceName) {
    final extension = p.extension(sourceName).toLowerCase();
    return switch (extension) {
      '.jpeg' || '.jpg' || '.png' || '.webp' || '.gif' => extension,
      _ => '.jpg',
    };
  }

  String _contentTypeForExtension(String extension) {
    return switch (extension) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }

  Future<void> _clearPickerTemporaryFiles() async {
    try {
      await FilePicker.platform.clearTemporaryFiles();
    } catch (_) {
      // Some platforms do not create or expose temporary picker files.
    }
  }
}

final mediaPickerProvider = Provider<MediaPickerService>((ref) {
  return SupabaseStorageMediaPickerService(ref.watch(supabaseClientProvider));
});
