import 'package:flutter/material.dart';

class CustomizableListTile extends StatelessWidget {
  final String title;
  final String subTitle;
  final Widget? trailing;
  final Widget? leading;
  final bool isSelected;
  final Color? color;
  final Color? selectedColor;

  const CustomizableListTile({
    super.key,
    required this.title,
    required this.subTitle,
    this.leading,
    this.trailing,
    this.isSelected = false,
    this.color,
    this.selectedColor,
  });
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        return Container(
          height: 50,
          width: box.maxWidth,
          color: isSelected
              ? selectedColor ?? Theme.of(context).colorScheme.surface
              : color ?? Colors.transparent,
          child: Row(
            children: [
              SizedBox(width: 3),
              if (leading != null) ...[const SizedBox(width: 10), leading!],
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // title and subtitle
                      Text(
                        title,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        subTitle,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              if (trailing != null) ...[trailing!, const SizedBox(width: 10)],
            ],
          ),
        );
      },
    );
  }
}

// Text((patient as PetModel).name ?? 'Null'),
