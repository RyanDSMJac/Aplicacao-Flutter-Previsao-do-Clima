import 'package:flutter_test/flutter_test.dart';
import 'package:previsao_cptec/services/cptec_service.dart';
import 'package:previsao_cptec/utils/formatters.dart';
import 'package:previsao_cptec/utils/weather_conditions.dart';

void main() {
  test('parseCities lê nome, UF e id e ignora entradas inválidas', () {
    const xml = '''<cidades>
      <cidade><nome>São Paulo</nome><uf>SP</uf><id>244</id></cidade>
      <cidade><nome>Sem id</nome><uf>SP</uf></cidade>
    </cidades>''';
    final cities = CptecService.parseCities(xml);
    expect(cities.length, 1);
    expect(cities.first.id, 244);
    expect(cities.first.uf, 'SP');
  });

  test('parseCities retorna lista vazia quando nada é encontrado', () {
    expect(CptecService.parseCities('<cidades/>'), isEmpty);
  });

  test('parseForecast tolera campos ausentes', () {
    const xml = '''<cidade><nome>São Paulo</nome><uf>SP</uf><atualizacao>2026-11-09</atualizacao>
      <previsao><dia>2026-11-10</dia><tempo>ps</tempo><maxima>26</maxima><minima>14</minima><iuv>6.0</iuv></previsao>
      <previsao><dia>2026-11-11</dia><tempo>n</tempo></previsao>
    </cidade>''';
    final f = CptecService.parseForecast(xml);
    expect(f.days.length, 2);
    expect(f.days[0].max, 26);
    expect(f.days[1].min, isNull);
    expect(f.days[1].uv, isNull);
  });

  test('XML inválido gera CptecException', () {
    expect(() => CptecService.parseForecast('<html>erro'), throwsA(isA<CptecException>()));
  });

  test('siglas e acentos', () {
    expect(conditionFor('ps').description, 'Predomínio de sol');
    expect(conditionFor('xyz').description, 'Condição não informada');
    expect(conditionFor(null).description, 'Condição não informada');
    expect(removeAccents('São Paulo'), 'Sao Paulo');
  });
}
