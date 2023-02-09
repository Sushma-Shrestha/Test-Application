import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:system_tray/system_tray.dart';
import 'package:win32/win32.dart';
import 'package:window_manager/window_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Window.initialize();
  if (Platform.isWindows) {
    Window.hideWindowControls();
    Window.hideTitle();
    Window.makeTitlebarTransparent();
  }
  await windowManager.ensureInitialized();

  await Window.setEffect(effect: WindowEffect.acrylic);
  await windowManager.hide();

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  LaunchAtStartup.instance.setup(
    appName: packageInfo.appName,
    appPath: Platform.resolvedExecutable,
  );
  await LaunchAtStartup.instance.enable();

  var initialSize = const Size(375, 750);
  WindowOptions windowOptions = WindowOptions(
    size: initialSize,
    center: false,
    skipTaskbar: true,
  );

  await windowManager.waitUntilReadyToShow(
    windowOptions,
    () async {
      await windowManager.setAsFrameless();
      Platform.isWindows
          ? await windowManager.setAlignment(Alignment.bottomRight)
          : await windowManager.setAlignment(Alignment.topRight);
      if (Platform.isWindows) {
        const className =
            'FLUTTER_RUNNER_WIN32_WINDOW'; // from win32_window.cpp
        const windowTitle = 'slide_window'; // application's window name

        final classNamePointer = TEXT(className);
        final windowTitlePointer = TEXT(windowTitle);
        final hwnd = FindWindow(classNamePointer, windowTitlePointer);

        final animate = AnimateWindow(hwnd, 1000, AW_SLIDE | AW_HOR_NEGATIVE);
        log('Animation Successful: ${animate == 1}');

        free(classNamePointer);
        free(windowTitlePointer);
      } else {
        await windowManager.show();
      }
    },
  );

  runApp(
    const MyApp(),
  );

  if (Platform.isWindows) {
    doWhenWindowReady(() {
      const initialSize = Size(375, 750);
      appWindow.minSize = initialSize;
      appWindow.size = initialSize;
      appWindow.alignment = Alignment.bottomRight;
      appWindow.show();
    });
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  @override
  void initState() {
    windowManager.addListener(this);
    initSystemTray();
    super.initState();
    Window.setEffect(effect: WindowEffect.acrylic);
    setState(() {});
  }

  Future<void> initSystemTray() async {
    String path =
        Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png';

    final SystemTray systemTray = SystemTray();

    await systemTray.initSystemTray(
      title: "system tray",
      iconPath: path,
    );

    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
          label: 'Show',
          onClicked: (menuItem) async => {
                (Platform.isWindows)
                    ? windowManager.restore()
                    : await windowManager.show()
              }),
      MenuItemLabel(
          label: 'Hide',
          onClicked: (menuItem) => (Platform.isWindows)
              ? windowManager.minimize()
              : windowManager.hide()),
      MenuItemLabel(
          label: 'Exit', onClicked: (menuItem) => windowManager.close()),
    ]);

    await systemTray.setContextMenu(menu);

    systemTray.registerSystemTrayEventHandler((eventName) async {
      windowManager.removeListener(this);

      debugPrint("eventName: $eventName");
      if (eventName == kSystemTrayEventClick) {
        if (Platform.isWindows) {
          if (await windowManager.isMinimized()) {
            await windowManager.restore();
            // setState(() {});
            windowManager.addListener(this);

            return;
          } else {
            await windowManager.minimize();
            // setState(() {});
            windowManager.addListener(this);

            return;
          }
        } else {
          if (await windowManager.isVisible()) {
            await windowManager.hide();
          } else {
            await windowManager.show();
            setState(() {});
          }
        }
      }
      if (eventName == kSystemTrayEventRightClick) {
        await systemTray.popUpContextMenu();
      }
      windowManager.addListener(this);
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
        designSize: const Size(375, 750),
        builder: ((context, child) {
          ScreenUtil.init(context);
          return MaterialApp(
            title: 'Slide Window',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: const MyHomePage(title: 'Flutter Demo Home Page'),
          );
        }));
  }

  @override
  Future<void> onWindowEvent(String eventName) async {}

  @override
  void onWindowClose() {}

  @override
  void onWindowFocus() async {
    (Platform.isWindows) ? windowManager.restore() : await windowManager.show();
  }

  @override
  void onWindowBlur() async {
    (Platform.isWindows)
        ? windowManager.minimize()
        : await windowManager.hide();
  }

  @override
  void onWindowMaximize() {
    // do something
  }

  @override
  void onWindowUnmaximize() {
    // do something
  }

  @override
  void onWindowMinimize() {
    // do something
  }

  @override
  void onWindowRestore() {
    // do something
  }

  @override
  void onWindowResize() {
    // do something
  }

  @override
  void onWindowMove() {
    // do something
  }

  @override
  void onWindowEnterFullScreen() {
    // do something
  }

  @override
  void onWindowLeaveFullScreen() {
    // do something
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
