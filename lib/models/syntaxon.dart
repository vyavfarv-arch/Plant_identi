import 'package:flutter/material.dart';

enum SyntaxonRank { zespol, zwiazek, rzad, klasa }

class Syntaxon {
  final String id;
  final String name;
  final SyntaxonRank rank;
  final Color color;
  final List<String> characteristicSpecies;
  final List<String> differentialSpecies;
  final String? parentId;

  Syntaxon({
    required this.id,
    required this.name,
    required this.rank,
    required this.color,
    required this.characteristicSpecies,
    required this.differentialSpecies,
    this.parentId,
  });

  factory Syntaxon.fromJson(Map<String, dynamic> json) {
    return Syntaxon(
      id: json['id'],
      name: json['name'],
      rank: SyntaxonRank.values.firstWhere((e) => e.toString().split('.').last == json['rank']),
      color: Color(int.parse(json['color'].replaceFirst('#', '0xFF'))),
      characteristicSpecies: List<String>.from(json['char_species']),
      differentialSpecies: List<String>.from(json['diff_species']),
      parentId: json['parent_id'],
    );
  }
}