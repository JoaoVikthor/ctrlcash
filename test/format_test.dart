import 'package:flutter_test/flutter_test.dart';

import 'package:ctrlcash/utils/format.dart';

void main() {
  group('formatCurrency', () {
    test('formata valor positivo simples sem espaco inicial', () {
      expect(formatCurrency(1.0), 'R\$ 1,00');
    });

    test('formata negativo com sinal "- " antes do R\$', () {
      expect(formatCurrency(-1.0), '- R\$ 1,00');
    });

    test('agrupa milhar com ponto e usa virgula decimal', () {
      expect(formatCurrency(1234.5), 'R\$ 1.234,50');
    });

    test('zero vira R\$ 0,00 sem sinal', () {
      expect(formatCurrency(0.0), 'R\$ 0,00');
    });

    test('arredonda para duas casas decimais', () {
      expect(formatCurrency(2.349), 'R\$ 2,35');
      expect(formatCurrency(2.341), 'R\$ 2,34');
    });

    test('agrupa multiplos milhares', () {
      expect(formatCurrency(1000000.0), 'R\$ 1.000.000,00');
      expect(formatCurrency(1234567.89), 'R\$ 1.234.567,89');
    });

    test('negativo grande mantem sinal e separadores', () {
      expect(formatCurrency(-1234567.89), '- R\$ 1.234.567,89');
    });
  });

  group('formatCurrencyAbs', () {
    test('ignora o sinal e formata o valor absoluto', () {
      expect(formatCurrencyAbs(-1234.5), 'R\$ 1.234,50');
    });

    test('positivo tem o mesmo resultado de formatCurrency', () {
      expect(formatCurrencyAbs(1234.5), 'R\$ 1.234,50');
      expect(formatCurrencyAbs(1.0), 'R\$ 1,00');
    });
  });

  group('formatDate', () {
    test('formata dd/mm/aaaa com zeros a esquerda', () {
      expect(formatDate(DateTime(2026, 3, 5)), '05/03/2026');
    });

    test('dia e mes de dois digitos permanecem', () {
      expect(formatDate(DateTime(2026, 12, 31)), '31/12/2026');
    });

    test('primeiro dia do ano', () {
      expect(formatDate(DateTime(2026, 1, 1)), '01/01/2026');
    });
  });

  group('formatDateShort', () {
    test('formata "dd Mes" com mes abreviado', () {
      expect(formatDateShort(DateTime(2026, 3, 5)), '05 Mar');
    });

    test('cobre todas as abreviaturas de mes', () {
      expect(formatDateShort(DateTime(2026, 1, 15)), '15 Jan');
      expect(formatDateShort(DateTime(2026, 2, 15)), '15 Fev');
      expect(formatDateShort(DateTime(2026, 3, 15)), '15 Mar');
      expect(formatDateShort(DateTime(2026, 4, 15)), '15 Abr');
      expect(formatDateShort(DateTime(2026, 5, 15)), '15 Mai');
      expect(formatDateShort(DateTime(2026, 6, 15)), '15 Jun');
      expect(formatDateShort(DateTime(2026, 7, 15)), '15 Jul');
      expect(formatDateShort(DateTime(2026, 8, 15)), '15 Ago');
      expect(formatDateShort(DateTime(2026, 9, 15)), '15 Set');
      expect(formatDateShort(DateTime(2026, 10, 15)), '15 Out');
      expect(formatDateShort(DateTime(2026, 11, 15)), '15 Nov');
      expect(formatDateShort(DateTime(2026, 12, 31)), '31 Dez');
    });

    test('zera a esquerda em dia simples', () {
      expect(formatDateShort(DateTime(2026, 7, 3)), '03 Jul');
    });
  });
}
