import 'package:flutter/material.dart';

class DirectionalPad extends StatefulWidget {
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const DirectionalPad({
    super.key,
    required this.onUp,
    required this.onDown,
    required this.onLeft,
    required this.onRight,
  });

  @override
  State<DirectionalPad> createState() => _DirectionalPadState();
}

class _DirectionalPadState extends State<DirectionalPad> {
  late Map<String, bool> _pressedState;

  @override
  void initState() {
    super.initState();
    _pressedState = {
      'up': false,
      'down': false,
      'left': false,
      'right': false,
    };
  }

  void _onDirectionDown(String direction) {
    setState(() {
      _pressedState[direction] = true;
    });

    switch (direction) {
      case 'up':
        widget.onUp();
        break;
      case 'down':
        widget.onDown();
        break;
      case 'left':
        widget.onLeft();
        break;
      case 'right':
        widget.onRight();
        break;
    }
  }

  void _onDirectionUp(String direction) {
    setState(() {
      _pressedState[direction] = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        children: [
          // Center indicator
          Positioned(
            left: 75,
            top: 75,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Up button
          Positioned(
            left: 75,
            top: 0,
            child: _DirectionButton(
              direction: 'UP',
              icon: Icons.arrow_upward,
              isPressed: _pressedState['up'] ?? false,
              onDown: () => _onDirectionDown('up'),
              onUp: () => _onDirectionUp('up'),
            ),
          ),
          // Down button
          Positioned(
            left: 75,
            bottom: 0,
            child: _DirectionButton(
              direction: 'DOWN',
              icon: Icons.arrow_downward,
              isPressed: _pressedState['down'] ?? false,
              onDown: () => _onDirectionDown('down'),
              onUp: () => _onDirectionUp('down'),
            ),
          ),
          // Left button
          Positioned(
            left: 0,
            top: 75,
            child: _DirectionButton(
              direction: 'LEFT',
              icon: Icons.arrow_back,
              isPressed: _pressedState['left'] ?? false,
              onDown: () => _onDirectionDown('left'),
              onUp: () => _onDirectionUp('left'),
            ),
          ),
          // Right button
          Positioned(
            right: 0,
            top: 75,
            child: _DirectionButton(
              direction: 'RIGHT',
              icon: Icons.arrow_forward,
              isPressed: _pressedState['right'] ?? false,
              onDown: () => _onDirectionDown('right'),
              onUp: () => _onDirectionUp('right'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionButton extends StatelessWidget {
  final String direction;
  final IconData icon;
  final bool isPressed;
  final VoidCallback onDown;
  final VoidCallback onUp;

  const _DirectionButton({
    required this.direction,
    required this.icon,
    required this.isPressed,
    required this.onDown,
    required this.onUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPressed ? Colors.blue : Colors.grey[800],
          border: Border.all(
            color: Colors.white,
            width: isPressed ? 3 : 2,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
