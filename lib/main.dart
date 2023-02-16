import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:system_tray/system_tray.dart';
import 'package:tray_test1/debouncer.dart';
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
  await windowManager.ensureInitialized();

  await Window.setEffect(effect: WindowEffect.aero);

  // PackageInfo packageInfo = await PackageInfo.fromPlatform();
  // LaunchAtStartup.instance.setup(
  //   appName: packageInfo.appName,
  //   appPath: Platform.resolvedExecutable,
  // );
  // await LaunchAtStartup.instance.enable();

  var initialSize = const Size(375, 500);

  WindowOptions windowOptions = WindowOptions(
    size: initialSize,
    minimumSize: initialSize,
    maximumSize: initialSize,
    center: false,
    skipTaskbar: true,
    title: windowTitle,
  );

  windowManager.waitUntilReadyToShow(
    windowOptions,
    () async {
      if (Platform.isWindows) {
        await windowManager.setAsFrameless();
        await windowManager.setAlignment(Alignment.bottomRight);
        windowHandle.initialize();
        AnimateWindow(
          windowHandle.handle,
          500,
          AW_ACTIVATE | AW_SLIDE | AW_HOR_NEGATIVE,
        );
        await windowManager.focus();
      } else {
        await windowManager.setAlignment(Alignment.topRight);
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

class _MyAppState extends State<MyApp> {
  late final SystemTray systemTray;

  @override
  void initState() {
    systemTray = SystemTray();
    initSystemTray();
    super.initState();
  }

  Future<void> initSystemTray() async {
    final String path =
        Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png';

    await systemTray.initSystemTray(
      title: "system tray",
      iconPath: path,
    );

    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
          label: 'Show',
          onClicked: (menuItem) async {
            if (await windowManager.isFocused()) {
              await windowManager.blur();
            } else {
              await windowManager.focus();
            }
          }),
      MenuItemLabel(
        label: 'Exit',
        onClicked: (menuItem) => windowManager.close(),
      ),
    ]);

    await systemTray.setContextMenu(menu);

    systemTray.registerSystemTrayEventHandler((eventName) async {
      if (eventName == kSystemTrayEventClick) {
        if (await windowManager.isFocused()) {
          return await windowManager.blur();
        } else {
          return await windowManager.focus();
        }
      }
      if (eventName == kSystemTrayEventRightClick) {
        return await systemTray.popUpContextMenu();
      }
    });
  }

  @override
  Future<void> dispose() async {
    windowHandle.dispose();
    Future.microtask(() async {
      await systemTray.destroy();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final virtualWindowFrameBuilder = VirtualWindowFrameInit();
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
            builder: (context, child) {
              return virtualWindowFrameBuilder(context, child);
            },
          );
        }));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with WindowListener, WidgetsBindingObserver {
  int _counter = 0;
  late final Debouncer _debouncer;

  @override
  void initState() {
    windowManager.addListener(this);
    _debouncer = Debouncer(const Duration(milliseconds: 200));
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    log(state.name);
    super.didChangeAppLifecycleState(state);
  }

  @override
  Future<void> onWindowBlur() async {
    if (Platform.isWindows) {
      AnimateWindow(
        windowHandle.handle,
        500,
        AW_SLIDE | AW_HOR_POSITIVE | AW_HIDE,
      );
    } else {
      await windowManager.hide();
    }
    log('Window is hidden');
  }

  @override
  void onWindowFocus() {
    setState(() {});
    _debouncer.call(() async {
      if (await windowManager.isFocused()) {
        if (Platform.isWindows) {
          AnimateWindow(
            windowHandle.handle,
            500,
            AW_ACTIVATE | AW_SLIDE | AW_HOR_NEGATIVE,
          );
        } else {
          windowManager.show();
        }
        log('Window is shown');
      }
    });
  }

  @override
  void onWindowEvent(String eventName) {
    log('[WindowManager] onWindowEvent: $eventName');
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _debouncer.reset();
    super.dispose();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: Colors.white,
    );
    final headlineStyle = theme.textTheme.headlineMedium?.copyWith(
      color: Colors.white,
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
              style: textStyle,
            ),
            Text('$_counter', style: headlineStyle),
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
