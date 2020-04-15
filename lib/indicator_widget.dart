import 'package:flutter/material.dart';
import 'refresh_convenient.dart';
import 'local_description.dart';

class IndicatorWidget extends StatefulWidget{
  final MoveController controller;
  final IconData iconData;
  final double height,iconSize,widgetHeight;
  final TextStyle timeStyle,descriptionStyle;
  final LocalDescription localDescription;
  final bool isPullUp;
  IndicatorWidget(
      this.controller,
      this.height,
      this.iconData,{
        Key key,
        this.isPullUp = true,
        this.timeStyle,
        this.localDescription,
        this.descriptionStyle,
        this.widgetHeight = 40.0,
        this.iconSize = 28.0
      }): super(key : key);
  createState() => IndicatorWidgetState();
}

class IndicatorWidgetState extends State<IndicatorWidget> with TickerProviderStateMixin{
  AnimationController _container;
  Tween<double> _tween;
  bool _isUp = false;
  String _refreshTime,_description;
  TextStyle _timeStyle,_descriptionStyle;
  LocalDescription _localDescription;

  @override
  void initState() {
    super.initState();
    _container = AnimationController(vsync: this);
    _tween = Tween<double>(begin: 0.0, end: 1.0);
    _tween.animate(_container);
    _timeStyle = widget.timeStyle ?? TextStyle(color: Colors.black54,fontSize: 14.0);
    _descriptionStyle = widget.descriptionStyle ?? TextStyle(color: Colors.black54,fontSize: 15.0);
    _localDescription = widget.localDescription ?? LocalDescription(
        refreshTime: '最近更新',
        unload: '松开加载',
        pullDown: '下拉刷新',
        pullUpload: '上拉加载',
        updating: '正在更新',
        noMore: '没有更多数据了=͟͞(꒪ᗜ꒪‧̣̥̇)'
    );
    _currentTime();
    widget.controller.addListener(_callback);
    widget.controller.addStateListener(_stateCallback);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      height: widget.height,
      child: widget.controller.state == - 1 ? _noMoreData() : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
              alignment: Alignment.center,
              height: widget.widgetHeight,
              child: widget.controller.state == 2 ? SizedBox(
                  width: widget.iconSize,
                  height: widget.iconSize,
                  child: CircularProgressIndicator(backgroundColor: Colors.grey)
              ) :
              RotationTransition(
                  turns: _container,
                  child: Icon(widget.iconData,color: Colors.grey,size: widget.iconSize))
          ),
          Padding(
              padding: EdgeInsets.only(left: 5.0),
              child: SizedBox(
                  height: widget.widgetHeight,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: Text(_description,style: _descriptionStyle)),
                        Expanded(child: Text('${_localDescription.refreshTime}$_refreshTime',style: _timeStyle))
                      ]
                  )
              )
          )
        ],
      ),
    );
  }

  _noMoreData() => Text(_localDescription.noMore,style: _descriptionStyle);

  _currentTime(){
    var date = DateTime.now();
    String h = _format(date.hour);
    String m = _format(date.minute);
    _refreshTime = "$h:$m";
    _description = widget.isPullUp ? _localDescription.pullDown : _localDescription.pullUpload;
  }

  String _format(int time) => time >= 10 ? '$time' : '0$time';

  _stateCallback(){
    switch(widget.controller.state){
      case 0:
        _currentTime();
        break;
      case 1:
        _description = _localDescription.unload;
        break;
      case 2:
        _description = _localDescription.updating;
        break;
    }
    if (mounted)
      setState(() {});
  }

  _callback(){
    if (widget.controller.value >= widget.height && !_isUp){
      _container.animateTo(0.5,
          duration: Duration(milliseconds: 300), curve: Curves.ease);
      _isUp = true;
    }
    if (widget.controller.value < widget.height && _isUp) {
      _container.animateTo(0.0,
          duration: Duration(milliseconds: 300), curve: Curves.ease);
      _isUp = false;
    }
  }

  @override
  void didUpdateWidget(IndicatorWidget oldWidget) {
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_callback);
      widget.controller.addListener(_callback);
      oldWidget.controller.removeStateListener(_stateCallback);
      widget.controller.addStateListener(_stateCallback);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_callback);
    widget.controller.removeStateListener(_stateCallback);
    _container?.dispose();
    _container = null;
    _tween = null;
    _refreshTime = null;
    _description = null;
    super.dispose();
  }
}