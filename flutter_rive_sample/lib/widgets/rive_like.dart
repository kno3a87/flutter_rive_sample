import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RiveLikeButton extends StatefulWidget {
  const RiveLikeButton({super.key});

  @override
  State<RiveLikeButton> createState() => _RiveLikeButtonState();
}

class _RiveLikeButtonState extends State<RiveLikeButton> {
  StateMachineController? _controller;
  SMIInput<bool>? _riveIsLiked;
  SMITrigger? _riveTap;

  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _liked = false;
  }

  void _onInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'State machine',
    );
    if (controller == null) return;
    artboard.addController(controller);
    _controller = controller;

    _riveIsLiked = controller.getBoolInput('isLiked');
    _riveTap = controller.getTriggerInput('tap');

    // 初期状態をRiveへ同期
    _riveIsLiked?.value = _liked;
  }

  void _handleTap() {
    _liked = !_liked;
    // RiveのBoolに反映
    _riveIsLiked?.value = _liked;
    // RiveのTriggerを発火
    _riveTap?.fire();
  }

  @override
  Widget build(BuildContext context) {
    // ハートアイコンのサイズ
    const double size = 48;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size * 1.2 * 2, // AnimationControllerの方の大きさに合わせた
        height: size * 1.2 * 2,
        child: RiveAnimation.asset(
          'assets/like_button.riv',
          fit: BoxFit.contain,
          onInit: _onInit,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
