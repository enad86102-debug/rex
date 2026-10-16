# REX native QA harness

تطبيق اختبار debug فقط، بهوية dev.rex.qa.native، وليس بديلًا عن منتجREX.
يستخدم Dart controller وtransport وvault من حزمة production/mobile مباشرة،
ويضم مصدر MainActivity.kt الإنتاجي وموارده عبر Gradle sourceSets. لا توجد
نسخة مقلدة من التشفير أو خادم محلي وهمي.

عزل الحزمة يمنع تبعيات integration_test الأصلية من دخول تطبيق الإنتاج؛
نسخة Flutter المستخدمة تضيف بعض تبعيات الاختبار إلى release أيضًا عند
وجود plugin في pubspec التطبيق. release/profile مغلقان في هذا المشروع.

شغل من root: bash production/tools/check_android_device.sh، بعد تشغيل
محاكي جديد علىemulator-5554 مع الأدوات والتراخيص المعتمدة مسبقًا. script
يبني خادمGo فعليًا، ويختبر القناة والتشفير وحذف الجلسة واستعادة الطاولة،
ويفحص ملفpreferences لغيابmarker نصي ثم يمسح بيانات تطبيق الاختبار فقط.
هذا لا يثبت اختبارات أربعة أجهزة أو أداء جهاز فعلي أو جودة أصول3D.
