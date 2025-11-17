import 'package:flutter/services.dart';

class ReferenceId {
  static String prefixFor(String specimenType) {
    if (specimenType == 'Macrobenthos') return 'BM';
    if (specimenType == 'Phytoplankton') return 'BP';
    return 'BZ';
  }

  static TextInputFormatter formatterForType(String specimenType) {
    return _PrefixDigitsFormatter(
      prefix: prefixFor(specimenType),
      maxDigits: 5,
    );
  }
}

class _PrefixDigitsFormatter extends TextInputFormatter {
  final String prefix;
  final int maxDigits;
  _PrefixDigitsFormatter({required this.prefix, this.maxDigits = 5});
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (!text.startsWith(prefix)) {
      text =
          prefix + text.replaceFirst(RegExp('^${RegExp.escape(prefix)}'), '');
    }
    final after = text.substring(prefix.length);
    final digitsOnly = after.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digitsOnly.length > maxDigits
        ? digitsOnly.substring(0, maxDigits)
        : digitsOnly;
    final result = prefix + limited;
    final sel = TextSelection.collapsed(offset: result.length);
    return TextEditingValue(text: result, selection: sel);
  }
}
