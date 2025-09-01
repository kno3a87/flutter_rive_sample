import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:rive/math.dart';
import 'package:rive/rive.dart';

class Dashmaru extends StatefulWidget {
  const Dashmaru({super.key});

  @override
  State<Dashmaru> createState() => _DashmaruState();
}

class _DashmaruState extends State<Dashmaru> {
  StateMachineController? _controller;
  SMIInput<double>? _tx;
  SMIInput<double>? _ty;
  // Axis-Aligned Bounding Box（アードボードの座標を持つ矩形）
  AABB? _ab;

  // 画面側のサイズ（BoxFit.containでスケール計算に使う）
  Size _viewSize = Size.zero;

  void _onInit(Artboard artboard) {
    final stateMachineController = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1',
    );
    if (stateMachineController == null) return;
    artboard.addController(stateMachineController);
    _controller = stateMachineController;
    _ab = artboard.localBounds;
    _tx = stateMachineController.getNumberInput('targetX');
    _ty = stateMachineController.getNumberInput('targetY');
  }

  // 画面ローカル座標 → アートボード座標に変換する
  // 例えば
  // 画面サイズ: 400×800px
  // アートボード: 200×200px
  // の時には
  // 1. scale = min(400/200, 800/200) = 2.0 (2倍に拡大することにする)
  // 2. dx = (400 - 200×2) × 0.5 = 0px (左右余白なし)
  // 3. dy = (800 - 200×2) × 0.5 = 200px (上下に200pxずつ余白ができる)
  // 4. 画面の(100, 400)タップ → アートボード内の(50, 100)に変換する！
  Offset _toArtboard(Offset local) {
    final ab = _ab!;
    final viewW = _viewSize.width, viewH = _viewSize.height;
    final abW = ab.width, abH = ab.height;

    // BoxFit.containでのスケール倍率を計算（アスペクト比維持）
    final scale = math.min(viewW / abW, viewH / abH);

    // 中央寄せによる余白を計算
    final dx = (viewW - abW * scale) * 0.5; // 左右の余白
    final dy = (viewH - abH * scale) * 0.5; // 上下の余白

    // 画面座標からアートボード座標に変換
    final x = (local.dx - dx) / scale + ab.minX;
    final y = (local.dy - dy) / scale + ab.minY;
    return Offset(x, y);
  }

  // タップされてる指の位置をそのままriveに流し込む
  void _updateFromLocal(Offset local) {
    if (_tx == null || _ty == null || _ab == null) return;
    final abPt = _toArtboard(local);

    _tx?.value = abPt.dx;
    _ty?.value = abPt.dy;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        _viewSize = Size(c.maxWidth, c.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) => _updateFromLocal(d.localPosition),
          onPanUpdate: (d) => _updateFromLocal(d.localPosition),
          child: RiveAnimation.asset(
            'assets/dashmaru.riv',
            fit: BoxFit.contain,
            onInit: _onInit,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
