import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutterquiz/model/categories.dart';
import 'package:flutterquiz/util/constant.dart';

DecorationImage buildImage(String base64Str) {
  final imageBytes = base64Decode(base64Str);
  return DecorationImage(
    image: MemoryImage(imageBytes),
    fit: BoxFit.cover,
  );
}

class CardItem extends StatelessWidget {
  final int index;
  final String image;
  final String name;
  // final Category category;

  const CardItem(
      {Key? key, required this.index, required this.image, required this.name})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: buildImage(image),
      ),
      child: Stack(
        children: <Widget>[
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                name,
                style: TextStyle(
                    fontSize: 19,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }
}
