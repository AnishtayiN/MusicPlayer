bool get isElectronBridgeAvailable => false;

Future<String?> selectFolderNative() async => null;
Future<List<String>> listAudioFilesNative(String p) async => const [];
String localFileUrl(String p) => p;
void setTitleBarColor(String bg, String fg) {}
Future<bool> renameFileNative(String a, String b) async => false;
Future<bool> deleteFileNative(String p) async => false;
void revealFileNative(String p) {}
Future<Map<String, dynamic>?> getMetadataNative(String p) async => null;
Future<String?> readFileTextNative(String p) async => null;
Future<String?> getMusicDirNative() async => null;
void onFilesDropped(void Function(List<String>) handler) {}
void onMediaKey(void Function(String) handler) {}
