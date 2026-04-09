import 'package:flutter/material.dart';

/// Flutter code for [SearchBar] for UNav.

void main() => runApp(const SearchBarWidget());

class SearchBarWidget extends StatelessWidget {
   final String hinttext;

   const SearchBarWidget({super.key, this.hintText = "Search UNav..."});

   @override
   Widget build(BuildContext context) {
    return Padding(
       padding: const EdgeInsets.all(UAlbanyTheme.edgePadding),
       child.Container(
        decoration: BoxDecoration
            color: UAlbanyTheme.lightgray,
            borderRadius: BorderRadius.circular(UAlbanyTheme.borderRadius),
            border: Border.all(color:UAlbanyTheme.purple, width: 1.5),
       ),
     ),
        child TextField(
            decoration: InputDecoration(
            hintText: hintText,
            prefixicon: const Icon(Icons.search, color: UAlbanyTheme.purple),
            borderRadius: BorderRadius.circular(UAlbanyTheme.borderRadius),
            border:InputBorder.none,
            contentPadding: EdgeInsets.symmetric(verical: 15),
            ),
        );
   }         
}