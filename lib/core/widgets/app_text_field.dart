import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A field's floating label: it sits on the box's top border and the border breaks behind it.
/// The label's background is the surface around the field (the screen, a card or a sheet), not
/// the white inside of the box, and it never covers the text she types. It stays visible when
/// the field has text, turns green while the field is focused and red with [error].
/// The screen reader hears the label on the field itself.
class Labeled extends StatefulWidget {
  final String label;
  final Widget child;
  final bool required, error;

  /// The colour around the field. Defaults to the surface it sits on.
  final Color? background;
  const Labeled({super.key, required this.label, required this.child, this.required = false, this.error = false, this.background});
  @override
  State<Labeled> createState() => _LabeledState();
}

class _LabeledState extends State<Labeled> {
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.background ?? Material.maybeOf(context)?.color ?? Theme.of(context).scaffoldBackgroundColor;
    final color = widget.error
        ? AppColors.red
        : focused
        ? AppColors.primary
        : AppColors.ink2;
    // room above the box for the upper half of the label, at any text size
    final top = MediaQuery.textScalerOf(context).scale(10);
    final reduce = MediaQuery.of(context).disableAnimations;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(top: top),
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onFocusChange: (f) => setState(() => focused = f),
            child: Semantics(label: widget.label, child: widget.child),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          top: top,
          child: FractionalTranslation(
            translation: const Offset(0, -.5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: ColoredBox(
                    color: bg,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AnimatedDefaultTextStyle(
                        duration: reduce ? Duration.zero : const Duration(milliseconds: 160),
                        curve: Curves.easeOut,
                        style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: color, height: 1.2),
                        child: Text.rich(
                          TextSpan(
                            text: widget.label,
                            children: [
                              if (widget.required)
                                const TextSpan(
                                  text: ' *',
                                  style: TextStyle(color: AppColors.red),
                                ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Text input. Same look as every field in the app: a floating label on the box's border, an
/// optional hint, and an inline error under it.
class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? hint, error, helper;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final bool required;
  final Key? fieldKey;
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.error,
    this.helper,
    this.keyboardType,
    this.onChanged,
    this.maxLines = 1,
    this.required = false,
    this.fieldKey,
  });
  @override
  Widget build(BuildContext context) => Labeled(
    label: label,
    required: required,
    error: error != null,
    child: TextField(
      key: fieldKey,
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      maxLines: maxLines,
      decoration: InputDecoration(hintText: hint, errorText: error, helperText: helper, helperMaxLines: 2),
    ),
  );
}

/// Search box: pill-free rounded field with a search icon and a clear button.
class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final Key? fieldKey;
  const AppSearchField({super.key, required this.controller, required this.hint, required this.onChanged, this.fieldKey});
  @override
  Widget build(BuildContext context) => TextField(
    key: fieldKey,
    controller: controller,
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      prefixIcon: const Icon(Icons.search, color: AppColors.ink2),
      suffixIcon: controller.text.isEmpty
          ? null
          : IconButton(
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              icon: const Icon(Icons.close),
              onPressed: () {
                controller.clear();
                onChanged('');
              },
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
    ),
  );
}
