import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../auth/presentation/widgets/profile_button.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/event_filters.dart';
import '../bloc/events_bloc.dart';
import '../map/map_cluster.dart';
import '../map/map_markers.dart';
import '../widgets/event_card.dart';
import '../widgets/event_filter_bar.dart';
import '../widgets/event_preview_sheet.dart';

/// Fallback location used when GPS is unavailable/denied.
const _fallbackLatitude = 43.2220;
const _fallbackLongitude = 76.8512;
const _fallbackZoom = 12.0;
const _maxZoom = 18.0;

/// Minimum height of the draggable events list (fraction of the screen).
const _sheetMinSize = 0.14;

class EventsMapPage extends StatefulWidget {
  const EventsMapPage({super.key});

  @override
  State<EventsMapPage> createState() => _EventsMapPageState();
}

class _EventsMapPageState extends State<EventsMapPage> {
  final ClusteringService _clusteringService = ClusteringService();
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  double _zoom = _fallbackZoom;
  List<EventEntity> _events = const [];
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveInitialLocation());
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _resolveInitialLocation() async {
    try {
      final position = await _resolveUserPosition();
      if (!mounted) return;
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        _fallbackZoom,
      );
      context.read<EventsBloc>().add(
            EventsLoadForLocation(
              latitude: position.latitude,
              longitude: position.longitude,
            ),
          );
    } catch (_) {
      if (!mounted) return;
      context.read<EventsBloc>().add(
            const EventsLoadForLocation(
              latitude: _fallbackLatitude,
              longitude: _fallbackLongitude,
            ),
          );
    }
  }

  Future<Position> _resolveUserPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError('Location services disabled');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission denied');
    }
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }

  List<Marker> _buildMarkers() {
    final clusters = _clusteringService.cluster(_events, _zoom);

    return [
      for (final cluster in clusters)
        if (cluster.isCluster)
          Marker(
            point: LatLng(cluster.latitude, cluster.longitude),
            width: 48,
            height: 48,
            child: GestureDetector(
              onTap: () => _mapController.move(
                LatLng(cluster.latitude, cluster.longitude),
                math.min(_zoom + 2, _maxZoom),
              ),
              child: ClusterBubble(count: cluster.events.length),
            ),
          )
        else
          Marker(
            point: LatLng(cluster.latitude, cluster.longitude),
            width: 48,
            height: 48,
            child: GestureDetector(
              onTap: () => _openPreview(cluster.single),
              child: EventPin(
                category: cluster.single.category,
                selected: cluster.single.id == _selectedId,
              ),
            ),
          ),
    ];
  }

  /// Tap on a list card: collapse the list, center the map on the event
  /// and show its preview.
  void _focusEvent(EventEntity event) {
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        _sheetMinSize,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
    _mapController.move(
      LatLng(event.latitude, event.longitude),
      math.max(_zoom, 15.0),
    );
    _openPreview(event);
  }

  void _openPreview(EventEntity event) {
    setState(() => _selectedId = event.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EventPreviewSheet(event: event),
    ).whenComplete(() {
      if (mounted) setState(() => _selectedId = null);
    });
  }

  void _searchThisArea() {
    final center = _mapController.camera.center;
    context.read<EventsBloc>().add(
          EventsLoadForLocation(
            latitude: center.latitude,
            longitude: center.longitude,
          ),
        );
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final newZoom = math.min(math.max(camera.zoom + delta, 2.0), _maxZoom);
    _mapController.move(camera.center, newZoom);
  }

  Future<void> _goToMyLocation() async {
    try {
      final position = await _resolveUserPosition();
      if (!mounted) return;
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        14,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Не удалось определить местоположение. '
            'Проверьте, что геолокация включена и доступ разрешён.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.sizeOf(context).height * _sheetMinSize;

    return Scaffold(
      body: BlocConsumer<EventsBloc, EventsState>(
        listener: (context, state) {
          if (state is EventsLoaded) {
            setState(() => _events = state.events);
          }
        },
        builder: (context, state) {
          final filters = switch (state) {
            EventsLoading(:final filters) => filters,
            EventsLoaded(:final filters) => filters,
            EventsError(:final filters) => filters,
            EventsInitial() => const EventFilters(),
          };
          final isLoading = state is EventsLoading;

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter:
                      const LatLng(_fallbackLatitude, _fallbackLongitude),
                  initialZoom: _fallbackZoom,
                  maxZoom: _maxZoom,
                  // Re-cluster only when the integer zoom level changes.
                  onPositionChanged: (camera, _) {
                    if (camera.zoom.floor() != _zoom.floor()) {
                      setState(() => _zoom = camera.zoom);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    // OSM blocks requests without its own identifier.
                    // Must match the app's applicationId.
                    userAgentPackageName: 'com.eventspot.eventspot',
                  ),
                  MarkerLayer(markers: _buildMarkers()),
                ],
              ),
              // OSM attribution is mandatory and must stay visible.
              Positioned(
                left: 8,
                bottom: sheetHeight + 6,
                child: const _OsmAttribution(),
              ),
              Positioned(
                right: 12,
                bottom: sheetHeight + 32,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MapButton(
                      icon: Icons.my_location,
                      tooltip: 'Моё местоположение',
                      onPressed: _goToMyLocation,
                    ),
                    const SizedBox(height: 8),
                    _MapButton(
                      icon: Icons.add,
                      tooltip: 'Приблизить',
                      onPressed: () => _zoomBy(1),
                    ),
                    const SizedBox(height: 8),
                    _MapButton(
                      icon: Icons.remove,
                      tooltip: 'Отдалить',
                      onPressed: () => _zoomBy(-1),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: EventFilterBar(
                                filters: filters,
                                onCategoryChanged: (category) => context
                                    .read<EventsBloc>()
                                    .add(EventsCategoryFilterChanged(category)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const ProfileButton(),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: FilledButton.icon(
                            onPressed: isLoading ? null : _searchThisArea,
                            icon: isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.search),
                            label: Text(
                              isLoading ? 'Ищем…' : 'Искать в этой области',
                            ),
                          ),
                        ),
                        if (state is EventsError)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: _ErrorBanner(
                              message: state.message,
                              onRetry: () => context
                                  .read<EventsBloc>()
                                  .add(const EventsRetryRequested()),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: _sheetMinSize,
                minChildSize: _sheetMinSize,
                maxChildSize: 0.85,
                snap: true,
                snapSizes: const [_sheetMinSize, 0.45, 0.85],
                builder: (context, scrollController) => _EventsSheet(
                  controller: scrollController,
                  events: _events,
                  isLoading: isLoading,
                  onEventTap: _focusEvent,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EventsSheet extends StatelessWidget {
  const _EventsSheet({
    required this.controller,
    required this.events,
    required this.isLoading,
    required this.onEventTap,
  });

  final ScrollController controller;
  final List<EventEntity> events;
  final bool isLoading;
  final ValueChanged<EventEntity> onEventTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        controller: controller,
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: (events.isEmpty ? 1 : events.length) + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _SheetHeader(count: events.length, isLoading: isLoading);
          }
          if (events.isEmpty) {
            return isLoading ? const SizedBox.shrink() : const _EmptyState();
          }
          final event = events[index - 1];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: EventCard(event: event, onTap: () => onEventTap(event)),
          );
        },
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.count, required this.isLoading});

  final int count;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isLoading ? 'Ищем события…' : 'Найдено событий: $count',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.travel_explore,
            size: 56,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'Здесь ничего не нашлось',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Выберите другую категорию или сдвиньте карту '
            'и нажмите «Искать в этой области».',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _OsmAttribution extends StatelessWidget {
  const _OsmAttribution();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(
        Uri.parse('https://www.openstreetmap.org/copyright'),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          '© OpenStreetMap contributors',
          style: TextStyle(fontSize: 10, color: Colors.black87),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: Text(message)),
            TextButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      shape: const CircleBorder(),
      color: Theme.of(context).colorScheme.surface,
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
