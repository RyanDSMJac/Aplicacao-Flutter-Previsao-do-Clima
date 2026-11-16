/// Previsão de um dia. Qualquer campo (exceto a data) pode estar ausente.
class DayForecast {
  final DateTime date;
  final String? code; // sigla da condição (ex.: "ps")
  final int? min;
  final int? max;
  final double? uv;

  const DayForecast({
    required this.date,
    this.code,
    this.min,
    this.max,
    this.uv,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'code': code,
        'min': min,
        'max': max,
        'uv': uv,
      };

  static DayForecast? fromJson(dynamic json) {
    if (json is! Map) return null;
    final date = DateTime.tryParse('${json['date']}');
    if (date == null) return null;
    return DayForecast(
      date: date,
      code: json['code'] as String?,
      min: (json['min'] as num?)?.toInt(),
      max: (json['max'] as num?)?.toInt(),
      uv: (json['uv'] as num?)?.toDouble(),
    );
  }
}

class Forecast {
  final String cityName;
  final String uf;
  final DateTime? updatedAt; // data de atualização informada pelo serviço
  final List<DayForecast> days;

  const Forecast({
    required this.cityName,
    required this.uf,
    required this.updatedAt,
    required this.days,
  });

  Map<String, dynamic> toJson() => {
        'cityName': cityName,
        'uf': uf,
        'updatedAt': updatedAt?.toIso8601String(),
        'days': days.map((d) => d.toJson()).toList(),
      };

  static Forecast? fromJson(dynamic json) {
    if (json is! Map) return null;
    final rawDays = json['days'];
    if (rawDays is! List) return null;
    return Forecast(
      cityName: (json['cityName'] as String?) ?? '',
      uf: (json['uf'] as String?) ?? '',
      updatedAt: DateTime.tryParse('${json['updatedAt']}'),
      days: rawDays.map(DayForecast.fromJson).whereType<DayForecast>().toList(),
    );
  }
}
