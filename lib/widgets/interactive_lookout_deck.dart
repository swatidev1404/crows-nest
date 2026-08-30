import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crows_nest/services/sound_service.dart';
import 'package:crows_nest/providers/theme_provider.dart';

class InteractiveLookoutDeck extends StatefulWidget {
  final VoidCallback onToggleCollapse;

  const InteractiveLookoutDeck({
    Key? key,
    required this.onToggleCollapse,
  }) : super(key: key);

  @override
  State<InteractiveLookoutDeck> createState() => _InteractiveLookoutDeckState();
}

class _InteractiveLookoutDeckState extends State<InteractiveLookoutDeck>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _crowBounceController;
  late AnimationController _bellWiggleController;

  String _crowQuote = "Caw! Ahoy, Captain!";
  bool _showQuote = false;
  int _quoteIndex = 0;

  final List<String> _quotes = [
    "Caw! Ready to set sail today?",
    "Ahoy! Keep a steady watch on your blocks!",
    "Caw caw! Smooth seas make no skilled sailors!",
    "Doubloons ahead! Time for deep work!",
    "Caw! Drop a quick note in the captain's log!",
    "Land ho! Another task completed!",
  ];

  @override
  void initState() {
    super.initState();
    // Continuous flowing sea waves animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Crow bounce/flap animation
    _crowBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Ship bell wiggle animation
    _bellWiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _crowBounceController.dispose();
    _bellWiggleController.dispose();
    super.dispose();
  }

  void _handleCrowTap(SoundService soundService) {
    soundService.playCrowCaw();
    _crowBounceController.forward(from: 0.0);
    setState(() {
      _crowQuote = _quotes[_quoteIndex % _quotes.length];
      _quoteIndex++;
      _showQuote = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showQuote = false);
      }
    });
  }

  void _handleBellTap(SoundService soundService) {
    soundService.playShipBell();
    _bellWiggleController.forward(from: 0.0);
  }

  void _handleSeaTap(SoundService soundService) {
    soundService.playOceanWaves();
  }

  @override
  Widget build(BuildContext context) {
    final soundService = Provider.of<SoundService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 195,
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Placeholder / Nautical Sky
            Image.asset(
              'assets/images/crows_nest_placeholder.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0F1E36), const Color(0xFF060B14)]
                        : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // 2. Atmospheric Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.transparent,
                    Colors.black.withOpacity(0.55),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // 3. Animated Flowing Ocean Waves at Bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 65,
              child: GestureDetector(
                onTap: () => _handleSeaTap(soundService),
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _WavePainter(
                        waveProgress: _waveController.value,
                        isDark: isDark,
                        primaryColor: colorScheme.primary,
                      ),
                    );
                  },
                ),
              ),
            ),

            // 4. Interactive Crow on Wooden Mast (Left Side)
            Positioned(
              left: 18,
              bottom: 32,
              child: GestureDetector(
                onTap: () => _handleCrowTap(soundService),
                child: AnimatedBuilder(
                  animation: _crowBounceController,
                  builder: (context, child) {
                    final bounce = math.sin(_crowBounceController.value * math.pi) * 8;
                    final scale = 1.0 + math.sin(_crowBounceController.value * math.pi) * 0.15;
                    return Transform.translate(
                      offset: Offset(0, -bounce),
                      child: Transform.scale(
                        scale: scale,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Perched Crow Avatar / Icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.65),
                          border: Border.all(color: const Color(0xFFFFD700), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.flutter_dash_rounded,
                          color: Color(0xFFFFD700),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "Tap Crow! 🦜",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 5. Animated Crow Speech Bubble
            if (_showQuote)
              Positioned(
                left: 75,
                bottom: 85,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    _crowQuote,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),

            // 6. Interactive Ship's Brass Bell (Center-Right)
            Positioned(
              right: 52,
              top: 14,
              child: GestureDetector(
                onTap: () => _handleBellTap(soundService),
                child: AnimatedBuilder(
                  animation: _bellWiggleController,
                  builder: (context, child) {
                    final angle = math.sin(_bellWiggleController.value * math.pi * 4) * 0.25;
                    return Transform.rotate(
                      angle: angle,
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFC107), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Color(0xFFFFC107),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),

            // 7. Audio Mute / Sound Toggle Button
            Positioned(
              right: 14,
              top: 14,
              child: GestureDetector(
                onTap: () => soundService.toggleSound(),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: soundService.soundEnabled ? Colors.greenAccent : Colors.grey,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    soundService.soundEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: soundService.soundEnabled ? Colors.greenAccent : Colors.grey,
                    size: 18,
                  ),
                ),
              ),
            ),

            // 8. Collapse / Expand Button
            Positioned(
              left: 14,
              top: 14,
              child: GestureDetector(
                onTap: widget.onToggleCollapse,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.expand_less_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),

            // 9. Lookout Deck Header Title & Theme Subtitle (Center)
            Positioned(
              bottom: 12,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Captain's Lookout Deck",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                  Text(
                    themeProvider.currentThemeName,
                    style: TextStyle(
                      color: const Color(0xFFFFD700).withOpacity(0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double waveProgress;
  final bool isDark;
  final Color primaryColor;

  _WavePainter({
    required this.waveProgress,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Layer 1: Back Wave
    final backPaint = Paint()
      ..color = primaryColor.withOpacity(isDark ? 0.35 : 0.45)
      ..style = PaintingStyle.fill;

    final backPath = Path();
    backPath.moveTo(0, h);
    for (double x = 0; x <= w; x += 4) {
      final y = h * 0.45 +
          math.sin((x / w * 2 * math.pi) + (waveProgress * 2 * math.pi)) * 8;
      backPath.lineTo(x, y);
    }
    backPath.lineTo(w, h);
    backPath.close();
    canvas.drawPath(backPath, backPaint);

    // Layer 2: Front Wave
    final frontPaint = Paint()
      ..color = (isDark ? const Color(0xFF00ADB5) : const Color(0xFF38B6FF))
          .withOpacity(0.55)
      ..style = PaintingStyle.fill;

    final frontPath = Path();
    frontPath.moveTo(0, h);
    for (double x = 0; x <= w; x += 4) {
      final y = h * 0.6 +
          math.cos((x / w * 2 * math.pi) - (waveProgress * 2 * math.pi)) * 7;
      frontPath.lineTo(x, y);
    }
    frontPath.lineTo(w, h);
    frontPath.close();
    canvas.drawPath(frontPath, frontPaint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.waveProgress != waveProgress;
}
