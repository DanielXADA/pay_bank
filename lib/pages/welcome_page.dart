import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  late final AnimationController _controller1;
  late final AnimationController _controller2;
  late final AnimationController _cardController;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> bankPalette = [
      const Color(0xFF10251B),
      const Color(0xFF244A3A),
      const Color(0xFF3FA168),
      const Color(0xFFD4F85A),
      const Color(0xFF3FA168),
      const Color(0xFF244A3A),
      const Color(0xFF10251B),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF244A3A), Color(0xFF10251B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: RotationTransition(
                turns: _controller1,
                child: Transform.scale(
                  scale: 2.5,
                  child: Opacity(
                    opacity: 0.8,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(colors: bankPalette),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller2,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -_controller2.value * 2 * math.pi,
                    child: child,
                  );
                },
                child: Transform.scale(
                  scale: 2.0,
                  child: Opacity(
                    opacity: 0.6,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: bankPalette.reversed.toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Bem-vindo ao\nPayBank",
                      style: TextStyle(
                        fontSize: 40,
                        height: 1.1,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Experimente recursos de ponta, segurança\nde primeira linha e acesso instantâneo ao\nseu banco feito para você",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _cardController,
                          builder: (context, child) {
                            final dy1 = _cardController.value * -12.0;
                            final dy2 = (1.0 - _cardController.value) * -12.0;

                            return Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Transform(
                                  alignment: FractionalOffset.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.0015)
                                    ..translate(-20.0, 50.0 + dy1, 0.0)
                                    ..rotateX(-0.7)
                                    ..rotateZ(-0.4),
                                  child: _buildCard(const Color(0xFF3FA168), false),
                                ),
                                Transform(
                                  alignment: FractionalOffset.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.0015)
                                    ..translate(20.0, -10.0 + dy2, 0.0)
                                    ..rotateX(-0.7)
                                    ..rotateZ(-0.4),
                                  child: _buildCard(const Color(0xFFD4F85A), true),
                                ),
                                const Positioned(
                                  top: 10,
                                  right: 200,
                                  child: BalanceBadge(),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4F85A),
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/cadastro');
                      },
                      child: const Text(
                        "Criar Conta",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: const Text(
                        "Entrar",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Color color, bool isDarkText) {
    final textColor = isDarkText ? Colors.black87 : Colors.white;
    final logoColor = isDarkText ? Colors.black54 : Colors.black26;

    return Container(
      width: 260,
      height: 160,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(10, 15),
          )
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(
            bottom: -50,
            left: -10,
            child: Text(
              "pagbank",
              style: TextStyle(
                fontSize: 85,
                fontWeight: FontWeight.w900,
                letterSpacing: -2.0,
                color: isDarkText
                    ? Colors.black.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.memory, color: textColor.withValues(alpha: 0.6), size: 32),
                    Text(
                      "pagbank",
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(radius: 14, backgroundColor: logoColor),
                      Transform.translate(
                        offset: const Offset(-12, 0),
                        child: CircleAvatar(radius: 14, backgroundColor: logoColor.withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BalanceBadge extends StatelessWidget {
  const BalanceBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 120,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "R\$ 2.537,98",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  "Saldo",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}