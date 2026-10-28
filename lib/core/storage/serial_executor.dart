/// A failed operation must not poison later retries.
class SerialExecutor {
  Future<void> _pending = Future.value();
  Future<T> run<T>(Future<T> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }
}
