import 'dart:js_util' as js_util;

/// نسخه وب / Electron (ویندوز)
dynamic get _bridge => js_util.getProperty(js_util.globalThis, 'sonicwave');

bool get isElectronBridgeAvailable => _bridge != null;

Future<String?> selectFolderNative() async {
  final bridge = _bridge;
  if (bridge == null) return null;

  try {
    final promise = js_util.callMethod(bridge, 'selectFolder', []);
    final result = await js_util.promiseToFuture(promise);
    return result as String?;
  } catch (_) {
    return null;
  }
}

Future<List<String>> listAudioFilesNative(String folderPath) async {
  final bridge = _bridge;
  if (bridge == null) return const [];

  try {
    final promise = js_util.callMethod(bridge, 'listAudioFiles', [folderPath]);
    final result = await js_util.promiseToFuture(promise);

    if (result is List) {
      return result.map((e) => e.toString()).toList();
    }
    return const [];
  } catch (_) {
    return const [];
  }
}

String localFileUrl(String filePath) {
  return Uri.base
      .resolve('/localfile?path=${Uri.encodeQueryComponent(filePath)}')
      .toString();
}

void setTitleBarColor(String bg, String fg) {
  try {
    final fn = js_util.getProperty(js_util.globalThis, 'setTitlebarColor');
    if (fn != null) {
      js_util.callMethod(js_util.globalThis, 'setTitlebarColor', [bg, fg]);
    }
  } catch (_) {}
}

Future<bool> renameFileNative(String oldPath, String newPath) async {
  final bridge = _bridge;
  if (bridge == null) return false;

  try {
    final promise = js_util.callMethod(bridge, 'renameFile', [oldPath, newPath]);
    final result = await js_util.promiseToFuture(promise);
    return result == true;
  } catch (_) {
    return false;
  }
}

Future<bool> deleteFileNative(String path) async {
  final bridge = _bridge;
  if (bridge == null) return false;

  try {
    final promise = js_util.callMethod(bridge, 'deleteFile', [path]);
    final result = await js_util.promiseToFuture(promise);
    return result == true;
  } catch (_) {
    return false;
  }
}

void revealFileNative(String path) {
  final bridge = _bridge;
  if (bridge == null) return;

  try {
    js_util.callMethod(bridge, 'revealFile', [path]);
  } catch (_) {}
}
