import 'package:flutter/material.dart';

class HorizontalFormField extends StatelessWidget {
  final String label;
  final Widget child;
  final bool required;

  const HorizontalFormField({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                required ? '$label *' : label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: required ? Colors.black87 : Colors.grey[700],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class FormRow extends StatelessWidget {
  final List<Widget> children;

  const FormRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.map((child) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: child,
        ))).toList(),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onDecrement != null)
                GestureDetector(
                  onTap: onDecrement,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                    child: Icon(Icons.remove, size: 16, color: color),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              ),
              if (onIncrement != null)
                GestureDetector(
                  onTap: onIncrement,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                    child: Icon(Icons.add, size: 16, color: color),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
