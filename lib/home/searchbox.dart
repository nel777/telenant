import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:telenant/FirebaseServices/services.dart';
import 'package:telenant/home/viewmore.dart';
import 'package:telenant/models/model.dart';

class SearchDemo extends StatefulWidget {
  final List<String> data;
  static const String routeName = '/material/search';

  const SearchDemo({super.key, required this.data});

  @override
  _SearchDemoState createState() => _SearchDemoState();
}

class _SearchDemoState extends State<SearchDemo> {
  late final List<String> _data = widget.data;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Search Transient'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () async {
              await showSearch(
                context: context,
                delegate: _SearchDemoSearchDelegate(_data),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            MergeSemantics(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const <Widget>[
                      Text('Press the '),
                      Tooltip(
                        message: 'search',
                        child: Icon(
                          Icons.search,
                          size: 18.0,
                        ),
                      ),
                      Text(' icon in the AppBar'),
                    ],
                  ),
                  const Text(
                      'and search for a transient registered in our database.'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Back', // Tests depend on this label to exit the demo.
        onPressed: () {
          Navigator.of(context).pop();
        },
        label: const Text('Close Search'),
        icon: const Icon(Icons.close),
      ),
    );
  }
}

class _SearchDemoSearchDelegate extends SearchDelegate<List<String>> {
  // final List<int> _data =
  //     List<int>.generate(100001, (int i) => i).reversed.toList();
  // final List<int> _history = <int>[42607, 85604, 66374, 44, 174];
  final List<String> datasearch;

  _SearchDemoSearchDelegate(this.datasearch);

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final Iterable<String> suggestions = datasearch;
    // ? _history
    // : _data.where((int i) => '$i'.startsWith(query));

    return _SuggestionList(
      query: query,
      suggestions: suggestions.map<String>((String i) => i).toList(),
      onSelected: (String suggestion) {
        query = suggestion;
        showResults(context);
      },
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
        tooltip: 'Clear',
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildResults(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestoreService.instance.readItems(),
        builder: ((context, snapshot) {
          QueryDocumentSnapshot<Object?>? finaldata;
          if (snapshot.hasData) {
            for (final detail in snapshot.data!.docs
                .where((element) => element['name'] == query)) {
              finaldata = detail;
            }
          }
          return finaldata == null
              ? const Center(
                  child: SizedBox(
                    height: 30,
                    width: 30,
                    child: CircularProgressIndicator(),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 300,
                    child: Card(
                      shape: OutlineInputBorder(
                          borderSide: const BorderSide(
                              width: 1.5, color: Colors.blueGrey),
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(10),
                                topLeft: Radius.circular(10)),
                            child: Image.network(
                              finaldata['coverpage'],
                              width: 500,
                              height: 200,
                              fit: BoxFit.cover,
                              loadingBuilder: (BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(
                              Icons.place,
                              color: Colors.blue,
                            ),
                            title: Text(finaldata['name'].toString()),
                            subtitle: Text(finaldata['location'].toString()),
                            trailing: TextButton(
                                onPressed: () {
                                  //print(finaldata!['pricerange']);
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: ((context) => ViewMore(
                                              detail: details(
                                            name: finaldata!['name'],
                                            location: finaldata['location'],
                                            coverPage: finaldata['coverpage'],
                                            bedrooms: finaldata['bedrooms'],
                                            gallery: finaldata['gallery'],
                                            // priceRange: PriceRange(
                                            //     min: finaldata['pricerange']
                                            //         ['min'],
                                            //     max: finaldata['pricerange']
                                            //         ['max']),
                                            contact: finaldata['contact'],
                                            type: finaldata['type'],
                                            website: finaldata['website'],
                                          )))));
                                },
                                child: const Text('View')),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
        }));
  }
}

// class _ResultCard extends StatelessWidget {
//   const _ResultCard(
//       {required this.integer,
//       required this.title,
//       required this.searchDelegate});

//   final int? integer;
//   final String title;
//   final SearchDelegate<int> searchDelegate;

//   @override
//   Widget build(BuildContext context) {
//     final ThemeData theme = Theme.of(context);
//     return GestureDetector(
//       onTap: () {
//         searchDelegate.close(context, integer!);
//       },
//       child: Card(
//         child: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Column(
//             children: <Widget>[
//               Text(title),
//               Text(
//                 '$integer',
//                 //style: theme.textTheme.headline.copyWith(fontSize: 72.0),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class _SuggestionList extends StatelessWidget {
  const _SuggestionList(
      {required this.suggestions,
      required this.query,
      required this.onSelected});

  final List<String> suggestions;
  final String query;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    //final ThemeData theme = Theme.of(context);
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (BuildContext context, int i) {
        final String suggestion = suggestions[i];
        return ListTile(
          leading: query.isEmpty ? const Icon(Icons.history) : const Icon(null),
          title: RichText(
            text: TextSpan(
              text: suggestion.substring(0, query.length),
              style: const TextStyle(color: Colors.black),
              children: <TextSpan>[
                TextSpan(
                  text: suggestion.substring(query.length),
                  //style: theme.textTheme.subhead,
                ),
              ],
            ),
          ),
          onTap: () {
            onSelected(suggestion);
          },
        );
      },
    );
  }
}
