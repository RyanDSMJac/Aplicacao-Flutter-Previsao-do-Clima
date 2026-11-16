/// Localidade retornada pelo serviço de busca do CPTEC/INPE.
class City {
  final int id; // identificador retornado pelo serviço
  final String name;
  final String uf;

  const City({required this.id, required this.name, required this.uf});

  String get label => uf.isEmpty ? name : '$name - $uf';

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'uf': uf};

  static City? fromJson(dynamic json) {
    if (json is! Map) return null;
    final id = json['id'];
    final name = json['name'];
    if (id is! int || name is! String || name.isEmpty) return null;
    return City(id: id, name: name, uf: (json['uf'] as String?) ?? '');
  }
}
