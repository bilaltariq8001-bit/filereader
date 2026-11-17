// widgets/floating_action_button.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FloatingAiSearchButton extends StatefulWidget {
  final bool isVisible;
  final String selectedText;
  final VoidCallback onTap;
  final VoidCallback? onSmartFind;
  final VoidCallback? onQuickSummary;
  final VoidCallback? onAskQuestion;

  const FloatingAiSearchButton({
    Key? key,
    required this.isVisible,
    this.selectedText = '',
    required this.onTap,
    this.onSmartFind,
    this.onQuickSummary,
    this.onAskQuestion,
  }) : super(key: key);

  @override
  _FloatingAiSearchButtonState createState() => _FloatingAiSearchButtonState();
}

class _FloatingAiSearchButtonState extends State<FloatingAiSearchButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  double _posX = 20.0;
  double _posY = 20.0;
  bool _isExpanded = false;
  bool _isDragging = false;
  bool _showTooltip = true;

  static const String _positionKey = 'floating_button_position';

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutBack,
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Load saved position
    _loadPosition();

    // Auto-hide tooltip after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showTooltip = false;
        });
      }
    });
  }

  Future<void> _loadPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedX = prefs.getDouble('${_positionKey}_x');
      final savedY = prefs.getDouble('${_positionKey}_y');

      if (savedX != null && savedY != null) {
        if (mounted) {
          setState(() {
            _posX = savedX;
            _posY = savedY;
          });
        }
      }
    } catch (e) {
      print('Error loading button position: $e');
    }
  }

  Future<void> _savePosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('${_positionKey}_x', _posX);
      await prefs.setDouble('${_positionKey}_y', _posY);
    } catch (e) {
      print('Error saving button position: $e');
    }
  }

  void _toggleExpand() {
    if (_isDragging) return;

    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _onDragEnd() {
    _isDragging = false;
    _savePosition();
    _snapToEdgeIfNear();
  }

  void _snapToEdgeIfNear() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    setState(() {
      // Snap to left edge
      if (_posX < screenWidth * 0.1) {
        _posX = 10.0;
      }
      // Snap to right edge
      else if (_posX > screenWidth - 70) {
        _posX = screenWidth - 70.0;
      }

      // Snap to top
      if (_posY < 100) {
        _posY = 100.0;
      }
      // Snap to bottom
      else if (_posY > screenHeight - 150) {
        _posY = screenHeight - 150.0;
      }

      _savePosition();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible && !_isExpanded) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // Background overlay when expanded
        if (_isExpanded)
          GestureDetector(
            onTap: _toggleExpand,
            child: Container(
              color: Colors.black.withOpacity(0.2),
              width: double.infinity,
              height: double.infinity,
            ),
          ),

        // Expanded options
        if (_isExpanded) ...[
          _buildOption(
            offsetX: -80,
            offsetY: -80,
            icon: Icons.bolt,
            label: 'Smart Find',
            color: Colors.deepPurple,
            onTap: widget.onSmartFind ?? widget.onTap,
          ),
          _buildOption(
            offsetX: 80,
            offsetY: -80,
            icon: Icons.summarize,
            label: 'Quick Summary',
            color: Colors.green,
            onTap: widget.onQuickSummary ?? widget.onTap,
          ),
          _buildOption(
            offsetX: -80,
            offsetY: 80,
            icon: Icons.lightbulb,
            label: 'Explain',
            color: Colors.orange,
            onTap: widget.onAskQuestion ?? widget.onTap,
          ),
          _buildOption(
            offsetX: 80,
            offsetY: 80,
            icon: Icons.search,
            label: 'AI Search',
            color: Colors.blue,
            onTap: widget.onTap,
          ),
        ],

        // Main draggable button
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          left: _posX.clamp(0.0, screenWidth - 70),
          top: _posY.clamp(0.0, screenHeight - 70),
          child: GestureDetector(
            onPanStart: (_) {
              setState(() {
                _isDragging = true;
                _showTooltip = false;
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _posX += details.delta.dx;
                _posY += details.delta.dy;
              });
            },
            onPanEnd: (_) => _onDragEnd(),
            onPanCancel: () => _onDragEnd(),
            onTap: () {
              if (widget.selectedText.isNotEmpty) {
                widget.onTap();
              } else {
                _toggleExpand();
              }
            },
            onLongPress: _toggleExpand,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blueAccent, Colors.indigo],
                ),
              ),
              child: Stack(
                children: [
                  // Selected text preview
                  if (widget.selectedText.isNotEmpty && !_isExpanded)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          'T',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Animated icon
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotateAnimation.value * 2 * 3.14159,
                        child: Icon(
                          _isExpanded ? Icons.close : Icons.auto_awesome,
                          color: Colors.white,
                          size: 24,
                        ),
                      );
                    },
                  ),

                  // Tooltip
                  if (_showTooltip && widget.selectedText.isEmpty && !_isDragging)
                    Positioned(
                      right: 70,
                      top: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app, size: 16, color: Colors.blue),
                            const SizedBox(width: 6),
                            Text(
                              'Drag or tap',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOption({
    required double offsetX,
    required double offsetY,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      left: _posX + offsetX,
      top: _posY + offsetY,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: () {
            onTap();
            _toggleExpand();
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}