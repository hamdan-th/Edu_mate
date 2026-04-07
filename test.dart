import 'dart:async';
main() async {
  var ctrl = StreamController<int>();
  ctrl.stream.asyncExpand((i) => Stream.periodic(const Duration(seconds: 1), (x)=> "$i-$x").take(3)).listen(print);
  ctrl.add(1);
  ctrl.add(2);
  await Future.delayed(const Duration(seconds: 4));
}
