import 'dart:math';

import 'package:flutter/material.dart';

class FooterLayout extends StatelessWidget {
  const FooterLayout({
    super.key,
    required this.body,
    required this.footer,
  });

  final Widget body;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return CustomMultiChildLayout(
      delegate: _FooterLayoutDelegate(MediaQuery.of(context).viewInsets),
      children: <Widget>[
        LayoutId(
          id: _FooterLayout.body,
          child: body,
        ),
        LayoutId(
          id: _FooterLayout.footer,
          child: footer,
        ),
      ],
    );
  }
}

enum _FooterLayout {
  footer,
  body,
}

class _FooterLayoutDelegate extends MultiChildLayoutDelegate {
  _FooterLayoutDelegate(this.viewInsets);

  final EdgeInsets viewInsets;

  @override
  void performLayout(Size s) {
    final Size size = Size(s.width, s.height + viewInsets.bottom);
    final Size footer =
        layoutChild(_FooterLayout.footer, BoxConstraints.loose(size));

    final BoxConstraints bodyConstraints = BoxConstraints.tightFor(
      height: size.height - max(footer.height, viewInsets.bottom),
      width: size.width,
    );

    final Size body = layoutChild(_FooterLayout.body, bodyConstraints);

    positionChild(_FooterLayout.body, Offset.zero);
    positionChild(_FooterLayout.footer, Offset(0, body.height));
  }

  @override
  bool shouldRelayout(MultiChildLayoutDelegate oldDelegate) {
    return true;
  }
}
