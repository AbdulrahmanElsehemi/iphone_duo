import 'package:flutter/widgets.dart';

import 'duo_device.dart';

/// Builds [builder] with how the iPhone Duo is held ([DuoPosture]; null on
/// a phone, an iPad, or where iOS says nothing), and again only when that
/// changes.
///
/// [DuoDevice.of] rebuilds what reads it on every step of the hinge, many
/// times a second while the Duo folds. A page laid out by its posture needs
/// none of those, so this reads the hinge itself and hands [builder] the
/// posture alone.
///
/// {@category Device}
class PostureBuilder extends StatefulWidget {
  const PostureBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, DuoPosture? posture) builder;

  @override
  State<PostureBuilder> createState() => _PostureBuilderState();
}

class _PostureBuilderState extends State<PostureBuilder> {
  DuoPosture? _posture;
  Widget? _built;

  @override
  void didUpdateWidget(PostureBuilder old) {
    super.didUpdateWidget(old);
    _built = null;
  }

  @override
  Widget build(BuildContext context) {
    final posture = DuoDevice.of(context).posture;
    if (posture != _posture) {
      _posture = posture;
      _built = null;
    }
    // The same widget back on a hinge step, so nothing under it rebuilds;
    // the Builder keeps what [builder] reads (the window, the fold) its own.
    return _built ??= Builder(
      builder: (context) => widget.builder(context, posture),
    );
  }
}
