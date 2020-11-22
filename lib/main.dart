import 'dart:io';

import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ShelfModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/service/TelAndSmsService.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/book/BookShelf.dart';
import 'package:book/view/book/GoodBook.dart';
import 'package:book/view/movie/MovieRecord.dart';
import 'package:book/view/movie/Video.dart';
import 'package:book/view/person/Me.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:fluro/fluro.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';

GetIt locator = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (await Permission.storage.request().isGranted) {
    await SpUtil.getInstance();

    locator.registerSingleton(TelAndSmsService());
    final router = FluroRouter();
    Routes.configureRoutes(router);
    Routes.router = router;
    runApp(Store.init(child: MyApp()));
    await DirectoryUtil.getInstance();

    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle =
          SystemUiOverlayStyle(statusBarColor: Colors.transparent);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    } else { 
      
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Store.connect<ColorModel>(
      builder: (context, ColorModel model, child) {
        return MaterialApp(
          title: '瞎看',
          home: MainPage(),
          builder: BotToastInit(),
          navigatorObservers: [BotToastNavigatorObserver(), RouterObserver()],
          onGenerateRoute: Routes.router.generator,
          theme: model.theme, // 配置route generate
        );
      },
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _tabIndex = 0;
  bool isMovie = false;
  static final GlobalKey<ScaffoldState> q = new GlobalKey();
  var _pageController = PageController();
  List<BottomNavigationBarItem> bottoms = [
    BottomNavigationBarItem(
      icon: ImageIcon(
        AssetImage("images/book_shelf.png"),
        size: 26,
      ),
      label: '书架',
    ),
    BottomNavigationBarItem(
      icon: ImageIcon(
        AssetImage("images/good.png"),
        size: 26,
      ),
      label: '精选',
    ),
    BottomNavigationBarItem(
      icon: ImageIcon(
        AssetImage("images/video.png"),
        size: 26,
      ),
      label: '美剧',
    ),
    // BottomNavigationBarItem(
    //   icon: ImageIcon(
    //     AssetImage("images/video.png"),
    //   ),
    //   label: '美剧',
    // ),
  ];
  imgIcon(String src, String title) {
    return BottomNavigationBarItem(
      icon: ImageIcon(
        AssetImage(src),
        size: 25,
      ),
      label: title,
    );
  }

  /*
   * 存储的四个页面，和Fragment一样
   */
  var _pages = [BookShelf(), GoodBook(), Video()];

  @override
  void initState() {
    super.initState();
    eventBus.on<OpenEvent>().listen((openEvent) {
      if (openEvent.name == "m") {
        isMovie = true;
      } else {
        isMovie = false;
      }
      if (mounted) {
        setState(() {});
      }
      q.currentState.openDrawer();
    });
    eventBus.on<NavEvent>().listen((navEvent) {
      _pageController.jumpToPage(navEvent.idx);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Store.connect<ColorModel>(
        builder: (context, ColorModel model, child) {
      return Theme(
        child: Store.connect<ShelfModel>(
            builder: (context, ShelfModel shelfModel, child) {
          return Scaffold(
            drawer: Drawer(
              child: isMovie ? MovieRecord() : Me(),
            ),
            key: q,
            body: PageView.builder(
                //要点1
                physics: NeverScrollableScrollPhysics(),
                //禁止页面左右滑动切换
                controller: _pageController,
                onPageChanged: _pageChanged,
                //回调函数
                itemCount: _pages.length,
                itemBuilder: (context, index) => _pages[index]),
            bottomNavigationBar: BottomNavigationBar(
              unselectedItemColor:
                  model.dark ? Colors.white : Color(0xFF1e1e1e),
              elevation: 0,
              items: bottoms,
              type: BottomNavigationBarType.fixed,
              currentIndex: _tabIndex,
              onTap: (index) {
                _pageController.jumpToPage(index);
              },
            ),
          );
        }),
        data: model.theme,
      );
    });
  }

  void _pageChanged(int index) {
    setState(() {
      if (_tabIndex != index) _tabIndex = index;
    });
  }
}
