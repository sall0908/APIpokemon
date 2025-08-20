import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}


class Pokemon {
  final int id;
  final String name;
  final String image;
  final List<String> types;
  final List<String> abilities;
  final List<Map<String, dynamic>> stats;
  final List<String> moves;

  Pokemon({
    required this.id,
    required this.name,
    required this.image,
    required this.types,
    required this.abilities,
    required this.stats,
    required this.moves,
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    return Pokemon(
      id: json['id'],
      name: json['name'],
      image: json['sprites']['other']['official-artwork']['front_default'] ?? '',
      types: List<String>.from(json['types'].map((t) => t['type']['name'])),
      abilities: List<String>.from(json['abilities'].map((a) => a['ability']['name'])),
      stats: List<Map<String, dynamic>>.from(json['stats']),
      moves: List<String>.from(json['moves'].take(5).map((m) => m['move']['name'])),
    );
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon Detail',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const PokemonPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PokemonPage extends StatefulWidget {
  const PokemonPage({super.key});

  @override
  State<PokemonPage> createState() => _PokemonPageState();
}

class _PokemonPageState extends State<PokemonPage> {
  List<Pokemon> detailedPokemons = [];
  List<Pokemon> filteredPokemons = [];
  int offset = 0;
  bool isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchDetailedPokemons();
  }

  Future<void> fetchDetailedPokemons({bool isLoadMore = false}) async {
    setState(() => isLoading = true);
    final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=10&offset=$offset'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];

      for (var item in results) {
        final detail = await http.get(Uri.parse(item['url']));
        if (detail.statusCode == 200) {
          final detailData = json.decode(detail.body);
          final pokemon = Pokemon.fromJson(detailData);
          detailedPokemons.add(pokemon);
        }
      }

      setState(() {
        filteredPokemons = List.from(detailedPokemons);
        isLoading = false;
      });
    } else {
      throw Exception('Gagal memuat daftar Pokémon');
    }
  }

  void searchPokemon(String query) {
    final q = query.toLowerCase();
    setState(() {
      filteredPokemons = detailedPokemons.where((p) => p.name.contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon Detail'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              onChanged: searchPokemon,
              decoration: InputDecoration(
                labelText: 'Cari Pokémon...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                detailedPokemons.clear();
                offset = 0;
                await fetchDetailedPokemons();
              },
              child: isLoading && detailedPokemons.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: filteredPokemons.length + 1,
                      itemBuilder: (context, index) {
                        if (index == filteredPokemons.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: ElevatedButton(
                              onPressed: () {
                                offset += 10;
                                fetchDetailedPokemons(isLoadMore: true);
                              },
                              child: const Text('Load More'),
                            ),
                          );
                        }

                        final pokemon = filteredPokemons[index];
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Image.network(
                                    pokemon.image,
                                    height: 120,
                                    width: 120,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: Text(
                                    pokemon.name.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Center(child: Text("ID: ${pokemon.id}")),
                                Center(
                                  child: Text(
                                    "Tipe: ${pokemon.types.join(', ')}",
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Kemampuan: ${pokemon.abilities.join(', ')}",
                                  style: const TextStyle(fontStyle: FontStyle.italic),
                                ),
                                const SizedBox(height: 12),
                                const Text("Statistik:", style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                ...pokemon.stats.map((stat) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          stat['stat']['name'],
                                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                                        ),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: LinearProgressIndicator(
                                            value: stat['base_stat'] / 100.0,
                                            minHeight: 8,
                                            backgroundColor: Colors.grey.shade300,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 12),
                                const Text("Moves (5 pertama):", style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                ...pokemon.moves.map((move) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Text("• $move"),
                                    )),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
