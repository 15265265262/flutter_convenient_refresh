import 'package:flutter/material.dart';
import 'package:flutterconvenientrefresh/refresh_container.dart';
import 'refresh_scrollphysics.dart';
import 'dart:async';

class RefreshConvenient extends StatefulWidget{
  final double height,headerBegin, footerBegin,maxOffset, headerEnd ,footerEnd;
  final Widget header,footer;
  final OnCallback onHeaderCallback,onFooterCallback;
  final BodyBuilder builder;
  final MoveController moveController;
  final bool isRebound;

  RefreshConvenient({
    Key key,
    @required this.builder,
    @required this.moveController,
    this.onHeaderCallback,
    this.onFooterCallback,
    this.header,
    this.footer,
    this.height,
    this.headerBegin,
    this.footerBegin,
    this.headerEnd,
    this.footerEnd,
    this.maxOffset,
    this.isRebound = true
  }): super(key : key);

  createState() => RefreshConvenientState();
}

class RefreshConvenientState extends State<RefreshConvenient>{
  ScrollController _controller;
  double _headerBegin, _footerBegin,_maxOffset, _headerEnd,_footerEnd,
      _refreshValue = 0.0,_loadingValue = 0.0, _maxScrollValue = 0.0;
  bool _outOfRange = false,_isLoading = false,_isComplete = false;
  ScrollJudgment _scrollJudgment;
  MoveController _moveController;
  Widget _body;

  @override
  void initState() {
    super.initState();
    if (widget.isRebound){
      _headerBegin = widget.headerBegin ?? 100.0;
      _headerEnd = widget.headerEnd ?? 300.0;
    }
    _footerBegin = widget.footerBegin ?? 100.0;
    _footerEnd = widget.footerEnd ?? -300.0;
    _maxOffset = widget.maxOffset ?? 300.0;
    _scrollJudgment = ScrollJudgment(false,false);
    _moveController = widget.moveController;
  }

  @override
  Widget build(BuildContext context) {
    _body = widget.builder(context, RefreshScrollPhysics(scrollJudgment: _scrollJudgment));
    if (_controller == null)
      _controller = _getController();
    List<Widget> children = [
      NotificationListener<ScrollNotification>(
          child: !widget.isRebound ? RefreshIndicator(child: _body,onRefresh: widget.onHeaderCallback) : _body,
          onNotification: (notification){
            if (notification is ScrollUpdateNotification){
              if (_controller != null && _isLoading) {
                if (_refreshValue != 0){
                  _controller.jumpTo(_refreshValue);
                  return true;
                }
                if (_loadingValue != 0){
                  _controller.jumpTo(_loadingValue);
                  return true;
                }
              }
              ScrollMetrics metrics = notification.metrics;
              _outOfRange = metrics.outOfRange;
              if (_outOfRange)
                if (notification.dragDetails != null){
                  double pixels = metrics.pixels;
                  if (pixels > 0){
                    _moveController.code = '1';
                    _moveController.value = pixels - metrics.maxScrollExtent;

                    double offset = metrics.maxScrollExtent + _footerBegin;
                    if (pixels >= offset && widget.footer != null){
                      _loadingValue = offset;
                      _moveController.state = 1;
                    }else{
                      _loadingValue = 0.0;
                      _moveController.state = 0;
                    }
                  }else{
                    if (widget.isRebound){
                      _moveController.code = '0';
                      _moveController.value = -pixels;

                      double offset = -_headerBegin;
                      if (pixels <= offset && widget.header != null){
                        _refreshValue = offset;
                        _moveController.state = 1;
                      }else{
                        _refreshValue = 0.0;
                        _moveController.state = 0;
                      }
                    }
                  }
                  _maxScrollValue = metrics.maxScrollExtent;
                }else if (_loadingValue > 0 || _refreshValue < 0){
                  _isLoading = true;
                  _moveController.loading = _isLoading;
                }
            }
            if (!widget.isRebound)
            _scrollJudgment.isRebound = notification.metrics.extentBefore == 0.0;
            return true;
          }
      )
    ];
    if (widget.header != null)
      children.add(RefreshContainer(
          code: '0',
          controller: _moveController,
          offset: _headerBegin,
          maxOffset: _maxOffset,
          alignment: Alignment.topCenter,
          tween: _header(),
          builder: (context) => widget.header));

    if (widget.footer != null)
      children.add(RefreshContainer(
          code: '1',
          controller: _moveController,
          offset: _footerBegin,
          maxOffset: _maxOffset,
          alignment: Alignment.bottomCenter,
          tween: _footer(),
          builder: (context) => widget.footer));
    return Listener(
        onPointerDown: (v) {
//          _startY =   v.delta.dy;
          _scrollJudgment.isRange = true;
        },
//        onPointerMove: (v){
//          _endY  = v.delta.dy;
//          if (_endY < _startY)
//            _scrollJudgment.isAlwaysScroll = false;
//          else
//            _scrollJudgment.isAlwaysScroll = true;
//        },
        onPointerUp: (v) {
          if (!_scrollJudgment.isRebound){
            if (_refreshValue == 0 && _loadingValue == 0 && _outOfRange){
              if (_moveController.code == '1'){
                _moveController.value = _footerEnd;
                _animateTo(_maxScrollValue);
                _maxScrollValue = 0.0;
              } else {
                _moveController.value = -_headerBegin;
                _animateTo(0.0);
              }
              _outOfRange = false;
            }else {
              if (!_isComplete){
                if (_loadingValue > 0){
                  if (widget.footer != null) {
                    _moveController.value = _footerBegin;
                    _scrollTo(_loadingValue, () {
                      _loading(widget.onFooterCallback, _maxScrollValue);
                    });
                  }else{
                    _animateTo(_maxScrollValue);
                    _maxScrollValue = 0.0;
                  }
                } else if (_refreshValue < 0)
                  if (widget.header != null){
                    _moveController.value = _headerBegin;
                    _scrollTo(_refreshValue,(){
                      _loading(widget.onHeaderCallback,0.0);
                    });
                  }else
                    _animateTo(0.0);
              }
            }
          }
          _scrollJudgment.isRange = false;
        },
        onPointerCancel: (v) => _scrollJudgment.isRange = false,
        child: Stack(children: children)
    );
  }

//  double _startY,_endY;

