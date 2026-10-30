import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One native editor preserves paste, autofill and backspace across six cells.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.controller,
    this.enabled = true,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final focus = FocusNode();

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mã xác thực 6 số',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: Listenable.merge([widget.controller, focus]),
          builder: (context, _) => Stack(
            children: [
              TextFormField(
                controller: widget.controller,
                focusNode: focus,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                showCursor: false,
                style: const TextStyle(
                  color: Colors.transparent,
                  fontSize: 24,
                  height: 1,
                ),
                decoration: const InputDecoration(
                  semanticCounterText: 'Mã xác thực gồm 6 chữ số',
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  errorMaxLines: 2,
                ),
                validator: (value) => RegExp(r'^\d{6}$').hasMatch(value ?? '')
                    ? null
                    : 'Nhập đủ 6 chữ số',
                onFieldSubmitted: widget.onSubmitted,
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 64,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: Row(
                      children: List.generate(6, (index) {
                        final value = widget.controller.text;
                        final filled = index < value.length;
                        final selected =
                            focus.hasFocus &&
                            widget.enabled &&
                            index ==
                                (widget.controller.selection.isValid
                                    ? widget.controller.selection.extentOffset
                                          .clamp(0, 5)
                                    : value.length.clamp(0, 5));
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? colors.primaryContainer
                                    : colors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  width: selected ? 2 : 1,
                                  color: selected
                                      ? colors.primary
                                      : colors.outline.withValues(
                                          alpha: filled ? .65 : .25,
                                        ),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    filled ? value[index] : '–',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: filled
                                          ? colors.onSurface
                                          : colors.onSurface.withValues(
                                              alpha: .28,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
