# تسليم استكمال REX — 2026-10-16

## تحديث 17 أكتوبر 2026: تثبيت التطبيق الجديد على Android

الفرع `production/android-app-install-smoke` فوق PR#9، ومسودة
[PR#10](https://github.com/enad86102-debug/rex/pull/10). نجح
[تشغيل CI 39009040175](https://github.com/enad86102-debug/rex/actions/runs/39009040175)
للـcommit `20c7342`: أربعة jobs ناجحة؛ APK debug لتطبيق `production/mobile`
نفسه ثُبّت على محاكي API36، ورُسمت شاشة الدخول، ودخل ضيف وأنشأ طاولة
خادمية عبر واجهة Android. لقطات الشاشة وAPK الداخلي محفوظة كـartifact
لمدة 7 أيام. تبدو واجهة الغرفة مقروءة لكنها بسيطة، ولا تطابق مشهد REX
الملكي المرجعي؛ لا أوراق أو شخصيات أو لعبة عامة. `start` يرد
`rules_not_approved`. لا جهاز Android فعلي أو AAB release أو اعتماد أصول.

## تحديث 17 أكتوبر 2026: تدقيق المشروع الكامل وإصلاح الإيصالات

الفرع `production/full-audit-receipt-fix` متراكم فوق PR#8. اقرأ
[تقرير التدقيق الكامل](docs/FULL_PROJECT_AUDIT_2026-10-17.md):
أُغلق تسريب دعوة تاريخية عند إعادة إيصال أمر بعد حذف الطاولة، وأضيف
اختبار قبل إعادة فتح التخزين وبعدها. نجحت فحوص Go/Flutter/live/security
وضغط TLS المعزول محليًا. التقرير يبين الفرق بين نجاح الغرف الحالية
وقبول مباراة REX V1.0، ويضع عوائق القواعد وTarneeb والأصول والحفظ
والأجهزة/الإصدار صراحة. لا يُفتح `/start` دون عقد معتمد.

## تحديث 17 أكتوبر 2026: تدقيق المحرك والبحث

الفرع الأحدث `production/trix-engine-hardening` متراكم فوق
`production/trix-complex-engine`. اقرأ
[تقرير البحث والتدقيق](docs/TRIX_ENGINE_DEEP_RESEARCH_REPORT_2026-10-17.md):
أُصلح تعارض مفاتيح إيصالات الأفعال ذات الفاصل `:`، وأضيف فحص إعادة تشغيل
الحالة الداخلية واختباراته. نجح Go race/coverage/vet وfuzz محلي وlive
وsecurity؛ هذه فحوص أساس لا اختبار مباراة على أربعة أجهزة. يطلب التقرير
من المشرف صياغة نص نهائي للقرارات البشرية المعلقة. تفعيل اللعبة وإعلان
REX V1.0 ما زالا محجوبين.

**REX V1.0 غير مكتمل؛ هذه دفعة هندسية فعلية للأساس، وليست تسليم لعبة نهائية.**

## تحديث محرك Trix Complex المرشح

المهمة 006 على `production/trix-complex-engine` فوق PR#5. اقرأ
[تقرير التنفيذ المرشح](docs/TRIX_CANDIDATE_IMPLEMENTATION.md) و
[العقد المسودّة](rules/trix_complex/RULES_CONTRACT_0.9.0_DRAFT.md).
المحرك الخالص يختبر ثماني صفقات وعقود Complex وTrix، بينما التفعيل
العام والحفظ الدائم ونقل المباراة وTarneeb والأصول والإصدار محجوبة.

## تحديث صفقة المقاعد وعقد المشهد

العمل الأحدث على `production/matchcore-asset-contracts` فوق PR#4؛ اقرأ
[تقرير الصفقة والمشهد](docs/MATCHCORE_SCENE_REPORT.md). أُضيفت صفقة
خادمية ذات أربعة مقاعد وعرض أوراق خاص بكل مقعد، وعقد تركيب محايد للـrenderer
للطاولات الست والوجهات الأربع. لم يُفعّل محرك قواعد أو تُقبل أصول نهائية.

## تحديث الاستعادة والتشغيل

العمل الأحدث على `production/operations-recovery` في
[PR#4](https://github.com/enad86102-debug/rex/pull/4)، متراكم فوق PR#3
من دون دمج. اقرأ [التنفيذ والاختبارات الحالية](docs/OPERATIONS_RECOVERY.md)
قبل سجل الأساس أدناه. دخل تنظيف جلسات الانتظار المنتهية وتدوير الدعوات
عند الإقلاع وكل خمس دقائق، وظهرت عدادات تشغيل محمية للمشرف.
حالة قبول V1.0 تبقى غير مكتملة؛ عقود اللعب والأصول والبنية التجارية
والتوقيع والمراجعة البشرية لم تُعتمد بعد.

## تحديث التحمل والبحث الموسع

الدفعة الأحدث على `production/resilience-research` في
[PR#3](https://github.com/enad86102-debug/rex/pull/3)، فوق PR#2 دون دمج.
اقرأ [تقرير التحمل](docs/RESILIENCE_REPORT.md) و[بحث 1,548 مستودعًا](docs/RESEARCH_1548.md).
توجد حدود admission وإصلاح لمحدد IP ونسخ معزول أسرع للمعاملات واختبارات
ضغط TLS وتسلسلات حالات مولدة. أرقام المختبر ليست سعة لاعبين أو قبول إصدار.
لا تغيير لقواعد اللعب أو الأصول أو الموافقات غير المحسومة أدناه.

## تحديث تدقيق QA والأمان

توجد دفعة لاحقة على `production/qa-security-audit` في
[PR#2](https://github.com/enad86102-debug/rex/pull/2)، فوق فرع الأساس دون دمج.
ابدأ من [تقرير QA الحالي](docs/QA_REPORT.md) و[بحث الأدوات](docs/QA_RESEARCH.md)
لمعرفة الإصلاحات ونتائج Android الفعلية والاعتماد التالي. بقية هذا الملف
سجل دفعة الأساس السابقة؛ أعداد اختباراته وحالة native فيه ليست آخر حالة.
تعديلات legacy اللاحقة محدودة باختبار regression ومنع توقيع release بـdebug.

## Git وحدود العمل

- المستودع: `enad86102-debug/rex`؛ base المفحوص `1c6698b` على main.
- الفرع: `production/v1-foundation`؛ لا merge أو force-push أو استبدال legacy.
- commit التنفيذ المتحقق `c6959ec`؛ [مسودة PR#1](https://github.com/enad86102-debug/rex/pull/1).
- الكود الجديد تحت `production/`، مع workflow جديد فقط في `.github/workflows/`.
- لم تتغير `app/` أو `experiments/` أو `assets/` الأصلية أو وثائق الحوكمة.
- مصدر التفويض: توجيه المستخدم التنفيذي الشامل في جلسة2026-10-16.
  لا نفترض أن هذا مصدر اعتماد قواعد إقليمية أو توقيع تقني من عبدالعزيز.

## المنفذ فعلًا والملفات

| المجموعة | الملفات / الوظيفة |
|---|---|
| خادم قابل للبناء | `server/cmd/rexd/main.go`؛ configuration وTLS/قفل عملية وإغلاق سليم |
| هوية وجلسات وحفظ | `server/internal/service/service.go`؛ ضيوف حقيقيون، بصمات جلسات، طاولات خاصة، معاملات snapshot وإيصالات وأحداث |
| بروتوكول وصلاحيات | `server/internal/api/api.go`؛ مصادقة وعضوية وrate limiting وJSON limits وقراءة تشغيلية محمية |
| أوراق مشتركة | `server/internal/cards/`؛ deck52 وCSPRNG shuffle وتوزيع round-robin، بلا قواعد لعبة أو تسجيل |
| عميل متصل | `mobile/lib/api.dart`, `controller.dart`, `main.dart`, `strings.dart`؛ دخول وطاولة ودعوة وجاهزية ومغادرة وخروج RTL |
| حفظ Android | `mobile/lib/vault.dart`, `mobile/android/.../MainActivity.kt`؛ AES-GCM/Keystore وحفظ pending action؛ native غير مختبر على جهاز بعد |
| Android configuration | `mobile/android/`؛ API36، min23، network policy/backup rules، release signing خارجي بلا debug fallback |
| تحقق | Go tests، `mobile/test/`، `tools/check_live.sh`, `tools/test_server_process.py` |
| أصول | `tools/inspect_glb.py`, `blender_intake.py`, `test_inspect_glb.py`, `assets/staging-intake.json`؛ فحص لا توليد/اعتماد |
| التشغيل | `server/Dockerfile`, `rexd.service`, README لكل حزمة |
| التوثيق | `docs/ENGINEERING_REVIEW.md`, `RULES_DECISIONS.md`, `ASSET_PRODUCTION.md`, `SECURITY_REVIEW.md`, `RELEASE_ACCEPTANCE.md` |
| CI | `.github/workflows/rex-production.yml`؛ لا نشر أو توقيع إنتاج |

العميل يحفظ action ID قبل الإرسال ويعيده بعد نتيجة ملتبسة أو استعادة عملية.
قراءة الحالة من الخادم ولا balances/XP/wins/خصوم وهمية. حجز المقاعد متسلسل؛
أربعة فقط. غير الأعضاء لا يرون الطاولة؛ المالك وحده يصل إلى start، الذي
يرفض `rules_not_approved` بدل اختراع مباراة. لا player hands في البروتوكول.

## التحقق المنفذ ونتائجه

| الفحص | النتيجة الفعلية |
|---|---|
| Go1.27.2 `gofmt`, `go vet` | ناجح |
| `go test -race -cover ./...` | 10 اختبارات ناجحة؛ api84.4%، cards100%، service79.0%، cmd0% تغطية unit |
| اختبارات HTTP/TLS | أربعة clients مستقلة، انضمام/جاهزية، رفض صلاحيات، reconnect عبر اتصالات جديدة وحالة محفوظة؛ ناجح، لا مباراة |
| اختبار process منفصل | اختباران ناجحان؛ cold restart يحفظ session/table/receipt/logout، رفض writer ثانٍ، إعداد HTTP مكشوف وadmin key قصير |
| `govulncheck@v1.9.0` | لا ثغرات معروفة مكتشفة؛ ليس تدقيقًا شاملًا للمنتج |
| Flutter3.35.7/Dart3.9.2 format/analyze | ناجح بلا ملاحظات |
| Flutter unit/widget | 6 ناجحة، RTL وحجمان320×640 و800×1280؛ live test متخطى صراحة في التشغيل العادي |
| `check_live.sh` | ناجح: اختبارا process ثم اختبار Flutter حقيقي بأربعة transports مع Go، دون skip |
| GLB intake | 19 ملفًا فُحصت؛ لا skins أو animation في أي منها؛ خمسة guide-only بما فيها scene |
| أدوات intake | اختباران Python ناجحان؛ لا قبول بصري آلي |
| Blender4.3.2 | استيراد شخصية الشمال القديمة ناجح؛ 6024 مثلثًا، armatures0، actions0، UV0 |
| Docker build | ناجح؛ image `sha256:40096b2de4c42f06bb650d6e67ea080806e84ae334548c18211aeec2b5c0bb54` |
| Docker تشغيل/حفظ | user65532، rootfs read-only، cap-drop ALL، no-new-privileges؛ health/guest/table ثم restart وsession/table/receipt ناجحة على volume |
| Android debug APK | **نجح على GitHub CI** للـcommit c6959ec؛ محليًا فشل لعدم اكتمالSDK/ترخيصه؛ النتيجتان منفصلتان |
| Android release/AAB | **لم يُبنَ**؛ التوقيع/الهوية وعوائق المنتج لم تُحسم |
| real-device/performance/visual acceptance | **لم تُجرَ**؛ لا Android device ولا أصول نهائية أو موافقة الفريق |

اختبار corrupt-store فشل أولًا وكشف أن unmarshal فوق defaults كان يخفي
حقولًا مفقودة؛ أُصلح بتصفير loaded state قبل decode ثم أعيدت الفحوص ونجحت.
تجنب تقديم نتائج قبل الإصلاح كنجاح. Kotlin وGradle بُنيا عبر CI؛ سلوك
Keystore على جهاز فعلي لم يُختبر.

### دليل CI الإضافي

[Run 38875799795](https://github.com/enad86102-debug/rex/actions/runs/38875799795)
نجح بالكامل للـcommit `c6959ec`، بما فيه اختبارات Go/Flutter والتكامل و
`flutter build apk --debug --no-pub`. السجل عند08:50:43UTC يؤكد إنتاج
`build/app/outputs/flutter-apk/app-debug.apk`. Gradle assembleDebug استغرق
173.3s؛ هذا زمن بناء، **ليس** قياس أداء اللعبة. NDK27.0.12077973 و
CMake3.22.1 نُزّلا في runner بترخيص موجود ومقبول مسبقًا فيه. لم نقبل
الاتفاقية المحلية؛ سؤالها ما زال معلقًا. لم تُنشر حزمة عامة أو تُرفع إلىPlay،
ولم يضف workflow خطوة حفظ APK كـartifact؛ دليل البناء في السجل والكود قابل للإعادة.

workflow القديم [Run38875799698](https://github.com/enad86102-debug/rex/actions/runs/38875799698)
فشل في formatting للملف `app/rex_mobile/test/rex_app_test.dart`، الذي
يطابقmain ولم يُعدّل في الفرع. فحوص analyze/test/build القديمة تخطيت بعد
ذلك؛ لا تُعلن نجاح جميع workflows. لم نغيّر legacy لمجرد تنسيق ملفه.

## حالة الخادم والأصول والعميل

- الخادم: قابل للتشغيل محليًا وفي حاوية، لا نشر إنتاج ولا قاعدة بيانات نهائية.
  snapshot أحادي العملية مرشح مراجعة؛ حدوده وسياساته في ENGINEERING_REVIEW.
- العميل: الوظائف المدرجة متصلة ومختبرة على Flutter host runner؛ debugAPK
  بُني فيCI، لكن لا أربعة أجهزة Android ولا renderer3D أو تحكم أوراق أو مباراة.
- الأصول: الشعار الأصلي فقط منقول دون تعديل؛ لا شخصيات/بيئات إنتاجية مدمجة.
  مواصفات التسليم والخطوات الفعلية للفنان/الفني في ASSET_PRODUCTION.
- الأمان: لا أموال أو شراء أو أسرار إنتاج. مكتبة Go القياسية فقط. سرية
  أيدي المباريات لم تُختبر لعدم وجود محركها. حسابات الاستعادة/الحذف والحظر
  وتقارير الدعم وRBAC/monitoring والاحتفاظ التجاري لا تزال غير مكتملة.

## العوائق والأسئلة المرسلة

1. **قواعد اللعبة الأولى:** أُرسل سؤال المستخدم عن Trix Complex/Tarneeb أولًا
   ومرجع القواعد. لا رد مسجل عند كتابة التسليم. لا تفعّل scoring/turns على
   افتراض شائع؛ التفاصيل المطلوب اعتمادها في RULES_DECISIONS.
2. **ترخيص Android SDK:** نُزّلت cmdline tools؛ sdkmanager يطلب اتفاقية
   Google، بند2.4 يشترط صلاحية إلزام الجهة. لم تُقبل نيابة عن الفريق.
   أُرسل سؤال تفويض محدد؛ لا رد مسجل عند كتابة التسليم. لا تعتبر مرور الوقت
   موافقة. العائق محلي فقط بعد نجاح debug build فيCI؛ بعد التفويض ثبّت
   الحزم للتحقق المحلي ثم اختبر native Keystore على Android.
3. **مراجعة عبدالعزيز:** persistence/auth/transport للمباريات/renderer/toolchain
   ومصفوفة الأجهزة/الميزانيات؛ الكود الحالي ليس إقرار اعتماد.
4. **أصول حقيقية:** فنانون/مصادر مرخصة ومراجعة بشرية للشخصيات والبيئات
   والطاولات؛ وجود Blender لا يوفر تلك النماذج تلقائيًا.
5. **إصدار:** هوية/توقيع وحسابPlay وسياسات وبيانات السلامة وقياس أجهزة
   وتشغيل خدمة فعلية؛ لا نشر أو شراء مفعّل في هذه الدفعة.

## الخطوة التالية بدقة

- تحقق من الردود الجديدة أولًا، مع الحفاظ على الأسئلة غير المحسومة.
- عند تفويض SDK: شغّل sdkmanager للحزم36، ثم `flutter doctor -v` وأعد
  debug build محليًا؛ البناء نفسه نجح فيCI. اختبر
  Keystore وbackup/lifecycle على Android. لا تنتج signing keys أو تقبل
  اتفاقيات إضافية غير مفوضة.
- عند ورود عقد لعبة معتمد: احفظ النسخة ومصدر الموافقة، ثم نفّذ engine
  مستقلًا واختبارات fixtures والتسجيل والحركات والأيدي الخاصة؛ اربطه
  بمعاملات match/actions/events/recovery، ثم vertical slice أربع أجهزة
  تكمل مباراة موثقة. لا تزيل بوابة start لمجرد وجود deck/shuffle.
- مع عبدالعزيز: راجع مرشح قاعدة بيانات معاملات قبل استقرار مخطط الحسابات
  والمباريات؛ لا توسع snapshot إلى تشغيل تجاري أو microservices.
- ابدأ intake للأصول النهائية فور توفرها؛ لا تستبدلها بنماذج guide.

إعادة الفحوص من root، بعد وضع الأدوات الصحيحة فيPATH:

```sh
cd production/server
go test -race -cover ./...
go vet ./...
go run golang.org/x/vuln/cmd/govulncheck@v1.9.0 ./...
cd ../mobile
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --reporter expanded
cd ../..
bash production/tools/check_live.sh
python3 -m unittest discover -s production/tools -p 'test_*.py'
```

اختباراprocess في unittest العام متخطيان دون `REX_SERVER_BINARY` عمدًا؛
check_live.sh يبني binary ويشغلهما فعلًا. ملفات البيانات/الجلسات/المفاتيح
لا تدخل Git. لا يلزم إبقاء خدمات التحقق شغالة بين المهام.
