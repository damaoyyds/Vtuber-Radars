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
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? primaryColor.withOpacity(0.08)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? primaryColor.withOpacity(0.35)
                : Colors.grey.withOpacity(0.15),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isSelected 
                      ? primaryColor
                      : Colors.grey.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 9,
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
                color: isSelected ? primaryColor : textSecondary,
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
    List<Widget> rows = [];
    List<Widget> currentRow = [];
    
    organizations.forEach((key, org) {
      currentRow.add(OrgChip(
        org: org,
        isSelected: selectedOrgs[key] ?? false,
        onTap: () => onOrgSelected(key, !(selectedOrgs[key] ?? false)),
      ));
      
      if (currentRow.length == 2) {
        rows.add(Row(
          children: [
            Expanded(child: currentRow[0]),
            const SizedBox(width: 12),
            Expanded(child: currentRow[1]),
          ],
        ));
        rows.add(const SizedBox(height: 12));
        currentRow.clear();
      }
    });
    
    if (currentRow.isNotEmpty) {
      rows.add(currentRow[0]);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }
}
