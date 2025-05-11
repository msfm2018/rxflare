import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

final myData = RxValue<Map<dynamic, dynamic>>({"a": 1, "b": 2, 1: "one"});
final myList = RxValue<List<String>>(["apple", "banana"]);

class MyReactiveWidget extends StatefulWidget {
  const MyReactiveWidget({super.key});

  @override
  State<MyReactiveWidget> createState() => _MyReactiveWidgetState();
}

class _MyReactiveWidgetState extends State<MyReactiveWidget> {
  String? aValue;
  String? firstListItem;

  @override
  void initState() {
    super.initState();
    myData.addFieldListener("a", (newValue) {
      setState(() {
        aValue = newValue.toString();
      });
    });

    myData.addFieldListener(1, (newValue) {
      setState(() {
        firstListItem = newValue.toString();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Rx(() => Text("Map Value a: ${myData.value["a"]}")),

        Rx(() => Text("List Item 0: ${myList.value.isNotEmpty ? myList.value[0] : ''}")),

        if (firstListItem != null) Text("Listened index 0***** value: $firstListItem"),
        if (aValue != null) Text("Listened a value: $aValue"),

        ElevatedButton(
          onPressed: () {
            myData.updateField("a", "Updated A");
          },
          child: const Text("Update A"),
        ),
        ElevatedButton(
          onPressed: () {
            myData.updateField(1, "Updated One");
          },
          child: const Text("Update One++++++++++++"),
        ),
        ElevatedButton(
          onPressed: () {
            myList.updateField(0, "orange");
          },
          child: const Text("Update List Item 0"),
        ),
      ],
    );
  }
}
