import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_registration_list_model.dart';
import '../providers/seller_registration_admin_providers.dart';
import '../widgets/registration_status_badge.dart';
import 'seller_registration_detail_screen.dart';

/// Refactored Admin Registrations List Screen with Provider-based state management
/// CORE PRINCIPLE: State Management - Uses Riverpod for scalable state
/// CORE PRINCIPLE: Caching - Displays cached data while fetching fresh
/// CORE PRINCIPLE: Pagination - Efficient server-side data loading
class SellerRegistrationsListScreenV2 extends ConsumerWidget {
  const SellerRegistrationsListScreenV2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(adminFiltersProvider);
    final registrationsAsync =
        ref.watch(adminRegistrationsListProvider(filters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Registrations'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab navigation
          _buildTabBar(context, ref, filters),
          // Filter bar
          _buildFilterBar(context, ref, filters),
          // Main content
          Expanded(
            child: registrationsAsync.when(
              data: (registrations) {
                if (registrations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No registrations found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: registrations.length,
                  itemBuilder: (context, index) {
                    return _buildRegistrationCard(
                      context,
                      ref,
                      registrations[index],
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $error',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.refresh(adminRegistrationsListProvider(filters)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(
      BuildContext context, WidgetRef ref, AdminFilters filters) {
    // CORE PRINCIPLE: UX - Tab-based navigation
    final tabs = [
      (null, 'All'),
      ('PENDING', 'Pending'),
      ('APPROVED', 'Approved'),
      ('REJECTED', 'Rejected'),
      ('REQUEST_MORE_INFO', 'More Info'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs
            .map((tab) {
              final (status, label) = tab;
              final isSelected = filters.status == status;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(label),
                  onSelected: (selected) async {
                    await ref
                        .read(adminFiltersProvider.notifier)
                        .setStatus(selected ? status : null);
                  },
                ),
              );
            })
            .toList(),
      ),
    );
  }

  Widget _buildFilterBar(
      BuildContext context, WidgetRef ref, AdminFilters filters) {
    // CORE PRINCIPLE: UX - Search and sort controls
    final searchController =
        TextEditingController(text: filters.searchQuery);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (query) async {
                await ref
                    .read(adminFiltersProvider.notifier)
                    .setSearchQuery(query);
              },
            ),
          ),
          const SizedBox(width: 8),
          // Sort button
          PopupMenuButton<String>(
            onSelected: (value) async {
              await ref
                  .read(adminFiltersProvider.notifier)
                  .setSortBy(value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'submitted_at',
                child: Text('Submission Date'),
              ),
              PopupMenuItem(
                value: 'days_pending',
                child: Text('Days Pending'),
              ),
              PopupMenuItem(
                value: 'buyer_name',
                child: Text('Buyer Name'),
              ),
            ],
            child: Tooltip(
              message: 'Sort by',
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.sort),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Sort direction toggle
          Tooltip(
            message: 'Toggle sort order',
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(
                  filters.sortOrder == 'asc'
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                ),
                onPressed: () async {
                  await ref
                      .read(adminFiltersProvider.notifier)
                      .toggleSortOrder();
                },
                tooltip: filters.sortOrder == 'asc'
                    ? 'Ascending'
                    : 'Descending',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationCard(
    BuildContext context,
    WidgetRef ref,
    AdminRegistrationListItem registration,
  ) {
    // CORE PRINCIPLE: UX - Card-based list item with key info
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  SellerRegistrationDetailScreen(
                registrationId: registration.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          registration.buyerName,
                          style:
                              Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          registration.buyerPhone,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                        ),
                      ],
                    ),
                  ),
                  RegistrationStatusBadge(
                    status: registration.status,
                    showLabel: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Info row
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      context,
                      Icons.agriculture,
                      registration.farmName,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      context,
                      Icons.storefront,
                      registration.storeName,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Documents and days pending
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(
                      registration.hasAllDocuments
                          ? '✓ All Documents'
                          : '⚠ Missing Documents',
                      style: TextStyle(
                        color: registration.hasAllDocuments
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                  if (registration.isPending)
                    Chip(
                      label: Text(
                        '${registration.daysPending} days pending',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String text,
  ) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
