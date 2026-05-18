import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../models/shell_model.dart';

// Image mapping per shell number
String _imageForShell(int number) {
  switch (number) {
    case 1:  return 'assets/images/schelp-bruin.png';
    case 2:  return 'assets/images/schelp-blauw.png';
    case 3:
    case 4:  return 'assets/images/schelp-groen.png';
    case 5:
    case 6:  return 'assets/images/schelp-zand.png';
    case 7:
    case 8:  return 'assets/images/schelp-oranje.png';
    default: return 'assets/images/schelp-bruin.png';
  }
}

class ShellCard extends StatefulWidget {
  final ShellModel shell;
  const ShellCard({super.key, required this.shell});

  @override
  State<ShellCard> createState() => _ShellCardState();
}

class _ShellCardState extends State<ShellCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _anim, curve: Curves.elasticOut));
    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _anim, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant ShellCard old) {
    super.didUpdateWidget(old);
    if (widget.shell.state != old.shell.state &&
        widget.shell.state != ShellState.hidden) {
      _anim.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Color get _borderColor {
    switch (widget.shell.state) {
      case ShellState.found:  return AppColors.success;
      case ShellState.wrong:  return AppColors.error;
      case ShellState.hidden: return AppColors.sandDark.withOpacity(0.4);
    }
  }

  Color get _glowColor {
    switch (widget.shell.state) {
      case ShellState.found:  return AppColors.success;
      case ShellState.wrong:  return AppColors.error;
      case ShellState.hidden: return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: widget.shell.isHidden ? const AlwaysStoppedAnimation(1.0) : _scale,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (animCtx, animChild) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.deepBrown.withOpacity(0.7),
              border: Border.all(color: _borderColor, width: 2),
              boxShadow: widget.shell.isHidden ? [] : [
                BoxShadow(
                  color: _glowColor.withOpacity(0.5 * _glow.value),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Parchment texture background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF5A3A1A).withOpacity(0.9),
                          AppColors.deepBrown,
                          const Color(0xFF2A1A0A),
                        ],
                      ),
                    ),
                  ),

                  // Shell image — transparent when hidden, full opacity when found
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: widget.shell.isFound ? 1.0 : 0.18,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        _imageForShell(widget.shell.number),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Wrong red overlay flash
                  if (widget.shell.isWrong)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: 0.25,
                      child: Container(color: AppColors.error),
                    ),

                  // Shell number — always visible, centered
                  if (!widget.shell.isFound)
                    Center(
                      child: Text(
                        '${widget.shell.number}',
                        style: GoogleFonts.pirataOne(
                          fontSize: 36,
                          color: widget.shell.isWrong
                              ? AppColors.error
                              : AppColors.sandLight.withOpacity(0.9),
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.8),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Found checkmark overlay
                  if (widget.shell.isFound)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 14),
                      ),
                    ),

                  // Shell number badge bottom left
                  Positioned(
                    bottom: 6,
                    left: 8,
                    child: Text(
                      'SHELL ${widget.shell.number}',
                      style: GoogleFonts.cinzel(
                        fontSize: 9,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                        color: widget.shell.isFound
                            ? AppColors.sandLight
                            : AppColors.sandDark.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}