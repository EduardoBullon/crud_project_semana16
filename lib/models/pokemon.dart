class Pokemon {
  final int id;
  final String name;
  final String imageUrl;
  final int height;
  final int weight;
  final List<String> types;
  final List<String> abilities;
  final Map<String, int> stats;
  bool isFavorite;

  Pokemon({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.height,
    required this.weight,
    required this.types,
    required this.abilities,
    required this.stats,
    this.isFavorite = false,
  });

  // Crear desde JSON de la API
  factory Pokemon.fromJson(Map<String, dynamic> json) {
    List<String> typesList = [];
    if (json['types'] != null) {
      for (var type in json['types']) {
        typesList.add(type['type']['name']);
      }
    }

    List<String> abilitiesList = [];
    if (json['abilities'] != null) {
      for (var ability in json['abilities']) {
        abilitiesList.add(ability['ability']['name']);
      }
    }

    Map<String, int> statsMap = {};
    if (json['stats'] != null) {
      for (var stat in json['stats']) {
        statsMap[stat['stat']['name']] = stat['base_stat'];
      }
    }

    return Pokemon(
      id: json['id'],
      name: json['name'],
      imageUrl:
          json['sprites']['other']['official-artwork']['front_default'] ??
          json['sprites']['front_default'] ??
          '',
      height: json['height'],
      weight: json['weight'],
      types: typesList,
      abilities: abilitiesList,
      stats: statsMap,
    );
  }

  // Convertir a Map para guardar en base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'height': height,
      'weight': weight,
      'types': types.join(','),
      'abilities': abilities.join(','),
      'stats': stats.entries.map((e) => '${e.key}:${e.value}').join(','),
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  // Crear desde Map de la base de datos
  factory Pokemon.fromMap(Map<String, dynamic> map) {
    List<String> typesList = map['types'].toString().split(',');
    List<String> abilitiesList = map['abilities'].toString().split(',');

    Map<String, int> statsMap = {};
    List<String> statsList = map['stats'].toString().split(',');
    for (var stat in statsList) {
      var parts = stat.split(':');
      if (parts.length == 2) {
        statsMap[parts[0]] = int.parse(parts[1]);
      }
    }

    return Pokemon(
      id: map['id'],
      name: map['name'],
      imageUrl: map['imageUrl'],
      height: map['height'],
      weight: map['weight'],
      types: typesList,
      abilities: abilitiesList,
      stats: statsMap,
      isFavorite: map['isFavorite'] == 1,
    );
  }

  Pokemon copyWith({
    int? id,
    String? name,
    String? imageUrl,
    int? height,
    int? weight,
    List<String>? types,
    List<String>? abilities,
    Map<String, int>? stats,
    bool? isFavorite,
  }) {
    return Pokemon(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      types: types ?? this.types,
      abilities: abilities ?? this.abilities,
      stats: stats ?? this.stats,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
