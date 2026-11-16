import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../models/city.dart';
import '../models/forecast.dart';
import '../utils/formatters.dart';

enum CptecErrorType { connection, timeout, unavailable, invalidResponse }

class CptecException implements Exception {
  final CptecErrorType type;
  final String message;
  const CptecException(this.type, this.message);

  @override
  String toString() => message;
}

class CptecService {
  CptecService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _base = 'https://servicos.cptec.inpe.br/XML';
  static const _timeout = Duration(seconds: 15);

  /// GET /listaCidades?city=<nome sem acentos>
  Future<List<City>> searchCities(String query) async {
    final name = removeAccents(query.trim()).replaceAll(RegExp(r'\s+'), ' ');
    final uri = Uri.parse('$_base/listaCidades?city=${Uri.encodeComponent(name)}');
    return parseCities(await _get(uri));
  }

  /// GET /cidade/<id>/previsao.xml (4 dias)
  Future<Forecast> fetchForecast(int cityId) async {
    final uri = Uri.parse('$_base/cidade/$cityId/previsao.xml');
    return parseForecast(await _get(uri));
  }

  // ---------- Parsing (público para facilitar testes) ----------

  static List<City> parseCities(String xml) {
    final root = _parse(xml, 'cidades');
    final cities = <City>[];
    for (final el in root.findElements('cidade')) {
      final id = int.tryParse(_text(el, 'id') ?? '');
      final name = _text(el, 'nome');
      if (id == null || name == null) continue; // ignora entradas inválidas
      cities.add(City(id: id, name: name, uf: _text(el, 'uf') ?? ''));
    }
    return cities;
  }

  static Forecast parseForecast(String xml) {
    final root = _parse(xml, 'cidade');
    final days = <DayForecast>[];
    for (final el in root.findElements('previsao')) {
      final date = DateTime.tryParse(_text(el, 'dia') ?? '');
      if (date == null) continue;
      days.add(DayForecast(
        date: date,
        code: _text(el, 'tempo'),
        min: int.tryParse(_text(el, 'minima') ?? ''),
        max: int.tryParse(_text(el, 'maxima') ?? ''),
        uv: double.tryParse((_text(el, 'iuv') ?? '').replaceAll(',', '.')),
      ));
    }
    return Forecast(
      cityName: _text(root, 'nome') ?? '',
      uf: _text(root, 'uf') ?? '',
      updatedAt: DateTime.tryParse(_text(root, 'atualizacao') ?? ''),
      days: days,
    );
  }

  static XmlElement _parse(String xml, String expectedRoot) {
    try {
      final root = XmlDocument.parse(xml).rootElement;
      if (root.name.local != expectedRoot) {
        throw const CptecException(
            CptecErrorType.invalidResponse, 'O serviço retornou uma resposta inesperada.');
      }
      return root;
    } on XmlException {
      throw const CptecException(CptecErrorType.invalidResponse,
          'O serviço retornou uma resposta inválida (XML malformado).');
    }
  }

  static String? _text(XmlElement parent, String tag) {
    final value = parent.getElement(tag)?.innerText.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  // ---------- HTTP ----------

  Future<String> _get(Uri uri) async {
    http.Response res;
    try {
      res = await _client.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw const CptecException(
          CptecErrorType.timeout, 'Tempo de conexão esgotado. Tente novamente.');
    } catch (_) {
      throw const CptecException(CptecErrorType.connection,
          'Falha de conexão. Verifique sua internet e tente novamente.');
    }
    if (res.statusCode != 200) {
      throw CptecException(CptecErrorType.unavailable,
          'Serviço do CPTEC/INPE indisponível no momento (HTTP ${res.statusCode}).');
    }
    return _decode(res.bodyBytes);
  }

  /// O serviço costuma responder em ISO-8859-1; trata os dois casos.
  static String _decode(List<int> bytes) {
    final head = latin1.decode(bytes.take(200).toList(), allowInvalid: true).toLowerCase();
    if (head.contains('iso-8859-1')) return latin1.decode(bytes);
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }
}
