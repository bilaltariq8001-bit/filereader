// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
//
// /// Draggable Floating AI Search Button
// /// Can be moved anywhere on the screen and persists across dialogs
// class DraggableFloatingAiButton extends StatefulWidget {
//   final bool isVisible;
//   final String selectedText;
//   final VoidCallback onTap;
//   final VoidCallback? onDismiss;
//
//   const DraggableFloatingAiButton({
//     Key? key,
//     required this.isVisible,
//     required this.selectedText,
//     required this.onTap,
//     this.onDismiss,
//   }) : super(key: key);
//
//   @override
//   State<DraggableFloatingAiButton> createState() => _DraggableFloatingAiButtonState();
// }
//
// class _DraggableFloatingAiButtonState extends State<DraggableFloatingAiButton>
//     with SingleTickerProviderStateMixin {
//   Offset _position = Offset(20, 100); // Default position
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;
//   bool _isDragging = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
//     );
//
//     if (widget.isVisible) {
//       _animationController.forward();
//     }
//   }
//
//   @override
//   void didUpdateWidget(DraggableFloatingAiButton oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.isVisible && !oldWidget.isVisible) {
//       _animationController.forward();
//     } else if (!widget.isVisible && oldWidget.isVisible) {
//       _animationController.reverse();
//     }
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (!widget.isVisible) return SizedBox.shrink();
//
//     return Positioned(
//       left: _position.dx,
//       top: _position.dy,
//       child: GestureDetector(
//         onPanStart: (_) {
//           setState(() => _isDragging = true);
//         },
//         onPanUpdate: (details) {
//           setState(() {
//             _position += details.delta;
//
//             // Keep button within screen bounds
//             final screenSize = MediaQuery.of(context).size;
//             _position = Offset(
//               _position.dx.clamp(0.0, screenSize.width - 80.w),
//               _position.dy.clamp(0.0, screenSize.height - 80.h),
//             );
//           });
//         },
//         onPanEnd: (_) {
//           setState(() => _isDragging = false);
//         },
//         onTap: () {
//           if (!_isDragging) {
//             widget.onTap();
//           }
//         },
//         child: ScaleTransition(
//           scale: _scaleAnimation,
//           child: Container(
//             width: 70.w,
//             height: 70.h,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Color(0xFF667EEA),
//                   Color(0xFF764BA2),
//                 ],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(35.r),
//               boxShadow: [
//                 BoxShadow(
//                   color: Color(0xFF667EEA).withOpacity(0.4),
//                   blurRadius: 15,
//                   offset: Offset(0, 5),
//                 ),
//               ],
//             ),
//             child: Stack(
//               children: [
//                 // Main icon
//                 Center(
//                   child: Icon(
//                     Icons.auto_awesome,
//                     color: Colors.white,
//                     size: 28.sp,
//                   ),
//                 ),
//
//                 // Close button
//                 Positioned(
//                   top: 0,
//                   right: 0,
//                   child: GestureDetector(
//                     onTap: widget.onDismiss,
//                     child: Container(
//                       width: 20.w,
//                       height: 20.h,
//                       decoration: BoxDecoration(
//                         color: Colors.red,
//                         shape: BoxShape.circle,
//                         border: Border.all(color: Colors.white, width: 1.5),
//                       ),
//                       child: Icon(
//                         Icons.close,
//                         color: Colors.white,
//                         size: 12.sp,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// /// Enhanced Floating AI Button with Tooltip
// class FloatingAiSearchButton extends StatefulWidget {
//   final bool isVisible;
//   final String selectedText;
//   final VoidCallback onTap;
//
//   const FloatingAiSearchButton({
//     Key? key,
//     required this.isVisible,
//     required this.selectedText,
//     required this.onTap,
//   }) : super(key: key);
//
//   @override
//   State<FloatingAiSearchButton> createState() => _FloatingAiSearchButtonState();
// }
//
// class _FloatingAiSearchButtonState extends State<FloatingAiSearchButton>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _scaleAnimation;
//   late Animation<double> _fadeAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: Duration(milliseconds: 400),
//       vsync: this,
//     );
//
//     _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
//     );
//
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeIn),
//     );
//
//     if (widget.isVisible) {
//       _controller.forward();
//     }
//   }
//
//   @override
//   void didUpdateWidget(FloatingAiSearchButton oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.isVisible && !oldWidget.isVisible) {
//       _controller.forward();
//     } else if (!widget.isVisible && oldWidget.isVisible) {
//       _controller.reverse();
//     }
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (!widget.isVisible) return SizedBox.shrink();
//
//     return Positioned(
//       bottom: 100.h,
//       right: 20.w,
//       child: FadeTransition(
//         opacity: _fadeAnimation,
//         child: ScaleTransition(
//           scale: _scaleAnimation,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               // Tooltip
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
//                 decoration: BoxDecoration(
//                   color: Colors.black87,
//                   borderRadius: BorderRadius.circular(8.r),
//                 ),
//                 child: Text(
//                   'AI Search: "${_truncateText(widget.selectedText)}"',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 12.sp,
//                     fontFamily: 'Inter',
//                   ),
//                 ),
//               ),
//               SizedBox(height: 8.h),
//
//               // Button
//               Material(
//                 color: Colors.transparent,
//                 child: InkWell(
//                   onTap: widget.onTap,
//                   borderRadius: BorderRadius.circular(30.r),
//                   child: Container(
//                     width: 60.w,
//                     height: 60.h,
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [
//                           Color(0xFF667EEA),
//                           Color(0xFF764BA2),
//                         ],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                       borderRadius: BorderRadius.circular(30.r),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Color(0xFF667EEA).withOpacity(0.5),
//                           blurRadius: 20,
//                           offset: Offset(0, 8),
//                         ),
//                       ],
//                     ),
//                     child: Icon(
//                       Icons.auto_awesome,
//                       color: Colors.white,
//                       size: 28.sp,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   String _truncateText(String text) {
//     if (text.length <= 30) return text;
//     return '${text.substring(0, 27)}...';
//   }
// }
//
// /// Expandable Floating Action Button with Multiple Actions
// class ExpandableFloatingAiButton extends StatefulWidget {
//   final VoidCallback onAiSearch;
//   final VoidCallback onSmartFind;
//   final VoidCallback onQuickSummary;
//   final VoidCallback? onTranslate;
//   final VoidCallback? onDefine;
//   final bool isVisible;
//
//   const ExpandableFloatingAiButton({
//     Key? key,
//     required this.onAiSearch,
//     required this.onSmartFind,
//     required this.onQuickSummary,
//     this.onTranslate,
//     this.onDefine,
//     this.isVisible = true,
//   }) : super(key: key);
//
//   @override
//   State<ExpandableFloatingAiButton> createState() =>
//       _ExpandableFloatingAiButtonState();
// }
//
// class _ExpandableFloatingAiButtonState extends State<ExpandableFloatingAiButton>
//     with SingleTickerProviderStateMixin {
//   bool _isExpanded = false;
//   late AnimationController _controller;
//   late Animation<double> _expandAnimation;
//   late Animation<double> _rotateAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: Duration(milliseconds: 300),
//       vsync: this,
//     );
//
//     _expandAnimation = CurvedAnimation(
//       parent: _controller,
//       curve: Curves.easeInOut,
//     );
//
//     _rotateAnimation = Tween<double>(begin: 0.0, end: 0.375).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   void _toggle() {
//     setState(() {
//       _isExpanded = !_isExpanded;
//       if (_isExpanded) {
//         _controller.forward();
//       } else {
//         _controller.reverse();
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (!widget.isVisible) return SizedBox.shrink();
//
//     return Positioned(
//       bottom: 80.h,
//       right: 20.w,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           // Action buttons (shown when expanded)
//           if (_isExpanded) ...[
//             _buildActionButton(
//               icon: Icons.auto_awesome,
//               label: 'AI Search',
//               color: Color(0xFF667EEA),
//               onTap: () {
//                 widget.onAiSearch();
//                 _toggle();
//               },
//             ),
//             SizedBox(height: 12.h),
//             _buildActionButton(
//               icon: Icons.search,
//               label: 'Smart Find',
//               color: Color(0xFF764BA2),
//               onTap: () {
//                 widget.onSmartFind();
//                 _toggle();
//               },
//             ),
//             SizedBox(height: 12.h),
//             _buildActionButton(
//               icon: Icons.summarize,
//               label: 'Summary',
//               color: Color(0xFFf093fb),
//               onTap: () {
//                 widget.onQuickSummary();
//                 _toggle();
//               },
//             ),
//             if (widget.onTranslate != null) ...[
//               SizedBox(height: 12.h),
//               _buildActionButton(
//                 icon: Icons.translate,
//                 label: 'Translate',
//                 color: Color(0xFF4facfe),
//                 onTap: () {
//                   widget.onTranslate!();
//                   _toggle();
//                 },
//               ),
//             ],
//             if (widget.onDefine != null) ...[
//               SizedBox(height: 12.h),
//               _buildActionButton(
//                 icon: Icons.menu_book,
//                 label: 'Define',
//                 color: Color(0xFF43e97b),
//                 onTap: () {
//                   widget.onDefine!();
//                   _toggle();
//                 },
//               ),
//             ],
//             SizedBox(height: 16.h),
//           ],
//
//           // Main FAB
//           FloatingActionButton(
//             onPressed: _toggle,
//             backgroundColor: Color(0xFF667EEA),
//             elevation: 8,
//             child: RotationTransition(
//               turns: _rotateAnimation,
//               child: Icon(
//                 _isExpanded ? Icons.close : Icons.auto_awesome,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildActionButton({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return FadeTransition(
//       opacity: _expandAnimation,
//       child: SlideTransition(
//         position: Tween<Offset>(
//           begin: Offset(1, 0),
//           end: Offset.zero,
//         ).animate(_expandAnimation),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20.r),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 8,
//                     offset: Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Text(
//                 label,
//                 style: TextStyle(
//                   color: color,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 14.sp,
//                   fontFamily: 'Inter',
//                 ),
//               ),
//             ),
//             SizedBox(width: 8.w),
//             FloatingActionButton(
//               mini: true,
//               onPressed: onTap,
//               backgroundColor: color,
//               elevation: 4,
//               child: Icon(icon, color: Colors.white, size: 20.sp),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }