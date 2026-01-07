import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/controller_page.dart';
import 'pages/mirroring_page.dart';
import 'pages/video_selector_page.dart';
import 'providers/app_state.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LED Matrix Controller',
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMode = ref.watch(activeModeProvider);
    final fppIp = ref.watch(fppIpProvider);
    final ipController = TextEditingController(text: fppIp);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LED Matrix Controller'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Text(
              'LED Wall Control',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 60),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Select Mode',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ModeButton(
                        label: 'Controller',
                        isSelected: activeMode == ActiveMode.controller,
                        onPressed: () => ref.read(activeModeProvider.notifier).state = ActiveMode.controller,
                      ),
                      _ModeButton(
                        label: 'Video',
                        isSelected: activeMode == ActiveMode.video,
                        onPressed: () => ref.read(activeModeProvider.notifier).state = ActiveMode.video,
                      ),
                      _ModeButton(
                        label: 'Mirroring',
                        isSelected: activeMode == ActiveMode.mirroring,
                        onPressed: () => ref.read(activeModeProvider.notifier).state = ActiveMode.mirroring,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'FPP IP Address',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 250,
                    child: TextField(
                      controller: ipController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '192.168.1.100',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          ref.read(fppIpProvider.notifier).state = value;
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: () {
                if (activeMode == ActiveMode.controller) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ControllerPage(),
                    ),
                  );
                } else if (activeMode == ActiveMode.video) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const VideoSelectorPage(),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MirroringPage(),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: Text(
                activeMode == ActiveMode.controller 
                    ? 'Launch Controller' 
                    : activeMode == ActiveMode.video
                        ? 'Select Video'
                        : 'Launch Mirroring',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[700],
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
