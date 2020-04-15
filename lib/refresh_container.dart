import 'package:flutter/material.dart';
import 'package:flutterconvenientrefresh/refresh_convenient.dart';

class RefreshContainer extends StatefulWidget{
  final String code;
  final double offset,maxOffset,height;
  final Alignment alignment;
  final MoveController controller;
  final RectTween tween;
  final RefreshBuilder builder;

  RefreshContainer({
    this.code,
    this.controller,
    this.alignment,
    this.height,
    this.offset,
    this.maxOffset,
    this.tween,
    this.builder});
  createState() => RefreshContainerState();
}

class RefreshContainerState extends State<RefreshContainer> with TickerProviderStateMixin{
  AnimationController _controller;
  Animation<Rect> _rectAnimation;
  VoidCallback _callback;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: Duration(milliseconds: 300),vsync: this);
    _rectAnimation = widget.tween.animate(_controller);
    double offset = widget.maxOffset + widget.offset;
    if (_callback == null)
      _callback = () {
        if (widget.code == widget.controller.code){
          double value = widget.controller.value / offset;
          widget.controller.loading ? _controller.animateTo(value,duration: Duration(milliseconds: 300),curve: Curves.easeOut) :
          _controller.value = value;
        }
      };
    widget.controller.addListener(_callback);
  }

  @override
  Widget build(BuildContext context) {
    return RelativePositionedTransition(
        rect: _rectAnimation,
        size: Size(0, 0),
        child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget child) {
              return Align(
                  child: SizedBox(
                    height: widget.offset,
                    child: widget.builder(context),
                  ),
                  alignment: widget.alignment
              );
            }));
  }

  @override
  void didUpdateWidget(RefreshContainer oldWidget) {
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_callback);
      widget.controller.addListener(_callback);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_callback);
    _callback = null;
    _controller?.dispose();
    _controller = null;
    _rectAnimation = null;
    super.dispose();
  }
}