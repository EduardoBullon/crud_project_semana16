import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pokemon.dart';
import '../database/database_helper.dart';

class PokemonDetailScreen extends StatefulWidget {
  final Pokemon pokemon;

  const PokemonDetailScreen({super.key, required this.pokemon});

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late Pokemon _pokemon;

  @override
  void initState() {
    super.initState();
    _pokemon = widget.pokemon;
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await _dbHelper.isFavorite(_pokemon.id);
    setState(() {
      _pokemon = _pokemon.copyWith(isFavorite: isFav);
    });
  }

  Future<void> _toggleFavorite() async {
    if (_pokemon.isFavorite) {
      await _dbHelper.deleteFavorite(_pokemon.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Eliminado de favoritos')));
      }
    } else {
      await _dbHelper.addFavorite(_pokemon.copyWith(isFavorite: true));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Agregado a favoritos')));
      }
    }

    setState(() {
      _pokemon = _pokemon.copyWith(isFavorite: !_pokemon.isFavorite);
    });
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'normal':
        return Colors.grey;
      case 'fire':
        return Colors.orange;
      case 'water':
        return Colors.blue;
      case 'electric':
        return Colors.yellow;
      case 'grass':
        return Colors.green;
      case 'ice':
        return Colors.cyan;
      case 'fighting':
        return Colors.red;
      case 'poison':
        return Colors.purple;
      case 'ground':
        return Colors.brown;
      case 'flying':
        return Colors.indigo;
      case 'psychic':
        return Colors.pink;
      case 'bug':
        return Colors.lightGreen;
      case 'rock':
        return Colors.brown.shade700;
      case 'ghost':
        return Colors.deepPurple;
      case 'dragon':
        return Colors.deepOrange;
      case 'dark':
        return Colors.black87;
      case 'steel':
        return Colors.blueGrey;
      case 'fairy':
        return Colors.pinkAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pokemon.name.toUpperCase()),
        backgroundColor: _getTypeColor(_pokemon.types.first),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _pokemon.isFavorite ? Icons.favorite : Icons.favorite_border,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con imagen
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _getTypeColor(_pokemon.types.first).withValues(alpha: 0.7),
                    Colors.white,
                  ],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CachedNetworkImage(
                    imageUrl: _pokemon.imageUrl,
                    height: 200,
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error, size: 100),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '#${_pokemon.id.toString().padLeft(3, '0')}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Información básica
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipos
                  const Text(
                    'Tipos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _pokemon.types.map((type) {
                      return Chip(
                        label: Text(
                          type.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: _getTypeColor(type),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Medidas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoCard(
                        icon: Icons.straighten,
                        title: 'Altura',
                        value: '${(_pokemon.height / 10).toStringAsFixed(1)} m',
                      ),
                      _buildInfoCard(
                        icon: Icons.fitness_center,
                        title: 'Peso',
                        value:
                            '${(_pokemon.weight / 10).toStringAsFixed(1)} kg',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Habilidades
                  const Text(
                    'Habilidades',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _pokemon.abilities.map((ability) {
                      return Chip(
                        label: Text(ability),
                        backgroundColor: Colors.blue.shade100,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Estadísticas
                  const Text(
                    'Estadísticas Base',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._pokemon.stats.entries.map((stat) {
                    return _buildStatBar(stat.key, stat.value);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 4,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: _getTypeColor(_pokemon.types.first)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBar(String statName, int value) {
    final maxStat = 255;
    final percentage = value / maxStat;

    String displayName = statName;
    switch (statName) {
      case 'hp':
        displayName = 'HP';
        break;
      case 'attack':
        displayName = 'Ataque';
        break;
      case 'defense':
        displayName = 'Defensa';
        break;
      case 'special-attack':
        displayName = 'Ataque Esp.';
        break;
      case 'special-defense':
        displayName = 'Defensa Esp.';
        break;
      case 'speed':
        displayName = 'Velocidad';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_getStatColor(value)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatColor(int value) {
    if (value < 50) return Colors.red;
    if (value < 80) return Colors.orange;
    if (value < 120) return Colors.yellow.shade700;
    return Colors.green;
  }
}
