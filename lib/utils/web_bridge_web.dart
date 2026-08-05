import 'dart:js_util' as js_util;

dynamic get _bridge => js_util.getProperty(js_util.globalThis, 'sonicwave');

bool get isElectronBridgeAvailable => _bridge != null;

Future<dynamic> _call(String method, [List args = const []]) async {
  final b = _bridge;
  if (b == null) return null;
  try {
    return await js_util.promiseToFuture(js_util.callMethod(b, method, args));
  } catch (_) {
    return null;
  }
}

Future<String?> selectFolderNative() async =>
    await _call('selectFolder') as String?;

Future<List<String>> listAudioFilesNative(String p) async {
  final r = await _call('listAudioFiles', [p]);
  if (r is List) return r.map((e) => e.toString()).toList();
  return const [];
}

String localFileUrl(String p) => Uri.base
    .resolve('/localfile?path=${Uri.encodeQueryComponent(p)}')
    .toString();

void setTitleBarColor(String bg, String fg) {
  try {
    final fn = js_util.getProperty(js_util.globalThis, 'setTitlebarColor');
    if (fn != null) {
      js_util.callMethod(js_util.globalThis, 'setTitlebarColor', [bg, fg]);
    }
  } catch (_) {}
}

Future<bool> renameFileNative(String a, String b) async =>
    (await _call('renameFile', [a, b])) == true;

Future<bool> deleteFileNative(String p) async =>
    (await _call('deleteFile', [p])) == true;

void revealFileNative(String p) {
  _call('revealFile', [p]);
}

Future<Map<String, dynamic>?> getMetadataNative(String p) async {
  final r = await _call('getMetadata', [p]);
  if (r is Map) return Map<String, dynamic>.from(r);
  return null;
}

Future<String?> readFileTextNative(String p) async =>
    await _call('readFileText', [p]) as String?;

Future<String?> getMusicDirNative() async =>
    await _call('getMusicDir') as String?;

void onFilesDropped(void Function(List<String>) handler) {
  final b = _bridge;
  if (b == null) return;
  js_util.callMethod(b, 'onFilesDropped', [
    js_util.allowInterop((dynamic paths) {
      if (paths is List) handler(paths.map((e) => e.toString()).toList());
    })
  ]);
}

void onMediaKey(void Function(String) handler) {
  final b = _bridge;
  if (b == null) return;
  js_util.callMethod(b, 'onMediaKey', [
    js_util.allowInterop((dynamic key) {
      handler(key.toString());
    })
  ]);
}
