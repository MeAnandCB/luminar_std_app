// widgets/section_header.dart
import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final VoidCallback? onViewAll;

  const SectionHeader({Key? key, required this.title, this.count, this.onViewAll}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (count != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                  child: Text(count.toString(), style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                ),
              ],
            ],
          ),
          if (onViewAll != null) TextButton(onPressed: onViewAll, child: const Text('View All')),
        ],
      ),
    );
  }
}