  _animateTo(double value){
    if (_controller != null)
    _controller.animateTo(value,duration: Duration(milliseconds: 300),curve: Curves.easeOut);
  }

  _scrollTo(double offset,Function callback) {
    if (_controller != null){
      _isComplete = true;
      _moveController.state = 2;
      _controller.animateTo(offset,duration: Duration(milliseconds: 300),curve: Curves.easeIn).
      whenComplete(callback);
    }
  }

  _loading(OnCallback callback, double value){
    callback().whenComplete((){
      _moveController.value = _moveController.code == '1' ? _footerEnd : -_headerBegin;
      _controller.jumpTo(value);
      _refreshValue = 0.0;
      _loadingValue = 0.0;
      _isLoading = false;
      _isComplete = false;
      _moveController.loading = _isLoading;
      _moveController.state = 0;
    });
  }

  ScrollController _getController() {
    switch (_body.runtimeType) {
      case ListView:
      case GridView:{
        return (_body as BoxScrollView).controller;
      }
      case SingleChildScrollView:
        return (_body as SingleChildScrollView).controller;
    }
    return null;
  }

  RectTween _header() => RectTween(
    begin: Rect.fromLTRB(0.0, -_headerBegin, 0.0, 0.0),
    end: Rect.fromLTRB(0.0, _headerEnd, 0.0, 0.0),
  );

  RectTween _footer() => RectTween(
    begin: Rect.fromLTRB(0.0, 0.0, 0.0, _footerBegin),
    end: Rect.fromLTRB(0.0, 0.0, 0.0, _footerEnd),
  );

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    _moveController?.dispose();
    _moveController = null;
    _scrollJudgment = null;
    super.dispose();
  }
}

class MoveController{
  final ValueNotifier<double> _notifier = ValueNotifier(0.0);
  final ValueNotifier<int> _state = ValueNotifier(0);
  String _code = '0';
  bool _isLoading = false;

  set loading(data) => _isLoading = data;

  bool get loading => _isLoading;

  set code(data) => _code = data;

  String get code => _code;

  set state(data) => _state.value = data;

  int get state => _state.value;

  double get value => _notifier.value;

  set value(data) => _notifier.value = data;

  addListener(VoidCallback callback) => _notifier.addListener(callback);

  removeListener(VoidCallback callback) => _notifier.removeListener(callback);

  addStateListener(VoidCallback callback) => _state.addListener(callback);

  removeStateListener(VoidCallback callback) => _state.removeListener(callback);

  dispose() {
    _notifier?.dispose();
    _state?.dispose();
  }
}

class ScrollJudgment {
  bool isRange,isRebound;
  ScrollJudgment(this.isRange,this.isRebound);
}

typedef Future<Null> OnCallback();

typedef RefreshBuilder = Function(BuildContext context);

typedef BodyBuilder = Function(BuildContext context,ScrollPhysics physics);