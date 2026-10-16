# بحث المستودعات والـskills — 2026-10-16

## ما جرى التحقق منه

جُمعت بيانات **1,548 مستودع GitHub فريدًا** بواسطة API الرسمي، من16استعلامًا،
100نتيجة لكل استعلام مرتبة بالنجوم، مع إزالة التكرار. شملت الألعاب الجماعية،
الأوراق، خوادمGo، ألعابFlutter، QA، الأمان، الضغط، fuzzing، أمانAndroid،
أنظمة التصميم، glTF، skills العامة والتصميمية والأمنية، المراقبة وهندسة الأعطال.

الملف الكامل [repository-catalog.json](../qa/repository-catalog.json) يحتوي
الروابط والوصف واللغة والترخيص المتاح ووقت آخر push والفئات والاستعلامات
ووقت الجمع. الأداة القابلة للإعادة `tools/research_catalog.py` تقرأ metadata
فقط؛ لا تنزل مستودعات أو تشغل كودها. إعادة البحث قد تعطي نتائج مختلفة.

هذه **ليست مراجعة كود لـ1,548مشروعًا**. البحث النصي يُرجع نتائج غير ملائمة
أحيانًا؛ مثل ظهور مشاريع عامة في بحثFlutter أو skills. النجوم وحداثة push
لا تثبت الجودة أو السلامة. يوجد383مستودعًا بترخيص غير محدد/NOASSERTION؛
لا يُنسخ منها كود أو أصول بناءً على هذا الكتالوج. archived:false وfork:false
مرشحا بحث، لا شهادة نشاط مستمر أو ملكية أو أمان. راجع أيضًا
[البحث السابق للأدوات15](QA_RESEARCH.md) للفاحصات التي شُغلت فعليًا.

## المشاريع الأقرب وما نستفيد منه

| المصدر | قيمة الدراسة لـREX | قرار هذه الدفعة |
|---|---|---|
| [Nakama](https://github.com/heroiclabs/nakama) | جلسات ومباريات وخدمات ألعابGo | مرجع، لم يدمج أو يستبدل modular monolith |
| [boardgame.io](https://github.com/boardgameio/boardgame.io) | فصل الحالة والأدوار وتصفية رؤية اللاعب | مرجع تصميم؛ لا نقل قواعد Trix/Tarneeb منه |
| [Pitaya](https://github.com/topfreegames/pitaya) | خادم ألعابGo واتصالات | دراسة لاحقة، لا اعتماد بنية موزعة |
| [Agones](https://github.com/agones-dev/agones) | إدارة خوادم ألعاب | لا حاجة مبررة إلىKubernetes حاليًا |
| [Flame](https://github.com/flame-engine/flame) | أدوات ألعابFlutter ثنائية الأبعاد | لا يعوض pipeline الشخصيات والمشهد3D |
| [Forge](https://github.com/Card-Forge/forge) | محرك أوراق واختبارات قواعد معقدة | مرجع فصل modules فقط؛ ليست قواعد ألعابنا |
| [rlcard](https://github.com/datamllab/rlcard) | بيئات اختبارات ألعاب أوراق | ليس multiplayer أو قرار إضافة bots |
| [k6](https://github.com/grafana/k6) | أحمال طويلة وموزعة لاحقًا | لم يشغل؛ الشاهد الحالي أداةGo محلية فعلية |
| [Toxiproxy](https://github.com/Shopify/toxiproxy) | حقن أعطال شبكة | مرشح لدورة أعطال موسعة، لم يشغل |

هذه توصيات بحثية؛ لا مراجعة تقنية أو موافقة مؤسسين أو إثبات تراخيص كل ملف.
لم تُضف أي تبعية تشغيلية إلى الخادم في هذه الدفعة.

## skills التصميم والأمان التي فُحص مصدرها

فُهرست ملفاتSKILL.md من الأشجار المثبتة بخمسة مستودعات:20منAnthropic،
85منTrail of Bits، و16منStitch، و9منVercel، و15منSuperpowers.
فُحص نص ستة ملفات مختارة؛ المسارات وtree SHA وروابط النسخة وبصماتSHA256
في [skills-research.json](../qa/skills-research.json). لم تُثبت هذه المهارات
أو تُنفذ scripts لها، ولم تتحول تعليماتها إلى صلاحيات على المشروع.

| المصدر | الاختيار والملاءمة |
|---|---|
| [Anthropic skills](https://github.com/anthropics/skills) | frontend-design لتماسك الهوية؛ webapp-testing خاص بالويب/Playwright ولا يثبتAndroid. الترخيص على مستوى الملف يحتاج قراءةLICENSE.txt قبل النسخ |
| [Trail of Bits skills](https://github.com/trailofbits/skills) | property-based-testing وsupply-chain-risk-auditor مناسبان لدراسة invariants ومخاطر التبعيات؛ الترخيص المعلنCC-BY-SA-4.0، ولا تزعم هذه الدفعة تشغيل أدواتهما |
| [Stitch skills](https://github.com/google-labs-code/stitch-skills) | إدارة design system، Apache-2.0؛ يحتاج خدمةStitch، ولم يرفع إليها المشروع |
| [Vercel agent skills](https://github.com/vercel-labs/agent-skills) | web-design-guidelines للويب؛ لا بديل عن اختباراتRTL واللمس وAndroid. الترخيص الأعلى غير محسوم فيAPI |
| [Superpowers](https://github.com/obra/superpowers) | مرجع أساليب اختبار وتصحيح، MIT؛ فهرسة فقط دون تنفيذ |

مهاراتFigma وأنظمة التصميم متاحة في الجلسة عند توفر تصميم مستهدف؛ لا
تستلزم إضافتها تغيير الشعار أو تحويل التطبيق إلى صفحة ويب. الإنتاج الفني
للشخصيات والبيئات لا ينتج تلقائيًا من skills تصميم الواجهات.

## القرار التنفيذي

بقيت أولوية التنفيذ تقوية الكود الحالي بأدوات مثبتة، بدل إدخال مئات
التبعيات. أصلحت حدود admission وكلفة محدد الطلبات ونسخ حالة المعاملة،
وأضيف اختبار ضغطTLS واختبارات تسلسلات حالات مولدة. الأدلة وحدودها في
[تقرير التحمل](RESILIENCE_REPORT.md). لا تغيّر هذه الدفعة عقود اللعب أو
الاقتصاد أو صلاحيات اعتماد القرارات.
