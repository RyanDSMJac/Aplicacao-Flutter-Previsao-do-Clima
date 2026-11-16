import 'package:flutter/material.dart';

import '../models/city.dart';
import '../services/cptec_service.dart';
import '../services/storage_service.dart';
import '../widgets/message_view.dart';
import 'forecast_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _service = CptecService();
  final _storage = StorageService();

  List<City> _results = [];
  List<City> _recent = [];
  bool _loading = false;
  bool _searched = false;
  String? _error;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final recent = await _storage.loadRecentCities();
    if (mounted) setState(() => _recent = recent);
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    final query = _controller.text.trim();
    if (query.length < 2) {
      setState(() {
        _error = 'Digite pelo menos 2 caracteres para pesquisar.';
        _searched = false;
        _results = [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _lastQuery = query;
    });
    try {
      final cities = await _service.searchCities(query);
      if (!mounted) return;
      setState(() {
        _results = cities;
        _searched = true;
        _loading = false;
      });
    } on CptecException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('Ocorreu um erro inesperado. Tente novamente.');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _searched = false;
      _results = [];
      _loading = false;
    });
  }

  Future<void> _open(City city) async {
    await _storage.saveRecentCity(city);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ForecastScreen(city: city)),
    );
    _loadRecent();
  }

  Future<void> _clearRecent() async {
    await _storage.clearRecentCities();
    _loadRecent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Previsão do Tempo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: 'Nome da cidade',
                hintText: 'Ex.: São Paulo',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Pesquisar',
                  onPressed: _loading ? null : _search,
                ),
              ),
            ),
          ),
          Expanded(child: _content()),
          const SourceFooter(),
        ],
      ),
    );
  }

  Widget _content() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return MessageView(
        icon: Icons.error_outline,
        message: _error!,
        onRetry: _controller.text.trim().length >= 2 ? _search : null,
      );
    }
    if (_searched) {
      if (_results.isEmpty) {
        return MessageView(
          icon: Icons.location_off,
          message: 'Nenhuma cidade encontrada para “$_lastQuery”.',
        );
      }
      return ListView.separated(
        itemCount: _results.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => _cityTile(_results[i]),
      );
    }
    if (_recent.isEmpty) {
      return const MessageView(
        icon: Icons.wb_cloudy_outlined,
        message: 'Pesquise uma cidade para ver a previsão do tempo.',
      );
    }
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text('Consultadas recentemente',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              TextButton(onPressed: _clearRecent, child: const Text('Limpar')),
            ],
          ),
        ),
        for (final c in _recent) _cityTile(c, icon: Icons.history),
      ],
    );
  }

  Widget _cityTile(City city, {IconData icon = Icons.location_city}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(city.name),
      subtitle: Text(city.uf.isEmpty ? 'UF não informada' : city.uf),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _open(city),
    );
  }
}
