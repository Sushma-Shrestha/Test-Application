import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:system_tray/system_tray.dart';
import 'package:win32/win32.dart';
import 'package:window_manager/window_manager.dart';

const className = 'FLUTTER_RUNNER_WIN32_WINDOW'; // from win32_window.cpp

const windowTitle = 'Test Application'; // application's window name

class WindowHandle {
  late final LPWSTR classNamePointer;
  late final LPWSTR windowTitlePointer;

  void initialize() {
    classNamePointer = TEXT(className);
    windowTitlePointer = TEXT(windowTitle);
  }

  int get handle => FindWindow(classNamePointer, windowTitlePointer);

  void dispose() {
    free(classNamePointer);
    free(windowTitlePointer);
  }
}

final windowHandle = WindowHandle();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Window.initialize();
  if (Platform.isWindows) {
    Window.hideWindowControls();
    Window.hideTitle();
    Window.makeTitlebarTransparent();
  }
  await windowManager.ensureInitialized();

  await Window.setEffect(effect: WindowEffect.solid, color: Colors.white);

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  LaunchAtStartup.instance.setup(
    appName: packageInfo.appName,
    appPath: Platform.resolvedExecutable,
  );
  await LaunchAtStartup.instance.enable();

  var initialSize = const Size(375, 750);

  WindowOptions windowOptions = WindowOptions(
    size: initialSize,
    minimumSize: initialSize,
    center: false,
    skipTaskbar: true,
    title: windowTitle,
  );

  await windowManager.waitUntilReadyToShow(
    windowOptions,
    () async {
      await windowManager.setAsFrameless();
      Platform.isWindows
          ? await windowManager.setAlignment(Alignment.bottomRight)
          : await windowManager.setAlignment(Alignment.topRight);
      if (Platform.isWindows) {
        windowHandle.initialize();

        final animate = AnimateWindow(
          windowHandle.handle,
          1000,
          AW_SLIDE | AW_HOR_NEGATIVE,
        );
        log('Animation Successful: ${animate == 1}');
      } else {
        await windowManager.show();
      }
    },
  );

  runApp(
    const MyApp(),
  );
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
          onClicked: (menuItem) async {
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
          }),
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
    windowHandle.dispose();
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
  void onWindowBlur() async {
    (Platform.isWindows)
        ? await windowManager.minimize()
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
  void onWindowRestore() {}

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
