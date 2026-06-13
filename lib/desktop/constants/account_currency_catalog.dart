/// ISO 4217 currency catalog: (code, Chinese name)
const kAccountCurrencyCatalog = [
  ('AED', '\u963f\u8054\u898b\u8fea\u8c6b\u8c28\u62c9\u59c6'),
  ('AFN', '\u963f\u5bcc\u6c57\u5c3c'),
  ('ALL', '\u963f\u5c14\u5df4\u5c3c\u4e9a\u5217\u514b'),
  ('ARS', '\u963f\u6839\u5ef7\u6bd4\u7d22'),
  ('AUD', '\u6fb3\u5927\u5229\u4e9a\u5143'),
  ('AWG', '\u963f\u9c81\u5df4\u5f17\u7f57\u6797'),
  ('AZN', '\u963f\u585e\u62dc\u7586\u9a6c\u7eb3\u7279'),
  ('BRL', '\u5df4\u897f\u96c7\u4e9a\u5c14'),
  ('CAD', '\u52a0\u62ff\u5927\u5143'),
  ('CHF', '\u745e\u58eb\u6cd5\u90ce'),
  ('CLP', '\u667a\u5229\u6bd4\u7d22'),
  ('CNY', '\u4eba\u6c11\u5e01'),
  ('COP', '\u54e5\u4f26\u6bd4\u4e9a\u6bd4\u7d22'),
  ('CZK', '\u6377\u514b\u514b\u6717'),
  ('DKK', '\u4e39\u9ea6\u514b\u6717'),
  ('DZD', '\u963f\u5c14\u53ca\u5229\u4e9a\u7b2c\u7eb3\u5c14'),
  ('EGP', '\u57c3\u53ca\u9521'),
  ('EUR', '\u6b27\u5143'),
  ('GBP', '\u82f1\u9551'),
  ('HKD', '\u6e2f\u5143'),
  ('HUF', '\u5308\u7259\u5229\u798f\u6797'),
  ('IDR', '\u5370\u5c3c\u76a7\u6bd4'),
  ('ILS', '\u4ee5\u8272\u5217\u65b0\u8c22\u514b\u5c14'),
  ('INR', '\u5370\u5ea6\u5362\u6bd4'),
  ('JPY', '\u65e5\u5143'),
  ('KES', '\u80af\u5c3c\u4e9a\u5148\u4ee4'),
  ('KRW', '\u97e9\u5143'),
  ('KWD', '\u79d1\u5a01\u7279\u7b2c\u7eb3\u5c14'),
  ('KZT', '\u54c8\u8428\u514b\u65af\u5766\u575a\u6208'),
  ('MAD', '\u6469\u6d1b\u54e5\u8fea\u62c9\u59c6'),
  ('MXN', '\u58a8\u897f\u54e5\u6bd4\u7d22'),
  ('MYR', '\u9a6c\u6765\u897f\u4e9a\u6797\u5409\u7279'),
  ('NGN', '\u5948\u62c9\u5229\u4e9a\u5948\u62c9'),
  ('NOK', '\u632a\u5a01\u514b\u6717'),
  ('NZD', '\u65b0\u897f\u5170\u5143'),
  ('OMR', '\u963f\u66fc\u805ae\u5c14'),
  ('PEN', '\u79d8\u9c81\u7d22\u5c14'),
  ('PHP', '\u83f2\u5f8b\u5bbe\u6bd4\u7d22'),
  ('PKR', '\u5df4\u57fa\u65af\u5766\u5362\u6bd4'),
  ('PLN', '\u6ce2\u5170\u8328\u7f57\u63d0'),
  ('QAR', '\u5361\u5854\u5c14\u91cc\u4e9a\u5c14'),
  ('RON', '\u7f57\u9a6c\u5c3c\u4e9a\u5217\u4f0a'),
  ('RUB', '\u4fc4\u7f57\u65af\u5362\u5e03'),
  ('SAR', '\u6c99\u7279\u963f\u62c9\u4f2f\u91cc\u4e9a\u5c14'),
  ('SEK', '\u745e\u5178\u514b\u6717'),
  ('SGD', '\u65b0\u52a0\u5761\u5143'),
  ('THB', '\u6cf0\u94ba'),
  ('TRY', '\u571f\u8033\u5176\u91cc\u62c9'),
  ('TWD', '\u65b0\u53f0\u5e01'),
  ('UAH', '\u4e4c\u514b\u5170\u683c\u91cc\u592b\u7eb3'),
  ('USD', '\u7f8e\u5143'),
  ('VND', '\u8d8a\u5357\u76fe'),
  ('ZAR', '\u5357\u975e\u5170\u7279'),
];

String accountCurrencySymbol(String code) {
  return switch (code) {
    'CNY' || 'JPY' => '\u00a5',
    'USD' => r'$',
    'EUR' => '\u20ac',
    'GBP' => '\u00a3',
    'RUB' => '\u20bd',
    'INR' => '\u20b9',
    'KRW' => '\u20a9',
    'NGN' => '\u20a6',
    'UAH' => '\u20b4',
    'KZT' => '\u20b8',
    'THB' => '\u0e3f',
    'ILS' => '\u20aa',
    'TRY' => '\u20ba',
    _ => code,
  };
}

String accountCurrencyLabel(String code) {
  for (final item in kAccountCurrencyCatalog) {
    if (item.$1 == code) return item.$2;
  }
  return code;
}

List<(String code, String name)> filterAccountCurrencies(String keyword) {
  final q = keyword.trim().toLowerCase();
  if (q.isEmpty) return kAccountCurrencyCatalog;
  return kAccountCurrencyCatalog.where((item) {
    return item.$1.toLowerCase().contains(q) || item.$2.contains(keyword.trim());
  }).toList();
}
