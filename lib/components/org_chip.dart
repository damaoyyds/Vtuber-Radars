import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/organization.dart';

class OrgChip extends StatelessWidget {
  final Organization org;
  final bool isSelected;
  final VoidCallback onTap;

  const OrgChip({
    super.key,
    required this.org,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? primaryColor.withOpacity(0.12)
              : Colors.grey.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? primaryColor.withOpacity(0.4)
                : Colors.grey.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected 
                      ? primaryColor.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              org.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? primaryColor : textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrgChipGrid extends StatelessWidget {
  final Map<String, Organization> organizations;
  final Map<String, bool> selectedOrgs;
  final Function(String, bool) onOrgSelected;

  const OrgChipGrid({
    super.key,
    required this.organizations,
    required this.selectedOrgs,
    required this.onOrgSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: organizations.entries.map((entry) {
        return OrgChip(
          org: entry.value,
          isSelected: selectedOrgs[entry.key] ?? false,
          onTap: () {
            onOrgSelected(entry.key, !(selectedOrgs[entry.key] ?? false));
          },
        );
      }).toList(),
    );
  }
}
