/// نسخه اندروید / غیر وب
bool get isElectronBridgeAvailable => false;

Future<String?> selectFolderNative() async => null;

Future<List<String>> listAudioFilesNative(String folderPath) async => const [];

String localFileUrl(String filePath) => filePath;

void setTitleBarColor(String bg, String fg) {}

Future<bool> renameFileNative(String oldPath, String newPath) async => false;

Future<bool> deleteFileNative(String path) async => false;

void revealFileNative(String path) {}
