import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/page_dots.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../home/presentation/widgets/destination_card.dart';
import '../cubit/saved_cubit.dart';
import '../cubit/saved_state.dart';
import '../widgets/saved_itinerary_card.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final PageController _itineraryController = PageController(viewportFraction: 0.9);
  int _currentItineraryIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<SavedCubit>().loadSavedContent();
  }

  @override
  void dispose() {
    _itineraryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocBuilder<SavedCubit, SavedState>(
          builder: (context, state) {
            if (state is SavedLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (state is SavedError) {
              return ErrorView(
                error: state.message,
                onRetry: () => context.read<SavedCubit>().loadSavedContent(),
              );
            }
            if (state is SavedLoaded) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // ITINERARIES SECTION
                    SectionHeader(
                      title: 'Lịch trình yêu thích',
                      onSeeAll: () {},
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 320,
                      child: PageView.builder(
                        controller: _itineraryController,
                        itemCount: state.itineraries.length,
                        onPageChanged: (index) {
                          setState(() => _currentItineraryIndex = index);
                        },
                        itemBuilder: (context, index) {
                          return SavedItineraryCard(item: state.itineraries[index]);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: PageDots(
                        current: _currentItineraryIndex,
                        count: state.itineraries.length,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // PLACES SECTION
                    SectionHeader(
                      title: 'Địa điểm yêu thích',
                      onSeeAll: () {},
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: state.places.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: DestinationCard(item: state.places[index]),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
