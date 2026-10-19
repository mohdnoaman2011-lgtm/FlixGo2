# FlixGo

yt-dlp مكتبة Python، لذلك تعمل على خادم صغير (FastAPI) ويتصل بها تطبيق Flutter.

## 1) الخادم
```bash
cd server
python -m venv venv && source venv/bin/activate     # ويندوز: venv\Scripts\activate
pip install -U yt-dlp
pip install -r requirements.txt
# مطلوب: تثبيت ffmpeg (دمج الفيديو + تحويل الصوت إلى mp3)
uvicorn main:app --host 0.0.0.0 --port 8000
```
حدّث yt-dlp دورياً: `pip install -U yt-dlp` (المنصات تغيّر أنظمتها باستمرار).

## 2) التطبيق
```bash
flutter create app_tmp --org com.flixgo --platforms=android,ios
# انسخ مجلدات app/lib و app/assets وملف app/pubspec.yaml إلى app_tmp (استبدل الموجود)
cd app_tmp && flutter pub get && flutter run
```
**أندرويد:** في `android/app/src/main/AndroidManifest.xml` أضف قبل `<application`:
`<uses-permission android:name="android.permission.INTERNET"/>`
وداخل وسم `<application` أضف: `android:usesCleartextTraffic="true"` (للتجربة عبر http).

**iOS:** في `ios/Runner/Info.plist` أضف `NSAppTransportSecurity` ← `NSAllowsArbitraryLoads` = true (للتجربة فقط).

**الحفظ في المعرض (مكتبة gal):**
- أندرويد: في `AndroidManifest.xml` أضف `<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29"/>` (للإصدارات حتى أندرويد 9). من أندرويد 10 فما فوق لا يلزم إذن.
- iOS: في `Info.plist` أضف `NSPhotoLibraryAddUsageDescription` و`NSPhotoLibraryUsageDescription` مع نص يشرح سبب الحفظ.
- الصوت (mp3) لا يظهر في المعرض؛ يُحفظ في مجلد التنزيلات (مكتبة file_saver).

عنوان الخادم من الإعدادات داخل التطبيق: المحاكي `http://10.0.2.2:8000`، والهاتف الحقيقي `http://IP-الجهاز:8000` على نفس الشبكة.