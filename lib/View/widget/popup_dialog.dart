import 'package:flutter/material.dart';

void showPopupDialog(BuildContext context, String title, String message, Color color) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Icon(
            title == "Error" ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
          ),
          SizedBox(width: 8),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}
