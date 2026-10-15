import 'package:flutter/foundation.dart';

final ValueNotifier<bool> installPromptAvailable = ValueNotifier<bool>(false);
void initializeInstallPrompt() {}
Future<bool> promptInstall() async => false;
