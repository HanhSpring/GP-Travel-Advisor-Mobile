import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/destination.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/trip_suggestion.dart';
import '../cubit/explore_cubit.dart';
import '../cubit/explore_state.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExploreCubit>()..loadData(),
      child: const _ExploreView(),
    );
  }
}

class _ExploreView extends StatefulWidget {
  const _ExploreView();

  @override
  State<_ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<_ExploreView> {
  int _suggestionPage = 0;
  int _destPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ExploreCubit, ExploreState>(
          builder: (context, state) {
            if (state is ExploreLoading || state is ExploreInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ExploreError) {
              return _ErrorView(
                error: state.message,
                onRetry: () => context.read<ExploreCubit>().loadData(),
              );
            }
            if (state is ExploreLoaded) {
              return _buildContent(context, state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ExploreLoaded state) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _SearchBar(),
          ),
        ),
        // ── Gợi ý cho bạn ────────────────────────────────────────────────
        if (state.suggestions.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(title: 'Gợi ý cho bạn', onSeeAll: () {}),
                const SizedBox(height: 12),
                SizedBox(
                  height: 230,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.88),
                    padEnds: false,
                    clipBehavior: Clip.none,
                    itemCount: state.suggestions.length,
                    onPageChanged: (i) =>
                        setState(() => _suggestionPage = i),
                    itemBuilder: (_, i) => Padding(
                      padding: EdgeInsets.only(
                        left: i == 0 ? 16 : 0,
                        right: 12,
                      ),
                      child: _TripCardWidget(item: state.suggestions[i]),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _PageDots(
                    count: state.suggestions.length,
                    current: _suggestionPage),
              ],
            ),
          ),
        // ── Điểm đến nổi bật ─────────────────────────────────────────────
        if (state.destinations.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _SectionHeader(
                    title: 'Điểm đến nổi bật', onSeeAll: () {}),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.38),
                    padEnds: false,
                    clipBehavior: Clip.none,
                    itemCount: state.destinations.length,
                    onPageChanged: (i) => setState(() => _destPage = i),
                    itemBuilder: (_, i) => Padding(
                      padding: EdgeInsets.only(
                        left: i == 0 ? 16 : 0,
                        right: 12,
                      ),
                      child:
                          _DestinationCard(item: state.destinations[i]),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _PageDots(
                    count: state.destinations.length, current: _destPage),
              ],
            ),
          ),
        // ── Khách sạn nổi bật ─────────────────────────────────────────────
        if (state.hotels.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _SectionHeader(title: 'Khách sạn nổi bật', onSeeAll: () {}),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: state.hotels
                        .map((h) => Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                    right: h == state.hotels.last ? 0 : 12),
                                child: _HotelCard(item: h),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ── Cached network image ──────────────────────────────────────────────────────
class _NetImage extends StatelessWidget {
  final String? url;
  final int placeholderColor;
  final double borderRadius;

  const _NetImage({
    required this.url,
    required this.placeholderColor,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      decoration: BoxDecoration(
        color: Color(placeholderColor),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => placeholder,
        errorWidget: (context, url, error) => placeholder,
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(children: [
        SizedBox(width: 14),
        Icon(Icons.search, color: Color(0xFF9E9E9E), size: 20),
        SizedBox(width: 8),
        Expanded(
          child: Text('Tìm địa điểm, lịch trình, trải nghiệm...',
              style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E))),
        ),
      ]),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1E))),
          GestureDetector(
            onTap: onSeeAll,
            child: const Text('Xem tất cả',
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ── Page dots ─────────────────────────────────────────────────────────────────
class _PageDots extends StatelessWidget {
  final int count, current;
  const _PageDots({required this.count, required this.current});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ── Trip card ─────────────────────────────────────────────────────────────────
class _TripCardWidget extends StatelessWidget {
  final TripSuggestion item;
  const _TripCardWidget({required this.item});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 6,
          child: _NetImage(url: item.imageUrl, placeholderColor: item.placeholderColor),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1E)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 12, color: Color(0xFF6B7280)),
                  const SizedBox(width: 3),
                  Text(item.days,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF6B7280))),
                  const SizedBox(width: 10),
                  const Icon(Icons.location_on_outlined,
                      size: 12, color: Color(0xFF6B7280)),
                  const SizedBox(width: 3),
                  Text(item.location,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF6B7280))),
                ]),
                Row(children: [
                  const Icon(Icons.remove_red_eye_outlined,
                      size: 12, color: Color(0xFF9E9E9E)),
                  const SizedBox(width: 3),
                  Text(item.views,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9E9E9E))),
                  const SizedBox(width: 10),
                  const Icon(Icons.favorite, size: 12, color: Colors.redAccent),
                  const SizedBox(width: 3),
                  Text(item.likes,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9E9E9E))),
                ]),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Destination card ──────────────────────────────────────────────────────────
class _DestinationCard extends StatelessWidget {
  final Destination item;
  const _DestinationCard({required this.item});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: _NetImage(
            url: item.imageUrl,
            placeholderColor: item.placeholderColor,
            borderRadius: 16),
      ),
      const SizedBox(height: 6),
      Text(item.name,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1C1C1E))),
    ]);
  }
}

// ── Hotel card ────────────────────────────────────────────────────────────────
class _HotelCard extends StatelessWidget {
  final Hotel item;
  const _HotelCard({required this.item});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 120,
          child: _NetImage(
              url: item.imageUrl, placeholderColor: item.placeholderColor),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.name,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFA500)),
              const SizedBox(width: 2),
              Text(item.rating.toString(),
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1C1C1E),
                      fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 4),
            Text(item.price,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            Text(item.priceUnit,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF9E9E9E))),
          ]),
        ),
      ]),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Không thể tải dữ liệu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(error,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ]),
      ),
    );
  }
}
