import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_controller.dart';
import 'app_theme.dart';
import 'platform/install_prompt.dart';
import 'screens/app_shell.dart';
import 'services/vault_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeInstallPrompt();
  final appController = AppController();
  await appController.initialize();
  final vaultService = VaultService();
  await vaultService.initialize(appController.data.autoLockMinutes);
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: appController),
      ChangeNotifierProvider.value(value: vaultService),
    ],
    child: const ComradeVaultApp(),
  ));
}

class ComradeVaultApp extends StatelessWidget {
  const ComradeVaultApp({super.key});

  @override
  Widget build(BuildContext context) => Consumer<AppController>(builder: (context, controller, _) {
    final light = controller.data.theme == 'light';
    final accent = controller.data.accent;
    return MaterialApp(
      title: 'Comrade Vault',
      debugShowCheckedModeBanner: false,
      theme: buildVaultTheme(light: true, accent: accent),
      darkTheme: buildVaultTheme(light: false, accent: accent),
      themeMode: controller.data.theme == 'system' ? ThemeMode.system : light ? ThemeMode.light : ThemeMode.dark,
      home: const AppShell(),
    );
  });
}
