import 'package:flutter/material.dart';

/// Widget pour afficher un texte avec option d'expansion
class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final String expandText;
  final String collapseText;
  final Color? linkColor;

  const ExpandableText({
    Key? key,
    required this.text,
    this.maxLines = 3,
    this.style,
    this.expandText = 'Voir plus',
    this.collapseText = 'Voir moins',
    this.linkColor,
  }) : super(key: key);

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: widget.style,
          maxLines: _isExpanded ? null : widget.maxLines,
          overflow: _isExpanded ? null : TextOverflow.ellipsis,
        ),
        if (widget.text.length > 100) // Simple heuristic
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _isExpanded ? widget.collapseText : widget.expandText,
                style: TextStyle(
                  color: widget.linkColor ?? Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: Theme.of(context).platform == TargetPlatform.iOS ? 14 : 13,
                  height: 1.2,
                  letterSpacing: Theme.of(context).platform == TargetPlatform.iOS ? -0.1 : -0.2,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
      ],
    );
  }
}