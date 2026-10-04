import 'package:flutter/material.dart';

void main() => runApp(const RexApp());
const _gold = Color(0xFFE4AF45),
    _ink = Color(0xFF080B10),
    _assets = 'assets/approved_ui/';

class RexApp extends StatelessWidget {
  const RexApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'REX',
    theme: ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: _ink,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _gold,
        brightness: Brightness.dark,
      ),
    ),
    home: const RexSplash(),
  );
}

class RexSplash extends StatefulWidget {
  const RexSplash({super.key});
  @override
  State<RexSplash> createState() => _RexSplashState();
}

class _RexSplashState extends State<RexSplash>
    with SingleTickerProviderStateMixin {
  late final c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RexHome()),
        );
    });
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('${_assets}05_splash_loading.png', fit: BoxFit.cover),
        Center(
          child: Semantics(
            label: 'REX',
            child: Text(
              'REX',
              style: TextStyle(color: Colors.transparent, fontSize: 1),
            ),
          ),
        ),
        Container(color: Colors.black.withAlpha(60)),
        Align(
          alignment: const Alignment(0, .78),
          child: FadeTransition(
            opacity: c,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'جار التحميل...',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: _gold,
                  ),
                ),
                const SizedBox(height: 14),
                const SizedBox(
                  width: 230,
                  child: LinearProgressIndicator(
                    color: _gold,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class RexHome extends StatelessWidget {
  const RexHome({super.key});
  @override
  Widget build(BuildContext context) => _Screen(
    image: '09_royal_lobby_variant_a.png',
    child: Column(
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 27,
              backgroundColor: _gold,
              child: Icon(Icons.person, color: _ink),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أبو محمد',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'المستوى 28',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(color: _gold),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none, color: _gold),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.settings_outlined, color: _gold),
            ),
          ],
        ),
        const Spacer(),
        const Align(
          alignment: Alignment.topCenter,
          child: Text(
            'ليان',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        _goldButton(
          'ابدأ اللعب',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RexGameSelection()),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _quick(context, 'الأصدقاء', Icons.people, const RexSession()),
            _quick(context, 'الجوائز اليومية', Icons.card_giftcard, null),
            _quick(context, 'المجتمع', Icons.groups, null),
          ],
        ),
        const SizedBox(height: 12),
        _section(context, 'عالم REX', Icons.public, const RexWorld()),
        _section(
          context,
          'رحلة الإنجازات',
          Icons.emoji_events,
          const RexAchievements(),
        ),
      ],
    ),
  );
}

class RexGameSelection extends StatelessWidget {
  const RexGameSelection({super.key});
  @override
  Widget build(BuildContext context) => _Screen(
    image: '03_rex_world_destinations.png',
    child: Column(
      children: [
        _title('ألعاب REX'),
        const SizedBox(height: 24),
        _section(context, 'تريكس كومبلكس', Icons.style, const RexWorld()),
        _section(context, 'طرنيب', Icons.auto_awesome, const RexWorld()),
      ],
    ),
  );
}

class RexWorld extends StatelessWidget {
  const RexWorld({super.key});
  @override
  Widget build(BuildContext context) => _Screen(
    image: '03_rex_world_destinations.png',
    child: Column(
      children: [
        _title('عالم REX'),
        const SizedBox(height: 16),
        for (final e in const [
          ('القاعة الملكية', Icons.castle),
          ('وادي رم', Icons.landscape),
          ('البتراء', Icons.account_balance),
          ('العقبة', Icons.sailing),
        ])
          _section(context, e.$1, e.$2, const RexEnvironments()),
      ],
    ),
  );
}

class RexEnvironments extends StatelessWidget {
  const RexEnvironments({super.key});
  @override
  Widget build(BuildContext context) => _Screen(
    image: '01_environment_picker.png',
    child: Column(
      children: [
        _title('اختر الأجواء'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in const [
              ('وادي رم', '02_table_green_players.png'),
              ('البتراء', '04_table_royal_players.png'),
              ('العقبة', '08_friends_session.png'),
              ('القاعة الملكية', '09_royal_lobby_variant_a.png'),
            ])
              SizedBox(
                width: (MediaQuery.sizeOf(context).width - 48) / 2,
                child: _section(
                  context,
                  entry.$1,
                  Icons.table_restaurant,
                  RexSession(environment: entry.$2),
                ),
              ),
          ],
        ),
        const Spacer(),
        _goldButton(
          'معاينة الأجواء',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RexSession()),
          ),
        ),
      ],
    ),
  );
}

class RexSession extends StatelessWidget {
  const RexSession({
    super.key,
    this.environment = '02_table_green_players.png',
  });
  final String environment;
  @override
  Widget build(BuildContext context) => _Screen(
    image: '08_friends_session.png',
    child: Column(
      children: [
        _title('ابدأ الجلسة'),
        const Spacer(),
        const Text(
          'أربعة لاعبين حول الطاولة',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        _goldButton(
          'ابدأ الجلسة',
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RexTablePage(environment: environment),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _section(context, 'دعوة صديق', Icons.link, null),
      ],
    ),
  );
}

class RexTablePage extends StatefulWidget {
  const RexTablePage({
    super.key,
    this.environment = '02_table_green_players.png',
  });
  final String environment;
  @override
  State<RexTablePage> createState() => _RexTableState();
}

class _RexTableState extends State<RexTablePage>
    with SingleTickerProviderStateMixin {
  int selected = -1;
  late final a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  @override
  void dispose() {
    a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('$_assets${widget.environment}', fit: BoxFit.cover),
        Container(color: Colors.black.withAlpha(75)),
        SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Spacer(),
                  const Text(
                    'طاولة REX',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      builder: (_) => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'رسائل سريعة • بالتوفيق',
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                height: 84,
                child: Stack(
                  children: [
                    for (int i = 0; i < 13; i++)
                      Positioned(
                        left: i * (MediaQuery.sizeOf(context).width - 64) / 12,
                        top: (i - 6).abs() * 1.2,
                        child: GestureDetector(
                          onTap: () => setState(() => selected = i),
                          child: _Card(
                            rank: [
                              'A',
                              '2',
                              '3',
                              '4',
                              '5',
                              '6',
                              '7',
                              '8',
                              '9',
                              '10',
                              'J',
                              'Q',
                              'K',
                            ][i],
                            selected: selected == i,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'أميرة',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'سامي',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'أنت',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _goldButton(
                      '😀',
                      () => ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('جاهزين؟'))),
                    ),
                  ),
                  Expanded(
                    child: _goldButton('رمي البطاقة', () => a.forward(from: 0)),
                  ),
                  Expanded(
                    child: _goldButton(
                      'فوز تجريبي',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RexVictory()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: a,
          builder: (_, __) => a.value == 0
              ? const SizedBox.shrink()
              : Positioned(
                  top: MediaQuery.sizeOf(context).height * (.45 - a.value * .2),
                  left: MediaQuery.sizeOf(context).width / 2 - 22,
                  child: const _Card(rank: 'A'),
                ),
        ),
      ],
    ),
  );
}

class RexAchievements extends StatelessWidget {
  const RexAchievements({super.key});
  @override
  Widget build(BuildContext context) => _Screen(
    image: '07_achievements.png',
    child: Column(
      children: [
        _title('رحلة الإنجازات'),
        const Spacer(),
        _goldButton('عرض الإنجازات', () {}),
      ],
    ),
  );
}

class RexVictory extends StatelessWidget {
  const RexVictory({super.key});
  @override
  Widget build(BuildContext context) => _Screen(
    image: '06_win_celebration.png',
    child: Column(
      children: [
        const Spacer(),
        _title('فوز رائع!'),
        const Text(
          'مبروك الفوز',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontSize: 22),
        ),
        const SizedBox(height: 16),
        _goldButton(
          'العب مجددًا',
          () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RexTablePage()),
          ),
        ),
        _section(context, 'العودة', Icons.arrow_back, null),
      ],
    ),
  );
}

class _Screen extends StatelessWidget {
  const _Screen({required this.image, required this.child});
  final String image;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('$_assets$image', fit: BoxFit.cover),
        Container(color: Colors.black.withAlpha(100)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: child,
          ),
        ),
      ],
    ),
  );
}

Widget _title(String s) => Text(
  s,
  textDirection: TextDirection.rtl,
  style: const TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    color: _gold,
  ),
);
Widget _goldButton(String s, VoidCallback tap) => SizedBox(
  width: double.infinity,
  height: 56,
  child: FilledButton(
    onPressed: tap,
    style: FilledButton.styleFrom(
      backgroundColor: _gold,
      foregroundColor: _ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    child: Text(
      s,
      textDirection: TextDirection.rtl,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  ),
);
Widget _section(BuildContext c, String s, IconData i, Widget? d) => Card(
  color: _ink.withAlpha(215),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
    side: const BorderSide(color: _gold),
  ),
  child: ListTile(
    onTap: d == null
        ? null
        : () => Navigator.push(c, MaterialPageRoute(builder: (_) => d)),
    leading: Icon(i, color: _gold),
    title: Text(
      s,
      textDirection: TextDirection.rtl,
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    trailing: const Icon(Icons.chevron_left, color: _gold),
  ),
);
Widget _quick(BuildContext c, String s, IconData i, Widget? d) => InkWell(
  onTap: d == null
      ? null
      : () => Navigator.push(c, MaterialPageRoute(builder: (_) => d)),
  child: Column(
    children: [
      CircleAvatar(
        backgroundColor: _gold,
        foregroundColor: _ink,
        child: Icon(i),
      ),
      const SizedBox(height: 4),
      Text(
        s,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontSize: 11),
      ),
    ],
  ),
);

class _Card extends StatelessWidget {
  const _Card({required this.rank, this.selected = false});
  final String rank;
  final bool selected;
  @override
  Widget build(BuildContext c) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    transform: Matrix4.translationValues(0, selected ? -10 : 0, 0),
    width: 44,
    height: 70,
    decoration: BoxDecoration(
      color: const Color(0xFFF5EFE2),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(
        color: selected ? _gold : Colors.white54,
        width: selected ? 3 : 1,
      ),
      boxShadow: const [
        BoxShadow(color: Colors.black54, blurRadius: 5, offset: Offset(1, 3)),
      ],
    ),
    child: Center(
      child: Text(
        rank,
        style: const TextStyle(
          color: Color(0xFF263536),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
