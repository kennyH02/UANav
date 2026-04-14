import 'package:flutter/material.dart';
import 'ualbany_theme.dart';

/// Flutter code for [SearchBar] for UNav.

void main() => runApp(const MaterialApp(home: Scaffold(body: SearchBarWidget())));

class SearchBarWidget extends StatelessWidget {
   final String hintText;

   const SearchBarWidget({super.key, this.hintText = "Search UNav..."});

   @override
   Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(UAlbanyTheme.edgePadding),
      child: Container(
         decoration: BoxDecoration(
            color: UAlbanyTheme.lightgray,
            borderRadius: BorderRadius.circular(UAlbanyTheme.borderRadius),
            border: Border.all(color: UAlbanyTheme.purple, width: 1.5),
         ),
         child: TextFeild(
            decoration: InputDecoration(
               hintText: hintText,
               prefixIcon: const Icon(Icons.search, color: UAlbanyTheme.purple),
               border: InputBorder.none,
               contentPadding: const EdgeInsets.symmertric(vertical: 15),
            ),
         ),
      ),
    );
   }         
}