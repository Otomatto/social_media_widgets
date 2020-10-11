import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:social_media_widgets/insta_swipe_controller.dart';

class InstagramStorySwipe extends StatefulWidget {
  final List<Widget> children;
  final int initialPage;
  final InstagramSwipeController instagramSwipeController;

  InstagramStorySwipe({
    @required this.children,
    this.initialPage = 0,
    this.instagramSwipeController,
  }) {
    assert(children != null);
    assert(children.length != 0);
  }

  @override
  _InstagramStorySwipeState createState() => _InstagramStorySwipeState();
}

class _InstagramStorySwipeState extends State<InstagramStorySwipe> {
  PageController _pageController;
  double currentPageValue = 0.0;

  Timer timer;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: widget.initialPage);
    _pageController.addListener(() {
      setState(() {
        currentPageValue = _pageController.page;
      });
    });

    if (widget.instagramSwipeController != null) {
      widget.instagramSwipeController.pageController = _pageController;
    }

    timer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (_pageController.page < widget.children.length - 1) {
        _pageController.nextPage(
            duration: Duration(milliseconds: 500), curve: Curves.linear);
      } else {
        Navigator.pop(context);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();

    _pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        double value;
        if (_pageController.position.haveDimensions == false) {
          value = index.toDouble();
        } else {
          value = _pageController.page;
        }
        return Stack(children: [
          GestureDetector(
            onTapDown: (TapDownDetails details) {},
            onTapUp: (TapUpDetails details) {
              if (MediaQuery.of(context).size.width / 2 <
                  details.localPosition.dx) {
                if (_pageController.page < widget.children.length - 1) {
                  _pageController.nextPage(
                      duration: Duration(milliseconds: 500),
                      curve: Curves.linear);
                } else {
                  Navigator.pop(context);
                }
              } else {
                if (_pageController.page - 1 >= 0) {
                  _pageController.previousPage(
                      duration: Duration(milliseconds: 500),
                      curve: Curves.linear);
                }
              }
            },
            child: _SwipeWidget(
              lenght: widget.children.length,
              index: index,
              pageNotifier: value,
              child: widget.children[index],
            ),
          ),
        ]);
      },
    );
  }
}

num degToRad(num deg) => deg * (pi / 180.0);

class _SwipeWidget extends StatelessWidget {
  final int index;
  final int lenght;

  final double pageNotifier;

  final Widget child;

  const _SwipeWidget({
    Key key,
    @required this.index,
    @required this.pageNotifier,
    @required this.child,
    this.lenght,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLeaving = (index - pageNotifier) <= 0;
    final t = (index - pageNotifier);
    final rotationY = lerpDouble(0, 90, t);
    final opacity = lerpDouble(0, 1, t.abs()).clamp(0.0, 1.0);
    final transform = Matrix4.identity();
    transform.setEntry(3, 2, 0.001);
    transform.rotateY(-degToRad(rotationY));
    return Transform(
      alignment: isLeaving ? Alignment.centerRight : Alignment.centerLeft,
      transform: transform,
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: Opacity(
              opacity: opacity,
              child: SizedBox.shrink(),
            ),
          ),
          SafeArea(
            child: StoryProgress(
              index: index,
              lenght: lenght,
            ),
          ),
        ],
      ),
    );
  }
}

class StoryProgress extends StatefulWidget {
  final int lenght;
  final int index;

  const StoryProgress({Key key, this.lenght, this.index}) : super(key: key);

  @override
  _StoryProgressState createState() => _StoryProgressState();
}

class _StoryProgressState extends State<StoryProgress>
    with SingleTickerProviderStateMixin {
  double animatedValue = 0;
  AnimationController controller;

  List<Widget> children() {
    List<Widget> list = [];
    for (var i = 0; i < widget.lenght; i++) {
      double value = i < widget.index ? 1 : 0;
      if (widget.index == i) {
        list.add(Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: StoryProgressIndicator(animatedValue),
            )));
      } else {
        list.add(Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: StoryProgressIndicator(value),
            )));
      }
    }
    return list;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    controller.forward();
    controller.addListener(() {
      setState(() {
        animatedValue = controller.value;
      });
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: children(),
    );
  }
}

/// Custom progress bar. Supposed to be lighter than the
/// original [ProgressIndicator], and rounded at the sides.
class StoryProgressIndicator extends StatelessWidget {
  /// From `0.0` to `1.0`, determines the progress of the indicator
  final double value;
  final double indicatorHeight;

  StoryProgressIndicator(
    this.value, {
    this.indicatorHeight = 5,
  }) : assert(indicatorHeight != null && indicatorHeight > 0,
            "[indicatorHeight] should not be null or less than 1");

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.fromHeight(
        this.indicatorHeight,
      ),
      foregroundPainter: IndicatorOval(
        Colors.white.withOpacity(0.8),
        this.value,
      ),
      painter: IndicatorOval(
        Colors.white.withOpacity(0.4),
        1.0,
      ),
    );
  }
}

class IndicatorOval extends CustomPainter {
  final Color color;
  final double widthFactor;

  IndicatorOval(this.color, this.widthFactor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = this.color;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width * this.widthFactor, size.height),
            Radius.circular(3)),
        paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
