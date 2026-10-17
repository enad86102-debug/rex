import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'api.dart';
import 'controller.dart';
import 'strings.dart';
import 'vault.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const endpoint = String.fromEnvironment('REX_API_URL');
  try {
    final api = RexApi(
      endpoint.isEmpty && kDebugMode ? 'http://10.0.2.2:8080' : endpoint,
      allowLoopbackHttp: kDebugMode,
    );
    runApp(RexApp(controller: RexController(api, AndroidVault())));
  } catch (_) {
    runApp(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(child: Text('الخدمة غير متاحة حاليًا.')),
          ),
        ),
      ),
    );
  }
}

class RexApp extends StatefulWidget {
  const RexApp({super.key, required this.controller});
  final RexController controller;

  @override
  State<RexApp> createState() => _RexAppState();
}

class _RexAppState extends State<RexApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(widget.controller.initialize());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    widget.controller.setActive(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: RexStrings.title,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xff080e1a),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xffd1ad62),
        brightness: Brightness.dark,
        primary: const Color(0xffe2c47d),
        surface: const Color(0xff111d30),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(18),
      ),
    ),
    home: RexHome(controller: widget.controller),
  );
}

class RexHome extends StatefulWidget {
  const RexHome({super.key, required this.controller});
  final RexController controller;

  @override
  State<RexHome> createState() => _RexHomeState();
}

class _RexHomeState extends State<RexHome> {
  final invite = TextEditingController();
  String game = 'trix_complex';
  RexController get c => widget.controller;

  @override
  void dispose() {
    invite.dispose();
    super.dispose();
  }

  Future<void> logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(RexStrings.logout),
        content: const Text(RexStrings.logoutNotice),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(RexStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(RexStrings.logout),
          ),
        ],
      ),
    );
    if (confirmed == true) await c.logout();
  }

  Future<void> resetCorruptSession() async {
    final preserve = c.canPreserveSession;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          preserve
              ? RexStrings.discardCorruptAction
              : RexStrings.resetCorruptSession,
        ),
        content: Text(
          preserve
              ? RexStrings.discardCorruptActionNotice
              : RexStrings.resetCorruptSessionNotice,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(RexStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              preserve
                  ? RexStrings.discardCorruptAction
                  : RexStrings.resetCorruptSession,
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await c.resetCorruptSession();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text(RexStrings.home),
        backgroundColor: Colors.transparent,
        actions: [
          if (c.signedIn)
            IconButton(
              tooltip: RexStrings.logout,
              onPressed: c.busy || c.hasPendingAction ? null : logout,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/rex_logo.png',
                    height: 140,
                    semanticLabel: 'شعار REX الأصلي',
                  ),
                  const SizedBox(height: 24),
                  if (c.busy)
                    const LinearProgressIndicator(
                      semanticsLabel: 'جارٍ الاتصال',
                    ),
                  if (c.error != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        RexStrings.failure(c.error!),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    if (c.recoveryRequired)
                      TextButton.icon(
                        onPressed: c.busy ? null : resetCorruptSession,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(
                          c.canPreserveSession
                              ? RexStrings.discardCorruptAction
                              : RexStrings.resetCorruptSession,
                        ),
                      )
                    else
                      TextButton.icon(
                        onPressed: c.busy
                            ? null
                            : () => c.initialized ? c.retry() : c.initialize(),
                        icon: const Icon(Icons.refresh),
                        label: const Text(RexStrings.retry),
                      ),
                  ],
                  if (c.initialized && !c.signedIn) ...[
                    Text(
                      RexStrings.entry,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    const Text(RexStrings.guestNotice),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: c.busy ? null : c.enterGuest,
                      child: const Text(RexStrings.guest),
                    ),
                  ],
                  if (c.signedIn && c.me != null && c.table == null)
                    ...lobby(context),
                  if (c.table != null) ...room(context),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  List<Widget> lobby(BuildContext context) => [
    Text(
      RexStrings.privateTable,
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    const SizedBox(height: 12),
    const Text(RexStrings.unavailable),
    const SizedBox(height: 24),
    DropdownButtonFormField<String>(
      initialValue: game,
      decoration: const InputDecoration(labelText: 'اللعبة'),
      items: ['trix_complex', 'tarneeb']
          .map(
            (value) => DropdownMenuItem(
              value: value,
              child: Text(RexStrings.game(value)),
            ),
          )
          .toList(),
      onChanged: c.busy || c.hasPendingAction
          ? null
          : (value) => setState(() => game = value!),
    ),
    const SizedBox(height: 16),
    FilledButton(
      onPressed: c.busy || c.hasPendingAction ? null : () => c.create(game),
      child: const Text(RexStrings.create),
    ),
    const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Divider(),
    ),
    TextField(
      controller: invite,
      maxLength: 32,
      textDirection: TextDirection.ltr,
      autocorrect: false,
      enableSuggestions: false,
      decoration: const InputDecoration(labelText: RexStrings.invite),
      onChanged: (_) => setState(() {}),
    ),
    FilledButton.tonal(
      onPressed:
          c.busy ||
              c.hasPendingAction ||
              !RegExp(r'^[0-9a-f]{32}$').hasMatch(invite.text.trim())
          ? null
          : () => c.join(invite.text),
      child: const Text(RexStrings.join),
    ),
  ];

  List<Widget> room(BuildContext context) {
    final table = c.table!;
    final seats = table['seats'] as List;
    final playerId = (c.me!['player'] as Map)['id'];
    final local = seats
        .whereType<Map>()
        .where((seat) => seat['player_id'] == playerId)
        .firstOrNull;
    return [
      Text(
        RexStrings.game(table['game'] as String),
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 12),
      const Text(RexStrings.unavailable),
      const SizedBox(height: 20),
      for (var i = 0; i < seats.length; i++) ...[
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xff111d30),
            border: Border.all(color: const Color(0xff8a703c)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            minVerticalPadding: 16,
            leading: Icon(
              seats[i] == null ? Icons.chair_outlined : Icons.person_outline,
            ),
            title: Text(RexStrings.seats[i]),
            subtitle: seats[i] == null
                ? const Text(RexStrings.waiting)
                : Text(
                    'لاعب ${(seats[i] as Map)['player_id'].toString().substring(0, 8)}',
                    textDirection: TextDirection.rtl,
                  ),
            trailing: seats[i] != null && (seats[i] as Map)['ready'] == true
                ? const Icon(Icons.check_circle, semanticLabel: 'جاهز')
                : null,
          ),
        ),
        const SizedBox(height: 12),
      ],
      FilledButton.tonalIcon(
        onPressed: () async {
          await Clipboard.setData(
            ClipboardData(text: table['invite'] as String),
          );
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text(RexStrings.copied)));
          }
        },
        icon: const Icon(Icons.copy),
        label: const Text(RexStrings.copy),
      ),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: c.busy || c.hasPendingAction || local == null
            ? null
            : () => c.ready(local['ready'] != true),
        child: Text(
          local?['ready'] == true ? RexStrings.notReady : RexStrings.ready,
        ),
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: c.busy || c.hasPendingAction ? null : c.leave,
        child: const Text(RexStrings.leave),
      ),
    ];
  }
}
