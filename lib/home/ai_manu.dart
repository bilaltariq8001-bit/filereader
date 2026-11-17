// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
//
// /// Advanced Expandable AI Menu with Speed Dial
// /// Provides multiple AI-powered actions in a compact menu
// class AdvancedAiSpeedDial extends StatefulWidget {
//   final bool isVisible;
//   final String? selectedText;
//   final VoidCallback onAiSearch;
//   final VoidCallback? onSummarize;
//   final VoidCallback? onTranslate;
//   final VoidCallback? onDefine;
//   final VoidCallback? onExplain;
//   final VoidCallback? onQuestions;
//
//   const AdvancedAiSpeedDial({
//     Key? key,
//     this.isVisible = true,
//     this.selectedText,
//     required this.onAiSearch,
//     this.onSummarize,
//     this.onTranslate,
//     this.onDefine,
//     this.onExplain,
//     this.onQuestions,
//   }) : super(key: key);
//
//   @override
//   State<AdvancedAiSpeedDial> createState() => _AdvancedAiSpeedDialState();
// }
//
// class _AdvancedAiSpeedDialState extends State<AdvancedAiSpeedDial>
//     with SingleTickerProviderStateMixin {
//   bool _isOpen = false;
//   late AnimationController _controller;
//   late Animation<double> _scaleAnimation;
//   late Animation<double> _rotateAnimation;
//
//   final List<_SpeedDialAction> _actions = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _setupAnimations();
//     _buildActions();
//   }
//
//   void _setupAnimations() {
//     _controller = AnimationController(
//       duration: Duration(milliseconds: 250),
//       vsync: this,
//     );
//
//     _scaleAnimation = CurvedAnimation(
//       parent: _controller,
//       curve: Curves.easeInOut,
//     );
//
//     _rotateAnimation = Tween<double>(begin: 0.0, end: 0.625).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
//     );
//   }
//
//   void _buildActions() {
//     _actions.clear();
//
//     _actions.add(_SpeedDialAction(
//       icon: Icons.auto_awesome,
//       label: 'AI Search',
//       color: Color(0xFF667EEA),
//       onTap: widget.onAiSearch,
//     ));
//
//     if (widget.onSummarize != null) {
//       _actions.add(_SpeedDialAction(
//         icon: Icons.summarize,
//         label: 'Summarize',
//         color: Color(0xFF764BA2),
//         onTap: widget.onSummarize!,
//       ));
//     }
//
//     if (widget.onTranslate != null) {
//       _actions.add(_SpeedDialAction(
//         icon: Icons.translate,
//         label: 'Translate',
//         color: Color(0xFF4facfe),
//         onTap: widget.onTranslate!,
//       ));
//     }
//
//     if (widget.onDefine != null) {
//       _actions.add(_SpeedDialAction(
//         icon: Icons.menu_book,
//         label: 'Define',
//         color: Color(0xFF43e97b),
//         onTap: widget.onDefine!,
//       ));
//     }
//
//     if (widget.onExplain != null) {
//       _actions.add(_SpeedDialAction(
//         icon: Icons.lightbulb,
//         label: 'Explain',
//         color: Color(0xFFf093fb),
//         onTap: widget.onExplain!,
//       ));
//     }
//
//     if (widget.onQuestions != null) {
//       _actions.add(_SpeedDialAction(
//         icon: Icons.quiz,
//         label: 'Questions',
//         color: Color(0xFFffa45b),
//         onTap: widget.onQuestions!,
//       ));
//     }
//   }
//
//   void _toggle() {
//     setState(() {
//       _isOpen = !_isOpen;
//       if (_isOpen) {
//         _controller.forward();
//       } else {
//         _controller.reverse();
//       }
//     });
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
//     return Stack(
//       alignment: Alignment.bottomRight,
//       children: [
//         // Backdrop
//         if (_isOpen)
//           GestureDetector(
//             onTap: _toggle,
//             child: Container(
//               color: Colors.black.withOpacity(0.3),
//             ),
//           ),
//
//         // Actions
//         Positioned(
//           right: 20.w,
//           bottom: 90.h,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ..._actions.asMap().entries.map((entry) {
//                 final index = entry.key;
//                 final action = entry.value;
//
//                 return _buildActionItem(
//                   action: action,
//                   index: index,
//                   total: _actions.length,
//                 );
//               }).toList(),
//             ],
//           ),
//         ),
//
//         // Main FAB
//         Positioned(
//           right: 20.w,
//           bottom: 20.h,
//           child: _buildMainFab(),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildActionItem({
//     required _SpeedDialAction action,
//     required int index,
//     required int total,
//   }) {
//     final delay = (total - index) * 50;
//
//     return AnimatedBuilder(
//       animation: _scaleAnimation,
//       builder: (context, child) {
//         final progress = Curves.easeOut.transform(
//           (_scaleAnimation.value * total - index).clamp(0.0, 1.0),
//         );
//
//         return Transform.scale(
//           scale: progress,
//           child: Opacity(
//             opacity: progress,
//             child: Padding(
//               padding: EdgeInsets.only(bottom: 12.h),
//               child: child,
//             ),
//           ),
//         );
//       },
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Label
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(20.r),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 8,
//                   offset: Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Text(
//               action.label,
//               style: TextStyle(
//                 color: action.color,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 13.sp,
//                 fontFamily: 'Inter',
//               ),
//             ),
//           ),
//           SizedBox(width: 10.w),
//
//           // Action button
//           Material(
//             color: Colors.transparent,
//             child: InkWell(
//               onTap: () {
//                 action.onTap();
//                 _toggle();
//               },
//               borderRadius: BorderRadius.circular(25.r),
//               child: Container(
//                 width: 50.w,
//                 height: 50.h,
//                 decoration: BoxDecoration(
//                   color: action.color,
//                   shape: BoxShape.circle,
//                   boxShadow: [
//                     BoxShadow(
//                       color: action.color.withOpacity(0.4),
//                       blurRadius: 12,
//                       offset: Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: Icon(
//                   action.icon,
//                   color: Colors.white,
//                   size: 24.sp,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMainFab() {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: _toggle,
//         borderRadius: BorderRadius.circular(30.r),
//         child: Container(
//           width: 60.w,
//           height: 60.h,
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Color(0xFF667EEA),
//                 Color(0xFF764BA2),
//               ],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             shape: BoxShape.circle,
//             boxShadow: [
//               BoxShadow(
//                 color: Color(0xFF667EEA).withOpacity(0.5),
//                 blurRadius: 20,
//                 offset: Offset(0, 8),
//               ),
//             ],
//           ),
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               // Rotating icon
//               RotationTransition(
//                 turns: _rotateAnimation,
//                 child: Icon(
//                   _isOpen ? Icons.close : Icons.auto_awesome,
//                   color: Colors.white,
//                   size: 28.sp,
//                 ),
//               ),
//
//               // Badge (if text is selected)
//               if (widget.selectedText != null && widget.selectedText!.isNotEmpty && !_isOpen)
//                 Positioned(
//                   top: 5.h,
//                   right: 5.w,
//                   child: Container(
//                     width: 12.w,
//                     height: 12.h,
//                     decoration: BoxDecoration(
//                       color: Colors.red,
//                       shape: BoxShape.circle,
//                       border: Border.all(color: Colors.white, width: 2),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _SpeedDialAction {
//   final IconData icon;
//   final String label;
//   final Color color;
//   final VoidCallback onTap;
//
//   _SpeedDialAction({
//     required this.icon,
//     required this.label,
//     required this.color,
//     required this.onTap,
//   });
// }
//
// /// Circular AI Menu (Alternative Design)
// class CircularAiMenu extends StatefulWidget {
//   final bool isVisible;
//   final List<AiMenuAction> actions;
//
//   const CircularAiMenu({
//     Key? key,
//     this.isVisible = true,
//     required this.actions,
//   }) : super(key: key);
//
//   @override
//   State<CircularAiMenu> createState() => _CircularAiMenuState();
// }
//
// class _CircularAiMenuState extends State<CircularAiMenu>
//     with SingleTickerProviderStateMixin {
//   bool _isOpen = false;
//   late AnimationController _controller;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: Duration(milliseconds: 300),
//       vsync: this,
//     );
//   }
//
//   void _toggle() {
//     setState(() {
//       _isOpen = !_isOpen;
//       if (_isOpen) {
//         _controller.forward();
//       } else {
//         _controller.reverse();
//       }
//     });
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
//       right: 20.w,
//       bottom: 20.h,
//       child: Stack(
//         alignment: Alignment.bottomRight,
//         children: [
//           // Action buttons in circular arrangement
//           ...widget.actions.asMap().entries.map((entry) {
//             final index = entry.key;
//             final action = entry.value;
//             final angle = (index / widget.actions.length) * 3.14159 * 2;
//             final radius = 100.0;
//
//             return AnimatedBuilder(
//               animation: _controller,
//               builder: (context, child) {
//                 final progress = Curves.easeInOut.transform(_controller.value);
//                 final x = radius * progress * (1 - index / widget.actions.length) * 0.8;
//                 final y = -radius * progress * (index / widget.actions.length + 0.5);
//
//                 return Transform.translate(
//                   offset: Offset(x, y),
//                   child: Opacity(
//                     opacity: progress,
//                     child: child,
//                   ),
//                 );
//               },
//               child: Material(
//                 color: Colors.transparent,
//                 child: InkWell(
//                   onTap: () {
//                     action.onTap();
//                     _toggle();
//                   },
//                   borderRadius: BorderRadius.circular(25.r),
//                   child: Container(
//                     width: 50.w,
//                     height: 50.h,
//                     decoration: BoxDecoration(
//                       color: action.color,
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           color: action.color.withOpacity(0.4),
//                           blurRadius: 12,
//                           offset: Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: Icon(
//                       action.icon,
//                       color: Colors.white,
//                       size: 24.sp,
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           }).toList(),
//
//           // Main button
//           FloatingActionButton(
//             onPressed: _toggle,
//             backgroundColor: Color(0xFF667EEA),
//             elevation: 8,
//             child: Icon(
//               _isOpen ? Icons.close : Icons.auto_awesome,
//               color: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class AiMenuAction {
//   final IconData icon;
//   final String label;
//   final Color color;
//   final VoidCallback onTap;
//
//   AiMenuAction({
//     required this.icon,
//     required this.label,
//     required this.color,
//     required this.onTap,
//   });
// }
//
// /// Compact AI Toolbar (Bottom-aligned)
// class CompactAiToolbar extends StatelessWidget {
//   final bool isVisible;
//   final String? selectedText;
//   final VoidCallback onAiSearch;
//   final VoidCallback? onHighlight;
//   final VoidCallback? onNote;
//   final VoidCallback? onShare;
//
//   const CompactAiToolbar({
//     Key? key,
//     this.isVisible = true,
//     this.selectedText,
//     required this.onAiSearch,
//     this.onHighlight,
//     this.onNote,
//     this.onShare,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     if (!isVisible) return SizedBox.shrink();
//
//     return Positioned(
//       left: 20.w,
//       right: 20.w,
//       bottom: 20.h,
//       child: Container(
//         height: 60.h,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Color(0xFF667EEA),
//               Color(0xFF764BA2),
//             ],
//           ),
//           borderRadius: BorderRadius.circular(30.r),
//           boxShadow: [
//             BoxShadow(
//               color: Color(0xFF667EEA).withOpacity(0.4),
//               blurRadius: 20,
//               offset: Offset(0, 10),
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             _buildToolbarButton(
//               icon: Icons.auto_awesome,
//               label: 'AI',
//               onTap: onAiSearch,
//             ),
//             if (onHighlight != null)
//               _buildToolbarButton(
//                 icon: Icons.highlight,
//                 label: 'Highlight',
//                 onTap: onHighlight!,
//               ),
//             if (onNote != null)
//               _buildToolbarButton(
//                 icon: Icons.note_add,
//                 label: 'Note',
//                 onTap: onNote!,
//               ),
//             if (onShare != null)
//               _buildToolbarButton(
//                 icon: Icons.share,
//                 label: 'Share',
//                 onTap: onShare!,
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildToolbarButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(20.r),
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, color: Colors.white, size: 24.sp),
//             SizedBox(height: 4.h),
//             Text(
//               label,
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 10.sp,
//                 fontWeight: FontWeight.w600,
//                 fontFamily: 'Inter',
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }