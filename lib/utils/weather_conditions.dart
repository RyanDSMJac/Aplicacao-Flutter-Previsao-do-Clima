import 'package:flutter/material.dart';

class WeatherCondition {
  final String description;
  final IconData icon;
  const WeatherCondition(this.description, this.icon);
}

const _unknown = WeatherCondition('Condição não informada', Icons.help_outline);

/// Siglas conforme a documentação do CPTEC/INPE.
const Map<String, WeatherCondition> _conditions = {
  'ec': WeatherCondition('Encoberto com chuvas isoladas', Icons.grain),
  'ci': WeatherCondition('Chuvas isoladas', Icons.grain),
  'c': WeatherCondition('Chuva', Icons.water_drop),
  'in': WeatherCondition('Instável', Icons.thunderstorm),
  'pp': WeatherCondition('Possibilidade de pancadas de chuva', Icons.grain),
  'cm': WeatherCondition('Chuva pela manhã', Icons.water_drop),
  'cn': WeatherCondition('Chuva à noite', Icons.water_drop),
  'pt': WeatherCondition('Pancadas de chuva à tarde', Icons.umbrella),
  'pm': WeatherCondition('Pancadas de chuva pela manhã', Icons.umbrella),
  'np': WeatherCondition('Nublado e pancadas de chuva', Icons.umbrella),
  'pc': WeatherCondition('Pancadas de chuva', Icons.umbrella),
  'pn': WeatherCondition('Parcialmente nublado', Icons.filter_drama),
  'cv': WeatherCondition('Chuvisco', Icons.water_drop),
  'ch': WeatherCondition('Chuvoso', Icons.water_drop),
  't': WeatherCondition('Tempestade', Icons.thunderstorm),
  'ps': WeatherCondition('Predomínio de sol', Icons.wb_sunny),
  'e': WeatherCondition('Encoberto', Icons.cloud),
  'n': WeatherCondition('Nublado', Icons.cloud),
  'cl': WeatherCondition('Céu claro', Icons.wb_sunny),
  'nv': WeatherCondition('Nevoeiro', Icons.foggy),
  'g': WeatherCondition('Geada', Icons.ac_unit),
  'ne': WeatherCondition('Neve', Icons.ac_unit),
  'nd': WeatherCondition('Não definido', Icons.help_outline),
  'pnt': WeatherCondition('Pancadas de chuva à noite', Icons.umbrella),
  'psc': WeatherCondition('Possibilidade de chuva', Icons.grain),
  'pcm': WeatherCondition('Possibilidade de chuva pela manhã', Icons.grain),
  'pct': WeatherCondition('Possibilidade de chuva à tarde', Icons.grain),
  'pcn': WeatherCondition('Possibilidade de chuva à noite', Icons.grain),
  'npt': WeatherCondition('Nublado com pancadas à tarde', Icons.umbrella),
  'npn': WeatherCondition('Nublado com pancadas à noite', Icons.umbrella),
  'ncn': WeatherCondition('Nublado com possibilidade de chuva à noite', Icons.grain),
  'nct': WeatherCondition('Nublado com possibilidade de chuva à tarde', Icons.grain),
  'ncm': WeatherCondition('Nublado com possibilidade de chuva pela manhã', Icons.grain),
  'npm': WeatherCondition('Nublado com pancadas pela manhã', Icons.umbrella),
  'npp': WeatherCondition('Nublado com possibilidade de chuva', Icons.grain),
  'vn': WeatherCondition('Variação de nebulosidade', Icons.filter_drama),
  'ct': WeatherCondition('Chuva à tarde', Icons.water_drop),
  'ppn': WeatherCondition('Possibilidade de pancadas de chuva à noite', Icons.grain),
  'ppt': WeatherCondition('Possibilidade de pancadas de chuva à tarde', Icons.grain),
  'ppm': WeatherCondition('Possibilidade de pancadas de chuva pela manhã', Icons.grain),
};

/// Converte a sigla em descrição + ícone. Siglas ausentes ou desconhecidas
/// retornam uma condição genérica (nunca lançam exceção).
WeatherCondition conditionFor(String? code) {
  if (code == null) return _unknown;
  return _conditions[code.trim().toLowerCase()] ?? _unknown;
}
