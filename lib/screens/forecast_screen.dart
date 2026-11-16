import 'package:flutter/material.dart';

import '../models/city.dart';
import '../models/forecast.dart';
import '../services/cptec_service.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';
import '../utils/weather_conditions.dart';
import '../widgets/message_view.dart';
import 'chart_screen.dart';

class ForecastScreen extends StatefulWidget {
  final City city;
  const ForecastScreen({super.key, required this.city});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  final _service = CptecService();
  final _storage = StorageService();

  Forecast? _forecast;
  String? _error;
  bool _loading = true;
  bool _fromCache = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final forecast = await _service.fetchForecast(widget.city.id);
      if (forecast.days.isNotEmpty) {
        await _storage.saveForecast(widget.city.id, forecast);
      }
      if (!mounted) return;
      setState(() {
        _forecast = forecast;
        _fromCache = false;
        _loading = false;
      });
    } catch (e) {
      final message =
          e is CptecException ? e.message : 'Ocorreu um erro inesperado. Tente novamente.';
      // Em caso de falha, usa a última previsão salva localmente (se houver).
      final fallback = _forecast ?? await _storage.loadForecast(widget.city.id);
      if (!mounted) return;
      setState(() {
        _error = message;
        _forecast = fallback;
        _fromCache = fallback != null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final forecast = _forecast;
    final canChart = forecast != null && forecast.days.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.city.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: 'Gráfico de temperatura',
            onPressed: canChart
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChartScreen(city: widget.city, forecast: forecast),
                      ),
                    )
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    final forecast = _forecast;
    if (forecast == null) {
      if (_loading) return const Center(child: CircularProgressIndicator());
      return Column(children: [
        Expanded(
          child: MessageView(
            icon: Icons.cloud_off,
            message: _error ?? 'Não foi possível obter a previsão.',
            onRetry: _load,
          ),
        ),
        const SourceFooter(),
      ]);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_error != null && _fromCache) _banner('$_error\nExibindo a última previsão salva no dispositivo.'),
          if (forecast.updatedAt != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Atualizado em ${formatDate(forecast.updatedAt!)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          if (forecast.days.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: MessageView(
                icon: Icons.cloud_queue,
                message: 'Não há previsão disponível para esta localidade no momento.',
              ),
            )
          else
            for (final day in forecast.days) _DayCard(day: day),
          const SourceFooter(),
        ],
      ),
    );
  }

  Widget _banner(String text) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Icon(Icons.warning_amber, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: scheme.onErrorContainer))),
        ]),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final DayForecast day;
  const _DayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final condition = conditionFor(day.code);
    final theme = Theme.of(context);
    final min = day.min != null ? '${day.min}°C' : '--';
    final max = day.max != null ? '${day.max}°C' : '--';
    final uv = day.uv;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(condition.icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${weekday(day.date)}, ${formatDate(day.date)}',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(condition.description, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.arrow_downward, size: 16, color: Colors.blue),
                    Text(' Mín $min'),
                    const SizedBox(width: 16),
                    const Icon(Icons.arrow_upward, size: 16, color: Colors.deepOrange),
                    Text(' Máx $max'),
                  ]),
                  if (uv != null) ...[
                    const SizedBox(height: 4),
                    Text('Índice UV: ${uv.toStringAsFixed(1)} (${uvCategory(uv)})',
                        style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
