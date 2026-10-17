# عميل Android المنفصل

التطبيق السابق `app/rex_mobile` محفوظ. هذا العميل يتصل بخادم Go الحقيقي؛
ليس منتج REX V1.0 المكتمل ولا حزمة للنشر العام. المنفذ: جلسة ضيف وطاولة
خاصة ودعوة وجاهزية ومغادرة وخروج. لا gameplay أو نتائج أو شراء وهمي.

## التحقق والتشغيل

Flutter3.35.7 / Dart3.9.2؛ JDK21 وbytecode17. Android compile/target36،
min23، AGP8.9.1/Kotlin2.1.0/Gradle8.12 مرشحة للمراجعة. راجع
[مراجعة البنية](../docs/ENGINEERING_REVIEW.md).

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --reporter expanded
flutter run --dart-define=REX_API_URL=https://YOUR-REVIEW-SERVER
```

لا خادم عام منشور. في Android emulator، debug فقط يسمح بـ
`http://10.0.2.2:8080` لخادم المضيف. للجهاز الموصول يمكن استخدام
`adb reverse tcp:8080 tcp:8080` و`http://127.0.0.1:8080` في debug.
النهائي HTTPS حصريًا، دون تجاوز لشهادات TLS أو إرسال token عبر redirects.

```sh
flutter build apk --debug
```

**نجح بناء debug APK في CI**، وآخر [تشغيل ناجح قبل فحص التثبيت الجديد](https://github.com/enad86102-debug/rex/actions/runs/39006048895)
للـcommit ea43e80. هذا ليس AAB أو إصدارًا نهائيًا. وظيفة Android الأصلية
اختبرت Keystore والجلسة على محاكي API36 داخل تطبيق QA منفصل؛ لم تكن تثبّت
تطبيق `production/mobile` نفسه. [تشغيل CI 39009040175](https://github.com/enad86102-debug/rex/actions/runs/39009040175)
للـcommit `20c7342` ثبّت التطبيق الجديد على محاكي API36، فتح الشاشة العربية،
دخل كضيف وأنشأ طاولة حقيقية بالخادم عبر الأزرار. حفظ APK debug ولقطتي
البداية والغرفة داخليًا لمدة 7 أيام. الفحص في `tools/check_android_app.sh`؛
هذا لا يثبت مباراة أو رسومًا ثلاثية الأبعاد أو أداء جهاز فعلي.

ثُبّت Flutter 3.35.7 محليًا لهذه الجولة وشُغلت اختبارات الواجهة، لكن بيئة
العمل لا تحتوي Android SDK أو ADB أو جهازًا موصولًا. لتكرار بناء Android
على جهاز مزود بأدوات مرخصة ومثبتة:

```sh
sdkmanager 'platforms;android-36' 'build-tools;36.0.0' 'platform-tools'
flutter doctor -v
flutter build apk --debug
```

قد يحتاج Gradle حزمة NDK التي يحددها Flutter؛ أي اتفاقيات إضافية يراجعها
مخوّل. فحوص CI الحالية أثبتت Keystore والجلسة على محاكي، ويضيف الفرع
الحالي فحص تثبيت التطبيق الجديد نفسه. لا يثبت ذلك سلوك جهاز فعلي أو
release build أو أداء اللعب. راجع HANDOFF للفرق بين دليل البناء وقياسات
الأداء الغائبة.

## تكامل حقيقي قابل للإعادة

من جذر المستودع، Go الصحيح وFlutter في PATH:

```sh
bash production/tools/check_live.sh
```

يشغّل خادمًا معزولًا على127.0.0.1:18081 بمجلد مؤقت ويختبر أربعة عملاء
Flutter: دخول وإنشاء/انضمام/جاهزية ومغادرة وخروج. ينظف الخادم والبيانات.
لا تستخدم بيانات حقيقية. `live_server_test.dart` يُتخطى صراحة في الاختبارات
العادية دون `REX_TEST_SERVER_URL`؛ تشغيل السكربت هو الدليل الفعلي.

## الجلسة والتعافي

قناة `rex/session_vault` تشفّر token والطلب المعلق باستخدام AES-GCM ومفتاح
غير قابل للتصدير في Android Keystore. encrypted preferences مستثناة من
backup وdevice transfer؛ لا plaintext fallback.

يُحفظ كل أمر مع action ID قبل إرساله. النتيجة الملتبسة تبقي الطلب لإعادة
المعرف نفسه؛ لا ينشئ العميل نية جديدة قد تنفذ مرتين. استعادة العملية تعيد
الطلب ثم تجلب الحالة. polling يتوقف في الخلفية ويعود في المقدمة. معرفات
اللاعبين من الخادم فعلًا؛ لا أسماء وهمية أو خصوم محليون يتظاهرون بأنهم أونلاين.

لا ربط/ترقية/استعادة عبر أجهزة أو حذف حساب بعد. الخروج ينبه لفقدان الوصول
إلى هوية الضيف ويغادر الطاولة ثم يبطل الجلسة. انتهاء الجلسة وسياسة تنظيف
مقعد اللاعب الغائب ضمن عوائق الإصدار.

## توقيع الإصدار

لا release debug signing. تتوقف release tasks دون توقيع خارجي و
`REX_APPLICATION_ID` نهائي معتمد. المفاتيح خارج Git، وkeystore/jks مستثناة.
يحقن المسؤول `REX_SIGNING_STORE`, `REX_SIGNING_STORE_PASSWORD`,
`REX_SIGNING_ALIAS`, `REX_SIGNING_KEY_PASSWORD` من مخزن أسرار؛ لا تضع
كلمات المرور في أوامر قابلة للمشاركة أو تقارير CI.

بعد اجتياز **كل** [بنود قبول الإصدار](../docs/RELEASE_ACCEPTANCE.md) فقط:

```sh
flutter build appbundle --release --dart-define=REX_API_URL=https://APPROVED-ENDPOINT
```

هذا أمر مستقبلي موثق؛ لا AAB بُني أو وُقّع ولا نشر Play. لا تُنشئ مفاتيح
إنتاج أو توافق سياسات قانونية نيابة عن الفريق.
