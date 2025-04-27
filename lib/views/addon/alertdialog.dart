import 'package:flutter/material.dart';

Future<bool> AddAnother(BuildContext context, String title, List<dynamic> views) async{
  bool ret = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Add $title'),
      content: Text('Do you want to add another $title?'),
      actions: [
        TextButton(
          child: Text('Yes'),
          onPressed: () {
            for (dynamic view in views){
              if (view is TextEditingController){
                view.clear();
              }
            }
            Navigator.pop(context,true);
          },
        ),
        TextButton(
          child: Text('No'),
          onPressed: () {
            Navigator.pop(context,false);
          },
        ),
      ],
    ),
  );
  return ret;
}