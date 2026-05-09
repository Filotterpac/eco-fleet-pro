// lib/setup_ui_components.dart
import 'package:flutter/material.dart';

class CategoryIconWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryIconWidget({Key? key, required this.icon, required this.label, required this.isSelected, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: isSelected ? Colors.tealAccent : Colors.grey),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: isSelected ? Colors.tealAccent : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class BigSelectionButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const BigSelectionButton({Key? key, required this.label, required this.isSelected, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.withOpacity(0.3) : Colors.black45,
          border: Border.all(color: isSelected ? Colors.tealAccent : Colors.grey[800]!, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? Colors.tealAccent : Colors.grey)),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final Color titleColor;
  final Widget child;

  const SectionCard({Key? key, required this.title, required this.titleColor, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: titleColor, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}

class LocationField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final Color iconColor;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final bool isLast;

  const LocationField({Key? key, required this.label, required this.controller, required this.icon, required this.iconColor, this.actionIcon, this.onAction, this.isLast = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 12, color: Colors.grey), border: InputBorder.none, isDense: true),
              ),
            ),
            if (actionIcon != null) IconButton(icon: Icon(actionIcon, color: Colors.blueAccent), onPressed: onAction)
          ],
        ),
        if (!isLast) Padding(padding: const EdgeInsets.only(left: 40), child: Divider(color: Colors.grey[800], thickness: 1)),
      ],
    );
  }
}

class SmallField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final Color iconColor;

  const SmallField({Key? key, required this.label, required this.ctrl, required this.icon, this.iconColor = Colors.tealAccent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: iconColor, size: 20),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!)),
      ),
    );
  }
}