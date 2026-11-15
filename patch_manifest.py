import re

path = "android/app/src/main/AndroidManifest.xml"
with open(path, "r", encoding="utf-8") as f:
    xml = f.read()

extra = (
    '<uses-permission android:name="android.permission.INTERNET"/>\n'
    '    <uses-feature android:name="android.software.leanback" android:required="false"/>\n'
    '    <uses-feature android:name="android.hardware.touchscreen" android:required="false"/>\n'
    '    <queries><intent><action android:name="android.intent.action.VIEW"/>'
    '<data android:scheme="https"/></intent></queries>\n'
    '    <application'
)
xml = xml.replace("<application", extra, 1)

launcher = '<category android:name="android.intent.category.LAUNCHER"/>'
xml = xml.replace(
    launcher,
    launcher + '\n                <category android:name="android.intent.category.LEANBACK_LAUNCHER"/>',
    1,
)

with open(path, "w", encoding="utf-8") as f:
    f.write(xml)
print("Manifest parcheado")
