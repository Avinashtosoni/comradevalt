import 'install_prompt_stub.dart'
    if (dart.library.html) 'install_prompt_web.dart' as platform;

final installPromptAvailable = platform.installPromptAvailable;
void initializeInstallPrompt() => platform.initializeInstallPrompt();
Future<bool> promptInstall() => platform.promptInstall();
