import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class ConfettiBurst extends StatefulWidget {
  final VoidCallback onComplete;
  final Duration duration;
  final double minBlastForce;
  final double maxBlastForce;
  final int numberOfParticles;
  final double gravity;
  final Size maximumSize;
  final Size minimumSize;
  final double containerWidth;
  final double containerHeight;
  final BlastDirectionality blastDirectionality;
  final double? blastDirection; // Only used if directionality is directional

  const ConfettiBurst({
    super.key,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 200),
    this.minBlastForce = 2,
    this.maxBlastForce = 5,
    this.numberOfParticles = 20,
    this.gravity = 0.3,
    this.maximumSize = const Size(10, 5),
    this.minimumSize = const Size(2, 2),
    this.containerWidth = 0.5,
    this.containerHeight = 0.5,
    this.blastDirectionality = BlastDirectionality.explosive,
    this.blastDirection,
  });

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> {
  late ConfettiController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: widget.duration);
    _controller.play();

    // Remove the overlay after animation duration + buffer (e.g. 500ms buffer)
    // If duration is very short (200ms), we might want a slightly longer fade out time.
    // Keeping logic consistent: widget duration + some buffer.
    // Previous logic was 500ms total for 200ms duration.
    // Let's settle on widget.duration + 300ms, or just a fixed logical timeout.
    // The user liked the "quicker" 500ms total.
    // If duration is custom (e.g. 1s), we should wait longer.
    // Safe bet: duration + 1 second.
    _timer = Timer(
      widget.duration + const Duration(seconds: 1),
      widget.onComplete,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.containerWidth,
      height: widget.containerHeight,
      child: ConfettiWidget(
        confettiController: _controller,
        blastDirectionality: widget.blastDirectionality,
        blastDirection:
            widget.blastDirection ??
            0, // Default to 0 (right) if not specified, though explosive ignores it.
        shouldLoop: false,
        colors: const [
          Colors.green,
          Colors.blue,
          Colors.pink,
          Colors.orange,
          Colors.purple,
          Colors.red,
          Colors.yellow,
        ],
        minBlastForce: widget.minBlastForce,
        maxBlastForce: widget.maxBlastForce,
        numberOfParticles: widget.numberOfParticles,
        gravity: widget.gravity,
        maximumSize: widget.maximumSize,
        minimumSize: widget.minimumSize,
      ),
    );
  }
}
