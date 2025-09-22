import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    // Remove todos os caracteres não numéricos
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.isEmpty) {
      return const TextEditingValue();
    }

    // Converte para double e divide por 100 para tratar os centavos
    double value = double.parse(text) / 100;

    // Formata o valor para o padrão de moeda brasileiro (ex: 1.234,56)
    final formatter = NumberFormat("#,##0.00", "pt_BR");
    String newText = formatter.format(value);

    return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length));
  }
}