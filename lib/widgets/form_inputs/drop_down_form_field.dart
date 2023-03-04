import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';

class DropdownFormField<T> extends FormField<T> {
  DropdownFormField({
    Key? key,
    InputDecoration? decoration,
    T? initialValue,
    required List<DropdownMenuItem<T>> items,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
    FormFieldSetter<T>? onSaved,
    FormFieldValidator<T>? validator,
    Icon? icon,
    required String labelText,
  }) : super(
          key: key,
          onSaved: onSaved,
          validator: validator,
          autovalidateMode: autovalidateMode,
          initialValue: items.firstWhereOrNull((DropdownMenuItem<T> item) =>
                      item.value == initialValue) ==
                  null
              ? null
              : initialValue,
          // items.contains(initialValue) ? initialValue : null,
          builder: (FormFieldState<T> field) {
            final InputDecoration effectiveDecoration = (decoration ??
                    const InputDecoration())
                .applyDefaults(Theme.of(field.context).inputDecorationTheme);

            return InputDecorator(
              decoration: effectiveDecoration.copyWith(
                errorText: field.hasError ? field.errorText : null,
                icon: icon,
                labelText: labelText,
              ),
              isEmpty: field.value == '' || field.value == null,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: field.value,
                  isDense: true,
                  onChanged: field.didChange,
                  items: items.toList(),
                ),
              ),
            );
          },
        );
}
