"""Prepare the Android build identity and QS service lifecycle."""
import argparse
import json
import re
from pathlib import Path
from prepare import ROOT, SOURCE, replace_once, write_if_changed

parser = argparse.ArgumentParser()
parser.add_argument("profile", choices=["full", "qs"])
args = parser.parse_args()
config = json.loads((ROOT / "config/client.json").read_text(encoding="utf-8"))
package = config[f"android_{args.profile}_package"]
manifest = SOURCE / "flutter/android/app/src/main/AndroidManifest.xml"
text = manifest.read_text(encoding="utf-8")
label = "FR CODE LABS QS" if args.profile == "qs" else "FR CODE LABS"
text, count = re.subn(r'android:label="[^"]+"', f'android:label="{label}"', text, count=1)
if count != 1:
    raise RuntimeError("Android application label not found")
write_if_changed(manifest, text)
gradle = SOURCE / "flutter/android/app/build.gradle"
text = gradle.read_text(encoding="utf-8")
text, count = re.subn(r'applicationId "[^"]+"', f'applicationId "{package}"', text, count=1)
if count != 1:
    raise RuntimeError("Android application ID not found")
write_if_changed(gradle, text)
replace_once(SOURCE / "flutter/android/gradle.properties", 'org.gradle.jvmargs=-Xmx1024M', 'org.gradle.jvmargs=-Xmx4096M -XX:MaxMetaspaceSize=1024M')

service = SOURCE / "flutter/android/app/src/main/kotlin/com/carriez/flutter_hbb/MainService.kt"
replace_once(service, '    override fun onTaskRemoved(rootIntent: Intent?) {', '''    override fun onTaskRemoved(rootIntent: Intent?) {
        if (FFI.getBuildinOption("cf-profile") == "qs") {
            destroy()
            android.os.Process.killProcess(android.os.Process.myPid())
            return
        }''')
replace_once(service, 'const val DEFAULT_NOTIFY_TITLE = "RustDesk"', 'const val DEFAULT_NOTIFY_TITLE = "FR CODE LABS"')
replace_once(service, 'val channelName = "RustDesk Service"', 'val channelName = "FR CODE LABS"')
replace_once(service, 'description = "RustDesk Service Channel"', 'description = "Suporte remoto FR CODE LABS"')
boot = SOURCE / "flutter/android/app/src/main/kotlin/com/carriez/flutter_hbb/BootReceiver.kt"
replace_once(boot, '    override fun onReceive(context: Context, intent: Intent) {', f'''    override fun onReceive(context: Context, intent: Intent) {{
        if (context.packageName == "{config['android_qs_package']}") return''')
home = SOURCE / "flutter/lib/mobile/pages/home_page.dart"
replace_once(home, '''      _chatPageTabIndex = _pages.length;
      _pages.addAll([ChatPage(type: ChatPageType.mobileMain), ServerPage()]);''', '''      if (bind.mainGetBuildinOption(key: 'cf-profile') == 'qs') {
        _chatPageTabIndex = -1;
        _pages.add(ServerPage());
      } else {
        _chatPageTabIndex = _pages.length;
        _pages.addAll([ChatPage(type: ChatPageType.mobileMain), ServerPage()]);
      }''')
settings = SOURCE / "flutter/lib/mobile/pages/settings_page.dart"
replace_once(settings, '    enhancementsTiles.add(SettingsTile.switchTile(\n        initialValue: _enableStartOnBoot,', "    if (bind.mainGetBuildinOption(key: 'cf-profile') != 'qs') {\n      enhancementsTiles.add(SettingsTile.switchTile(\n        initialValue: _enableStartOnBoot,")
replace_once(settings, '''          gFFI.invokeMethod(AndroidChannel.kSetStartOnBootOpt, toValue);
        }));''', '''          gFFI.invokeMethod(AndroidChannel.kSetStartOnBootOpt, toValue);
        }));
    }''')
print(f"Android {args.profile}: {label} / {package}")
