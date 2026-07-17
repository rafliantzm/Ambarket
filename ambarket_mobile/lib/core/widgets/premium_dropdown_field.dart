import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

class DropdownItem<T> {
  final T value;
  final String label;

  DropdownItem({required this.value, required this.label});
}

class PremiumDropdownField<T> extends FormField<T> {
  PremiumDropdownField({
    super.key,
    required List<DropdownItem<T>> items,
    required String hintText,
    String? labelText,
    T? value,
    void Function(T?)? onChanged,
    super.validator,
    super.onSaved,
    super.enabled = true,
  }) : super(
         initialValue: value,
         builder: (FormFieldState<T> state) {
           final hasError = state.hasError;
           final colors = state.context.colors;

           DropdownItem<T>? selectedItem;
           for (final item in items) {
             if (item.value == state.value) {
               selectedItem = item;
               break;
             }
           }

           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               if (labelText != null) ...[
                 Text(
                   labelText,
                   style: AppTypography.bodySm.copyWith(
                     color: colors.textSecondary,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
                 const SizedBox(height: 8),
               ],
               Material(
                 color: Colors.transparent,
                 child: InkWell(
                   onTap: enabled
                       ? () async {
                           final T? result = await _showSelector(
                             state.context,
                             items: items,
                             title: labelText ?? hintText,
                             selectedValue: state.value,
                           );
                           if (result != null) {
                             state.didChange(result);
                             if (onChanged != null) {
                               onChanged(result);
                             }
                           }
                         }
                       : null,
                   borderRadius: BorderRadius.circular(16),
                   child: Container(
                     padding: const EdgeInsets.symmetric(
                       horizontal: 16,
                       vertical: 16,
                     ),
                     decoration: BoxDecoration(
                       color: enabled ? colors.surface : colors.background,
                       borderRadius: BorderRadius.circular(16),
                       border: Border.all(
                         color: hasError ? colors.error : colors.border,
                       ),
                     ),
                     child: Row(
                       children: [
                         Expanded(
                           child: Text(
                             selectedItem?.label ?? hintText,
                             style: AppTypography.bodyMd.copyWith(
                               color: selectedItem == null
                                   ? colors.textMuted
                                   : colors.textPrimary,
                             ),
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                           ),
                         ),
                         const SizedBox(width: AppSpacing.sm),
                         Icon(
                           Icons.keyboard_arrow_down,
                           color: colors.textSecondary,
                           size: 20,
                         ),
                       ],
                     ),
                   ),
                 ),
               ),
               if (hasError)
                 Padding(
                   padding: const EdgeInsets.only(top: 6, left: 16),
                   child: Text(
                     state.errorText!,
                     style: AppTypography.bodySm.copyWith(color: colors.error),
                   ),
                 ),
             ],
           );
         },
       );

  static Future<T?> _showSelector<T>(
    BuildContext context, {
    required List<DropdownItem<T>> items,
    required String title,
    T? selectedValue,
  }) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    if (isDesktop) {
      return _showDialogSelector(context, items, title, selectedValue);
    } else {
      return _showBottomSheetSelector(context, items, title, selectedValue);
    }
  }

  static Future<T?> _showBottomSheetSelector<T>(
    BuildContext context,
    List<DropdownItem<T>> items,
    String title,
    T? selectedValue,
  ) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _BottomSheetContent(
        items: items,
        title: title,
        selectedValue: selectedValue,
      ),
    );
  }

  static Future<T?> _showDialogSelector<T>(
    BuildContext context,
    List<DropdownItem<T>> items,
    String title,
    T? selectedValue,
  ) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: ctx.colors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _BottomSheetContent(
            items: items,
            title: title,
            selectedValue: selectedValue,
            isDialog: true,
          ),
        ),
      ),
    );
  }
}

class _BottomSheetContent<T> extends StatelessWidget {
  final List<DropdownItem<T>> items;
  final String title;
  final T? selectedValue;
  final bool isDialog;

  const _BottomSheetContent({
    required this.items,
    required this.title,
    this.selectedValue,
    this.isDialog = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final innerContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isDialog) ...[
          // Bottom Sheet Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderStrong,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 24,
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colors.border),
        Flexible(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemExtent: 56,
            cacheExtent: 280,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = item.value == selectedValue;

              return Material(
                color: isSelected
                    ? colors.primary.withValues(alpha: 0.05)
                    : Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(item.value),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMd.copyWith(
                              color: isSelected
                                  ? colors.primary
                                  : colors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: colors.primary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );

    if (isDialog) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: innerContent,
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(child: innerContent),
    );
  }
}
