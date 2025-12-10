import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pokemon.dart';
import '../services/pokemon_api_service.dart';
import '../database/database_helper.dart';
import 'pokemon_detail_screen.dart';
import 'favorites_screen.dart';
import 'team_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PokemonApiService _apiService = PokemonApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Pokemon> _pokemons = [];
  List<Pokemon> _filteredPokemons = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPokemons();
  }

  Future<void> _loadPokemons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar 100 pokemones para tener más variedad
      final pokemons = await _apiService.getPokemons(limit: 100);

      if (pokemons.isEmpty) {
        // Si no hay pokémons, mostrar error
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudieron cargar los pokémones. Verifica tu conexión a internet.',
              ),
              duration: Duration(seconds: 5),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Verificar cuáles están en favoritos
      for (var pokemon in pokemons) {
        pokemon.isFavorite = await _dbHelper.isFavorite(pokemon.id);
      }

      setState(() {
        _pokemons = pokemons;
        _filteredPokemons = pokemons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e\n\nVerifica tu conexión a internet.'),
            duration: const Duration(seconds: 8),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: _loadPokemons,
            ),
          ),
        );
      }
    }
  }

  void _filterPokemons(String query) async {
    setState(() {
      _searchQuery = query;
      _isLoading = true;
    });

    if (query.isEmpty) {
      setState(() {
        _filteredPokemons = _pokemons;
        _isLoading = false;
      });
      return;
    }

    // Buscar en la lista local primero
    final localResults = _pokemons
        .where(
          (pokemon) =>
              pokemon.name.toLowerCase().contains(query.toLowerCase()) ||
              pokemon.id.toString().contains(query),
        )
        .toList();

    // Si hay resultados locales, mostrarlos
    if (localResults.isNotEmpty) {
      setState(() {
        _filteredPokemons = localResults;
        _isLoading = false;
      });
      return;
    }

    // Si no hay resultados locales, buscar en la API
    try {
      final searchResult = await _apiService.searchPokemonByName(query);
      if (searchResult != null) {
        searchResult.isFavorite = await _dbHelper.isFavorite(searchResult.id);
        setState(() {
          _filteredPokemons = [searchResult];
          _isLoading = false;
        });
      } else {
        setState(() {
          _filteredPokemons = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _filteredPokemons = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(Pokemon pokemon) async {
    if (pokemon.isFavorite) {
      await _dbHelper.deleteFavorite(pokemon.id);
    } else {
      await _dbHelper.addFavorite(pokemon.copyWith(isFavorite: true));
    }

    setState(() {
      pokemon.isFavorite = !pokemon.isFavorite;
    });
  }

  Future<void> _addToTeam(Pokemon pokemon) async {
    final success = await _dbHelper.addToTeam(pokemon);

    if (!mounted) return;

    if (success) {
      final count = await _dbHelper.getTeamCount();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${pokemon.name.toUpperCase()} agregado al equipo ($count/6)',
          ),
          action: SnackBarAction(
            label: 'Ver Equipo',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TeamScreen()),
              );
            },
          ),
        ),
      );
    } else {
      final isInTeam = await _dbHelper.isInTeam(pokemon.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isInTeam
                ? '${pokemon.name.toUpperCase()} ya está en el equipo'
                : 'Equipo lleno (máximo 6 pokemones)',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Pokédex de Eduardo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.groups),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TeamScreen()),
              );
              _loadPokemons();
            },
            tooltip: 'Mi Equipo',
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
              _loadPokemons(); // Recargar al volver
            },
            tooltip: 'Favoritos',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPokemons,
            tooltip: 'Refrescar',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 100),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '🔍 Buscar Pokémon...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF6C5CE7),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onChanged: _filterPokemons,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6C5CE7,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF6C5CE7),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Cargando Pokémon...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6C5CE7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filteredPokemons.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No hay pokemones'
                                : 'No se encontraron pokemones',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: _filteredPokemons.length,
                      itemBuilder: (context, index) {
                        final pokemon = _filteredPokemons[index];
                        return _buildPokemonCard(pokemon);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPokemonCard(Pokemon pokemon) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PokemonDetailScreen(pokemon: pokemon),
            ),
          );
          _loadPokemons(); // Recargar al volver
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getTypeColor(pokemon.types.first).withValues(alpha: 0.8),
                _getTypeColor(pokemon.types.first).withValues(alpha: 0.4),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _getTypeColor(
                  pokemon.types.first,
                ).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.group_add, color: Colors.white),
                    onPressed: () => _addToTeam(pokemon),
                    tooltip: 'Agregar al equipo',
                  ),
                  IconButton(
                    icon: Icon(
                      pokemon.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: pokemon.isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: () => _toggleFavorite(pokemon),
                    tooltip: 'Favorito',
                  ),
                ],
              ),
              Expanded(
                child: Hero(
                  tag: 'pokemon-${pokemon.id}',
                  child: CachedNetworkImage(
                    imageUrl: pokemon.imageUrl,
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error, color: Colors.white),
                    height: 100,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#${pokemon.id.toString().padLeft(3, '0')}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pokemon.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      offset: Offset(1, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: pokemon.types.map((type) {
                  return Chip(
                    label: Text(
                      type,
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                    backgroundColor: _getTypeColor(type),
                    padding: const EdgeInsets.all(2),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
