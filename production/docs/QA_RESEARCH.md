# بحث أدوات QA والأمان والمجسمات — 2026-10-16

النطاق: بحث GitHub والمصادر الأصلية ثم تطبيق أدوات مناسبة على الكود الموجود.
فُسرت كلمة «الجسمات» في الطلب بأنها المجسمات/الأصول3D؛ لم يُنتظر التوضيح
لإجراء فحوص الكود والأمان المستقلة. هذا ليس بحثًا عن محركات ألعاب بديلة،
ولا موافقة على تغيير المكدس أو قواعد اللعب.

## المقارنة والاختيار

الرخص أدناه كما يعرّفها المستودع الأصلي/بيانات GitHub يوم البحث. الأدوات
المطبقة تبعيات تطوير مستقلة؛ لا تُضمّن مكتبات فحص الأمن أو npm في تطبيق
اللعبة أو خادم الإنتاج، ولا تُرسل الشفرة إلى خدمة فحص خارجية.

| المشروع والمصدر الأصلي | الرخصة | ملاءمته لـREX والقرار |
|---|---|---|
| [Flutter](https://github.com/flutter/flutter) | BSD-3-Clause | flutter_test وintegration_test الرسميان؛ مطبقان للاختبارات والعميل، وتجهيز اختبارات Keystore على Android |
| [Patrol](https://github.com/leancodepl/patrol) | Apache-2.0 | مفيد لتفاعلات النظام/الأذونات؛ لم يُضف لأن اختبارات القناة الأصلية الحالية تكفيها integration_test، ويحتاج أجهزة أيضًا |
| [Staticcheck](https://github.com/dominikh/go-tools) | MIT | تحليل Go إضافي إلى vet؛ استُخدم v0.8.2 وأُضيف فحص قابل للإعادة |
| [gosec](https://github.com/securego/gosec) | Apache-2.0 | SAST لـGo؛ تثبيت commit707f2271f665 المتوافق معGo1.27؛ لا AI/autofix ولا مفاتيح سحابية |
| [Gitleaks](https://github.com/gitleaks/gitleaks) | MIT | فحص أسرار Git والـdiff مع redaction؛ CLI v8.30.1 دون gitleaks-action مدفوع/مقيد |
| [MASVS](https://github.com/OWASP/masvs) | CC-BY-SA-4.0 | مرجع تخزين/شبكة/مصادقة/خصوصية؛ ربط نطاق الفحوص بالضوابط لا إعلان شهادة امتثال |
| [MASTG](https://github.com/OWASP/mastg) | CC-BY-SA-4.0 | مرجع اختبار Android والتخزين الأصلي؛ أساس سيناريوهات Keystore، وفحوص backup/lifecycle تبقى أوسع من هذه الدفعة |
| [MobSF](https://github.com/MobSF/Mobile-Security-Framework-MobSF) | GPL-3.0 | فحص APK ثابت/ديناميكي لاحق مستقل؛ لم يُشغّل، ولا يُزعم أن إعداد native tests يعوضه أو يعوض pentest |
| [ZAP](https://github.com/zaproxy/zaproxy) | Apache-2.0 | DAST على بيئة مصرح بها لاحقًا؛ لم يُشغّل ضد أي خدمة عامة، واختبارات HTTP الحالية محلية معزولة |
| [Schemathesis](https://github.com/schemathesis/schemathesis) | MIT | مفيد بعد OpenAPI كامل موثق؛ لم يُضف spec شكلي لمجرد تشغيله، استُخدم Go fuzzing للعقد الحالي |
| [k6](https://github.com/grafana/k6) | AGPL-3.0 | مرشح أحمال/latency للخدمة بعد تحديد budgets وبيئة اختبار؛ ليس اختبار FPS أو أداء Android؛ لم يُشغّل |
| [Trivy](https://github.com/aquasecurity/trivy) | Apache-2.0 | مرشح فحص صورة/SBOM؛ لم يُشغّل في هذه الدفعة، ولا يُنسب إليه فحص govulncheck أو gosec |
| [Khronos glTF Validator](https://github.com/KhronosGroup/glTF-Validator) | Apache-2.0 | مطبق npm2.0.0-dev.3.10 مع lock/integrity، لفحص جميع ملفاتGLB القديمة رسميًا مع منع موارد خارجية |
| [glTF Transform](https://github.com/donmccurdy/glTF-Transform) | MIT | مرشح لاحقًا لضغط textures/تحويل scene بعد اختيار renderer؛ لا تعديل تلقائي للأصول الأصلية |
| [meshoptimizer](https://github.com/zeux/meshoptimizer) | MIT | مرشح optimization/LOD بعد ميزانيات واقعية؛ لا يحول mannequin إلى إنسان نهائي؛ لم يُدمج |

جميع المستودعات15 كانت غير مؤرشفة وقت الفحص. snapshot بيانات المصادر
مرفق في `production/qa/research-sources.json`؛ لا تُعامل أرقام النشاط أو
النجوم كضمان جودة أو أمان. لا كود لعبة خارجي نُسخ لتجاوز اعتماد قواعدREX.

## لماذا هذه المجموعة

اختبارات Flutter الرسمية + Go race/vet/fuzz + Staticcheck/gosec/Gitleaks
وgovulncheck تغطي إخفاقات مختلفة دون إطار اختبار ضخم داخل المنتج. Khronos
يتحقق من conformance الحقيقية للـGLB، بينما intake الخاص بنا يقيس ما يلزم
لتصنيف جاهزية الأصل مثل skins/animations/UV. سلامة الملف لا تثبت حقوقه أو
جماله أو أداءه على Android، لذلك تظل releaseApproved=false دائمًا في التقرير.

## أمان أدوات الفحص

- إصدارات أدوات Go مثبتة، وnpm lock يسجل SHA-512؛ لا أوامر `curl | sh`.
- gosec v2.29.0 فشل في تحليل export data لـGo1.27، لذلك لا تعد نتيجة
  Issues=0 فيه فحصًا ناجحًا. اختير upstream commit
  `707f2271f66579a18e1da25794b1e8012247274b` (نسخة module
  `v2.29.1-0.20261015133444-707f2271f665`) مع x/tools0.52.0؛ script
  يرفض أخطاء التحليل حتى إن كانت قائمة findings فارغة. هذا pin لأداةQA،
  ولا يغير dependencies خادم الإنتاج. راجع التقرير لنتيجة التشغيل.
- يمنع callback الموارد الخارجية في فحصGLB أي تحميل HTTP أو ملفات محلية
  يطلبها الأصل؛ حد الملف64MiB وحد أقصى1000 issue في الفحص الرسمي.
- مخرجات Gitleaks مخفية الأسرار؛ لا تُرفع tokens أو snapshots أو مفاتيح.
- رُوجعت نتيجتاG304 في gosec: مصدر المسار `REX_STORE` من إعداد مسؤول
  الخدمة، لا HTTP؛ وُثّقت استثناءات ضيقة على السطرين فقط. لا تعطيل عام للقاعدة.
- لم يُستخدم android-emulator-runner لأنه يقبل تلقائيًا جميع تراخيصSDK
  في مصدره. workflow الخاص بنا لا ينفذ yes أو --licenses؛ يفشل إذا تطلب
  تثبيت الصورة ترخيصًا غير مقبول مسبقًا في runner.
- اختبارات Android في حزمة مستقلة `production/qa/android_harness` تستخدم
  كود Dart وملف Kotlin الإنتاجيين مباشرة. السبب موثق في مصدر SDK وتعليق
  [Flutter issue56591](https://github.com/flutter/flutter/issues/56591):
  تبعيات integration_test الأصلية قد تدخل release رغم تعريفها dev_dependency.
  لا يضيف تطبيق الإنتاج هذه التبعية. العزل لا يجعل harness منتجًا للتوزيع.
- [إرشادات Android الرسمية](https://developer.android.com/build/optimize-your-build#disable-jetifier)
  تدعم تعطيل Jetifier عندما تكون التبعيات AndroidX. جرى التحقق من مصادر
  الإضافة الأصلية، وعُطل التحويل بعد فشل CI بسبب Java heap، مع انتظار إعادة البناء.

## التشغيل

```sh
# من جذر المستودع، Go/Flutter/Node فيPATH
bash production/tools/check_security.sh
bash production/tools/check_live.sh
npm ci --ignore-scripts --prefix production/tools/qa
npm test --prefix production/tools/qa
node production/tools/qa/validate_assets.mjs assets/staging/rex_starter_kit/REX_Asset_Starter_Kit_2026_10_10/3d/glb /tmp/rex-gltf.json
```

`check_android_device.sh` يتطلب محاكيًا جديدًا شغالًا علىemulator-5554؛
يستخدم خادمًا معزولًا، لا fake vault أو fake server. نتائج تنفيذه الفعلية
وحالات التعذر في [تقرير QA](QA_REPORT.md)، ولا تُعد كتابة اختبار دليلاً على نجاحه.
