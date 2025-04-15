import 'package:flutter/material.dart';

String ShowDialog(BuildContext context, String title, List<String> body, bool Function() function) {
  String returnString = '';
  String _body = '';

  for (int i=0; i<body.length; i++){
    _body += "\"${body[i]}\"\n";
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Do you want to delete $title?"),
      content: Text("Are you sure?\nDelete $_body"),
      actions: [
        TextButton(
          onPressed: (){
            Navigator.of(context).pop();
            function();
            returnString = 'y';
          }, 
          child: Text("Yes")),
        TextButton(
          onPressed: (){
            Navigator.of(context).pop();
            returnString = 'n';
          }, 
          child: Text("No")),
      ],
    ),
  );
  return returnString;
}


bool AddAnother(BuildContext context, String title, List<dynamic> views){
  bool _isConfirm = false;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Add HQ'),
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
            _isConfirm = true;
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: Text('No'),
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
      ],
    ),
  );
  return _isConfirm;
}