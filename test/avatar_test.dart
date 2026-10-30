import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:truong_tuan_vinh_2380602577_diem_danh/core/avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Avatars are copied to app storage, isolated per account and removable',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'rollcall-avatar-test-',
      );
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => temporary.path);
      FlutterSecureStorage.setMockInitialValues({});
      final image = XFile('assets/branding/app-icon.png');
      final store = AvatarStore.instance;
      try {
        await store.save('avatar-test-a', image);
        await store.save('avatar-test-b', image);
        final first = store.file('avatar-test-a')!,
            second = store.file('avatar-test-b')!;
        expect(first.path, isNot(second.path));
        expect(await first.readAsBytes(), await image.readAsBytes());
        expect(
          await const FlutterSecureStorage().read(
            key: 'rollcall_avatar_avatar-test-a',
          ),
          first.path,
        );
        await store.remove('avatar-test-a');
        expect(store.file('avatar-test-a'), isNull);
        expect(await first.exists(), isFalse);
        expect(await second.exists(), isTrue);
        await store.remove('avatar-test-b');
      } finally {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        await temporary.delete(recursive: true);
      }
    },
  );
}
