//library popup_menu;
import 'dart:core';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'triangle_painter.dart';

abstract class MenuItemProvider {
  String get menuTitle;
  Widget get menuImage;
  TextStyle get menuTextStyle;
  TextAlign get menuTextAlign;
}

class MenuItem extends MenuItemProvider {
  Widget image; // 图标名称
  String title; // 菜单标题
  var userInfo; // 额外的菜单荐信息
  TextStyle textStyle;
  TextAlign? textAlign;

  MenuItem(
      {required this.title,
      required this.image,
      this.userInfo,
      required this.textStyle,
      required this.textAlign});

  @override
  Widget get menuImage => image;

  @override
  String get menuTitle => title;

  @override
  TextStyle get menuTextStyle => textStyle;

  @override
  TextAlign get menuTextAlign => textAlign ?? TextAlign.center;
}

enum MenuType { big, oneLine }

typedef MenuClickCallback = Function(MenuItemProvider item);
typedef PopupMenuStateChanged = Function(bool isShow);

class PopupMenu {
  //static var itemWidth = 115.0;
  static var itemHeight = 45.0;
  static var arrowHeight = 12.0;
  late OverlayEntry _entry;
  late List<MenuItemProvider> items;

  late double _itemWidth;

  /// row count
  late int _row;

  /// col count
  late int _col;

  /// The left top point of this menu.
  late Offset _offset;

  /// Menu will show at above or under this rect
  late Rect _showRect;

  /// if false menu is show above of the widget, otherwise menu is show under the widget
  bool _isDown = true;

  /// The max column count, default is 4.
  int _maxColumn = 4;

  bool isReference = false;

  /// callback
  late VoidCallback dismissCallback;
  late MenuClickCallback onClickMenu;
  late PopupMenuStateChanged stateChanged;

  late Size _screenSize; // 屏幕的尺寸

  /// Cannot be null
  static late BuildContext context;

  /// style
  Color _backgroundColor = Color(0xff232323);
  Color _highlightColor = Color(0x55000000);
  Color _lineColor = Color(0xff353535);

  /// It's showing or not.
  bool _isShow = false;
  bool get isShow => _isShow;

  PopupMenu(
      {required MenuClickCallback onClickMenu,
      required BuildContext context,
      required VoidCallback onDismiss,
      required double itemWidth,
      required int maxColumn,
      required bool isReference,
      required Color backgroundColor,
      required Color highlightColor,
      required Color lineColor,
      required PopupMenuStateChanged stateChanged,
      required List<MenuItemProvider> items}) {
    this.onClickMenu = onClickMenu;
    this.dismissCallback = onDismiss;
    this._itemWidth = itemWidth;
    this.stateChanged = stateChanged;
    this.items = items;
    this._maxColumn = maxColumn;
    this.isReference = isReference;
    this._backgroundColor = backgroundColor;
    this._lineColor = lineColor;
    this._highlightColor = highlightColor;

    PopupMenu.context = context;
  }

  void show(
      {required Rect rect,
      required GlobalKey widgetKey,
      required List<MenuItemProvider> items}) {
    // if (rect == null && widgetKey == null) {
    //   print("'rect' and 'key' can't be both null");
    //   return;
    // }

    this.items = items;
    this._showRect = rect; // ?? PopupMenu.getWidgetGlobalRect(widgetKey);
    this._screenSize = window.physicalSize / window.devicePixelRatio;
    this.dismissCallback = dismissCallback;

    _calculatePosition(PopupMenu.context);

    _entry = OverlayEntry(builder: (context) {
      return buildPopupMenuLayout(_offset);
    });

    Overlay.of(PopupMenu.context)!.insert(_entry);
    _isShow = true;
    //if (this.stateChanged != null) {
    this.stateChanged(true);
    //}
  }

