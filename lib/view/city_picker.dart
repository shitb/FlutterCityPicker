import 'package:flutter/material.dart';
import 'package:lpinyin/lpinyin.dart';

import '../city_picker.dart';
import '../listener/item_listener.dart';
import '../model/address.dart';
import '../model/section_city.dart';
import '../model/tab.dart';
import '../view/item_widget.dart';
import 'inherited_widget.dart';
import 'layout_delegate.dart';

/// 省市区选择器
///
/// 从服务器获取数据
///
class CityPickerWidget extends StatefulWidget {
  /// 组件高度
  final double? height;

  /// 标题高度
  final double? titleHeight;

  /// 顶部圆角
  final double? corner;

  /// 左边间距
  final double? paddingLeft;

  /// 标题样式
  final Widget? titleWidget;

  /// 选择文字
  final String? selectText;

  /// 关闭图标组件
  final Widget? closeWidget;

  /// tab 高度
  final double? tabHeight;

  /// 是否显示 indicator
  final bool? showTabIndicator;

  /// indicator 颜色
  final Color? tabIndicatorColor;

  /// indicator 高度
  final double? tabIndicatorHeight;

  /// label 文字大小
  final double? labelTextSize;

  /// 选中 label 颜色
  final Color? selectedLabelColor;

  /// 未选中 label 颜色
  final Color? unselectedLabelColor;

  /// item 头部高度
  final double? itemHeadHeight;

  /// item 头部背景颜色
  final Color? itemHeadBackgroundColor;

  /// item 头部分割线颜色
  final Color? itemHeadLineColor;

  /// item 头部分割线高度
  final double? itemHeadLineHeight;

  /// item 头部文字样式
  final TextStyle? itemHeadTextStyle;

  /// item 高度
  final double? itemHeight;

  /// 索引组件宽度
  final double? indexBarWidth;

  /// 索引组件 item 高度
  final double? indexBarItemHeight;

  /// 索引组件背景颜色
  final Color? indexBarBackgroundColor;

  /// 索引组件文字样式
  final TextStyle? indexBarTextStyle;

  /// 选中城市的图标组件
  final Widget? itemSelectedIconWidget;

  /// 选中城市文字样式
  final TextStyle? itemSelectedTextStyle;

  /// 未选中城市文字样式
  final TextStyle? itemUnSelectedTextStyle;

  /// 初始值
  final List<AddressNode>? initialAddress;

  /// 监听事件
  final CityPickerListener? cityPickerListener;

  CityPickerWidget({
    this.height,
    this.titleHeight,
    this.corner,
    this.paddingLeft,
    this.titleWidget,
    this.selectText,
    this.closeWidget,
    this.tabHeight,
    this.showTabIndicator,
    this.tabIndicatorColor,
    this.tabIndicatorHeight,
    this.labelTextSize,
    this.selectedLabelColor,
    this.unselectedLabelColor,
    this.itemHeadHeight,
    this.itemHeadBackgroundColor,
    this.itemHeadLineColor,
    this.itemHeadLineHeight,
    this.itemHeadTextStyle,
    this.itemHeight,
    this.indexBarWidth,
    this.indexBarItemHeight,
    this.indexBarBackgroundColor,
    this.indexBarTextStyle,
    this.itemSelectedIconWidget,
    this.itemSelectedTextStyle,
    this.itemUnSelectedTextStyle,
    this.initialAddress,
    required this.cityPickerListener,
  });

  @override
  State<StatefulWidget> createState() => CityPickerState();
}

