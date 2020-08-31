# timeconsuming_page_builder

A time-consuming flutter page builder.

## Usage
Use [dartrofit](https://pub.dev/packages/dartrofit) to request remote markdown resources, then display markdown on the page 
using [Flutter Markdown](https://pub.dev/packages/flutter_markdown).
```dart
import 'package:timeconsuming_page_builder/timeconsuming_page_builder.dart';

TimeConsumingPage<ResponseBody>(
    futureBuilder: () => Api(dartrofit).getContent(path),
    waitingWidgetBuilder: (BuildContext context) =>
        BuiltInWaitingWidget(progressIndicatorValueColor: (BuildContext context) => AlwaysStoppedAnimation(Colors.teal)),
    errorWidgetBuilder: (BuildContext context, RetryCaller caller) =>
        BuiltInErrorWidget(onRetryClick: caller),
    dataWidgetBuilder: (BuildContext context, ResponseBody body) {
      if (body.string.orEmpty().isEmpty) {
        return BuiltInEmptyWidget();
      }
      return SafeArea(
          child: Markdown(selectable: true, data: body.string));
    })
```
# Parameters
* futureBuilder: A builder used to build `Future`.
* waitingWidgetBuilder: A builder used to build waiting widget, e.g `BuiltInWaitingWidget`.
* errorWidgetBuilder: A builder used to build error widget when error occurred, e.g `BuiltInErrorWidget`.
* dataWidgetBuilder: A builder used to build data widget if has data, or build empty widget if no data (e.g `BuiltInEmptyWidget`).
