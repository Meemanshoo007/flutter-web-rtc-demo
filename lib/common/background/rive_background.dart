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
          // 1. The Rive Animation Layer
          Positioned.fill(
            child: RiveAnimation.asset(
              "assets/rive/background2.riv",
              // BoxFit.cover is CRITICAL for backgrounds
              // It ensures no black bars appear, cutting off edges if needed
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
                child: Container(
                  // A slight dark tint helps text readability and makes the blur look better
                  color: Colors.black.withOpacity(0.2),
                ),
              ),
            ),
          ),

          // 3. Your Actual Content
          // We wrap it in a SafeArea so it doesn't get hidden behind notches
          SafeArea(child: widget.child),
        ],
      ),
    );
  }

  void _onRiveInit(Artboard artboard) {
    print("DEBUG: Rive Artboard Loaded!");

    // 1. Try to find the State Machine
    var controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1', // CHECK THIS NAME IN EDITOR!
    );

    if (controller != null) {
      artboard.addController(controller);
      _controller = controller;
      print("DEBUG: State Machine Found & Running!");
    } else {
      print("DEBUG: ERROR - State Machine 'State Machine 1' NOT FOUND.");
      print(
        "DEBUG: Available Animations: ${artboard.animations.map((a) => a.name).toList()}",
      );

      // Fallback: Try to play the first animation if state machine fails
      if (artboard.animations.isNotEmpty) {
        print(
          "DEBUG: Trying fallback animation '${artboard.animations.first.name}'",
        );
        artboard.addController(SimpleAnimation(artboard.animations.first.name));
      }
    }
  }
}
