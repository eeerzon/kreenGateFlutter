import 'package:flutter/widgets.dart';
import 'package:kreengate/helper/global_var.dart';

/// Padanan `Resource<T>` (utils/base/Resource.kt) di atas Map hasil ApiService.
enum ResourceType { success, error, loading, empty }

class Resource {
  final ResourceType type;
  final Map<String, dynamic>? data;
  final String? message;
  final String? desc;
  final int? errorCode;

  const Resource._(this.type, {this.data, this.message, this.desc, this.errorCode});

  const Resource.loading() : this._(ResourceType.loading);
  const Resource.empty() : this._(ResourceType.empty);

  /// Map dari ApiService -> Resource (status "none" -> null = tidak ada post)
  static Resource? fromApi(Map<String, dynamic> result) {
    switch (result['status']) {
      case 'success':
        return Resource._(ResourceType.success, data: result['data'] as Map<String, dynamic>);
      case 'error':
        return Resource._(ResourceType.error,
            message: result['message'] as String?,
            desc: result['desc'] as String?,
            errorCode: result['errorCode'] as int?);
      default:
        return null;
    }
  }
}

/// MutableLiveData sederhana: observer baru langsung menerima value terakhir (kalau sudah pernah di-set),
/// semua observer menerima setiap value baru, sampai halaman (lifecycle owner) di-dispose.
class LiveData<T> {
  final List<void Function(T? value)> _observers = [];
  bool _hasValue = false;
  T? _value;

  T? get value => _value;

  void observe(void Function(T? value) observer) {
    _observers.add(observer);
    if (_hasValue) observer(_value);
  }

  void postValue(T? value) {
    _hasValue = true;
    _value = value;
    for (final o in List.of(_observers)) {
      o(value);
    }
  }

  void removeObservers() => _observers.clear();
}

/// onResume / onPause seperti Activity: dipanggil saat halaman pertama tampil, saat kembali dari
/// halaman di atasnya, dan saat aplikasi kembali dari background (hanya kalau halaman ini paling atas).
mixin ActivityLifecycle<W extends StatefulWidget> on State<W> implements RouteAware {
  bool _visible = false;
  bool _subscribed = false;
  late final _AppLifecycleObserver _appObserver = _AppLifecycleObserver(_onAppLifecycle);

  void onResume() {}
  void onPause() {}

  void _resume() {
    if (_visible) return;
    _visible = true;
    onResume();
  }

  void _pause() {
    if (!_visible) return;
    _visible = false;
    onPause();
  }

  void _onAppLifecycle(AppLifecycleState state) {
    if (!mounted) return;
    final isTop = ModalRoute.of(context)?.isCurrent ?? false;
    if (state == AppLifecycleState.resumed) {
      if (isTop) _resume();
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _pause();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_appObserver);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resume();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (!_subscribed && route is PageRoute) {
      activityRouteObserver.subscribe(this, route);
      _subscribed = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_appObserver);
    activityRouteObserver.unsubscribe(this);
    _pause();
    super.dispose();
  }

  @override
  void didPushNext() => _pause();
  @override
  void didPopNext() => _resume();
  @override
  void didPush() {}
  @override
  void didPop() {}
}

class _AppLifecycleObserver with WidgetsBindingObserver {
  final void Function(AppLifecycleState state) onChange;
  _AppLifecycleObserver(this.onChange);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => onChange(state);
}
