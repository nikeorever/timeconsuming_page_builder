part of timeconsuming_page_builder;

typedef RetryCaller = void Function();

typedef WaitingWidgetBuilder = Widget Function(BuildContext context);

typedef ErrorWidgetBuilder = Widget Function(
    BuildContext context, RetryCaller caller);

typedef DataWidgetBuilder<T> = Widget Function(BuildContext context, T data);

typedef FutureBuilder<T> = Future<T> Function();

class TimeConsumingPage<T> extends StatefulWidget {
  static AsyncWidgetBuilder<T> _asyncWidgetBuilder<T>({
    @required WaitingWidgetBuilder waitingWidgetBuilder,
    @required ErrorWidgetBuilder errorWidgetBuilder,
    @required DataWidgetBuilder<T> dataWidgetBuilder,
  }) {
    return (BuildContext context, AsyncSnapshot<T> snapshot) {
      debugPrint("[TimeConsumingPage] $snapshot");
      Widget child;
      if (snapshot.hasData) {
        child = dataWidgetBuilder(context, snapshot.data);
      } else if (snapshot.hasError) {
        child = errorWidgetBuilder(context, () {
          final state =
              (context as StatefulElement).state as _TimeConsumingPageState;
          state.resubscribe();
        });
      } else {
        child = waitingWidgetBuilder(context);
      }
      return child;
    };
  }

  TimeConsumingPage({
    Key key,
    this.initialData,
    @required this.futureBuilder,
    @required WaitingWidgetBuilder waitingWidgetBuilder,
    @required ErrorWidgetBuilder errorWidgetBuilder,
    @required DataWidgetBuilder<T> dataWidgetBuilder,
  })  : assert(futureBuilder != null),
        assert(waitingWidgetBuilder != null),
        assert(errorWidgetBuilder != null),
        assert(dataWidgetBuilder != null),
        builder = _asyncWidgetBuilder(
            waitingWidgetBuilder: waitingWidgetBuilder,
            errorWidgetBuilder: errorWidgetBuilder,
            dataWidgetBuilder: dataWidgetBuilder),
        super(key: key);

  final FutureBuilder<T> futureBuilder;

  final AsyncWidgetBuilder<T> builder;

  final T initialData;

  @override
  State<TimeConsumingPage<T>> createState() => _TimeConsumingPageState<T>();
}

/// State for [TimeConsumingPage].
class _TimeConsumingPageState<T> extends State<TimeConsumingPage<T>> {
  Object _activeCallbackIdentity;
  AsyncSnapshot<T> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot =
        AsyncSnapshot<T>.withData(ConnectionState.none, widget.initialData);
    _subscribe();
  }

  @override
  void didUpdateWidget(TimeConsumingPage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.futureBuilder != widget.futureBuilder) {
      if (_activeCallbackIdentity != null) {
        _unsubscribe();
        _snapshot = _snapshot.inState(ConnectionState.none);
      }
      _subscribe();
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _snapshot);

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void resubscribe() {
    if (_activeCallbackIdentity != null) {
      _unsubscribe();
      _snapshot =
          AsyncSnapshot<T>.withData(ConnectionState.none, widget.initialData);
    }
    _subscribe(notifyWaitingState: true);
  }

  void _subscribe({bool notifyWaitingState = false}) {
    if (widget.futureBuilder != null) {
      final Object callbackIdentity = Object();
      _activeCallbackIdentity = callbackIdentity;
      widget.futureBuilder().then<void>((T data) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withData(ConnectionState.done, data);
          });
        }
      }, onError: (Object error) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withError(ConnectionState.done, error);
          });
        }
      });

      final inWaitingState = () {
        _snapshot = _snapshot.inState(ConnectionState.waiting);
      };
      if (notifyWaitingState) {
        setState(inWaitingState);
      } else {
        inWaitingState();
      }
    }
  }

  void _unsubscribe() {
    _activeCallbackIdentity = null;
  }
}
