import 'package:flutter/material.dart';
import 'dart:math' as math;

// Un modelo simple para definir cada acción en el menú flotante
class ActionButton {
  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;

  ActionButton({required this.onPressed, required this.icon, required this.tooltip});
}

class ExpandingFab extends StatefulWidget {
  final List<ActionButton> actions;
  final double distance;
  final IconData openIcon;
  final IconData closeIcon;

  const ExpandingFab({
    super.key,
    required this.actions,
    this.distance = -90.0,
    this.openIcon = Icons.chat_bubble_rounded,
    this.closeIcon = Icons.close,
  });

  @override
  State<ExpandingFab> createState() => _ExpandingFabState();
}

class _ExpandingFabState extends State<ExpandingFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          // --- MEJORA 2: Fondo para cerrar al tocar fuera ---
          _buildTapToDismissOverlay(),
          // Botones de acción secundarios
          ..._buildExpandingActionButtons(),
          // Botón principal
          _buildTapToCloseFab(),
          _buildTapToOpenFab(),
        ],
      ),
    );
  }

  // --- NUEVO WIDGET: Capa semi-transparente que cierra el menú al tocarla ---
  Widget _buildTapToDismissOverlay() {
    return IgnorePointer(
      ignoring: !_isOpen,
      child: AnimatedOpacity(
        opacity: _isOpen ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: GestureDetector(
          onTap: _toggle,
          child: Container(
            color: Colors.black.withOpacity(0.1), // Color sutil para el fondo
          ),
        ),
      ),
    );
  }
  
  // Botón para cerrar el menú (visible cuando está abierto)
  Widget _buildTapToCloseFab() {
    return SizedBox(
      width: 56.0,
      height: 56.0,
      child: Center(
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4.0,
          child: InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnimatedOpacity(
                opacity: _isOpen ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  widget.closeIcon,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Botones que aparecen al expandir
  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.actions.length;
    // Ajuste para que el ángulo sea más abierto, como en Telegram
    const step = 60.0; 
    const initialAngle = -90.0;

    for (var i = 0; i < count; i++) {
      final angleInDegrees = initialAngle + i * step;
      children.add(
        _ExpandingActionButton(
          directionInDegrees: angleInDegrees,
          maxDistance: widget.distance,
          progress: _expandAnimation,
          // --- MEJORA 1: Se pasa una función que ejecuta la acción y luego cierra ---
          onPressed: () {
            widget.actions[i].onPressed();
            _toggle();
          },
          child: widget.actions[i],
        ),
      );
    }
    return children;
  }

  // Botón principal para abrir el menú (visible cuando está cerrado)
  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _isOpen,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _isOpen ? 0.7 : 1.0,
          _isOpen ? 0.7 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 250),
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _isOpen ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 250),
          child: FloatingActionButton(
            onPressed: _toggle,
            child: Icon(widget.openIcon),
          ),
        ),
      ),
    );
  }
}

class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
    required this.onPressed,
  });

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final ActionButton child;
  // --- MEJORA 1: Se recibe un solo callback ---
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final offset = Offset.fromDirection(
          directionInDegrees * (math.pi / -180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: 4.0 + offset.dx,
          bottom: 4.0 + offset.dy,
          child: Transform.scale(
            scale: progress.value,
            child: FadeTransition(
              opacity: progress,
              child: Tooltip(
                message: child.tooltip,
                child: FloatingActionButton(
                  heroTag: null,
                  // --- MEJORA 1: Se usa el nuevo callback ---
                  onPressed: onPressed,
                  child: Icon(child.icon),
                  mini: true,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}