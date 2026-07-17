import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class PremiumCommandSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final VoidCallback? onFilterTap;
  final bool autofocus;

  const PremiumCommandSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Cari barang, merek, atau kategori...',
    this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
    this.autofocus = false,
  });

  @override
  State<PremiumCommandSearchBar> createState() =>
      _PremiumCommandSearchBarState();
}

class _PremiumCommandSearchBarState extends State<PremiumCommandSearchBar> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_isFocused == _focusNode.hasFocus) return;
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      height: 48,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: _isFocused
              ? context.colors.primary.withValues(alpha: 0.5)
              : Colors.black.withValues(alpha: 0.05),
          width: _isFocused ? 1.5 : 1.0,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: context.colors.primary.withValues(alpha: 0.08),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.sm,
            ),
            child: Icon(
              Icons.search_rounded,
              color: _isFocused
                  ? context.colors.primary
                  : context.colors.textMuted,
              size: 20,
            ),
          ),
          Expanded(
            child: CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(
                  LogicalKeyboardKey.keyK,
                  control: true,
                ): () {
                  _focusNode.requestFocus();
                },
                const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () {
                  _focusNode.requestFocus();
                },
              },
              child: Focus(
                autofocus: widget.autofocus,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  onChanged: (value) {
                    if (widget.onChanged != null) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 350), () {
                        widget.onChanged!(value);
                      });
                    }
                  },
                  onSubmitted: (_) {
                    if (_debounce?.isActive ?? false) {
                      _debounce!.cancel();
                    }
                    if (widget.onChanged != null) {
                      widget.onChanged!(widget.controller?.text ?? '');
                    }
                    if (widget.onSubmitted != null) {
                      widget.onSubmitted!();
                    }
                  },
                  textInputAction: TextInputAction.search,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: context.colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: context.colors.textMuted,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ),

          if (widget.onFilterTap != null)
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: widget.onFilterTap,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle),
                    child: Icon(
                      Icons.tune_rounded,
                      color: context.colors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: AppSpacing.sm),
        ],
      ),
    );
  }
}
