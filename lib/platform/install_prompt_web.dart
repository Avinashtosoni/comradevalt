import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

dynamic _deferredPrompt;
final ValueNotifier<bool> installPromptAvailable = ValueNotifier<bool>(false);
bool _initialized = false;

void initializeInstallPrompt() {
  if (_initialized) return;
  _initialized = true;
  html.window.on['beforeinstallprompt'].listen((event) {
    event.preventDefault();
    _deferredPrompt = event;
    installPromptAvailable.value = true;
  });
  html.window.on['appinstalled'].listen((_) {
    _deferredPrompt = null;
    installPromptAvailable.value = false;
  });
}

Future<bool> promptInstall() async {
  final prompt = _deferredPrompt;
  if (prompt == null) return false;
  _deferredPrompt = null;
  installPromptAvailable.value = false;
  try {
    await prompt.prompt();
    final choice = await prompt.userChoice;
    return choice.outcome == 'accepted';
  } catch (_) {
    return false;
  }
}
