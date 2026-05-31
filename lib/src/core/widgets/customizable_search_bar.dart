import 'package:flutter/material.dart';
import 'package:web_ui_plugins/web_ui_plugins.dart';

class CustomizableSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final Color? backgroundColor;

  const CustomizableSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color:
          backgroundColor ??
          Theme.of(context).colorScheme.surfaceContainerLowest,
      height: AppTheme.formFieldHeight,
      child: TextField(
        textInputAction: TextInputAction.search,
        controller: controller,
        textAlignVertical: TextAlignVertical.center, //centre
        decoration: InputDecoration(
          hintText: 'Search',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 3),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: const Icon(Icons.search),
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              final hasText = value.text.isNotEmpty;
              return hasText
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    )
                  : const SizedBox.shrink();
            },
          ),
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
          ), // Use bodyMedium for hint text style
        ),
        onChanged: onChanged,
      ),
    );
  }
}