  static Rect getWidgetGlobalRect(GlobalKey key) {
    RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
    var offset = renderBox.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
        offset.dx, offset.dy, renderBox.size.width, renderBox.size.height);
  }

  void _calculatePosition(BuildContext context) {
    _col = _calculateColCount();
    _row = _calculateRowCount();
    _offset = _calculateOffset(PopupMenu.context);
  }

  Offset _calculateOffset(BuildContext context) {
    double dx = _showRect.left + _showRect.width / 2.0 - menuWidth() / 2.0;
    if (dx < 10.0) {
      dx = 10.0;
    }

    if (dx + menuWidth() > _screenSize.width && dx > 10.0) {
      double tempDx = _screenSize.width - menuWidth() - 10;
      if (tempDx > 10) dx = tempDx;
    }

    double dy = _showRect.top - menuHeight();
    if (dy <= MediaQuery.of(context).padding.top + 10) {
      // The have not enough space above, show menu under the widget.
      dy = arrowHeight + _showRect.height + _showRect.top;
      _isDown = false;
    } else {
      dy -= arrowHeight;
      _isDown = true;
    }

    return Offset(dx, dy);
  }

  double menuWidth() {
    return _itemWidth * _col;
  }

  // This height exclude the arrow
  double menuHeight() {
    return itemHeight * _row;
  }

  LayoutBuilder buildPopupMenuLayout(Offset offset) {
    return LayoutBuilder(builder: (context, constraints) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          dismiss();
        },
//        onTapDown: (TapDownDetails details) {
//          dismiss();
//        },
        // onPanStart: (DragStartDetails details) {
        //   dismiss();
        // },
        onVerticalDragStart: (DragStartDetails details) {
          dismiss();
        },
        onHorizontalDragStart: (DragStartDetails details) {
          dismiss();
        },
        child: Container(
          child: Stack(
            children: <Widget>[
              // triangle arrow
              Positioned(
                left: _showRect.left + _showRect.width / 2.0 - 7.5,
                top: _isDown
                    ? offset.dy + menuHeight()
                    : offset.dy - arrowHeight,
                child: CustomPaint(
                  size: Size(16.0, arrowHeight),
                  painter:
                      TrianglePainter(isDown: _isDown, color: _backgroundColor),
                ),
              ),
              // menu content
              Positioned(
                left: offset.dx,
                top: offset.dy,
                child: Container(
                  width: menuWidth(),
                  height: menuHeight(),
                  child: Column(
                    children: <Widget>[
                      ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Container(
                            width: menuWidth(),
                            height: menuHeight(),
                            decoration: BoxDecoration(
                                color: _backgroundColor,
                                borderRadius: BorderRadius.circular(8.0)),
                            child: Column(
                              children: _createRows(),
                            ),
                          )),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      );
    });
  }

  // 创建行
  List<Widget> _createRows() {
    List<Widget> rows = [];
    for (int i = 0; i < _row; i++) {
      Color color =
          (i < _row - 1 && _row != 1) ? _lineColor : Colors.transparent;
      Widget rowWidget = Container(
        decoration:
            BoxDecoration(border: Border(bottom: BorderSide(color: color))),
        height: itemHeight,
        child: Row(
          children: _createRowItems(i),
        ),
      );

      rows.add(rowWidget);
    }

    return rows;
  }

  // 创建一行的item,  row 从0开始算
  List<Widget> _createRowItems(int row) {
    List<MenuItemProvider> subItems =
        items.sublist(row * _col, min(row * _col + _col, items.length));
    List<Widget> itemWidgets = [];
    int i = 0;
    for (var item in subItems) {
      itemWidgets.add(_createMenuItem(
        item,
        i < (_col - 1),
      ));
      i++;
    }

    return itemWidgets;
  }

  // calculate row count
  int _calculateRowCount() {
    if (items.length == 0) {
      debugPrint('error menu items can not be null');
      return 0;
    }

    int itemCount = items.length;

    if (_calculateColCount() == 1) {
      return itemCount;
    }

    int row = (itemCount - 1) ~/ _calculateColCount() + 1;

    return row;
  }

  // calculate col count
  int _calculateColCount() {
    if (items.length == 0) {
      debugPrint('error menu items can not be null');
      return 0;
    }

    int itemCount = items.length;
    if (_maxColumn != 4 && _maxColumn > 0) {
      return _maxColumn;
    }

    if (itemCount == 4) {
      // 4个显示成两行
      return 2;
    }

    if (itemCount <= _maxColumn) {
      return itemCount;
    }

    if (itemCount == 5) {
      return 3;
    }

    if (itemCount == 6) {
      return 3;
    }

    return _maxColumn;
  }

  double get screenWidth {
    double width = window.physicalSize.width;
    double ratio = window.devicePixelRatio;
    return width / ratio;
  }

  Widget _createMenuItem(MenuItemProvider item, bool showLine) {
    return _MenuItemWidget(
      item: item,
      showLine: showLine,
      clickCallback: itemClicked,
      itemWidth: _itemWidth,
      lineColor: _lineColor,
      backgroundColor: _backgroundColor,
      highlightColor: _highlightColor,
    );
  }

  dynamic itemClicked(MenuItemProvider item) {
    //if (onClickMenu != null) {
    onClickMenu(item);
    //}

    dismiss();
  }

  void dismiss() {
    if (!_isShow) {
      // Remove method should only be called once
      return;
    }

    _entry.remove();
    _isShow = false;
    //if (dismissCallback != null) {
    dismissCallback();
    //}

    //if (this.stateChanged != null) {
    this.stateChanged(false);
    //}
  }
}

class _MenuItemWidget extends StatefulWidget {
  final MenuItemProvider item;
  // 是否要显示右边的分隔线
  final bool showLine;
  final bool isReference;
  final double itemWidth;
  final Color lineColor;
  final Color backgroundColor;
  final Color highlightColor;

  final Function(MenuItemProvider item) clickCallback;

  _MenuItemWidget(
      {required this.item,
      this.showLine = false,
      this.isReference = false,
      required this.itemWidth,
      required this.clickCallback,
      required this.lineColor,
      required this.backgroundColor,
      required this.highlightColor});

  @override
  State<StatefulWidget> createState() {
    return _MenuItemWidgetState();
  }
}

class _MenuItemWidgetState extends State<_MenuItemWidget> {
  Color highlightColor = Color(0x55000000);
  Color color = Color(0xff232323);

  @override
  void initState() {
    color = widget.backgroundColor;
    highlightColor = widget.highlightColor;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        color = highlightColor;
        setState(() {});
      },
      onTapUp: (details) {
        color = widget.backgroundColor;
        setState(() {});
      },
      onLongPressEnd: (details) {
        color = widget.backgroundColor;
        setState(() {});
      },
      onTap: () {
        //if (widget.clickCallback != null) {
        widget.clickCallback(widget.item);
        //}
      },
      child: Container(
          width: widget.itemWidth,
          height: PopupMenu.itemHeight,
          decoration: BoxDecoration(
              color: color,
              border: Border(
                  right: BorderSide(
                      color: widget.showLine
                          ? widget.lineColor
                          : Colors.transparent))),
          child: _createContent()),
    );
  }

  Widget _createContent() {
    //if (widget.item.menuImage != null) {
    // image and text
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        widget.isReference == true
            ? Container(
                margin: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.purpleAccent,
                    border: Border.all(width: 4),
                    backgroundBlendMode: BlendMode.exclusion),
                width: 26.0,
                height: 26.0,
                child: widget.item.menuImage,
              )
            : Container(
                margin: EdgeInsets.symmetric(horizontal: 8),
                width: 24.0,
                height: 24.0,
                child: widget.item.menuImage,
              ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 1),
          margin: EdgeInsets.only(right: 6),
          height: 22.0,
          child: Material(
            color: Colors.transparent,
            child: Text(
              widget.item.menuTitle,
              style: widget.item.menuTextStyle,
            ),
          ),
        )
      ],
    );
    // } else {
    //   // only text
    //   return Container(
    //     child: Center(
    //       child: Material(
    //         color: Colors.transparent,
    //         child: Text(
    //           widget.item.menuTitle,
    //           style: widget.item.menuTextStyle,
    //           textAlign: widget.item.menuTextAlign,
    //         ),
    //       ),
    //     ),
    //   );
    // }
  }
}
