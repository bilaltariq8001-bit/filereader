import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Floating AI Search Button Widget
///
/// This widget appears when user selects/copies text in a PDF
/// Allows quick AI search based on selected text
class FloatingAiSearchButton extends StatefulWidget {
  final VoidCallback onTap;
  final String? selectedText;
  final bool isVisible;

  const FloatingAiSearchButton({
    Key? key,
    required this.onTap,
    this.selectedText,
    this.isVisible = false,
  }) : super(key: key);

  @override
  _FloatingAiSearchButtonState createState() => _FloatingAiSearchButtonState();
}

class _FloatingAiSearchButtonState extends State<FloatingAiSearchButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(FloatingAiSearchButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 80.h,
      right: 16.w,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(30.r),
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF9C27B0), // Purple
                    Color(0xFF673AB7), // Deep Purple
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF9C27B0).withOpacity(0.4),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(30.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'AI Search',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                      if (widget.selectedText != null &&
                          widget.selectedText!.isNotEmpty) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 16.sp,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Alternative: Compact Floating Button (Smaller)
class CompactFloatingAiButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isVisible;

  const CompactFloatingAiButton({
    Key? key,
    required this.onTap,
    this.isVisible = false,
  }) : super(key: key);

  @override
  _CompactFloatingAiButtonState createState() =>
      _CompactFloatingAiButtonState();
}

class _CompactFloatingAiButtonState extends State<CompactFloatingAiButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(CompactFloatingAiButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 80.h,
      right: 16.w,
      child: ScaleTransition(
        scale: _animation,
        child: FloatingActionButton(
          onPressed: widget.onTap,
          backgroundColor: Color(0xFF9C27B0),
          elevation: 8,
          child: Icon(
            Icons.psychology,
            color: Colors.white,
            size: 28.sp,
          ),
        ),
      ),
    );
  }
}

/// Multi-action Floating Button (Expandable)
class ExpandableFloatingAiButton extends StatefulWidget {
  final VoidCallback onAiSearch;
  final VoidCallback onSmartFind;
  final VoidCallback onQuickSummary;
  final bool isVisible;

  const ExpandableFloatingAiButton({
    Key? key,
    required this.onAiSearch,
    required this.onSmartFind,
    required this.onQuickSummary,
    this.isVisible = false,
  }) : super(key: key);

  @override
  _ExpandableFloatingAiButtonState createState() =>
      _ExpandableFloatingAiButtonState();
}

class _ExpandableFloatingAiButtonState
    extends State<ExpandableFloatingAiButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 80.h,
      right: 16.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Expanded options
          if (_isExpanded) ...[
            _buildExpandedOption(
              icon: Icons.auto_awesome,
              label: 'Smart Find',
              color: Color(0xFFFF9800),
              onTap: () {
                _toggleExpanded();
                widget.onSmartFind();
              },
            ),
            SizedBox(height: 12.h),
            _buildExpandedOption(
              icon: Icons.lightbulb,
              label: 'Quick Summary',
              color: Color(0xFFFFC107),
              onTap: () {
                _toggleExpanded();
                widget.onQuickSummary();
              },
            ),
            SizedBox(height: 12.h),
            _buildExpandedOption(
              icon: Icons.psychology,
              label: 'AI Search',
              color: Color(0xFF9C27B0),
              onTap: () {
                _toggleExpanded();
                widget.onAiSearch();
              },
            ),
            SizedBox(height: 16.h),
          ],

          // Main button
          FloatingActionButton(
            onPressed: _toggleExpanded,
            backgroundColor: Color(0xFF9C27B0),
            elevation: 8,
            child: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _controller,
              color: Colors.white,
              size: 28.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(1, 0),
          end: Offset.zero,
        ).animate(_controller),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(25.r),
          color: color,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(25.r),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 10.h,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}