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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050C18),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF24D58A),
          onPrimary: Color(0xFF03150F),
          secondary: Color(0xFF32B5FF),
          surface: Color(0xFF0B1626),
          surfaceContainer: Color(0xFF101D30),
          onSurface: Color(0xFFF3F7FA),
          onSurfaceVariant: Color(0xFFA2B0C1),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF050C18),
          foregroundColor: Color(0xFFF3F7FA),
          elevation: 0,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF07111F),
          indicatorColor: Color(0xFF123C36),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF0C192A).withAlpha(235),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
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
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Groupe'),
          NavigationDestination(icon: Icon(Icons.balance_outlined), selectedIcon: Icon(Icons.balance), label: 'Équité'),
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
        title: const Text('CovoiTour', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'À propos',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
            ),
            icon: const Icon(Icons.info_outline),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.sync)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text('Bonjour, ${state.group.members.first.name.split(' ').first}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70)),
          const SizedBox(height: 6),
          Text('À qui le volant aujourd’hui ?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          _RouteHeader(groupName: state.group.name),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _MetricCard(icon: Icons.groups_rounded, value: '${trip.presentMemberIds.length}', label: 'participants', color: const Color(0xFF24D58A))),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(icon: Icons.directions_car_filled_rounded, value: '1', label: 'voiture nécessaire', color: const Color(0xFF32B5FF))),
          ]),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF0D8F68), Color(0xFF075348)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Conducteur recommandé', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Basé sur l’équité du groupe', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 14),
                  if (recommendation != null)
                    _DriverRow(
                      name: state.group.members.firstWhere((member) => member.id == recommendation).name,
                      score: state.scoresFor(trip.presentMemberIds.length)[recommendation] ?? 0,
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF32D891), foregroundColor: const Color(0xFF032017)),
                      onPressed: recommendation == null ? null : () => ref.read(appStateProvider).confirmDriver(recommendation),
                      child: const Text('Valider le trajet', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Présences', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text('${trip.presentMemberIds.length}/${trip.participants.length}', style: const TextStyle(color: Color(0xFF24D58A), fontWeight: FontWeight.w700)),
                  ]),
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

class _RouteHeader extends StatelessWidget {
  const _RouteHeader({required this.groupName});

  final String groupName;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded, color: Color(0xFF24D58A)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Demain, lundi 14 sept.', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('$groupName  •  Aller 08:00  •  Retour 18:00', style: const TextStyle(color: Colors.white60)),
            ])),
          ]),
        ),
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.value, required this.label, required this.color});

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          CircleAvatar(backgroundColor: color.withAlpha(28), child: Icon(icon, color: color)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ])),
        ]),
      ));
}

class _DriverRow extends StatelessWidget {
  const _DriverRow({required this.name, required this.score});

  final String name;
  final int score;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.black.withAlpha(28), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          const CircleAvatar(backgroundColor: Color(0xFFE7D2C5), child: Icon(Icons.person, color: Color(0xFF5C4033))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text('Score $score', style: const TextStyle(color: Colors.white70)),
          ])),
          const Icon(Icons.workspace_premium_rounded, color: Color(0xFF8BFFBC)),
        ]),
      );

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

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/hebus_tech_logo.png',
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'CovoiTour',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Le covoiturage équitable où chacun conduit à son tour.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Version 0.1.0',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'À propos de l’application',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'CovoiTour aide les groupes de covoiturage réguliers à organiser les trajets, déclarer les présences et répartir équitablement les journées de conduite.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Les données du groupe sont destinées à être stockées dans le fichier partagé de son administrateur.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Développé par',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Image.asset(
            'assets/images/hebus_tech_logo.png',
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          Text(
            'Hebus Tech',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 32),
          Text(
            '© 2026 Hebus Tech',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