class CityPickerState extends State<CityPickerWidget>
    with TickerProviderStateMixin
    implements ItemClickListener {
  TabController? _tabController;
  PageController? _pageController;

  // 列表数据
  Map<int, List<SectionCity>> _mData = {};

  // 中间 tab
  List<TabTitle> _myTabs = [];

  // 当前索引
  int _currentIndex = 0;

  // 已选择的数据
  List<AddressNode> _selectData = [];

  @override
  void initState() {
    super.initState();

    if (widget.initialAddress != null && widget.initialAddress!.length > 0) {
      _currentIndex = widget.initialAddress!.length - 1;
      _mData[_currentIndex] = [];
      for (int i = 0; i < widget.initialAddress!.length; i++) {
        _myTabs.add(TabTitle(index: i, title: widget.initialAddress![i].name));
        if (i != widget.initialAddress!.length - 1) {
          _selectData.add(AddressNode(
              code: widget.initialAddress![i].code,
              name: widget.initialAddress![i].name));
        }
      }
      _tabController = TabController(
          vsync: this, length: _myTabs.length, initialIndex: _currentIndex);
      _pageController = PageController(initialPage: _currentIndex);
      for (int i = 0; i < widget.initialAddress!.length; i++) {
        if (i == 0) {
          widget.cityPickerListener!.onDataLoad(i, "", "").then((value) {
            List<SectionCity> list = sortCity(value);
            _mData[i] = list;
            if (mounted) {
              setState(() {});
            }
          });
        } else {
          widget.cityPickerListener!
              .onDataLoad(i, widget.initialAddress![i - 1].code!,
                  widget.initialAddress![i - 1].name!)
              .then((value) {
            List<SectionCity> list = sortCity(value);
            _mData[i] = list;
            if (mounted) {
              setState(() {});
            }
          });
        }
      }
    } else {
      widget.cityPickerListener!
          .onDataLoad(_currentIndex, "", "")
          .then((value) {
        List<SectionCity> list = sortCity(value);
        if (list.length <= 0) {
          widget.cityPickerListener!.onFinish(_selectData);
          Navigator.pop(context);
        } else {
          _mData[_currentIndex] = list;
          _myTabs.add(TabTitle(
              index: _currentIndex, title: widget.selectText ?? "请选择"));
          _tabController = TabController(
              vsync: this, length: _myTabs.length, initialIndex: _currentIndex);
          if (mounted) {
            setState(() {});
          }
        }
      });
      _tabController = TabController(vsync: this, length: _myTabs.length);
      _pageController = PageController();
    }
  }

  @override
  void dispose() {
    if (mounted) {
      _tabController!.dispose();
      _pageController!.dispose();
    }
    super.dispose();
  }

  /// 排序数据
  List<SectionCity> sortCity(List<AddressNode> value) {
    // 先排序
    List<AddressNode> _cityList = [];
    value.forEach((city) {
      String letter = PinyinHelper.getFirstWordPinyin(city.name!)
          .substring(0, 1)
          .toUpperCase();
      _cityList
          .add(AddressNode(code: city.code, letter: letter, name: city.name));
    });
    _cityList.sort((a, b) => a.letter!.compareTo(b.letter!));
    // 组装数据
    List<SectionCity> _sectionList = [];
    String? _letter = "A";
    List<AddressNode> _cityList2 = [];
    for (int i = 0; i < _cityList.length; i++) {
      if (_letter == _cityList[i].letter) {
        _cityList2.add(_cityList[i]);
      } else {
        if (_cityList2.length > 0) {
          _sectionList.add(SectionCity(letter: _letter, data: _cityList2));
        }
        _cityList2 = [];
        _cityList2.add(_cityList[i]);
        _letter = _cityList[i].letter;
      }
      if (i == _cityList.length - 1) {
        if (_cityList2.length > 0) {
          _sectionList.add(SectionCity(letter: _letter, data: _cityList2));
        }
      }
    }
    return _sectionList;
  }

  @override
  void onItemClick(int tabIndex, String name, String code) {
    // 点击永远是移动到下一个 tab
    _currentIndex++;
    // 先把后面的全部删除
    if (_selectData.length >= _currentIndex) {
      _selectData.removeRange(_currentIndex - 1, _selectData.length);
      _myTabs.removeRange(_currentIndex - 1, _myTabs.length - 1);
      _tabController = TabController(
          vsync: this, length: _myTabs.length, initialIndex: _currentIndex - 1);
      if (mounted) {
        setState(() {});
      }
    }

    _selectData.insert(_currentIndex - 1, AddressNode(code: code, name: name));
    widget.cityPickerListener!
        .onDataLoad(_currentIndex, code, name)
        .then((value) {
      List<SectionCity> list = sortCity(value);
      if (list.length <= 0) {
        widget.cityPickerListener!.onFinish(_selectData);
        Navigator.pop(context);
      } else {
        _mData[_currentIndex] = list;
        _myTabs.elementAt(_currentIndex - 1).title =
            _selectData[_currentIndex - 1].name;
        _myTabs.add(
            TabTitle(index: _currentIndex, title: widget.selectText ?? "请选择"));
        _tabController = TabController(
            vsync: this, length: _myTabs.length, initialIndex: _currentIndex);
        _pageController!.animateToPage(_currentIndex,
            duration: Duration(milliseconds: 10), curve: Curves.linear);
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final route = CustomInheritedWidget.of(context)!.router;
    return AnimatedBuilder(
      animation: route.animation!,
      builder: (BuildContext context, Widget? child) => CustomSingleChildLayout(
          delegate: CustomLayoutDelegate(
              progress: route.animation!.value, height: widget.height),
          child: Material(
            color: Colors.transparent,
            child: Container(
                width: double.infinity,
                child: Column(children: <Widget>[
                  _topTextWidget(),
                  Expanded(
                    child: Container(
                      color: Theme.of(context).dialogBackgroundColor,
                      child: Column(children: <Widget>[
                        _middleTabWidget(),
                        Expanded(child: _bottomListWidget())
                      ]),
                    ),
                  )
                ])),
          )),
    );
  }

  /// 头部文字组件
  Widget _topTextWidget() {
    return Container(
      height: widget.titleHeight,
      decoration: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(widget.corner!),
              topRight: Radius.circular(widget.corner!))),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            widget.titleWidget ??
                Container(
                  padding: EdgeInsets.only(left: widget.paddingLeft!),
                  child: Text(
                    '请选择所在地区',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            InkWell(
                onTap: () => {Navigator.pop(context)},
                child: Container(
                  width: widget.titleHeight,
                  height: double.infinity,
                  child: widget.closeWidget ?? Icon(Icons.close, size: 26),
                )),
          ]),
    );
  }

  /// 中间 tab 组件
  Widget _middleTabWidget() {
    return Container(
      width: double.infinity,
      height: widget.tabHeight,
      color: Theme.of(context).dialogBackgroundColor,
      child: TabBar(
        controller: _tabController,
        onTap: (index) {
          _currentIndex = index;
          if (mounted) {
            setState(() {});
          }
          _pageController!.animateToPage(_currentIndex,
              duration: Duration(milliseconds: 10), curve: Curves.linear);
        },
        isScrollable: true,
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.only(left: widget.paddingLeft!),
        indicator: widget.showTabIndicator!
            ? UnderlineTabIndicator(
                insets: EdgeInsets.only(left: widget.paddingLeft!),
                borderSide: BorderSide(
                    width: widget.tabIndicatorHeight!,
                    color: widget.tabIndicatorColor ??
                        Theme.of(context).primaryColor),
              )
            : BoxDecoration(),
        indicatorColor:
            widget.tabIndicatorColor ?? Theme.of(context).primaryColor,
        unselectedLabelColor: widget.unselectedLabelColor ?? Colors.black54,
        labelColor: widget.selectedLabelColor ?? Theme.of(context).primaryColor,
        tabs: _myTabs.map((data) {
          return Text(data.title!,
              style: TextStyle(fontSize: widget.labelTextSize));
        }).toList(),
      ),
    );
  }

  /// 底部城市列表组件
  Widget _bottomListWidget() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        _currentIndex = index;
        if (mounted) {
          setState(() {});
        }
        _tabController!.animateTo(_currentIndex);
      },
      children: _myTabs.map((tab) {
        return ItemWidget(
          height: widget.height! - widget.titleHeight! - widget.tabHeight!,
          index: tab.index,
          list: _mData[tab.index],
          title: tab.title,
          selectText: widget.selectText,
          paddingLeft: widget.paddingLeft,
          itemHeadHeight: widget.itemHeadHeight,
          itemHeadBackgroundColor: widget.itemHeadBackgroundColor,
          itemHeadLineColor: widget.itemHeadLineColor,
          itemHeadLineHeight: widget.itemHeadLineHeight,
          itemHeadTextStyle: widget.itemHeadTextStyle,
          itemHeight: widget.itemHeight,
          indexBarWidth: widget.indexBarWidth,
          indexBarItemHeight: widget.indexBarItemHeight,
          indexBarBackgroundColor: widget.indexBarBackgroundColor,
          indexBarTextStyle: widget.indexBarTextStyle,
          itemSelectedIconWidget: widget.itemSelectedIconWidget,
          itemSelectedTextStyle: widget.itemSelectedTextStyle,
          itemUnSelectedTextStyle: widget.itemUnSelectedTextStyle,
          itemClickListener: this,
        );
      }).toList(),
    );
  }
}
