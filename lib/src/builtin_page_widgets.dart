part of timeconsuming_page_builder;

/// Widget used to show waiting to the user.
class BuiltInWaitingWidget extends StatefulWidget {
  BuiltInWaitingWidget({Key key, @required this.progressIndicatorValueColor})
      : super(key: key);

  final Animation<Color> Function(BuildContext context)
      progressIndicatorValueColor;

  @override
  _BuiltInWaitingWidgetState createState() => _BuiltInWaitingWidgetState();
}

class _BuiltInWaitingWidgetState extends State<BuiltInWaitingWidget>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    debugPrint("[WaitingWidget] initState");
    _controller = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
        animationBehavior: AnimationBehavior.preserve)
      ..forward();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.9, curve: Curves.fastOutSlowIn),
      reverseCurve: Curves.fastOutSlowIn,
    )..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          _controller.forward();
        } else if (status == AnimationStatus.completed) {
          _controller.reverse();
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("[WaitingWidget] build");
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(8),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) => CircularProgressIndicator(
              valueColor: widget.progressIndicatorValueColor(context),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    debugPrint("[WaitingWidget] dispose");
    _controller.stop();
    super.dispose();
  }
}

/// Widget used to show error to the user.
class BuiltInErrorWidget extends StatelessWidget {
  const BuiltInErrorWidget(
      {Key key, this.retryButtonText = 'retry', @required this.onRetryClick})
      : assert(onRetryClick != null),
        super(key: key);
  final String retryButtonText;
  final VoidCallback onRetryClick;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(8),
          child: FlatButton(
            child: Text(retryButtonText, style: TextStyle(fontSize: 20)),
            onPressed: onRetryClick,
          ),
        ),
      ),
    );
  }
}

/// Widget used to show empty to user, indicates that no content is displayed
/// to the user.
class BuiltInEmptyWidget extends StatelessWidget {
  const BuiltInEmptyWidget({Key key, this.emptyText = 'empty content'})
      : super(key: key);
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Text(emptyText, style: TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}
