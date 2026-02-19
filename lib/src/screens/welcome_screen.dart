import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pc = PageController();
  int _page = 0;
  bool _showButton = false;

  final List<String> _images = [
    'assets/1.png',
    'assets/2.png',
    'assets/3.png',
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pc,
                    itemCount: _images.length,
                    onPageChanged: (i) => setState(() {
                      _page = i;
                      _showButton = i == _images.length - 1;
                    }),
                    itemBuilder: (context, i) => SizedBox.expand(
                      child: Center(
                        child: Image.asset(
                          _images[i],
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 120,
                    child: Center(
                      child: AnimatedSlide(
                        duration: _showButton
                            ? const Duration(milliseconds: 420)
                            : Duration.zero,
                        curve: Curves.easeOutCubic,
                        offset:
                            _showButton ? Offset.zero : const Offset(0, 0.3),
                        child: AnimatedOpacity(
                          duration: _showButton
                              ? const Duration(milliseconds: 360)
                              : Duration.zero,
                          opacity: _showButton ? 1.0 : 0.0,
                          child: SizedBox(
                            width: 220,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.black,
                                shape: const StadiumBorder(),
                              ),
                              onPressed: _showButton
                                  ? () => Navigator.pushNamed(context, '/login')
                                  : null,
                              child: const Text('COMENZAR AHORA',
                                  style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _images.length,
                (i) => Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                  width: _page == i ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? Colors.orange : Colors.black45,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
