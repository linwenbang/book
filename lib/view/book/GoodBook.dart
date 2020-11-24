import 'dart:convert';

import 'package:book/common/PicWidget.dart';
import 'package:book/common/common.dart';
import 'package:book/common/net.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/entity/GBook.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

class GoodBook extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return StateGoodBook();
  }
}

class StateGoodBook extends State<GoodBook>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  TabController controller;

  @override
  void initState() {
    super.initState();
    //initialIndex初始选中第几个
    controller = TabController(initialIndex: 0, length: 2, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ColorModel value = Store.value<ColorModel>(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
          appBar: AppBar(
            brightness: Brightness.light,
            backgroundColor: Colors.transparent,
            title: TabBar(
              unselectedLabelColor: Color(0xFF1e1e1e),
              labelColor: value.dark ? Colors.white : Color(0xFF1e1e1e),
              indicatorColor: Theme.of(context).primaryColor,
              indicatorSize: TabBarIndicatorSize.label,
              controller: controller,
              tabs: [
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    "男生",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    "女生",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
              labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: TabBarView(
            controller: controller,
            children: [TabItem("1"), TabItem("2")],
          )),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class TabItem extends StatefulWidget {
  final String type;

  TabItem(this.type);

  @override
  State<StatefulWidget> createState() {
    return StateTabItem();
  }
}

class StateTabItem extends State<TabItem>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  List<List<GBook>> values = [];
  List<String> keys = [];
  ColorModel value;

  @override
  void initState() {
    super.initState();
    getData();
  }

  Widget item(String title, List<GBook> bks) {
    return Container(
      padding: EdgeInsets.only(left: 12, right: 12),
      child: ListView(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: <Widget>[
          SizedBox(
            height: 5.0,
          ),
          Row(
            children: <Widget>[
              Padding(
                child: Store.connect<ColorModel>(
                    builder: (context, ColorModel data, child) {
                  return Container(
                    width: 4,
                    height: 20,
                    color: data.dark
                        ? data.theme.textTheme.body1.color
                        : data.theme.primaryColor,
                  );
                }),
                padding: EdgeInsets.only(left: 5.0, right: 3.0),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 14.0),
              ),
              Expanded(
                child: Container(),
              ),
              GestureDetector(
                child: Row(
                  children: <Widget>[
                    Text(
                      "更多",
                      style: TextStyle(color: Colors.grey, fontSize: 12.0),
                    ),
                    Icon(
                      Icons.keyboard_arrow_right,
                      color: Colors.grey,
                    )
                  ],
                ),
                onTap: () {
                  Routes.navigateTo(context, Routes.allTagBook,
                      params: {"title": title, "bks": jsonEncode(bks)});
                },
              )
            ],
          ),
          GridView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(5.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 1.0,
                crossAxisSpacing: 10.0,
                childAspectRatio: 0.5),
            children: bks.sublist(0, 8).map((item) => img(item)).toList(),
          )
        ],
      ),
    );
  }

  Widget img(GBook gbk) {
    return Column(
      children: <Widget>[
        GestureDetector(
          child: PicWidget(
            gbk.cover,
            width: (ScreenUtil.getScreenW(context) - 40) / 4,
            height: ((ScreenUtil.getScreenW(context) - 40) / 4) * 1.2,
          ),
          onTap: () async {
            String url = Common.two + '/${gbk.name}/${gbk.author}';
            Response future = await Util(context).http().get(url);
            var d = future.data['data'];
            if (d == null) {
              Routes.navigateTo(context, Routes.search, params: {
                "type": "book",
                "name": gbk.name,
              });
            } else {
              BookInfo bookInfo = BookInfo.fromJson(d);
              Routes.navigateTo(context, Routes.detail,
                  params: {"detail": jsonEncode(bookInfo)});
            }
          },
        ),
        SizedBox(height: 4),
        Text(
          gbk.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12),
        )
      ],
    );
  }

  getData() async {
    Map d;
    var key = Common.toplist + this.widget.type;
    var haveKey = SpUtil.haveKey(key);
    if (haveKey) {
      d = SpUtil.getObject(key);
      formatData(d);
    }
    String url = Common.rank + "/${this.widget.type}";
    Response future = await Util(null).http().get(url);
    d = future.data['data'];
    if (d != null) {
      SpUtil.putObject(key, d);
    }
    formatData(d);
  }

  void formatData(Map d) {
    var iterator2 = d.keys.iterator;
    while (iterator2.moveNext()) {
      keys.add(iterator2.current.toString());
    }
    var iterator3 = d.values.iterator;
    while (iterator3.moveNext()) {
      List temp = iterator3.current;
      values.add(temp.map((f) => GBook.fromJson(f)).toList());
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: values.length == 0
          ? Container()
          : ListView.builder(
              itemCount: keys.length,
              itemBuilder: (BuildContext context, int index) {
                return item(keys[index], values[index]);
              },
            ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
