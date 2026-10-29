set -e
HTML=$(ls *.html | head -1)
echo "Игра: $HTML"
for d in app/src/main/assets app/src/main/java/com/aigamelog/blackdawn app/src/main/res/mipmap-xxxhdpi; do mkdir -p $d; done
cp "$HTML" app/src/main/assets/index.html
if [ -f three.min.js ]; then cp three.min.js app/src/main/assets/three.min.js; else curl -fsSL -o app/src/main/assets/three.min.js https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js; fi
test $(wc -c < app/src/main/assets/three.min.js) -gt 100000
sed -i 's#https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js#three.min.js#' app/src/main/assets/index.html
python3 - <<'PY'
import zlib,struct,math
n=192
raw=b''
for y in range(n):
    r=bytearray([0])
    for x in range(n):
        dx,dy=x-n/2,y-n/2
        d=math.hypot(dx,dy)
        on=abs(d-n*0.3)<n*0.02 or (abs(dx)<n*0.012 and abs(dy)<n*0.42) or (abs(dy)<n*0.012 and abs(dx)<n*0.42) or d<n*0.04
        r+=bytes((255,42,26) if on else (8,9,11))
    raw+=bytes(r)
def ch(t,d):
    return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
png=b'\x89PNG\r\n\x1a\n'+ch(b'IHDR',struct.pack('>IIBBBBB',n,n,8,2,0,0,0))+ch(b'IDAT',zlib.compress(raw))+ch(b'IEND',b'')
open('app/src/main/res/mipmap-xxxhdpi/ic_launcher.png','wb').write(png)
PY
cat > settings.gradle <<'EOF'
pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement { repositories { google(); mavenCentral() } }
rootProject.name = "BlackDawn"
include ':app'
EOF
echo "plugins { id 'com.android.application' version '8.5.2' apply false }" > build.gradle
echo "org.gradle.jvmargs=-Xmx2g" > gradle.properties
cat > app/build.gradle <<'EOF'
plugins { id 'com.android.application' }
android {
    namespace 'com.aigamelog.blackdawn'
    compileSdk 34
    defaultConfig {
        applicationId "com.aigamelog.blackdawn"
        minSdk 24
        targetSdk 34
        versionCode 9
        versionName "9.0"
    }
    compileOptions { sourceCompatibility JavaVersion.VERSION_17; targetCompatibility JavaVersion.VERSION_17 }
}
EOF
cat > app/src/main/AndroidManifest.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application
        android:label="Чёрный рассвет"
        android:icon="@mipmap/ic_launcher"
        android:hardwareAccelerated="true"
        android:theme="@android:style/Theme.DeviceDefault.NoActionBar.Fullscreen">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:screenOrientation="sensorLandscape"
            android:configChanges="orientation|screenSize|keyboardHidden|smallestScreenSize|screenLayout|uiMode"
            android:windowSoftInputMode="adjustNothing">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF
cat > app/src/main/java/com/aigamelog/blackdawn/MainActivity.java <<'EOF'
package com.aigamelog.blackdawn;

import android.app.Activity;
import android.graphics.Color;
import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class MainActivity extends Activity {
    private WebView web;

    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        if (android.os.Build.VERSION.SDK_INT >= 28) {
            getWindow().getAttributes().layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
        }
        web = new WebView(this);
        web.setBackgroundColor(Color.BLACK);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setAllowFileAccess(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setMixedContentMode(WebSettings.MIXED_CONTENT_COMPATIBILITY_MODE);
        web.setLayerType(View.LAYER_TYPE_HARDWARE, null);
        web.setOverScrollMode(View.OVER_SCROLL_NEVER);
        web.setWebViewClient(new WebViewClient());
        web.setWebChromeClient(new WebChromeClient());
        setContentView(web);
        web.loadUrl("file:///android_asset/index.html");
    }

    private void immersive() {
        getWindow().getDecorView().setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY | View.SYSTEM_UI_FLAG_FULLSCREEN
            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION);
    }

    @Override public void onWindowFocusChanged(boolean f) { super.onWindowFocusChanged(f); if (f) immersive(); }
    @Override protected void onPause() { super.onPause(); web.onPause(); }
    @Override protected void onResume() { super.onResume(); web.onResume(); immersive(); }
    @Override protected void onDestroy() { web.destroy(); super.onDestroy(); }
}
EOF
