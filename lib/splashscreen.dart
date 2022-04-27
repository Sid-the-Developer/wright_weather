import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wright_weather/listPage.dart';

class SplashPage extends StatefulWidget {
  SplashPage({Key? key}) : super(key: key);

  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController controller =
    AnimationController(vsync: this, duration: Duration(seconds: 1));

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Color(0xff24A4FE),
        statusBarIconBrightness: Brightness.light));

    controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed)
        Navigator.of(context).pushReplacement(SharedAxisPageRoute(
            MainPage(), transitionType: SharedAxisTransitionType.scaled));
    });
    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => Navigator.of(context).pushReplacement(SharedAxisPageRoute(
            MainPage(), transitionType: SharedAxisTransitionType.scaled)),
        child: Scaffold(
          backgroundColor: Color(0xff24A4FE),
          body: FadeTransition(
              opacity: controller.drive(Tween(begin: 0, end: 1.0)),
              child: SlideTransition(
                position: controller.drive(
                    Tween(begin: Offset(0, 0.1), end: Offset.zero)
                        .chain(CurveTween(curve: Curves.easeOutCirc))),
//          SizeTransition(
//            sizeFactor: CurvedAnimation(
//                curve: Curves.easeInToLinear, parent: controller),
//            axisAlignment: -1,
//            axis: Axis.horizontal,
                child: Center(
                  child: Image.asset(
                    'assets/wright_weather_logo.png',
                  ),
                ),
              )),
        ));
  }
}
