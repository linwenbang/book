import 'dart:convert';

import 'package:book/common/ReadSetting.dart';
import 'package:book/common/Screen.dart';
import 'package:book/common/common.dart';
import 'package:book/common/net.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

class Menu extends StatefulWidget {
  const Menu({Key key}) : super(key: key);
  @override
  _MenuState createState() => _MenuState();
}

enum Type { SLIDE, MORE_SETTING, DOWNLOAD }

class _MenuState extends State<Menu> {
  Type type = Type.SLIDE;
  ReadModel _readModel;
  ColorModel _colorModel;
  List<String> bgimg = [
    "QR_bg_1.jpg",
    "QR_bg_2.jpg",
    "QR_bg_3.jpg",
    "QR_bg_5.jpg",
    "QR_bg_7.png",
    "QR_bg_8.png",
    // "QR_bg_4.jpg",
  ];

  @override
  void initState() {
    super.initState();
    _readModel = Store.value<ReadModel>(context);
    _colorModel = Store.value<ColorModel>(context);
  }

  Widget head() {
    return Container(
      color: _colorModel.dark ? Color(0xFF1e1e1e) : Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 15.0),
      child: Row(
        children: [
          Text(
            '${_readModel?.book?.Name ?? ""}',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 22),
          ),
          // Spacer(),
          Expanded(
            child: Container(),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _readModel.reloadCurrentPage();
            },
          ),
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () async {
              _readModel.saveData();
              _readModel.clear();
              String url = Common.detail + '/${_readModel.book.Id}';
              Response future = await Util(context).http().get(url);
              var d = future.data['data'];
              BookInfo bookInfo = BookInfo.fromJson(d);

              Routes.navigateTo(context, Routes.detail,
                  params: {"detail": jsonEncode(bookInfo)});
            },
          )
        ],
      ),
    );
  }

  Widget midTranspant() {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: 0.0,
          child: Container(
            width: double.infinity,
          ),
        ),
        onTap: () {
          _readModel.toggleShowMenu();
          if (_readModel.font) {
            _readModel.reCalcPages();
          }
        },
      ),
    );
  }

  Widget chapterSilde() {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 15.0),
        child: Row(
          children: <Widget>[
            GestureDetector(
              child: Container(child: Text('上一章')),
              onTap: () async {
                _readModel.book.cur -= 1;
                await _readModel.intiPageContent(_readModel.book.cur, true);
                BotToast.showText(text: _readModel.curPage.chapterName);
              },
            ),
            Expanded(
              child: Container(
                child: Slider(
                  // activeColor: Colors.white,
                  // inactiveColor: Colors.white70,
                  value: _readModel.book.cur.toDouble(),
                  max: (_readModel.chapters.length - 1).toDouble(),
                  min: 0.0,
                  onChanged: (newValue) {
                    int temp = newValue.round();
                    _readModel.book.cur = temp;

                    _readModel.intiPageContent(_readModel.book.cur, true);
                  },
                  label: '${_readModel.chapters[_readModel.book.cur].name} ',
                  semanticFormatterCallback: (newValue) {
                    return '${newValue.round()} dollars';
                  },
                ),
              ),
            ),
            GestureDetector(
              child: Container(child: Text('下一章')),
              onTap: () async {
                _readModel.book.cur += 1;
                await _readModel.intiPageContent(_readModel.book.cur, true);
                BotToast.showText(text: _readModel.curPage.chapterName);
              },
            ),
          ],
        ));
  }

  Widget fontOperate(String imgName, func) {
    return Container(
      decoration: BoxDecoration(
          color: _colorModel.dark ? Color(0xFF1e1e1e) : Colors.white),
      height: 40,
      width: 140,
      margin: EdgeInsets.only(top: 15, bottom: 15),
      child: GestureDetector(
        onTap: func,
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(25.0)),
              border: Border.all(
                width: 1,
                color: _colorModel.dark ? Colors.white : Color(0xFF1e1e1e),
              )),
          alignment: Alignment(0, 0),
          child: ImageIcon(
            AssetImage(imgName),
          ),
        ),
      ),
    );
  }

  Widget downloadWidget() {
    return Container(
      decoration: BoxDecoration(
        color: _colorModel.dark ? Color(0xFF1e1e1e) : Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
      height: 70,
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                      color:
                          _colorModel.dark ? Color(0xFF1e1e1e) : Colors.white),
                  height: 40,
                  width: (Screen.width - 40) / 2,
                  margin: EdgeInsets.only(top: 15, bottom: 15),
                  child: GestureDetector(
                    onTap: () {
                      BotToast.showText(text: '从当前章节开始下载...');

                      _readModel.downloadAll(_readModel.book.cur);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(20.0)),
                          border: Border.all(
                            width: 1,
                            color: _colorModel.dark
                                ? Colors.white
                                : Color(0xFF1e1e1e),
                          )),
                      alignment: Alignment(0, 0),
                      child: Text(
                        '从当前章节缓存',
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                Container(
                  decoration: BoxDecoration(
                      color:
                          _colorModel.dark ? Color(0xFF1e1e1e) : Colors.white),
                  height: 40,
                  width: (Screen.width - 40) / 2,
                  margin: EdgeInsets.only(top: 15, bottom: 15),
                  child: GestureDetector(
                    onTap: () {
                      BotToast.showText(text: '开始全本下载...');

                      _readModel.downloadAll(0);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(25.0)),
                          border: Border.all(
                            width: 1,
                            color: _colorModel.dark
                                ? Colors.white
                                : Color(0xFF1e1e1e),
                          )),
                      alignment: Alignment(0, 0),
                      child: Text(
                        '全本缓存',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      padding: EdgeInsets.only(left: 15.0),
    );
  }

  Widget moreSetting() {
    return Container(
      decoration: BoxDecoration(
        color: _colorModel.dark ? Color(0xFF1e1e1e) : Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
      height: 130,
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                Container(
                  child: Center(
                    child: Text('字号', style: TextStyle(fontSize: 13.0)),
                  ),
                  height: 40,
                  width: 40,
                ),
                SizedBox(
                  width: 10,
                ),
                fontOperate("images/fontsmall.png", () {
                  ReadSetting.calcFontSize(-1.0);
                  _readModel.modifyFont();
                }),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.0),
                  child: Center(
                    child: Text(ReadSetting.getFontSize().toString(),
                        style: TextStyle(fontSize: 12.0)),
                  ),
                  height: 40,
                  width: 50,
                ),
                fontOperate("images/fontbig.png", () {
                  ReadSetting.calcFontSize(1.0);
                  _readModel.modifyFont();
                }),
                SizedBox(
                  width: 10,
                ),
                Container(
                  child: FlatButton(
                    onPressed: () {
                      Routes.navigateTo(
                        context,
                        Routes.fontSet,
                      );
                    },
                    child: Row(
                      children: [
                        Text(
                          '字体',
                          style: TextStyle(
                              color: _colorModel.dark
                                  ? Colors.white
                                  : Color(0xFF1e1e1e)),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                        )
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20.0))),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              child: ListView(
            children: bgThemes(),
            scrollDirection: Axis.horizontal,
          ))
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceAround,
          //   children: bgThemes(),
          // ),
        ],
      ),
      padding: EdgeInsets.only(left: 15.0),
    );
  }

  Widget bottomHead() {
    switch (type) {
      case Type.MORE_SETTING:
        return moreSetting();
        break;
      case Type.DOWNLOAD:
        return downloadWidget();
        break;
      default:
        return chapterSilde();
    }
  }

  Widget bottom() {
    return Container(
      decoration: BoxDecoration(
        color: _colorModel.dark ? Color(0xFF1e1e1e) : Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
      // height: 140,
      width: double.infinity,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            bottomHead(),
            buildBottomMenus(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        child: Column(
          children: <Widget>[
            _renderBar(),
            midTranspant(),
            bottom(),
          ],
        ),
      ),
      onTap: () {
        _readModel.toggleShowMenu();
      },
    );
  }

  _renderBar() {
    return Container(
      // color: _colorModel.dark ? Color(0xFF1e1e1e) : Colors.white,
      child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: _colorModel.dark ? Colors.white : Colors.black38,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              GestureDetector(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.refresh,
                    color: _colorModel.dark ? Colors.white : Colors.black38,
                  ),
                ),
                onTap: () {
                  _readModel.reloadCurrentPage();
                },
              ),
            ],
          )),
    );
  }

  buildBottomMenus() {
    return Theme(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          buildBottomItem('目录', Icons.menu),
          GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: ScreenUtil.getScreenW(context) / 4,
                padding: EdgeInsets.symmetric(vertical: 7),
                child: Column(
                  children: <Widget>[
                    ImageIcon(
                      _colorModel.dark
                          ? AssetImage("images/sun.png")
                          : AssetImage("images/moon.png"),
                      // color: Colors.white,
                    ),
                    SizedBox(height: 5),
                    Text(_colorModel.dark ? '日间' : '夜间',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              onTap: () {
                Store.value<ColorModel>(context).switchModel();
              }),
          buildBottomItem('缓存', Icons.cloud_download),
          buildBottomItem('设置', Icons.settings),
        ],
      ),
      data: _colorModel.theme,
    );
  }

  buildBottomItem(String title, IconData iconData) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: ScreenUtil.getScreenW(context) / 4,
        padding: EdgeInsets.symmetric(vertical: 7),
        child: Column(
          children: <Widget>[
            Icon(
              iconData,
              // color: Colors.white,
            ),
            SizedBox(height: 5),
            Text(title, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      onTap: () {
        print(title.toString());
        switch (title) {
          case '目录':
            {
              eventBus.fire(OpenChapters("dd"));

              _readModel.toggleShowMenu();
            }
            break;
          case '缓存':
            {
              setState(() {
                if (type == Type.DOWNLOAD) {
                  type = Type.SLIDE;
                } else {
                  type = Type.DOWNLOAD;
                }
              });
            }
            break;
          case '设置':
            {
              setState(() {
                if (type == Type.MORE_SETTING) {
                  type = Type.SLIDE;
                } else {
                  type = Type.MORE_SETTING;
                }
              });
            }
            break;
        }
      },
    );
  }

  List<Widget> bgThemes() {
    List<Widget> wds = [];
    wds.add(Container(
      width: 40.0,
      height: 40.0,
      child: Center(
        child: Text(
          '背景',
          style: TextStyle(fontSize: 13.0),
        ),
      ),
    ));
    for (var i = 0; i < bgimg.length; i++) {
      var f = "images/${bgimg[i]}";
      wds.add(RawMaterialButton(
        onPressed: () {
          setState(() {
            _readModel.switchBgColor(i);
          });
        },
        constraints: BoxConstraints(minWidth: 60.0, minHeight: 50.0),
        child: Container(
            margin: EdgeInsets.only(top: 5.0, bottom: 5.0),
            width: 45.0,
            height: 45.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(25.0)),
              border: Border.all(
                  width: 1.5,
                  color: _readModel.bgIdx == i
                      ? _colorModel.theme.primaryColor
                      : Colors.white10),
              image: DecorationImage(
                image: AssetImage(f),
                fit: BoxFit.cover,
              ),
            )),
      ));
    }
    wds.add(SizedBox(
      height: 8,
    ));
    return wds;
  }
}
