import 'dart:convert';

import 'package:book/common/DbHelper.dart';
import 'package:book/common/PicWidget.dart';
import 'package:book/entity/Book.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/widgets/ConfirmDialog.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class BooksWidget extends StatefulWidget {
  final String type;
  BooksWidget(this.type);
  @override
  _BooksWidgetState createState() => _BooksWidgetState();
}

class _BooksWidgetState extends State<BooksWidget> {
  Widget body;
  RefreshController _refreshController;
  ShelfModel _shelfModel;
  bool isShelf;
  @override
  void initState() {
    isShelf = this.widget.type == '';
    _refreshController =
        RefreshController(initialRefresh: SpUtil.haveKey('auth') && isShelf);
    _shelfModel = Store.value<ShelfModel>(context);
    eventBus
        .on<SyncShelfEvent>()
        .listen((SyncShelfEvent booksEvent) => freshShelf());
    super.initState();
    var widgetsBinding = WidgetsBinding.instance;
    widgetsBinding.addPostFrameCallback((callback) {
      _shelfModel.context = context;
      _shelfModel.setShelf();
      if (isShelf) {
        _shelfModel.freshToken();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      enablePullDown: true,
      footer: CustomFooter(
        builder: (BuildContext context, LoadStatus mode) {
          if (mode == LoadStatus.idle) {
          } else if (mode == LoadStatus.loading) {
            body = CupertinoActivityIndicator();
          } else if (mode == LoadStatus.failed) {
            body = Text("加载失败！点击重试！");
          } else if (mode == LoadStatus.canLoading) {
            body = Text("松手,加载更多!");
          } else {
            body = Text("到底了!");
          }
          return Center(
            child: body,
          );
        },
      ),
      controller: _refreshController,
      onRefresh: freshShelf,
      child: _shelfModel.model ? coverModel() : listModel(),
    );
  }

  //刷新书架
  freshShelf() async {
    if (SpUtil.haveKey('auth')) {
      await _shelfModel.refreshShelf();
    }
    _refreshController.refreshCompleted();
  }

  //书架封面模式
  Widget coverModel() {
    return GridView(
      shrinkWrap: true,
      padding: EdgeInsets.all(10.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 5.0,
          crossAxisSpacing: 10.0,
          childAspectRatio: 0.8),
      children: cover(),
    );
  }

  List<Widget> cover() {
    List<Widget> wds = [];
    List<Book> books = _shelfModel.shelf;
    Book book;
    for (var i = 0; i < books.length; i++) {
      book = books[i];
      wds.add(GestureDetector(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Stack(
              alignment: AlignmentDirectional.topCenter,
              children: <Widget>[
                PicWidget(
                  book.Img,
                  width: (ScreenUtil.getScreenW(context) - 100) / 3,
                  height: ((ScreenUtil.getScreenW(context) - 100) / 3) * 1.2,
                ),
                book.NewChapterCount == 1
                    ? Container(
                        width: (ScreenUtil.getScreenW(context) - 100) / 3,
                        height:
                            ((ScreenUtil.getScreenW(context) - 100) / 3) * 1.2,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Image.asset(
                            'images/h6.png',
                            width: 30,
                            height: 30,
                          ),
                        ),
                      )
                    : Container(),
                this.widget.type == "sort"
                    ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: (ScreenUtil.getScreenW(context) - 80) / 3,
                          height:
                              ((ScreenUtil.getScreenW(context) - 80) / 3) * 1.2,
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Image.asset(
                              'images/pick.png',
                              color: !_shelfModel.picks(i)
                                  ? Colors.white
                                  : Store.value<ColorModel>(context)
                                      .theme
                                      .primaryColor,
                              width: 30,
                              height: 30,
                            ),
                          ),
                        ),
                        onTap: () {
                          _shelfModel.changePick(i);
                        },
                      )
                    : Container()
              ],
            ),
            Text(
              book.Name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          ],
        ),
        onTap: () async {
          await goRead(_shelfModel.shelf[i], i);
        },
        onLongPress: () {
          Routes.navigateTo(
            context,
            Routes.sortShelf,
          );
        },
      ));
    }

    return wds;
  }

  //书架列表模式
  Widget listModel() {
    return ListView.separated(
      itemCount: _shelfModel.shelf.length,
      itemBuilder: (context, i) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            await goRead(_shelfModel.shelf[i], i);
          },
          child: _renderBookItem(_shelfModel.shelf[i], i),
          onLongPress: () {
            Routes.navigateTo(
              context,
              Routes.sortShelf,
            );
          },
        );
      },
      separatorBuilder: (ctx, index) {
        return Padding(
          padding: EdgeInsets.only(left: 86, right: 12),
          child: Divider(
            height: 1,
          ),
        );
      },
    );
  }

  Future goRead(Book book, int i) async {
    Book b = await DbHelper.instance.getBook(book.Id);
    Routes.navigateTo(
      context,
      Routes.read,
      params: {
        'read': jsonEncode(b),
      },
    );
    _shelfModel.upTotop(b, i);
  }

  _renderBookItem(Book item, int i) {
    return Dismissible(
      key: Key(item.Id.toString()),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 16.0, top: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _renderImage(item),
                _renderTitle(item),
              ],
            ),
          ),
          Align(
              alignment: Alignment.topRight,
              child: this.widget.type == "sort"
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        // color: Colors.red,
                        margin: EdgeInsets.only(right: 20),
                        height: 115,
                        width: ScreenUtil.getScreenW(context),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Image.asset(
                            'images/pick.png',
                            color: !_shelfModel.picks(i)
                                ? Colors.white
                                : Store.value<ColorModel>(context)
                                    .theme
                                    .primaryColor,
                            width: 30,
                            height: 30,
                          ),
                        ),
                      ),
                      onTap: () {
                        _shelfModel.changePick(i);
                      },
                    )
                  : Container())
        ],
      ),
      onDismissed: (direction) {
        _shelfModel.modifyShelf(item);
      },
      background: Container(
        color: Colors.green,
        // 这里使用 ListTile 因为可以快速设置左右两端的Icon
        child: ListTile(
          leading: Icon(
            Icons.bookmark,
            color: Colors.white,
          ),
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        // 这里使用 ListTile 因为可以快速设置左右两端的Icon
        child: ListTile(
          trailing: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      confirmDismiss: (direction) async {
        var _confirmContent;

        var _alertDialog;

        if (direction == DismissDirection.endToStart) {
          // 从右向左  也就是删除
          _confirmContent = '确认删除     ${item.Name}';
          _alertDialog = ConfirmDialog(
            _confirmContent,
            () {
              // 展示 SnackBar
              Navigator.of(context).pop(true);
            },
            () {
              Navigator.of(context).pop(false);
            },
          );
        } else {
          return false;
        }
        var isDismiss = await showDialog(
            context: context,
            builder: (context) {
              return _alertDialog;
            });
        return isDismiss;
      },
    );
  }

  Column _renderTitle(Book item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Container(
          width: ScreenUtil.getScreenW(context) - 115,
          padding: const EdgeInsets.only(left: 10.0, top: 8.0),
          child: Text(
            item.Name,
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 10.0, top: 4),
          child: Text(
            item.LastChapter,
            style: TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          width: ScreenUtil.getScreenW(context) - 115,
        ),
        Container(
          padding: const EdgeInsets.only(left: 10.0, top: 6.0),
          child: Text(item?.UTime ?? '',
              style: TextStyle(color: Colors.grey, fontSize: 11)),
        ),
      ],
    );
  }

  Column _renderImage(Book item) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Container(
          child: Stack(
            children: <Widget>[
              PicWidget(
                item.Img,
                width: 55,
                height: 77,
              ),
              if (item.NewChapterCount == 1)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Image.asset(
                    'images/h6.png',
                    width: 30,
                    height: 30,
                  ),
                ),
            ],
          ),
        )
      ],
    );
  }
}
