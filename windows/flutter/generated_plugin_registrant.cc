//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <auto_update/auto_update_plugin.h>
#include <dart_vlc/dart_vlc_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  AutoUpdatePluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("AutoUpdatePlugin"));
  DartVlcPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("DartVlcPlugin"));
}
