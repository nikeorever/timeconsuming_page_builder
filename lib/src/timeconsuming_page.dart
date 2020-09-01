part of timeconsuming_page_builder;

/// Signature for adding ability to retry when error occurred.
///
/// Used by [ErrorWidgetBuilder]
typedef RetryCaller = void Function();

/// Signature for building waiting widget.
/// See also:
///  * [BuiltInWaitingWidget], which is built-in waiting widget.
typedef WaitingWidgetBuilder = Widget Function(BuildContext context);

/// Signature for building error widget.
/// See also:
///  * [BuiltInErrorWidget], which is built-in error widget.
typedef ErrorWidgetBuilder = Widget Function(
    BuildContext context, RetryCaller caller);

/// Signature for building data widget.
/// See also:
///  * [BuiltInEmptyWidget], which is built-in empty widget.
typedef DataWidgetBuilder<T> = Widget Function(BuildContext context, T data);

/// Signature for building [Future].
typedef FutureBuilder<T> = Future<T> Function();

/// Widgets that switches widget state based on different situation
/// on a time-consuming page with a [Future].
///
/// ```dart
/// TimeConsumingPageBuilder<int>(
///   futureBuilder: ()=> Future.delayed(Duration(microseconds: 10), () => 8),
///   waitingWidgetBuilder: (BuildContext context) {
///     // show waiting to user.
///     return ...; //
///   },
///   errorWidgetBuilder: (BuildContext context, RetryCaller caller) {
///     // show error to the user.
///     // caller() will retry again.
///     return ...;
///   },
///   dataWidgetBuilder: (BuildContext context, int data) {
///     // show data to the user.
///     // parameter[data] will be set 8 after 10 microseconds.
///     return ...;
///   },
/// )
/// ```
class TimeConsumingPageBuilder<T> extends StatefulWidget {
  /// Creates a time-consuming page builder.
  ///
  /// [futureBuilder] which used to build future.
  /// [waitingWidgetBuilder] which used to build waiting widget.
  /// [errorWidgetBuilder] which used to build error widget.
  /// [dataWidgetBuilder] which used to build data widget.
  TimeConsumingPageBuilder({
    Key key,
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
          final state = (context as StatefulElement).state
              as _TimeConsumingPageBuilderState;
          state.resubscribe();
        });
      } else {
        child = waitingWidgetBuilder(context);
      }
      return child;
    };
  }

  final FutureBuilder<T> futureBuilder;

  final AsyncWidgetBuilder<T> builder;

  @override
  State<TimeConsumingPageBuilder<T>> createState() =>
      _TimeConsumingPageBuilderState<T>();
}

/// State for [TimeConsumingPageBuilder].
class _TimeConsumingPageBuilderState<T>
    extends State<TimeConsumingPageBuilder<T>> {
  Object _activeCallbackIdentity;
  AsyncSnapshot<T> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = AsyncSnapshot<T>.withData(ConnectionState.none, null);
    _subscribe();
  }

  @override
  void didUpdateWidget(TimeConsumingPageBuilder<T> oldWidget) {
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
      _snapshot = AsyncSnapshot<T>.withData(ConnectionState.none, null);
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
