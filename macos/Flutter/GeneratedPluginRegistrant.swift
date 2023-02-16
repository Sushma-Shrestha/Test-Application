//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import bitsdojo_window_macos
import macos_window_utils
import package_info_plus
import screen_retriever
import system_tray
import window_manager

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  BitsdojoWindowPlugin.register(with: registry.registrar(forPlugin: "BitsdojoWindowPlugin"))
  MacOSWindowUtilsPlugin.register(with: registry.registrar(forPlugin: "MacOSWindowUtilsPlugin"))
  FLTPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FLTPackageInfoPlusPlugin"))
  ScreenRetrieverPlugin.register(with: registry.registrar(forPlugin: "ScreenRetrieverPlugin"))
  SystemTrayPlugin.register(with: registry.registrar(forPlugin: "SystemTrayPlugin"))
  WindowManagerPlugin.register(with: registry.registrar(forPlugin: "WindowManagerPlugin"))
}
