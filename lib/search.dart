import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'main.dart';

class Delegate extends SearchDelegate {
  TextStyle style = GoogleFonts.lato(fontSize: 18, color: Colors.black);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            query = '';
          })
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
        icon: Icon(
          Icons.arrow_back,
        ),
        onPressed: () {
          close(context, null);
        });
  }

  @override
  Widget buildResults(BuildContext context) {
    List suggestions = (cityList.where((element) {
              return '${element['city']}'
                  .contains(RegExp(query, caseSensitive: false));
            }).toList() +
            cityList.where((element) {
              return '${element['city']}, ${element['state']}'
                  .contains(RegExp(query, caseSensitive: false));
            }).toList())
        .toSet()
        .toList();

    return ListView.separated(
        physics: BouncingScrollPhysics(),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return ListTile(
              title: Text(
                '${suggestions[index]['city']}, ${suggestions[index]['state']}',
                style: style,
              ),
              onTap: () {
                close(context,
                    '${suggestions[index]['city']}, ${suggestions[index]['state']}');
              });
        },
        separatorBuilder: (context, index) => Divider());
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    Pattern queryPos = RegExp(query, caseSensitive: false);
    List suggestions = query.isNotEmpty
        ? (cityList.where((element) {
                  return '${element['city']}'.contains(queryPos);
                }).toList() +
                cityList.where((element) {
                  return '${element['city']}, ${element['state']}'
                      .contains(queryPos);
                }).toList())
            .toSet()
            .toList()
        : [];

    return ListView.separated(
        physics: BouncingScrollPhysics(),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          List parts =
              '${suggestions[index]['city']}, ${suggestions[index]['state']}'
                  .split(queryPos);

          return ListTile(
              title: RichText(
                text: TextSpan(
                    text: '',
                    children: List.generate(parts.length, (index) {
                      String previousPart = 'first';
                      if (index != 0) previousPart = parts[index - 1];

                      String last = '';
                      if (previousPart.isNotEmpty) {
                        last = previousPart[previousPart.length - 1];
                      }

                      return TextSpan(
                          text: boldQuerySuggestions(
                              query, index, previousPart, last),
                          style: style.copyWith(
                              fontWeight: FontWeight.bold, fontSize: 18),
                          children: [
                            TextSpan(
                                text: parts[index],
                                style: style.copyWith(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 18))
                          ]);
                    })),
              ),
              onTap: () {
                close(context,
                    '${suggestions[index]['city']}, ${suggestions[index]['state']}');
              });
        },
        separatorBuilder: (context, index) => Divider());
  }

  String boldQuerySuggestions(String query, index, previousPart, last) {
    String boldWords = '';

    //dont bold words before first part ('' if query is first)
    if (previousPart == 'first')
      boldWords = '';
    //if the query appears first and there is no letter before it then capitalize
    // if the query is more than one word capitalize all
    else if ((index == 1 && previousPart == '') ||
        query.contains(' ') ||
        last == ' ') {
      List queryParts = query.split(' ');
      for (String part in queryParts) {
        //make the first letter of every part uppercase since there are spaces between parts
        if (part.isNotEmpty) {
          boldWords += part[0].toUpperCase() + part.substring(1).toLowerCase();

          //add spaces after parts except the last one
          if (queryParts.last != part) boldWords += ' ';
        }
      }
    } else {
      boldWords = query.toLowerCase();
    }

    return boldWords;
  }
}
