import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'icons.dart';

/// Device-local avatars, isolated by the authenticated user's immutable ID.
/// The system photo picker grants access only to the image the user selects.
class AvatarStore extends ChangeNotifier {
  static final instance = AvatarStore._();
  AvatarStore._();
  static const storage = FlutterSecureStorage();
  final _paths = <String, String>{};
  final _loaded = <String>{};
  final picker = ImagePicker();
  File? file(String userId) =>
      _paths[userId] == null ? null : File(_paths[userId]!);
  Future<Directory> _directory() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/avatars').create(recursive: true);
  }

  Future<void> load(String userId) async {
    if (_loaded.contains(userId)) return;
    final path = await storage.read(key: 'rollcall_avatar_$userId');
    if (path != null &&
        File(path).parent.path == (await _directory()).path &&
        await File(path).exists()) {
      _paths[userId] = path;
    }
    _loaded.add(userId);
    notifyListeners();
  }

  Future<void> save(String userId, XFile image) async {
    final bytes = await image.readAsBytes();
    if (bytes.length > 10 * 1024 * 1024) {
      throw const FormatException('Chọn ảnh nhỏ hơn 10 MB.');
    }
    final directory = await _directory();
    final safe = userId.replaceAll(RegExp('[^a-zA-Z0-9_-]'), '');
    final target = File(
      '${directory.path}/$safe-${DateTime.now().microsecondsSinceEpoch}.img',
    );
    await target.writeAsBytes(bytes, flush: true);
    try {
      await storage.write(key: 'rollcall_avatar_$userId', value: target.path);
    } catch (_) {
      await target.delete();
      rethrow;
    }
    final old = _paths[userId];
    _paths[userId] = target.path;
    _loaded.add(userId);
    notifyListeners();
    if (old != null &&
        File(old).parent.path == directory.path &&
        await File(old).exists()) {
      await File(old).delete();
    }
  }

  Future<bool> choose(String userId) async {
    await storage.write(key: 'rollcall_avatar_pending_user', value: userId);
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
        requestFullMetadata: false,
      );
      if (image == null) return false;
      await save(userId, image);
      return true;
    } finally {
      await storage.delete(key: 'rollcall_avatar_pending_user');
    }
  }

  Future<void> recover(String userId) async {
    if (!Platform.isAndroid ||
        await storage.read(key: 'rollcall_avatar_pending_user') != userId) {
      return;
    }
    final lost = await picker.retrieveLostData();
    if (lost.files?.isNotEmpty ?? false) await save(userId, lost.files!.first);
    await storage.delete(key: 'rollcall_avatar_pending_user');
  }

  Future<void> remove(String userId) async {
    final old = _paths[userId];
    final directory = await _directory();
    await storage.delete(key: 'rollcall_avatar_$userId');
    _paths.remove(userId);
    notifyListeners();
    if (old != null &&
        File(old).parent.path == directory.path &&
        await File(old).exists()) {
      await File(old).delete();
    }
  }
}

class UserAvatar extends StatefulWidget {
  final String userId, name;
  final double size;
  const UserAvatar({
    super.key,
    required this.userId,
    required this.name,
    this.size = 40,
  });
  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  @override
  void initState() {
    super.initState();
    AvatarStore.instance.load(widget.userId).catchError((_) {});
  }

  @override
  void didUpdateWidget(UserAvatar old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId) {
      AvatarStore.instance.load(widget.userId).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AvatarStore.instance,
    builder: (context, _) {
      final image = AvatarStore.instance.file(widget.userId);
      final placeholder = ColoredBox(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .14),
        child: Center(
          child: widget.name.trim().isEmpty
              ? const RcIcon(RcIcons.person_rounded)
              : Text(
                  widget.name.trim().characters.first.toUpperCase(),
                  style: TextStyle(
                    fontSize: widget.size * .38,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
        ),
      );
      return Semantics(
        label: 'Ảnh đại diện của ${widget.name}',
        image: true,
        child: ClipOval(
          child: SizedBox.square(
            dimension: widget.size,
            child: image == null
                ? placeholder
                : Image.file(
                    image,
                    key: ValueKey(image.path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => placeholder,
                  ),
          ),
        ),
      );
    },
  );
}
