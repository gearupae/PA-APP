import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';

class TravelScreen extends StatelessWidget {
  const TravelScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final trips = state.trips;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Travel'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _addTrip(context),
              ),
            ],
          ),
          body: trips.isEmpty
              ? _empty(context)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: trips.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _tripCard(context, trips[i]),
                ),
        );
      },
    );
  }

  Widget _empty(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flight_takeoff, size: 52, color: AppColors.slate),
              const SizedBox(height: 14),
              const Text('No trips yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Add a trip to track flights, a pre-departure reminder, and spend per trip.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.slate),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _addTrip(context),
                icon: const Icon(Icons.add),
                label: const Text('Add a trip'),
              ),
            ],
          ),
        ),
      );

  Widget _tripCard(BuildContext context, Trip t) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: AppColors.accentSoft,
            child: const Icon(Icons.flight, color: AppColors.accent, size: 20),
          ),
          title: Text(t.destination,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(
              '${dayMonth(t.start)} – ${dayMonth(t.end)} · ${t.flights.length} flight(s) · spend ${money(state.tripSpend(t))}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => _TripDetail(state: state, tripId: t.id),
          )),
        ),
      );

  Future<void> _addTrip(BuildContext context) async {
    final destC = TextEditingController();
    DateTime start = DateTime.now();
    DateTime end = DateTime.now().add(const Duration(days: 3));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New trip',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(
                controller: destC,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Destination',
                    prefixIcon: Icon(Icons.place_outlined)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                            context: ctx,
                            initialDate: start,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 730)));
                        if (d != null) setM(() => start = d);
                      },
                      child: Text('From ${dayMonth(start)}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                            context: ctx,
                            initialDate: end,
                            firstDate: start,
                            lastDate: DateTime.now()
                                .add(const Duration(days: 730)));
                        if (d != null) setM(() => end = d);
                      },
                      child: Text('To ${dayMonth(end)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (destC.text.trim().isEmpty) return;
                    state.addTrip(Trip(
                      id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
                      destination: destC.text.trim(),
                      start: start,
                      end: end,
                      flights: [],
                    ));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save trip'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripDetail extends StatelessWidget {
  const _TripDetail({required this.state, required this.tripId});
  final AppState state;
  final String tripId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final matches = state.trips.where((t) => t.id == tripId);
        final trip = matches.isEmpty ? null : matches.first;
        if (trip == null) {
          return const Scaffold(body: Center(child: Text('Trip deleted')));
        }
        final receipts = state.tripTxns(trip);
        return Scaffold(
          appBar: AppBar(
            title: Text(trip.destination),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  state.deleteTrip(trip.id);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          body: ListView(
            padding: AppTheme.pagePad,
            children: [
              Text('${dayMonth(trip.start)} – ${dayMonth(trip.end)}',
                  style: const TextStyle(color: AppColors.slate)),
              const SizedBox(height: 16),
              _card(
                'Flights',
                Icons.flight,
                trailing: IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => _addFlight(context, trip),
                ),
                child: trip.flights.isEmpty
                    ? _line('No flights added.')
                    : Column(
                        children: trip.flights
                            .map((f) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.flight_takeoff,
                                      color: AppColors.accent),
                                  title: Text('${f.code}  ${f.from}→${f.to}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text(dayMonthTime(f.departsAt)),
                                ))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 14),
              _card(
                'Spend & receipts',
                Icons.receipt_long,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total this trip',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(money(state.tripSpend(trip)),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                        ],
                      ),
                    ),
                    if (receipts.isEmpty)
                      _line(
                          'Transactions during the trip dates will be filed here.')
                    else
                      ...receipts.take(12).map((x) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Expanded(
                                    child: Text(x.merchant,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis)),
                                Text(money(x.amount),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          )),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Live flight delay alerts & rebooking need a flight-data API key — ask to enable.',
                style: TextStyle(color: AppColors.slate, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _card(String title, IconData icon,
          {required Widget child, Widget? trailing}) =>
      Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppColors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: AppColors.ink),
                  const SizedBox(width: 10),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (trailing != null) trailing,
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: child,
              ),
            ],
          ),
        ),
      );

  Widget _line(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(t, style: const TextStyle(color: AppColors.slate)),
      );

  Future<void> _addFlight(BuildContext context, Trip trip) async {
    final codeC = TextEditingController();
    final fromC = TextEditingController();
    final toC = TextEditingController();
    DateTime departs = trip.start.add(const Duration(hours: 9));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add flight',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(
                controller: codeC,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                    labelText: 'Flight no. (e.g. EK523)',
                    prefixIcon: Icon(Icons.confirmation_number_outlined)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: fromC,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'From'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: toC,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'To'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.schedule, size: 18),
                label: Text('Departs ${dayMonthTime(departs)}'),
                onPressed: () async {
                  final d = await showDatePicker(
                      context: ctx,
                      initialDate: departs,
                      firstDate: DateTime.now()
                          .subtract(const Duration(days: 1)),
                      lastDate:
                          DateTime.now().add(const Duration(days: 730)));
                  if (d == null) return;
                  if (!ctx.mounted) return;
                  final tm = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(departs));
                  setM(() => departs = DateTime(
                      d.year, d.month, d.day, tm?.hour ?? 9, tm?.minute ?? 0));
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (codeC.text.trim().isEmpty) return;
                    trip.flights.add(Flight(
                      code: codeC.text.trim().toUpperCase(),
                      from: fromC.text.trim().toUpperCase(),
                      to: toC.text.trim().toUpperCase(),
                      departsAt: departs,
                    ));
                    state.persistTrips();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save flight'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
