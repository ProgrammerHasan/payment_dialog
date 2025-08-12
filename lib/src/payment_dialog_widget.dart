import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:motion_toast/motion_toast.dart';

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
class _WebView extends StatefulWidget {
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
  State<_WebView> createState() => _WebViewState();
}

class _WebViewState extends State<_WebView> {
  late final StreamController<_LoadingState> _rawStreamController;
  late final StreamController<_LoadingState> _debouncedStreamController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _rawStreamController = StreamController<_LoadingState>.broadcast();
    _debouncedStreamController = StreamController<_LoadingState>.broadcast();

    // Listen to raw events and apply manual debounce
    _rawStreamController.stream.listen((event) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 1), () {
        if (!_debouncedStreamController.isClosed) {
          _debouncedStreamController.add(event);
        }
      });
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _rawStreamController.close();
    _debouncedStreamController.close();
    super.dispose();
  }

  void _emitLoadingState(_LoadingState state) {
    if (!_rawStreamController.isClosed) {
      _rawStreamController.add(state);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> internalUrls = [widget.succeededUrl, widget.failedUrl, widget.cancelledUrl];
    return Stack(
      alignment: Alignment.center,
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri(widget.paymentUrl),
          ),
          initialSettings: InAppWebViewSettings(
            useShouldOverrideUrlLoading: true,
          ),
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            final url = navigationAction.request.url.toString();
            if (internalUrls.contains(url)) {
              Navigator.of(context).pop();
              if (url == widget.succeededUrl) {
                widget.onSuccessful?.call();
              } else if (url == widget.failedUrl) {
                widget.onFailed?.call();
              } else if (url == widget.cancelledUrl) {
                widget.onCancelled?.call();
              }
              return NavigationActionPolicy.CANCEL;
            }
            return NavigationActionPolicy.ALLOW;
          },
          onLoadStart: (controller, url) {
            _emitLoadingState(_LoadingState.loading);
          },
          onLoadStop: (controller, url) async {
            _emitLoadingState(_LoadingState.loaded);
          },
          onLoadError: (controller, url, code, message) {
            _emitLoadingState(_LoadingState.error);
          },
          onLoadHttpError: (controller, url, code, message) {
            _emitLoadingState(_LoadingState.serverError);
          },
        ),
        StreamBuilder<_LoadingState>(
          stream: _debouncedStreamController.stream,
          initialData: _LoadingState.loading,
          builder: (context, snapshot) {
            final state = snapshot.data ?? _LoadingState.loading;
            return _ErrorWidget(state: state, loading: widget.loading, error: widget.error, serverError: widget.serverError);
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
        return SizedBox.expand(
          child: loading ?? Container(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                    height: 35,
                    width: 35,
                    child: CircularProgressIndicator()
                ),
                Text("Please wait, Loading the payment gateway..."),
              ],
            ),
          ),
        );
      case _LoadingState.loaded:
        return const SizedBox.shrink();
      case _LoadingState.error:
        return SizedBox.expand(
          child: error ?? Container(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'Please check your internet connection!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        );
      case _LoadingState.serverError:
        return SizedBox.expand(
          child: serverError ?? Container(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                ),
                const SizedBox(height: 8),
                Text(
                  "Temporarily Service Unavailable",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        );
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
    return WillPopScope(
      onWillPop: () {
        return showConfirmPrompt(context, goBack);
      },
      child: IconButton(
        onPressed: () {
          showConfirmPrompt(context, goBack);
        },
        icon: Icon(Icons.close,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<bool> showConfirmPrompt(BuildContext context, VoidCallback? goBack) {
    final completer = Completer<bool>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(8),
        ),
      ),
      builder: (context) {
        return IntrinsicHeight(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Text(
                  "Are you sure to cancel?",
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "If you change your mind, you’ll need to put them back in.",
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 12
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                            Colors.black12.withOpacity(0.1),
                          ),
                          foregroundColor: WidgetStateProperty.all(
                            Colors.black54,
                          ),
                        ),
                        child: Text(
                          "Cancel",
                        ),
                      ),
                    ),
                    SizedBox(width: 32),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (goBack != null) {
                            goBack();
                          } else if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                            Colors.red.withOpacity(0.2),
                          ),
                          foregroundColor: WidgetStateProperty.all(
                            Colors.red,
                          ),
                        ),
                        child: Text("Confirm", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return completer.future;
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
          title: Text(successMsgTitle ?? "Payment Success", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          description: Text(successMsgDescription ?? "Your payment has been successfully completed.", style: TextStyle(color: Colors.white)),
          toastDuration: const Duration(seconds: 10),
        ).show(context);
        isPaid?.value = true;
        completer.complete(true);
      },
      onFailed: () {
        MotionToast.error(
          title: Text(failedMsgTitle ?? "Payment Failed", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          description: Text(failedMsgDescription ?? "Your payment has been failed, Please try again.", style: TextStyle(color: Colors.white)),
          toastDuration: const Duration(seconds: 10),
        ).show(context);
        completer.complete(false);
      },
      onCancelled: () {
        MotionToast.info(
          title: Text(errorMsgTitle ?? "Oops! Cancelled.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          description: Text(errorMsgDescription ?? "Your payment has been cancelled, Please try again.", style: TextStyle(color: Colors.white)),
          toastDuration: const Duration(seconds: 10),
        ).show(context);
        completer.complete(false);
      },
    ),
  );
  return completer.future;
}
