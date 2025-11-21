import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../utils/performance_utils.dart';

/// Widget de card optimisé avec RepaintBoundary et constantes
class OptimizedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const OptimizedCard({
    super.key,
    required this.child,
    this.padding = PerformanceConstants.defaultPadding,
    this.color,
    this.elevation = 1.0,
    this.borderRadius = PerformanceConstants.defaultRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        color: color,
        elevation: elevation,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? PerformanceConstants.defaultRadius,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? PerformanceConstants.defaultRadius,
          child: Padding(
            padding: padding ?? PerformanceConstants.defaultPadding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Widget de liste optimisé avec RepaintBoundary automatique
class OptimizedListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;
  final Color? selectedColor;

  const OptimizedListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        selected: selected,
        selectedColor: selectedColor,
        contentPadding: PerformanceConstants.defaultPadding,
      ),
    );
  }
}

/// Widget de bouton optimisé avec feedback haptique
class OptimizedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final bool isLoading;
  final Widget? icon;
  final bool enableHapticFeedback;

  const OptimizedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style,
    this.isLoading = false,
    this.icon,
    this.enableHapticFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: PerformanceConstants.fastAnimation,
        child: icon != null
            ? ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () {
                        if (enableHapticFeedback) {
                          HapticFeedback.lightImpact();
                        }
                        onPressed?.call();
                      },
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : icon!,
                label: Text(text),
                style: style,
              )
            : ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        if (enableHapticFeedback) {
                          HapticFeedback.lightImpact();
                        }
                        onPressed?.call();
                      },
                style: style,
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(text),
              ),
      ),
    );
  }
}

/// Widget de TextField optimisé avec debounce
class OptimizedTextField extends StatefulWidget {
  final String? hintText;
  final String? labelText;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final Duration debounceDuration;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const OptimizedTextField({
    super.key,
    this.hintText,
    this.labelText,
    this.controller,
    this.onChanged,
    this.debounceDuration = PerformanceConstants.inputDebounce,
    this.keyboardType,
    this.maxLines = 1,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
  });

  @override
  State<OptimizedTextField> createState() => _OptimizedTextFieldState();
}

class _OptimizedTextFieldState extends State<OptimizedTextField> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onChanged?.call(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TextFormField(
        controller: widget.controller,
        onChanged: widget.onChanged != null ? _onChanged : null,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        obscureText: widget.obscureText,
        validator: widget.validator,
        decoration: InputDecoration(
          hintText: widget.hintText,
          labelText: widget.labelText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
          border: const OutlineInputBorder(),
          contentPadding: PerformanceConstants.defaultPadding,
        ),
      ),
    );
  }
}

/// Widget de grid optimisé pour les performances
class OptimizedGridView extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const OptimizedGridView({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GridView.count(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
        padding: padding,
        physics: physics,
        shrinkWrap: shrinkWrap,
        children: children.map((child) => RepaintBoundary(child: child)).toList(),
      ),
    );
  }
}

/// Widget de StreamBuilder optimisé avec cache et debounce
class OptimizedStreamBuilder<T> extends StatefulWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Duration cacheDuration;
  final Duration debounceDuration;

  const OptimizedStreamBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.cacheDuration = const Duration(minutes: 5),
    this.debounceDuration = const Duration(milliseconds: 100),
  });

  @override
  State<OptimizedStreamBuilder<T>> createState() => _OptimizedStreamBuilderState<T>();
}

class _OptimizedStreamBuilderState<T> extends State<OptimizedStreamBuilder<T>> {
  static final Map<String, dynamic> _cache = {};
  late String _cacheKey;
  Timer? _cacheTimer;

  @override
  void initState() {
    super.initState();
    _cacheKey = widget.stream.toString();
  }

  @override
  void dispose() {
    _cacheTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: widget.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // Mettre en cache les données
          _cache[_cacheKey] = snapshot.data;
          _cacheTimer?.cancel();
          _cacheTimer = Timer(widget.cacheDuration, () {
            _cache.remove(_cacheKey);
          });

          return RepaintBoundary(
            child: widget.builder(context, snapshot.data as T),
          );
        } else if (snapshot.hasError) {
          return widget.errorBuilder?.call(context, snapshot.error!) ??
              Center(
                child: Text('Erreur: ${snapshot.error}'),
              );
        } else {
          // Vérifier le cache pendant le chargement
          if (_cache.containsKey(_cacheKey)) {
            return RepaintBoundary(
              child: widget.builder(context, _cache[_cacheKey] as T),
            );
          }

          return widget.loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

/// Mixin pour optimiser les animations
mixin AnimationOptimization on State, TickerProviderStateMixin {
  late AnimationController _optimizedController;
  static const Duration _defaultDuration = PerformanceConstants.normalAnimation;

  @override
  void initState() {
    super.initState();
    _optimizedController = AnimationController(
      duration: _defaultDuration,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _optimizedController.dispose();
    super.dispose();
  }

  AnimationController get controller => _optimizedController;

  /// Animation avec courbe optimisée
  Animation<double> createOptimizedAnimation({
    Curve curve = Curves.easeInOutCubic,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: _optimizedController,
      curve: curve,
    ));
  }
}