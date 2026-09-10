import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/entities/trip.dart';
import 'presentation/providers/app_state.dart';

void main() {
  runApp(const ProviderScope(child: CovoiTourApp()));
}

class CovoiTourApp extends StatelessWidget {
  const CovoiTourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CovoiTour',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardScreen(),
      const MembersScreen(),
      const ScoresScreen(),
      const HistoryScreen(),
    ];
    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => setState(() => selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.route), label: 'Trajet'),
          NavigationDestination(icon: Icon(Icons.groups), label: 'Membres'),
          NavigationDestination(icon: Icon(Icons.leaderboard), label: 'Scores'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historique'),
        ],
      ),
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final trip = state.group.trips.first;
    final recommendation = state.recommendDriver();
    return Scaffold(
      appBar: AppBar(
        title: Text(state.group.name),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.sync))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Prochain trajet',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(child: ListTile(
            leading: Icon(Icons.calendar_month),
            title: Text('Lundi 14 septembre'),
            subtitle: Text('Maison -> Bureau | 08:00 / 18:00'),
          )),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Présences', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...trip.participants.map((participant) => _AttendanceTile(
                        participant: participant,
                        memberName: state.group.members
                            .firstWhere((member) => member.id == participant.memberId)
                            .name,
                        onChanged: (status) => ref
                            .read(appStateProvider)
                            .setAttendance(participant.memberId, status),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.directions_car),
              title: Text(recommendation == null
                  ? 'Aucun conducteur disponible'
                  : 'Suggestion : ${state.group.members.firstWhere((member) => member.id == recommendation).name}'),
              subtitle: const Text('Le groupe peut confirmer un autre conducteur.'),
              trailing: recommendation == null
                  ? null
                  : FilledButton(
                      onPressed: () => ref.read(appStateProvider).confirmDriver(recommendation),
                      child: const Text('Confirmer'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({required this.participant, required this.memberName, required this.onChanged});

  final TripParticipant participant;
  final String memberName;
  final ValueChanged<AttendanceStatus> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        title: Text(memberName),
        subtitle: Text(_label(participant.status)),
        trailing: PopupMenuButton<AttendanceStatus>(
          initialValue: participant.status,
          onSelected: onChanged,
          itemBuilder: (_) => const [
            PopupMenuItem(value: AttendanceStatus.present, child: Text('Présent')),
            PopupMenuItem(value: AttendanceStatus.absent, child: Text('Absent')),
            PopupMenuItem(value: AttendanceStatus.notAnswered, child: Text('Non répondu')),
          ],
        ),
      );

  static String _label(AttendanceStatus status) => switch (status) {
        AttendanceStatus.present => 'Présent',
        AttendanceStatus.absent => 'Absent',
        AttendanceStatus.notAnswered => 'Non répondu',
      };
}

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Membres')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addMember(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Ajouter'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: state.activeMembers.length,
        itemBuilder: (_, index) {
          final member = state.activeMembers[index];
          return Card(child: ListTile(
            leading: CircleAvatar(child: Text(member.name.substring(0, 1))),
            title: Text(member.name),
            subtitle: Text(member.hasVehicle
                ? '${member.email}\n${member.passengerCapacity} places passager'
                : '${member.email}\nPas de véhicule'),
            isThreeLine: true,
          ));
        },
      ),
    );
  }

  Future<void> _addMember(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nouveau membre'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nom')),
          TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ajouter')),
        ],
      ),
    );
    if (result == true && nameController.text.trim().isNotEmpty) {
      ref.read(appStateProvider).addMember(
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            hasVehicle: false,
            passengerCapacity: 0,
          );
    }
  }
}

class ScoresScreen extends ConsumerWidget {
  const ScoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau des scores')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: state.group.scoresByGroupSize.entries.map((entry) => Card(
              child: ExpansionTile(
                title: Text('${entry.key} participants'),
                subtitle: Text('Total : ${entry.value.values.fold(0, (a, b) => a + b)}'),
                children: entry.value.entries.map((score) {
                  final member = state.group.members.firstWhere((item) => item.id == score.key);
                  return ListTile(title: Text(member.name), trailing: Text('${score.value}'));
                }).toList(),
              ),
            )).toList(),
      ),
    );
  }
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: state.group.trips.length,
        itemBuilder: (_, index) {
          final trip = state.group.trips[index];
          final driver = trip.confirmedDriverId == null
              ? 'Conducteur non confirmé'
              : state.group.members.firstWhere((member) => member.id == trip.confirmedDriverId).name;
          return Card(child: ListTile(
            leading: const Icon(Icons.event_available),
            title: Text('${trip.date.day}/${trip.date.month}/${trip.date.year}'),
            subtitle: Text('$driver - ${trip.presentMemberIds.length} présents'),
          ));
        },
      ),
    );
  }
}
