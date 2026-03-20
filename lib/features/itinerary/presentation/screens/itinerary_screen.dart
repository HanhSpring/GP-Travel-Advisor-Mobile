import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';

import '../../domain/entities/itinerary_entity.dart';
import '../cubit/itinerary_cubit.dart';
import '../cubit/itinerary_state.dart';
import '../widgets/itinerary_card.dart';
import '../widgets/itinerary_completed_card.dart';
import '../widgets/itinerary_empty_view.dart';
import '../widgets/itinerary_filter_chips.dart';
import '../widgets/itinerary_summary_grid.dart';
import '../../../../core/widgets/error_view.dart';
import 'itinerary_summary_screen.dart';

/// Màn hình chính "Lịch trình của tôi".
class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ItineraryView();
  }
}

class _ItineraryView extends StatelessWidget {
  const _ItineraryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<ItineraryCubit, ItineraryState>(
          builder: (context, state) {
            if (state is ItineraryInitial) {
              return const SizedBox.shrink();
            }

            if (state is ItineraryLoading) {
              return _buildLoadingShimmer();
            }

            if (state is ItineraryError) {
              return ErrorView(
                error: state.message,
                onRetry: () => context.read<ItineraryCubit>().loadData(),
              );
            }

            final loaded = state as ItineraryLoaded;
            return _buildLoadedView(context, loaded);
          },
        ),
      ),
    );
  }

  Widget _buildLoadedView(BuildContext context, ItineraryLoaded state) {
    final cubit = context.read<ItineraryCubit>();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Lịch trình của tôi',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (state.itineraries.isNotEmpty) ...[
                  _iconButton(Icons.search, () {}),
                  const SizedBox(width: 8),
                  _iconButton(Icons.tune, () {}),
                ],
              ],
            ),
          ),
        ),

        if (state.itineraries.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ItineraryFilterChips(
                activeFilter: state.activeFilter,
                onChanged: (status) => cubit.filterBy(status),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ItinerarySummaryGrid(summary: state.summary),
            ),
          ),
        ],

        if (state.itineraries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: ItineraryEmptyView(
              onCreateTap: () {
                // TODO: navigate to create itinerary screen
              },
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == 0) return const SizedBox(height: 12);
                if (index == state.itineraries.length + 1) {
                  return const SizedBox(height: 100);
                }

                final item = state.itineraries[index - 1];
                void onCardTap() async {
                  cubit.selectItinerary(item.id);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: cubit,
                        child: ItinerarySummaryScreen(itineraryId: item.id),
                      ),
                    ),
                  );
                }

                if (item.status == ItineraryStatus.completed) {
                  return ItineraryCompletedCard(
                    item: item,
                    onTap: onCardTap,
                    onEdit: () {},
                    onDelete: () => cubit.deleteItem(item.id),
                  );
                }
                return ItineraryCard(
                  item: item,
                  onTap: onCardTap,
                  onEdit: () {},
                  onDelete: () => cubit.deleteItem(item.id),
                );
              },
              childCount: state.itineraries.length + 2,
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingShimmer() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF374151)),
      ),
    );
  }
}
