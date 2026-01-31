import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RiveBackground extends StatefulWidget {
  final Widget child;

  const RiveBackground({super.key, required this.child});

  @override
  State<RiveBackground> createState() => _RiveBackgroundState();
}

class _RiveBackgroundState extends State<RiveBackground> {
  StateMachineController? _controller;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: RiveAnimation.asset(
              "assets/rive/background2.riv",
              fit: BoxFit.cover,
              stateMachines: ['State Machine 1'],
              animations: ['Timeline 1'],
              onInit: _onRiveInit,
            ),
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(color: Colors.black.withValues(alpha: 0.2)),
              ),
            ),
          ),

          SafeArea(child: widget.child),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    if (_controller != null) {
      _controller!.dispose();
    }
  }

  void _onRiveInit(Artboard artboard) {
    var controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1',
    );

    if (controller != null) {
      artboard.addController(controller);
      _controller = controller;
    } else {
      if (artboard.animations.isNotEmpty) {
        artboard.addController(SimpleAnimation(artboard.animations.first.name));
      }
    }
  }
}
