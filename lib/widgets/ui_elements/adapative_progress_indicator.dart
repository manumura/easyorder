import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easyorder/shared/constants.dart';

class AdaptiveProgressIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS
        ? const CupertinoActivityIndicator()
        : CircularProgressIndicator(
            backgroundColor: backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.secondary),
          );
  }
}
