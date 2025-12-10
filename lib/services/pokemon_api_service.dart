import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';

class PokemonApiService {
  static const String baseUrl = 'https://pokeapi.co/api/v2';

  // Obtener lista de pokemones (con paginación) - OPTIMIZADO CON LOTES
  Future<List<Pokemon>> getPokemons({int limit = 151, int offset = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pokemon?limit=$limit&offset=$offset'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Pokemon> allPokemons = [];

        // Procesar en lotes de 20 para no saturar
        final List<dynamic> results = data['results'];
        const batchSize = 20;

        for (int i = 0; i < results.length; i += batchSize) {
          final end = (i + batchSize < results.length)
              ? i + batchSize
              : results.length;
          final batch = results.sublist(i, end);

          // Procesar lote en paralelo
          final futures = batch
              .map((item) => getPokemonDetails(item['url']))
              .toList();
          final batchResults = await Future.wait(futures);

          // Agregar resultados válidos
          allPokemons.addAll(batchResults.whereType<Pokemon>());
        }

        return allPokemons;
      } else {
        throw Exception('Error al cargar pokemones');
      }
    } catch (e) {
      // Error al cargar pokemones
      return [];
    }
  }

  // Obtener detalles de un pokemon específico
  Future<Pokemon?> getPokemonDetails(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Pokemon.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      // Error al obtener detalles
      return null;
    }
  }

  // Obtener pokemon por ID
  Future<Pokemon?> getPokemonById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pokemon/$id'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Pokemon.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      // Error al obtener pokemon por ID
      return null;
    }
  }

  // Buscar pokemon por nombre
  Future<Pokemon?> searchPokemonByName(String name) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pokemon/${name.toLowerCase()}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Pokemon.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      // Error al buscar pokemon
      return null;
    }
  }
}
