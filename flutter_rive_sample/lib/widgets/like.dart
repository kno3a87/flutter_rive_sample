import 'dart:ui';

import 'package:flutter/material.dart';

class LikeButton extends StatefulWidget {
  final bool initialLiked;
  final ValueChanged<bool>? onChanged;

  const LikeButton({super.key, this.initialLiked = false, this.onChanged});

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> with TickerProviderStateMixin {
  late bool _liked;

  // リングアニメーション用
  late final AnimationController _burstController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  );

  // いいねアイコンアニメーション用
  late final AnimationController _scaleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );

  // タップ時のスケール
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 1.5,
  ).chain(CurveTween(curve: Curves.easeOut)).animate(_scaleController);

  // リングアニメーション（0→1で半径とフェードアウトを表現）
  late final Animation<double> _ring = CurvedAnimation(
    parent: _burstController,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _liked = widget.initialLiked;
  }

  @override
  void dispose() {
    _burstController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _toggleLike() async {
    setState(() => _liked = !_liked);
    widget.onChanged?.call(_liked);

    // タップ時のスケールアニメーション（一瞬だけ）
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });

    if (_liked) {
      // いいね時：通常のリングアニメーション（内側から外側へ）
      _burstController.forward(from: 0);
    } else {
      // いいね解除時：逆のリングアニメーション（外側から内側へ）
      // forward を使うが，リングの計算を逆にする
      // 単純にreverseを使うと薄いリングから濃いリングに変化してしまう
      _burstController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ハートアイコンのサイズ
    const double size = 48;
    // リングの最大半径（size * 1.2）
    const double maxRingRadius = size * 1.2;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleLike,
      child: SizedBox(
        width: maxRingRadius * 2,
        height: maxRingRadius * 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // タップ時のリング
            AnimatedBuilder(
              animation: _ring,
              builder: (context, _) {
                // アニメーションが動いていない，かつ値が0または1の場合は非表示
                if (!_burstController.isAnimating &&
                    (_ring.value == 0.0 || _ring.value == 1.0)) {
                  return const SizedBox.shrink();
                }

                double radius;
                double opacity;
                Color ringColor;

                if (_liked) {
                  // lerpDouble(開始値, 終了値, 進行度)
                  // radius = (size * 0.6) + ((size * 1.2)) - (size * 0.6)) * _ring.value; と一緒
                  // 引数にnullを渡していないので強制アンラップでも良いのだけど怖いのでデフォルト値をぶっこんである

                  // いいね時：内側から外側へ広がって消える（ピンク）
                  radius =
                      lerpDouble(size * 0.6, size * 1.2, _ring.value) ??
                      size * 0.6;
                  opacity = lerpDouble(0.35, 0.0, _ring.value) ?? 0.0;
                  ringColor = Colors.pink;
                } else {
                  // いいね解除時：外側から内側へ縮んで消える（グレー）
                  radius =
                      lerpDouble(size * 1.2, size * 0.6, _ring.value) ??
                      size * 1.2;
                  opacity = lerpDouble(0.35, 0.0, _ring.value) ?? 0.0;
                  ringColor = Colors.grey;
                }

                return Container(
                  width: radius * 2,
                  height: radius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: 4,
                      color: ringColor.withAlpha((255 * opacity).toInt()),
                    ),
                  ),
                );
              },
            ),

            // ハートアイコン
            ScaleTransition(
              scale: _scale,
              child: Icon(
                _liked ? Icons.favorite : Icons.favorite_border,
                size: size,
                color: _liked ? Colors.pink : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
