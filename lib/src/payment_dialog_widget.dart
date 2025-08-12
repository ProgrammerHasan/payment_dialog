import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:rxdart/rxdart.dart';

enum _LoadingState { loading, loaded, error, serverError }

// ----------------- Payment Dialog -----------------
class _PaymentDialog extends StatelessWidget {
  const _PaymentDialog({
    required this.paymentUrl,
    required this.succeededUrl,
    required this.failedUrl,
    required this.cancelledUrl,
    this.title,
    this.appBarBackgroundColor,
    this.loading,
    this.error,
    this.serverError,
    this.onSuccessful,
    this.onFailed,
    this.onCancelled,
  });

  final String paymentUrl;
  final String succeededUrl;
  final String failedUrl;
  final String cancelledUrl;
  final Widget? title;
  final Color? appBarBackgroundColor;
  final Widget? loading;
  final Widget? error;
  final Widget? serverError;
  final VoidCallback? onSuccessful;
  final VoidCallback? onFailed;
  final VoidCallback? onCancelled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarBackgroundColor,
        title: title ?? const Text("Payment", style: TextStyle(color: Colors.white)),
        leading: _ConfirmationCloseButton(
          goBack: () {
            Navigator.of(context).pop();
            onCancelled?.call();
          },
        ),
      ),
      body: SafeArea(
        child: _WebView(
          paymentUrl: paymentUrl,
          succeededUrl: succeededUrl,
          failedUrl: failedUrl,
          cancelledUrl: cancelledUrl,
          loading: loading,
          error: error,
          serverError: serverError,
          onSuccessful: onSuccessful,
          onFailed: onFailed,
          onCancelled: onCancelled,
        ),
      ),
    );
  }
}

// ----------------- WebView -----------------
class _WebView extends HookWidget {
  const _WebView({
    required this.paymentUrl,
    required this.succeededUrl,
    required this.failedUrl,
    required this.cancelledUrl,
    this.loading,
    this.error,
    this.serverError,
    this.onSuccessful,
    this.onFailed,
    this.onCancelled,
  });

  final String paymentUrl;
  final String succeededUrl;
  final String failedUrl;
  final String cancelledUrl;
  final Widget? loading;
  final Widget? error;
  final Widget? serverError;
  final VoidCallback? onSuccessful;
  final VoidCallback? onFailed;
  final VoidCallback? onCancelled;

  @override
  Widget build(BuildContext context) {
    List<String> kInternalUrls = [succeededUrl, failedUrl, cancelledUrl];

    final loadingStreamController = useStreamController<_LoadingState>();
    final loadingStateStream = useMemoized(() {
      return loadingStreamController.stream.debounceTime(const Duration(seconds: 1));
    }, [loadingStreamController]);
    return Stack(
      alignment: Alignment.center,
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri(paymentUrl),
          ),
          initialSettings: InAppWebViewSettings(
            useShouldOverrideUrlLoading: true,
            builtInZoomControls: true
          ),
          initialUserScripts: UnmodifiableListView<UserScript>([]),
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            final url = navigationAction.request.url.toString();
            if (kInternalUrls.contains(url)) {
              Navigator.of(context).pop();
              if (url == succeededUrl) {
                onSuccessful?.call();
              } else if (url == failedUrl) {
                onFailed?.call();
              } else if (url == cancelledUrl) {
                onCancelled?.call();
              }
              return NavigationActionPolicy.CANCEL;
            }
            return NavigationActionPolicy.ALLOW;
          },
          onLoadStart: (controller, url) {
            loadingStreamController.add(_LoadingState.loading);
          },
          onLoadStop: (controller, url) async {
            loadingStreamController.add(_LoadingState.loaded);
          },
          onLoadError: (controller, url, code, message) {
            loadingStreamController.add(_LoadingState.error);
          },
          onLoadHttpError: (controller, url, code, message) {
            loadingStreamController.add(_LoadingState.serverError);
          },
        ),
        StreamBuilder(
          stream: loadingStateStream,
          initialData: _LoadingState.loading,
          builder: (context, AsyncSnapshot<_LoadingState> snapshot) {
            final state = snapshot.data ?? _LoadingState.loading;
            return _ErrorWidget(state: state, loading: loading, error: error, serverError: serverError);
          },
        ),
      ],
    );
  }
}

// ----------------- Error Widget -----------------
class _ErrorWidget extends StatelessWidget {
  final _LoadingState state;
  final Widget? loading;
  final Widget? error;
  final Widget? serverError;

  const _ErrorWidget({required this.state, this.loading, this.error, this.serverError});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _LoadingState.loading:
        return loading ?? const Center(child: CircularProgressIndicator());
      case _LoadingState.loaded:
        return const SizedBox.shrink();
      case _LoadingState.error:
        return error ?? const Center(child: Text("Please check your internet connection!"));
      case _LoadingState.serverError:
        return serverError ?? const Center(child: Text("Service temporarily unavailable"));
    }
  }
}

// ----------------- Close Button -----------------
class _ConfirmationCloseButton extends StatelessWidget {
  const _ConfirmationCloseButton({
    this.goBack,
  });

  final VoidCallback? goBack;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        if (goBack != null) goBack!();
        Navigator.of(context).pop();
      },
      icon: const Icon(Icons.close, color: Colors.white),
    );
  }
}

// ----------------- Public Function -----------------
Future<bool> showPaymentDialog({
  required BuildContext context,
  required String paymentUrl,
  required String succeededUrl,
  required String failedUrl,
  required String cancelledUrl,
  Widget? title,
  Color? appBarBackgroundColor,
  Widget? loading,
  Widget? error,
  Widget? serverError,
  String? successMsgTitle,
  String? successMsgDescription,
  String? errorMsgTitle,
  String? errorMsgDescription,
  String? failedMsgTitle,
  String? failedMsgDescription,
  ValueNotifier<bool>? isPaid,
}) {
  final completer = Completer<bool>();
  showDialog(
    context: context,
    barrierColor: Colors.black38,
    useSafeArea: false,
    builder: (_) => _PaymentDialog(
      paymentUrl: paymentUrl,
      succeededUrl: succeededUrl,
      failedUrl: failedUrl,
      cancelledUrl: cancelledUrl,
      title: title,
      appBarBackgroundColor: appBarBackgroundColor,
      loading: loading,
      error: error,
      serverError: serverError,
      onSuccessful: () {
        MotionToast.success(
          title: Text(successMsgTitle ?? "Payment Success"),
          description: Text(successMsgDescription ?? "Your payment was completed."),
        ).show(context);
        isPaid?.value = true;
        completer.complete(true);
      },
      onFailed: () {
        MotionToast.error(
          title: Text(failedMsgTitle ?? "Payment Failed"),
          description: Text(failedMsgDescription ?? "Your payment failed, please try again."),
        ).show(context);
        completer.complete(false);
      },
      onCancelled: () {
        MotionToast.info(
          title: Text(errorMsgTitle ?? "Cancelled"),
          description: Text(errorMsgDescription ?? "Payment was cancelled."),
        ).show(context);
        completer.complete(false);
      },
    ),
  );
  return completer.future;
}
