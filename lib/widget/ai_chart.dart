import 'package:flutter/material.dart';
//
// class GlobalDraggableButton extends StatefulWidget {
//   final Widget child;
//
//   const GlobalDraggableButton({super.key, required this.child});
//
//   @override
//   State<GlobalDraggableButton> createState() => _GlobalDraggableButtonState();
// }
//
// class _GlobalDraggableButtonState extends State<GlobalDraggableButton> {
//   Offset position = const Offset(20, 100);
//
//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         widget.child,
//
//         Positioned(
//           left: position.dx,
//           top: position.dy,
//           child: Draggable(
//             feedback: _button(),
//             childWhenDragging: const SizedBox(),
//             onDragEnd: (details) {
//               setState(() {
//                 position = details.offset;
//               });
//             },
//             child: _button(),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _button() {
//     return FloatingActionButton(
//       onPressed: () {
//         debugPrint("Global Button Clicked");
//       },
//       child: const Icon(Icons.support_agent),
//     );
//   }
// }
class GlobalDraggableButtonWrapper extends StatefulWidget {
  final Widget child;

  const GlobalDraggableButtonWrapper({super.key, required this.child});

  @override
  State<GlobalDraggableButtonWrapper> createState() =>
      _GlobalDraggableButtonWrapperState();
}

class _GlobalDraggableButtonWrapperState
    extends State<GlobalDraggableButtonWrapper> {
  Offset position = const Offset(20, 120);

  @override
  Widget build(BuildContext context) {
    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) {
            return Stack(
              children: [
                widget.child,

                Positioned(
                  left: position.dx,
                  top: position.dy,
                  child: Draggable(
                    feedback: _fab(),
                    childWhenDragging: const SizedBox(),
                    onDragEnd: (details) {
                      setState(() => position = details.offset);
                    },
                    child: GestureDetector(
                      onTapDown: (details) {
                        _showPopupMenu(
                          context,
                          details.globalPosition,
                        );
                      },
                      child: _fab(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _fab() {
    return FloatingActionButton(
      onPressed: () {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final Offset position = box.localToGlobal(Offset.zero);

        _showPopupMenu(context, position);
      },
      child: const Icon(Icons.support_agent),
    );
  }


  void _showPopupMenu(BuildContext context, Offset offset) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        0,
        0,
      ),
      items: [
        const PopupMenuItem(
          value: 'chat',
          child: Text('Live Chat'),
        ),
        const PopupMenuItem(
          value: 'call',
          child: Text('Call Support'),
        ),
        const PopupMenuItem(
          value: 'email',
          child: Text('Email Us'),
        ),
      ],
    ).then((value) {
      if (value == null) return;

      switch (value) {
        case 'chat':
          debugPrint('Chat selected');
          break;
        case 'call':
          debugPrint('Call selected');
          break;
        case 'email':
          debugPrint('Email selected');
          break;
      }
    });
  }
}