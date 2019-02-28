import 'package:flutter/material.dart';

class AdvancedSettings extends StatelessWidget {
  final items = List<String>.generate(3, (i) => "Item ${i + 1}");
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('高级'),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          return Dismissible(
            // Each Dismissible must contain a Key. Keys allow Flutter to
            // uniquely identify Widgets.
            key: Key(item),
            // We also need to provide a function that tells our app
            // what to do after an item has been swiped away.
            onDismissed: (direction) {
              // Remove the item from our data source.
              // setState(() {
              //   items.removeAt(index);
              // });

              // Then show a snackbar!
              Scaffold.of(context)
                  .showSnackBar(SnackBar(content: Text("$item dismissed")));
            },
            // Show a red background as the item is swiped away
            background: Container(
                color: Colors.red,
                child: Row(
                  children: <Widget>[
                    Expanded(flex: 1, child: Container()),
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '删除',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  ],
                )),
            child: ListTile(title: Text('$item')),
          );
        },
      ),
    );
  }
}
