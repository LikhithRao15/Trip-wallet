import 'package:flutter/material.dart';

const List<String> kExpenseCategories = [
  'FOOD',
  'TRAVEL',
  'HOTEL',
  'SHOPPING',
  'TICKETS',
  'ENTERTAINMENT',
  'MEDICAL',
  'OTHER',
];

IconData getExpenseCategoryIcon(String category) {
  switch (category.trim().toUpperCase()) {
    case 'FOOD':
      return Icons.restaurant;
    case 'TRAVEL':
      return Icons.directions_car;
    case 'HOTEL':
      return Icons.hotel;
    case 'SHOPPING':
      return Icons.shopping_bag;
    case 'TICKETS':
      return Icons.confirmation_num;
    case 'ENTERTAINMENT':
      return Icons.theater_comedy;
    case 'MEDICAL':
      return Icons.medical_services;
    case 'OTHER':
    default:
      return Icons.receipt_long;
  }
}

Color getExpenseCategoryColor(String category) {
  switch (category.trim().toUpperCase()) {
    case 'FOOD':
      return Colors.orange;
    case 'TRAVEL':
      return Colors.blue;
    case 'HOTEL':
      return Colors.indigo;
    case 'SHOPPING':
      return Colors.pink;
    case 'TICKETS':
      return Colors.teal;
    case 'ENTERTAINMENT':
      return Colors.purple;
    case 'MEDICAL':
      return Colors.red;
    case 'OTHER':
    default:
      return Colors.grey.shade700;
  }
}
