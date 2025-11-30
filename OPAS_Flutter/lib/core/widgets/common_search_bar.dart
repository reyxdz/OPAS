import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';

class CommonSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final Function(String)? onSubmitted;
  final VoidCallback? onFilterTap;
  final bool enabled;

  const CommonSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search products...',
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.onFilterTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            textInputAction: TextInputAction.search,
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.grey[400],
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey[400],
                size: 20,
              ),
              suffixIcon: enabled
                  ? GestureDetector(
                      onTap: onFilterTap ?? () => onSubmitted?.call(controller?.text ?? ''),
                      child: Icon(
                        Icons.filter_list,
                        color: Colors.grey[300],
                        size: 20,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 14,
              ),
            ),
            onChanged: onChanged,
            onSubmitted: onSubmitted,
          ),
        ),
      ),
    );
  }
}
