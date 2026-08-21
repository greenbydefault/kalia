import 'package:flutter/material.dart';

import 'bottom_content_card.dart';
import 'sheet_motion.dart';

/// [showModalBottomSheet] mit [SheetMotion] und [BottomContentCard]-Chrome.
Future<T?> showAppModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool padForKeyboard = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    sheetAnimationStyle: SheetMotion.sheetAnimationStyle,
    builder: (ctx) =>
        BottomContentCard(padForKeyboard: padForKeyboard, child: builder(ctx)),
  );
}
