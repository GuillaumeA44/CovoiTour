import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';

import 'domain/entities/trip.dart';
import 'domain/entities/member.dart';
import 'domain/entities/advanced_trip.dart';
import 'presentation/providers/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
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
          surface: Color(0xFF050C18),
          surfaceContainer: Color(0xFF0C192A),
          onSurface: Color(0xFFF3F7FA),
          onSurfaceVariant: Color(0xFFA2B0C1),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF050C18),
          foregroundColor: Color(0xFFF3F7FA),
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF050C18),
          indicatorColor: Colors.transparent,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFF24D58A), size: 28);
            }
            return const IconThemeData(color: Color(0xFFA2B0C1));
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF24D58A));
            }
            return const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFA2B0C1));
          }),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF0C192A),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
    final state = ref.watch(appStateProvider);
    
    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!state.hasGroup) {
      return const CreateGroupScreen();
    }

    final isAdmin = state.isCurrentUserAdmin;

    final pages = [
      const DashboardScreen(),
      const GroupScreen(),
      const ScoresScreen(),
      const PresenceScreen(),
      if (isAdmin) const MainAdminScreen(),
    ];
    final visibleIndex = selectedIndex >= pages.length ? pages.length - 1 : selectedIndex;

    return Scaffold(
      body: pages[visibleIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1)),
        ),
        child: NavigationBar(
          height: 65,
          selectedIndex: visibleIndex,
          onDestinationSelected: (index) => setState(() => selectedIndex = index),
          destinations: [
            const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
            const NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Groupe'),
            const NavigationDestination(icon: Icon(Icons.balance_outlined), selectedIcon: Icon(Icons.balance), label: 'Équité'),
            const NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendrier'),
            if (isAdmin) const NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings), label: 'Admin'),
          ],
        ),
      ),
    );
  }
}

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _outboundController = TextEditingController();
  final _returnController = TextEditingController();
  final _capacityController = TextEditingController();
  bool _isCreating = false;
  String? _groupImageData;
  bool _startAddressVerified = false;
  bool _endAddressVerified = false;
  bool _isCheckingStartAddress = false;
  bool _isCheckingEndAddress = false;
  String? _startAddressError;
  String? _endAddressError;
  List<String> _startSuggestions = [];
  List<String> _endSuggestions = [];
  int _addressSearchToken = 0;
  TimeOfDay? _outboundTime;
  TimeOfDay? _returnTime;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _startController.dispose();
    _endController.dispose();
    _outboundController.dispose();
    _returnController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final account = state.currentUser;

    return Scaffold(
      body: FullPageBackground(
        imageUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=1000',
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
            children: [
              const CovoiTourLogo(size: 28),
              const SizedBox(height: 40),
              const Text('Créer votre groupe', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Le créateur du groupe devient automatiquement son administrateur.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 32),
              if (account == null)
                _buildSignInCard(state)
              else
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildField(_nameController, 'Nom du groupe', Icons.groups_outlined, required: true),
                      _buildGroupImagePicker(),
                      _buildField(_descriptionController, 'Description', Icons.notes_outlined),
                      _buildAddressField(_startController, 'Point de départ', Icons.trip_origin, true),
                      _buildAddressField(_endController, 'Point de retour', Icons.location_on_outlined, false),
                      Row(
                        children: [
                          Expanded(child: _buildTimeField('Heure de départ', Icons.schedule, true)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTimeField('Heure de retour', Icons.schedule_outlined, false)),
                        ],
                      ),
                      _buildField(
                        _capacityController,
                        'Places disponibles dans la voiture (hors conducteur)',
                        Icons.airline_seat_recline_normal_outlined,
                        required: true,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final capacity = int.tryParse(value?.trim() ?? '');
                          return capacity == null || capacity < 1 ? 'Indiquez au moins 1 place' : null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _isCreating ? null : _createGroup,
                          icon: _isCreating
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.add_circle_outline),
                          label: const Text('Créer le groupe'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInCard(AppState state) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Connexion requise', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Connectez-vous avec Google pour devenir le propriétaire du groupe et synchroniser ses données.', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => state.signIn(),
              icon: const Icon(Icons.login),
              label: const Text('Se connecter à Google'),
            ),
          ],
        ),
      );

  Widget _buildGroupImagePicker() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
          leading: _groupImageData == null
              ? const CircleAvatar(child: Icon(Icons.groups_outlined))
              : CircleAvatar(child: ClipOval(child: _ImageSource(source: _groupImageData!, size: 40))),
          title: const Text('Image du groupe'),
          subtitle: Text(_groupImageData == null ? 'Ajouter une photo ou un fichier' : 'Image sélectionnée'),
          trailing: const Icon(Icons.add_a_photo_outlined),
          onTap: () async {
            final image = await _pickImageData(context);
            if (image != null) setState(() => _groupImageData = image);
          },
        ),
      );

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
          validator: validator ?? (required ? (value) => value == null || value.trim().isEmpty ? 'Champ requis' : null : null),
        ),
      );

  Widget _buildAddressField(TextEditingController controller, String label, IconData icon, bool isStart) {
    final suggestions = isStart ? _startSuggestions : _endSuggestions;
    final error = isStart ? _startAddressError : _endAddressError;
    final verified = isStart ? _startAddressVerified : _endAddressVerified;
    final checking = isStart ? _isCheckingStartAddress : _isCheckingEndAddress;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
              suffixIcon: checking
                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                  : IconButton(
                      icon: Icon(verified ? Icons.verified : Icons.search, color: verified ? const Color(0xFF24D58A) : null),
                      tooltip: 'Vérifier l’adresse',
                      onPressed: () => _verifyAddress(controller, isStart),
                    ),
              errorText: error,
              helperText: verified ? 'Adresse reconnue' : 'Saisissez une adresse puis sélectionnez une suggestion',
            ),
            onChanged: (value) => _suggestAddress(value, isStart),
            validator: (value) => value == null || value.trim().isEmpty ? 'Adresse requise' : null,
          ),
          if (suggestions.isNotEmpty)
            Container(
              decoration: BoxDecoration(color: const Color(0xFF0C192A), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: suggestions.map((suggestion) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined, size: 18),
                  title: Text(suggestion),
                  onTap: () {
                    controller.text = suggestion;
                    setState(() {
                      if (isStart) {
                        _startSuggestions = [];
                        _startAddressVerified = true;
                        _startAddressError = null;
                      } else {
                        _endSuggestions = [];
                        _endAddressVerified = true;
                        _endAddressError = null;
                      }
                    });
                  },
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeField(String label, IconData icon, bool isOutbound) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          readOnly: true,
          controller: isOutbound ? _outboundController : _returnController,
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), suffixIcon: const Icon(Icons.access_time)),
          onTap: () => _pickTime(isOutbound),
          validator: (value) => value == null || value.isEmpty ? 'Requis' : null,
        ),
      );

  String _formatTime(TimeOfDay time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isOutbound) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOutbound ? (_outboundTime ?? const TimeOfDay(hour: 8, minute: 0)) : (_returnTime ?? const TimeOfDay(hour: 18, minute: 0)),
      helpText: isOutbound ? 'Choisir l’heure de départ' : 'Choisir l’heure de retour',
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    if (!isOutbound && _outboundTime != null && minutes <= _outboundTime!.hour * 60 + _outboundTime!.minute) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('L’heure de retour doit être après l’heure de départ.')));
      return;
    }
    setState(() {
      if (isOutbound) {
        _outboundTime = picked;
        _outboundController.text = _formatTime(picked);
        if (_returnTime != null && _returnTime!.hour * 60 + _returnTime!.minute <= minutes) {
          _returnTime = null;
          _returnController.clear();
        }
      } else {
        _returnTime = picked;
        _returnController.text = _formatTime(picked);
      }
    });
  }

  Future<void> _suggestAddress(String value, bool isStart) async {
    final token = ++_addressSearchToken;
    if (value.trim().length < 3) {
      setState(() {
        if (isStart) {
          _startSuggestions = [];
          _startAddressVerified = false;
        } else {
          _endSuggestions = [];
          _endAddressVerified = false;
        }
      });
      return;
    }

    try {
      final places = await locationFromAddress(value.trim());
      if (!mounted || token != _addressSearchToken) return;
      final suggestions = places.take(4).map((place) {
        return [place.street, place.postalCode, place.locality, place.country]
            .whereType<String>()
            .where((part) => part.isNotEmpty)
            .join(', ');
      }).where((address) => address.isNotEmpty).toSet().toList();
      setState(() {
        if (isStart) {
          _startSuggestions = suggestions;
          _startAddressVerified = false;
        } else {
          _endSuggestions = suggestions;
          _endAddressVerified = false;
        }
      });
    } catch (_) {
      if (!mounted || token != _addressSearchToken) return;
      setState(() {
        if (isStart) {
          _startSuggestions = [];
          _startAddressVerified = false;
        } else {
          _endSuggestions = [];
          _endAddressVerified = false;
        }
      });
    }
  }

  Future<void> _verifyAddress(TextEditingController controller, bool isStart) async {
    if (controller.text.trim().isEmpty) return;
    setState(() {
      if (isStart) {
        _isCheckingStartAddress = true;
        _startAddressError = null;
      } else {
        _isCheckingEndAddress = true;
        _endAddressError = null;
      }
    });
    try {
      final places = await locationFromAddress(controller.text.trim());
      if (!mounted) return;
      if (places.isEmpty) throw const FormatException();
      final place = places.first;
      final formatted = [place.street, place.postalCode, place.locality, place.country]
          .whereType<String>()
          .where((part) => part.isNotEmpty)
          .join(', ');
      setState(() {
        controller.text = formatted.isEmpty ? controller.text.trim() : formatted;
        if (isStart) {
          _startAddressVerified = true;
          _startSuggestions = [];
          _isCheckingStartAddress = false;
        } else {
          _endAddressVerified = true;
          _endSuggestions = [];
          _isCheckingEndAddress = false;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (isStart) {
          _isCheckingStartAddress = false;
          _startAddressVerified = false;
          _startAddressError = 'Adresse introuvable. Choisissez une suggestion ou précisez-la.';
        } else {
          _isCheckingEndAddress = false;
          _endAddressVerified = false;
          _endAddressError = 'Adresse introuvable. Choisissez une suggestion ou précisez-la.';
        }
      });
    }
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_startAddressVerified || !_endAddressVerified) {
      setState(() {
        _startAddressError = _startAddressVerified ? null : 'Vérifiez cette adresse avant de continuer.';
        _endAddressError = _endAddressVerified ? null : 'Vérifiez cette adresse avant de continuer.';
      });
      return;
    }
    setState(() => _isCreating = true);
    final created = await ref.read(appStateProvider).createGroup(
          name: _nameController.text,
          description: _descriptionController.text,
          startPoint: _startController.text,
          endPoint: _endController.text,
          outboundTime: _outboundController.text,
          returnTime: _returnController.text,
          passengerCapacity: int.parse(_capacityController.text.trim()),
          imageData: _groupImageData,
        );
    if (!mounted) return;
    setState(() => _isCreating = false);
    if (!created) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de créer le groupe.')));
    }
  }
}

// --- COMMONS ---

class CovoiTourLogo extends StatelessWidget {
  final double size;
  final bool showTagline;

  const CovoiTourLogo({super.key, this.size = 32, this.showTagline = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.sync_rounded, color: const Color(0xFF24D58A), size: size * 1.2),
                Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: size * 0.6),
              ],
            ),
            const SizedBox(width: 8),
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: size * 0.9, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                children: const [
                  TextSpan(text: 'Covoi', style: TextStyle(color: Colors.white)),
                  TextSpan(text: 'Tour', style: TextStyle(color: Color(0xFF24D58A))),
                ],
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 2),
          const Text('À qui le volant aujourd’hui ?', style: TextStyle(color: Color(0xFF24D58A), fontSize: 10, fontWeight: FontWeight.w600)),
        ]
      ],
    );
  }
}

class FullPageBackground extends StatelessWidget {
  const FullPageBackground({super.key, required this.imageUrl, required this.child, this.overlayOpacity = 0.85});
  final String imageUrl;
  final Widget child;
  final double overlayOpacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF050C18)))),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  const Color(0xFF050C18).withValues(alpha: overlayOpacity),
                  const Color(0xFF050C18),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class MemberAvatar extends StatelessWidget {
  final Member member;
  final double radius;
  const MemberAvatar({super.key, required this.member, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    if (member.avatarUrl != null && member.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white12,
        child: ClipOval(child: _ImageSource(source: member.avatarUrl!, size: radius * 2)),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF24D58A).withValues(alpha: 0.2),
      child: Text(member.initials, style: TextStyle(color: const Color(0xFF24D58A), fontWeight: FontWeight.bold, fontSize: radius * 0.8)),
    );
  }
}

class _ImageSource extends StatelessWidget {
  const _ImageSource({required this.source, required this.size});
  final String source;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (source.startsWith('data:image/')) {
      final separator = source.indexOf(',');
      if (separator > 0) {
        try {
          return Image.memory(
            base64Decode(source.substring(separator + 1)),
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        } catch (_) {
          return const Icon(Icons.broken_image_outlined);
        }
      }
    }
    return Image.network(source, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined));
  }
}

Future<String?> _pickImageData(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Wrap(
        children: [
          ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Choisir un fichier'), onTap: () => Navigator.pop(sheetContext, ImageSource.gallery)),
          ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Prendre une photo'), onTap: () => Navigator.pop(sheetContext, ImageSource.camera)),
        ],
      ),
    ),
  );
  if (source == null) return null;

  final file = await ImagePicker().pickImage(source: source, imageQuality: 80, maxWidth: 1600, maxHeight: 1600);
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  final extension = file.name.toLowerCase().split('.').last;
  final mime = extension == 'png' ? 'png' : extension == 'webp' ? 'webp' : 'jpeg';
  return 'data:image/$mime;base64,${base64Encode(bytes)}';
}

Future<void> _editGroupImage(BuildContext context, WidgetRef ref) async {
  final image = await _pickImageData(context);
  if (image == null || !context.mounted) return;
  final state = ref.read(appStateProvider);
  state.updateGroup(
    name: state.group.name,
    description: state.group.description,
    startPoint: state.group.startPoint,
    endPoint: state.group.endPoint,
    outboundTime: state.group.outboundTime,
    returnTime: state.group.returnTime,
    imageData: image,
  );
}

// --- SCREENS ---

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final group = state.group;
    final trips = group.trips.where((t) => t.confirmedDriverIds.isEmpty).toList();
    
    if (trips.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('CovoiTour')), body: const Center(child: Text('Aucun trajet prévu.')));
    }

    final trip = trips.first;
    final plan = state.recommendPlan();
    final canValidate = state.canValidateTrip(trip.date);
    final dateFormat = DateFormat('EEEE d MMM', 'fr_FR');
    
    return Scaffold(
      body: FullPageBackground(
        imageUrl: 'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?q=80&w=1000',
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Bonjour ${group.members.firstOrNull?.firstName ?? ""} 👋', 
                            style: const TextStyle(fontSize: 16, color: Colors.white70),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _showPastTripNotifications(context, state.pastUnvalidatedTrips),
                                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                            if (state.pastUnvalidatedTrips.isNotEmpty)
                              Positioned(
                                right: -4,
                                top: -6,
                                child: CircleAvatar(
                                  radius: 9,
                                  backgroundColor: Colors.redAccent,
                                  child: Text('${state.pastUnvalidatedTrips.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Center(child: CovoiTourLogo(size: 48, showTagline: true)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text('${canValidate ? 'Trajet du' : 'Trajet prévu le'} ${dateFormat.format(trip.date)}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Trajet aller - ${group.outboundTime}', 
                    style: const TextStyle(fontSize: 16, color: Colors.white54)),
                  const SizedBox(height: 32),
                  Row(children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.groups_rounded, 
                        value: '${trip.presentMemberIds.length}', 
                        label: 'participants', 
                        color: const Color(0xFF24D58A)
                      )
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.directions_car_rounded, 
                        value: '${plan.assignments.length}', 
                        label: 'voitures', 
                        color: const Color(0xFF32B5FF)
                      )
                    ),
                  ]),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0D8F68), Color(0xFF075348)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Conducteurs proposés', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Text('Basés sur l’équité du groupe', style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 24),
                        if (plan.assignments.isNotEmpty)
                          ...plan.assignments.map((assignment) {
                            final driver = group.members.firstWhere((m) => m.id == assignment.driverId);
                            final score = state.scoresFor(assignment.passengerIds.length + 1)[driver.id] ?? 0;
                            return _DriverCard(member: driver, score: score);
                          })
                        else
                          const Text('Aucun conducteur disponible', style: TextStyle(color: Colors.white54)),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF24D58A)),
                              foregroundColor: const Color(0xFF24D58A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TripTrackingScreen())),
                            icon: const Icon(Icons.location_on_outlined),
                            label: const Text('Suivre le trajet (J-15 min)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF24D58A),
                              foregroundColor: const Color(0xFF03150F),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: !canValidate || plan.assignments.isEmpty ? null : () {
                              ref.read(appStateProvider).confirmPlan(plan);
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => CarAssignmentScreen(plan: plan)));
                            },
                            child: Text(
                              canValidate ? 'Valider le trajet' : 'Validation disponible le jour J',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.value, required this.label, required this.color});
  final IconData icon; final String value; final String label; final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(10), 
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), 
        child: Icon(icon, color: color, size: 22)
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis), 
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54, height: 1), overflow: TextOverflow.ellipsis)
          ]
        )
      ),
    ]
  );
}

void _showPastTripNotifications(BuildContext context, List<Trip> trips) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Journées à valider'),
      content: trips.isEmpty
          ? const Text('Aucune journée passée en attente de validation.')
          : SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: trips
                    .map((trip) => ListTile(
                          leading: const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                          title: Text(DateFormat('EEEE d MMMM', 'fr_FR').format(trip.date)),
                          subtitle: const Text('Le covoiturage n’a pas été validé'),
                        ))
                    .toList(),
              ),
            ),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Fermer'))],
    ),
  );
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.member, required this.score});
  final Member member; final int score;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          MemberAvatar(member: member, radius: 24), const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(member.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text('Score $score', style: const TextStyle(color: Colors.white70))])),
          const Icon(Icons.workspace_premium, color: Color(0xFF24D58A)),
        ]),
      ),
    );
  }
}

class GroupScreen extends ConsumerWidget {
  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final group = state.group;

    return Scaffold(
      body: FullPageBackground(
        imageUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=1000',
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CovoiTourLogo(size: 24),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: const Color(0xFF24D58A).withValues(alpha: 0.2),
                        child: group.imageData == null
                            ? const Icon(Icons.groups_outlined, size: 34, color: Color(0xFF24D58A))
                            : ClipOval(child: _ImageSource(source: group.imageData!, size: 68)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text('${group.startPoint} ➔ ${group.endPoint}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                      if (state.isCurrentUserAdmin)
                        IconButton(
                          onPressed: () => _editGroupImage(context, ref),
                          icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF24D58A)),
                          tooltip: 'Modifier l’image du groupe',
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          state.currentUser == null ? Icons.cloud_off : Icons.cloud_done,
                          color: const Color(0xFF24D58A),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.currentUser?.displayName ?? 'Compte Google non connecté',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                state.currentUser == null
                                    ? 'Connectez-vous pour synchroniser le groupe'
                                    : state.isCurrentUserAdmin
                                        ? 'Synchronisation Google Drive active'
                                        : 'Compte connecté, synchronisation réservée à l’administrateur',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (state.currentUser == null)
                          IconButton(
                            onPressed: () => state.signIn(),
                            icon: const Icon(Icons.login, color: Color(0xFF24D58A)),
                            tooltip: 'Se connecter à Google',
                          )
                        else ...[
                          if (state.isCurrentUserAdmin)
                            IconButton(
                              onPressed: state.isSyncing ? null : () => state.syncWithDrive(),
                              icon: state.isSyncing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.sync, color: Color(0xFF24D58A)),
                              tooltip: 'Synchroniser avec Google Drive',
                            ),
                          TextButton(onPressed: () => state.signOut(), child: const Text('Déconnexion')),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Infos trajet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _InfoCard(
                    items: [
                      _InfoRow(label: 'Départ', value: group.outboundTime),
                      _InfoRow(label: 'Retour', value: group.returnTime),
                      const _InfoRow(label: 'Attente max', value: '5 min'),
                      _InfoRow(label: 'Règles du groupe', value: 'Voir ➔', isLink: true, onTap: () => _showRules(context)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Membres', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${group.members.length} membres', style: const TextStyle(color: Colors.white54)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: group.members.length > 8 ? 9 : group.members.length,
                      itemBuilder: (context, index) {
                        if (index == 8) return _MemberAvatarPlus(count: group.members.length - 8);
                        return _MemberAvatar(member: group.members[index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Moi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _MyProfileMiniCard(member: state.group.members.firstWhere((m) => m.email == state.currentUser?.email, orElse: () => state.activeMembers.first)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyProfileMiniCard extends ConsumerWidget {
  const _MyProfileMiniCard({required this.member});
  final Member member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              MemberAvatar(member: member, radius: 30),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _editAvatar(context, ref, member),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFF24D58A), shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(member.email, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                const SizedBox(height: 4),
                Text(
                  member.hasVehicle ? '${member.passengerCapacity} place${member.passengerCapacity > 1 ? 's' : ''} passager' : 'Pas de voiture déclarée',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _editCarCapacity(context, ref, member),
            icon: const Icon(Icons.directions_car_outlined, color: Color(0xFF24D58A)),
            tooltip: 'Modifier ma voiture',
          ),
        ],
      ),
    );
  }

  void _editAvatar(BuildContext context, WidgetRef ref, Member member) async {
    final image = await _pickImageData(context);
    if (image != null && context.mounted) {
      ref.read(appStateProvider).updateMember(member.copyWith(avatarUrl: image));
    }
  }

  Future<void> _editCarCapacity(BuildContext context, WidgetRef ref, Member member) async {
    final capacityController = TextEditingController(
      text: member.hasVehicle && member.passengerCapacity > 0 ? '${member.passengerCapacity}' : '',
    );
    var hasVehicle = member.hasVehicle;
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Ma voiture'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Je peux conduire'),
                  value: hasVehicle,
                  onChanged: (value) => setDialogState(() => hasVehicle = value),
                ),
                if (hasVehicle)
                  TextFormField(
                    controller: capacityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Places passagers disponibles',
                      prefixIcon: Icon(Icons.event_seat_outlined),
                    ),
                    validator: (value) {
                      final capacity = int.tryParse(value?.trim() ?? '');
                      return capacity == null || capacity < 1 ? 'Indiquez au moins 1 place' : null;
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
            FilledButton(
              onPressed: () {
                if (!hasVehicle || formKey.currentState!.validate()) Navigator.pop(dialogContext, true);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

    if (result == true && context.mounted) {
      ref.read(appStateProvider).updateMember(
            member.copyWith(
              hasVehicle: hasVehicle,
              passengerCapacity: hasVehicle ? int.parse(capacityController.text.trim()) : 0,
            ),
          );
    }
    capacityController.dispose();
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.items});
  final List<Widget> items;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: const Color(0xFF0C192A), borderRadius: BorderRadius.circular(24)),
    child: Column(children: items),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.isLink = false, this.onTap});
  final String label; final String value; final bool isLink; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.white54)), Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isLink ? const Color(0xFF24D58A) : Colors.white))]),
    ),
  );
}

void _showRules(BuildContext context) {
  showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Règles du groupe'), content: const Text('1. Soyez à l\'heure.\n2. Prévenez la veille.\n3. Conducteur choisi par équité.\n4. Partagez les frais.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member});
  final Member member;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(right: 12), child: MemberAvatar(member: member, radius: 24));
}

class _MemberAvatarPlus extends StatelessWidget {
  const _MemberAvatarPlus({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF101D30), border: Border.all(color: Colors.white10, width: 2)), child: Center(child: Text('+$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))));
}

class ScoresScreen extends ConsumerStatefulWidget {
  const ScoresScreen({super.key});
  @override
  ConsumerState<ScoresScreen> createState() => _ScoresScreenState();
}

class _ScoresScreenState extends ConsumerState<ScoresScreen> {
  int _selectedGroupSize = 2;
  @override
  void initState() { 
    super.initState(); 
    _selectedGroupSize = ref.read(appStateProvider).activeMembers.length.clamp(2, 5); 
  }
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final scores = state.scoresFor(_selectedGroupSize);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: FullPageBackground(
        imageUrl: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?q=80&w=1000',
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 60),
            const CovoiTourLogo(size: 24),
            const SizedBox(height: 20),
            const Text('Équité', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            Row(children: [
              if (state.activeMembers.length >= 2) _SizeToggle(label: '2', isSelected: _selectedGroupSize == 2, onTap: () => setState(() => _selectedGroupSize = 2)),
              if (state.activeMembers.length >= 3) _SizeToggle(label: '3', isSelected: _selectedGroupSize == 3, onTap: () => setState(() => _selectedGroupSize = 3)),
              if (state.activeMembers.length >= 4) _SizeToggle(label: '4', isSelected: _selectedGroupSize == 4, onTap: () => setState(() => _selectedGroupSize = 4)),
              if (state.activeMembers.length >= 5) _SizeToggle(label: '5+', isSelected: _selectedGroupSize >= 5, onTap: () => setState(() => _selectedGroupSize = 5)),
            ]),
            const SizedBox(height: 16),
            ...state.activeMembers.map((member) { 
              final score = scores[member.id] ?? 0; 
              return _ScoreRow(member: member, score: score); 
            }),
            const SizedBox(height: 24),
            const _BalanceStatusCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SizeToggle extends StatelessWidget {
  const _SizeToggle({required this.label, required this.isSelected, required this.onTap});
  final String label; final bool isSelected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(onTap: onTap, child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: isSelected ? const Color(0xFF24D58A) : Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)), child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? const Color(0xFF03150F) : Colors.white70, fontWeight: FontWeight.bold)))));
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.member, required this.score});
  final Member member; final int score;
  @override
  Widget build(BuildContext context) {
    final double progress = (score.abs() / 10).clamp(0.0, 1.0);
    final Color barColor = score < 0 ? const Color(0xFF24D58A) : (score > 3 ? Colors.redAccent : Colors.orangeAccent);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        MemberAvatar(member: member, radius: 20), const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4), ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white.withValues(alpha: 0.05), color: barColor, minHeight: 6))])),
        const SizedBox(width: 16),
        Text(score > 0 ? '+$score' : '$score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: barColor)),
      ]),
    );
  }
}

class _BalanceStatusCard extends StatelessWidget {
  const _BalanceStatusCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF0C192A), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.05))),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF24D58A).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.balance, color: Color(0xFF24D58A))),
      const SizedBox(width: 16),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Le score du groupe est équilibré', style: TextStyle(fontWeight: FontWeight.bold)), Text('Total : 0 point', style: TextStyle(color: Colors.white54, fontSize: 12))])),
    ]),
  );
}

class PresenceScreen extends ConsumerWidget {
  const PresenceScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: FullPageBackground(
        imageUrl: 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?q=80&w=1000',
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 60),
            const CovoiTourLogo(size: 24),
            const SizedBox(height: 20),
            const Text('Ma présence', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 32),
            _StatusItem(icon: Icons.check_circle, title: 'Présent', subtitle: 'Je participe au trajet', color: const Color(0xFF24D58A), isSelected: false, onTap: () => _openCalendar(context, AttendanceStatus.present)),
            _StatusItem(icon: Icons.laptop_mac_rounded, title: 'Télétravail', subtitle: 'Je travaille à distance', color: const Color(0xFF32B5FF), isSelected: false, onTap: () => _openCalendar(context, AttendanceStatus.telework)),
            _StatusItem(icon: Icons.home_rounded, title: 'Absent', subtitle: 'Je ne suis pas disponible', color: Colors.white30, isSelected: false, onTap: () => _openCalendar(context, AttendanceStatus.absent)),
            _StatusItem(icon: Icons.calendar_today_rounded, title: 'Congés', subtitle: 'Je suis en congés', color: Colors.white30, isSelected: false, onTap: () => _openCalendar(context, AttendanceStatus.leave)),
            const Divider(height: 32, color: Colors.white10),
            _StatusItem(icon: Icons.chat_bubble_outline_rounded, title: 'Commentaire', subtitle: 'Ajouter une note sur un jour', color: Colors.orangeAccent, isSelected: false, onTap: () => _openCalendar(context, null, isCommentMode: true)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  void _openCalendar(BuildContext context, AttendanceStatus? status, {bool isCommentMode = false}) { Navigator.of(context).push(MaterialPageRoute(builder: (_) => SharedCalendarScreen(targetStatus: status, isCommentMode: isCommentMode))); }
}

class SharedCalendarScreen extends ConsumerStatefulWidget {
  const SharedCalendarScreen({super.key, this.targetStatus, this.isCommentMode = false});
  final AttendanceStatus? targetStatus; final bool isCommentMode;
  @override
  ConsumerState<SharedCalendarScreen> createState() => _SharedCalendarScreenState();
}

enum _CalendarSelectionMode { individual, range }

class _SharedCalendarScreenState extends ConsumerState<SharedCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  final Set<DateTime> _selectedDays = {};
  _CalendarSelectionMode _selectionMode = _CalendarSelectionMode.individual;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
  }

  String _getTitle() {
    if (widget.isCommentMode) return 'Commentaires';
    return switch (widget.targetStatus) {
      AttendanceStatus.present => 'Présent',
      AttendanceStatus.telework => 'Télétravail',
      AttendanceStatus.absent => 'Absent',
      AttendanceStatus.leave => 'Congés',
      _ => 'Présence',
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final currentUserEmail = state.currentUser?.email;
    final member = state.group.members.firstWhere(
      (m) => m.email == currentUserEmail,
      orElse: () => state.activeMembers.first,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CovoiTourLogo(size: 20),
            const SizedBox(width: 12),
            Text(_getTitle(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FullPageBackground(
        imageUrl: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?q=80&w=1000',
        child: Column(
          children: [
            const SizedBox(height: 100),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SegmentedButton<_CalendarSelectionMode>(
                segments: const [
                  ButtonSegment(value: _CalendarSelectionMode.individual, icon: Icon(Icons.event), label: Text('Jours')),
                  ButtonSegment(value: _CalendarSelectionMode.range, icon: Icon(Icons.date_range), label: Text('Période')),
                ],
                selected: {_selectionMode},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectionMode = selection.first;
                    _selectedDays.clear();
                    _rangeStart = null;
                    _rangeEnd = null;
                  });
                },
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected) ? const Color(0xFF24D58A).withValues(alpha: 0.22) : Colors.white10;
                  }),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TableCalendar(
              locale: 'fr_FR',
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                rangeSelectionMode: _selectionMode == _CalendarSelectionMode.range
                  ? RangeSelectionMode.toggledOn
                  : RangeSelectionMode.toggledOff,
              selectedDayPredicate: (day) => _selectedDays.any((d) => isSameDay(d, day)),
              enabledDayPredicate: (day) => !state.group.offDays.contains(day.weekday),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
              ),
              calendarStyle: CalendarStyle(
                defaultTextStyle: const TextStyle(color: Colors.white),
                weekendTextStyle: const TextStyle(color: Colors.white70),
                outsideTextStyle: const TextStyle(color: Colors.white24),
                disabledTextStyle: const TextStyle(color: Colors.white12),
                disabledDecoration: BoxDecoration(
                  color: Colors.white10,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: const Color(0xFF24D58A).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF24D58A).withValues(alpha: 0.5)),
                ),
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFF24D58A),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Color(0xFF32B5FF),
                  shape: BoxShape.circle,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                if (_selectionMode != _CalendarSelectionMode.individual ||
                    state.group.offDays.contains(selectedDay.weekday)) {
                  return;
                }
                setState(() {
                  _focusedDay = focusedDay;
                  bool alreadySelected = false;
                  DateTime? toRemove;
                  for (var d in _selectedDays) {
                    if (isSameDay(d, selectedDay)) {
                      alreadySelected = true;
                      toRemove = d;
                      break;
                    }
                  }
                  if (alreadySelected) {
                    _selectedDays.remove(toRemove);
                  } else {
                    _selectedDays.add(selectedDay);
                  }
                });
              },
              onRangeSelected: (start, end, focusedDay) {
                if (_selectionMode != _CalendarSelectionMode.range) return;
                setState(() {
                  _focusedDay = focusedDay;
                  _rangeStart = start;
                  _rangeEnd = end;
                  _selectedDays.clear();

                  if (start == null || end == null) return;
                  for (var day = DateTime(start.year, start.month, start.day);
                      !day.isAfter(end);
                      day = day.add(const Duration(days: 1))) {
                    if (!state.group.offDays.contains(day.weekday)) {
                      _selectedDays.add(day);
                    }
                  }
                });
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  final trip = state.group.trips.firstWhere(
                    (t) => isSameDay(t.date, day),
                    orElse: () => Trip(id: '', date: day, participants: []),
                  );
                  
                  final others = trip.participants.where((p) => p.memberId != member.id).toList();
                  if (others.isEmpty) return null;

                  return Positioned(
                    bottom: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: others.take(4).map((p) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _getStatusColor(p.status),
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white10, height: 32),
            Expanded(
              child: _buildSelectedDaysList(member),
            ),
            if (_selectedDays.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF24D58A),
                      foregroundColor: const Color(0xFF03150F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _validateSelection(member.id),
                    child: Text(
                      'Valider (${_selectedDays.length} ${_selectedDays.length == 1 ? 'jour' : 'jours'})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDaysList(Member member) {
    if (_selectedDays.isEmpty) {
      return const Center(child: Text('Sélectionnez des jours sur le calendrier', style: TextStyle(color: Colors.white30)));
    }

    final sortedDays = _selectedDays.toList()..sort((a, b) => a.compareTo(b));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
          child: Text(
            '${sortedDays.length} ${sortedDays.length == 1 ? 'jour sélectionné' : 'jours sélectionnés'}',
            style: const TextStyle(color: Color(0xFF24D58A), fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: sortedDays.length,
            itemBuilder: (context, index) {
        final day = sortedDays[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF24D58A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_today, color: Color(0xFF24D58A), size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  DateFormat('EEEE d MMMM', 'fr_FR').format(day),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white30, size: 18),
                onPressed: () => setState(() => _selectedDays.remove(day)),
              ),
            ],
          ),
        );
            },
          ),
        ),
      ],
    );
  }

  void _validateSelection(String memberId) async {
    final state = ref.read(appStateProvider);
    
    if (widget.isCommentMode) {
      final controller = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Commentaire groupé'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Votre message pour ces jours...'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Valider')),
          ],
        ),
      );

      if (result != null && result.trim().isNotEmpty) {
        for (var day in _selectedDays) {
          state.setComment(memberId, day, result.trim());
        }
        if (mounted) Navigator.pop(context);
      }
    } else if (widget.targetStatus != null) {
      for (var day in _selectedDays) {
        state.setAttendance(memberId, widget.targetStatus!, date: day);
      }
      Navigator.pop(context);
    }
  }
  Widget _buildDayDetails(DateTime day) {
    final state = ref.watch(appStateProvider);
    final trip = state.group.trips.firstWhere((t) => isSameDay(t.date, day), orElse: () => Trip(id: '', date: day, participants: []));
    return ListView(padding: const EdgeInsets.symmetric(horizontal: 24), children: [
      Text(DateFormat('EEEE d MMMM', 'fr_FR').format(day), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
      if (trip.participants.isEmpty) const Text('Aucune présence déclarée.', style: TextStyle(color: Colors.white30))
      else ...trip.participants.map((p) {
        final m = state.group.members.firstWhere((m) => m.id == p.memberId, orElse: () => Member(id: p.memberId, firstName: '?', lastName: '', email: ''));
        return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(children: [MemberAvatar(member: m, radius: 16), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)), if (p.comment != null) Text(p.comment!, style: const TextStyle(fontSize: 12, color: Colors.white54, fontStyle: FontStyle.italic))])), _StatusBadge(status: p.status)]));
      }),
    ]);
  }
  Color _getStatusColor(AttendanceStatus status) => switch (status) { AttendanceStatus.present => const Color(0xFF24D58A), AttendanceStatus.telework => const Color(0xFF32B5FF), AttendanceStatus.absent => Colors.redAccent, AttendanceStatus.leave => Colors.orangeAccent, _ => Colors.grey };
  Future<void> _showCommentDialog(DateTime date) async {
    final state = ref.read(appStateProvider); final memberId = state.activeMembers.first.id; final controller = TextEditingController();
    final result = await showDialog<String>(context: context, builder: (context) => AlertDialog(title: Text('Commentaire pour le ${DateFormat('d MMMM').format(date)}'), content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Votre message...'), autofocus: true), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')), FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Valider'))]));
    if (result != null && result.trim().isNotEmpty) { state.setComment(memberId, date, result.trim()); }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final AttendanceStatus status;
  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.5))), child: Text(_label(status), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)));
  }
  static String _label(AttendanceStatus status) => switch (status) { AttendanceStatus.present => 'PRÉSENT', AttendanceStatus.telework => 'TÉLÉTRAVAIL', AttendanceStatus.absent => 'ABSENT', AttendanceStatus.leave => 'CONGÉS', _ => '?' };
  Color _getStatusColor(AttendanceStatus status) => switch (status) { AttendanceStatus.present => const Color(0xFF24D58A), AttendanceStatus.telework => const Color(0xFF32B5FF), AttendanceStatus.absent => Colors.redAccent, AttendanceStatus.leave => Colors.orangeAccent, _ => Colors.grey };
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.icon, required this.title, required this.subtitle, required this.color, required this.isSelected, required this.onTap});
  final IconData icon; final String title; final String subtitle; final Color color; final bool isSelected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap, child: Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isSelected ? const Color(0xFF0C192A) : Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? const Color(0xFF24D58A).withOpacity(0.5) : Colors.white.withOpacity(0.05))), child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05), shape: BoxShape.circle), child: Icon(icon, color: isSelected ? color : Colors.white30)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.white70)), Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white30))]))])),
  );
}

class AdminUnvalidatedCalendarScreen extends ConsumerStatefulWidget {
  const AdminUnvalidatedCalendarScreen({super.key});

  @override
  ConsumerState<AdminUnvalidatedCalendarScreen> createState() => _AdminUnvalidatedCalendarScreenState();
}

class _AdminUnvalidatedCalendarScreenState extends ConsumerState<AdminUnvalidatedCalendarScreen> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final trips = ref.watch(appStateProvider).pastUnvalidatedTrips;
    final dates = trips.map((trip) => trip.date).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validations oubliées'),
        actions: [
          if (trips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('${trips.length}', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))),
            ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'fr_FR',
            firstDay: DateTime.now().subtract(const Duration(days: 3650)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            onDaySelected: (selectedDay, focusedDay) {
              _focusedDay = focusedDay;
              final trip = trips.cast<Trip?>().firstWhere((item) => isSameDay(item!.date, selectedDay), orElse: () => null);
              if (trip != null) _showAcknowledgeDialog(context, trip);
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (!dates.any((date) => isSameDay(date, day))) return null;
                return const Positioned(bottom: 4, child: Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 16));
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: trips.isEmpty
                ? const Center(child: Text('Aucune journée à traiter.', style: TextStyle(color: Colors.white54)))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: trips.map((trip) => ListTile(
                      leading: const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                      title: Text(DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(trip.date)),
                      subtitle: const Text('Covoiturage non validé'),
                      trailing: IconButton(icon: const Icon(Icons.check_circle_outline, color: Color(0xFF24D58A)), tooltip: 'Marquer comme normal', onPressed: () => _acknowledge(trip)),
                    )).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAcknowledgeDialog(BuildContext context, Trip trip) async {
    final acknowledge = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Validation oubliée'),
        content: Text('Le covoiturage du ${DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(trip.date)} n’a pas été validé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Fermer')),
          FilledButton.icon(onPressed: () => Navigator.pop(dialogContext, true), icon: const Icon(Icons.check), label: const Text('C’est normal')),
        ],
      ),
    );
    if (acknowledge == true) _acknowledge(trip);
  }

  void _acknowledge(Trip trip) {
    ref.read(appStateProvider).acknowledgeUnvalidatedTrip(trip.id);
  }
}

class MainAdminScreen extends StatelessWidget {
  const MainAdminScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3, 
    child: Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0), 
      body: FullPageBackground(
        imageUrl: 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?q=80&w=1000', 
        overlayOpacity: 0.9, 
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(alignment: Alignment.centerLeft, child: CovoiTourLogo(size: 24)),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft, 
                child: Text('Administration', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white))
              ),
            ),
            const SizedBox(height: 20),
            const TabBar(
              tabs: [
                Tab(text: 'Membres', icon: Icon(Icons.people_outline)),
                Tab(text: 'Groupe', icon: Icon(Icons.settings_outlined)),
                Tab(text: 'Historique', icon: Icon(Icons.history))
              ], 
              indicatorColor: Color(0xFF24D58A), 
              labelColor: Color(0xFF24D58A), 
              unselectedLabelColor: Colors.white54
            ),
            Expanded(
              child: TabBarView(
                children: [
                  const MembersScreen(),
                  const AdminScreen(),
                  const HistoryScreen()
                ]
              )
            ),
          ],
        )
      )
    ),
  );
}

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    return ListView(padding: const EdgeInsets.fromLTRB(24, 20, 24, 100), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Liste des membres', style: Theme.of(context).textTheme.titleLarge), FilledButton.icon(onPressed: () => _showMemberDialog(context, ref), icon: const Icon(Icons.person_add), label: const Text('Ajouter'))]),
      const SizedBox(height: 20),
      ...state.activeMembers.map((member) => Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(leading: MemberAvatar(member: member), title: Text(member.name), subtitle: Text(member.hasVehicle ? '${member.email}\n${member.passengerCapacity} places' : '${member.email}\nPas de véhicule'), isThreeLine: true, trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'edit') _showMemberDialog(context, ref, member: member); else if (v == 'archive') ref.read(appStateProvider).archiveMember(member.id); }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Modifier')), PopupMenuItem(value: 'archive', child: Text('Archiver'))])))),
    ]);
  }
  Future<void> _showMemberDialog(BuildContext context, WidgetRef ref, {Member? member}) async {
    final fName = TextEditingController(text: member?.firstName);
    final lName = TextEditingController(text: member?.lastName);
    final email = TextEditingController(text: member?.email);
    final cap = TextEditingController(text: member?.passengerCapacity.toString() ?? '0');
    var avatarData = member?.avatarUrl;
    var hasV = member?.hasVehicle ?? false;
    final formKey = GlobalKey<FormState>();
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(member == null ? 'Nouveau membre' : 'Modifier membre'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: fName, decoration: const InputDecoration(labelText: 'Prénom *'), validator: (v) => v!.isEmpty ? 'Requis' : null),
                  TextFormField(controller: lName, decoration: const InputDecoration(labelText: 'Nom *'), validator: (v) => v!.isEmpty ? 'Requis' : null),
                  TextFormField(controller: email, decoration: const InputDecoration(labelText: 'Email *'), validator: (v) => !v!.contains('@') ? 'Invalide' : null),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: avatarData == null ? const CircleAvatar(child: Icon(Icons.person)) : CircleAvatar(child: ClipOval(child: _ImageSource(source: avatarData!, size: 40))),
                    title: const Text('Photo du membre'),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_a_photo_outlined),
                      onPressed: () async {
                        final image = await _pickImageData(ctx);
                        if (image != null) setS(() => avatarData = image);
                      },
                    ),
                  ),
                  SwitchListTile(title: const Text('Véhicule'), value: hasV, onChanged: (v) => setS(() => hasV = v)),
                  if (hasV) TextFormField(controller: cap, decoration: const InputDecoration(labelText: 'Capacité *'), keyboardType: TextInputType.number, validator: (v) => int.tryParse(v ?? '') == null ? 'Requis' : null),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(ctx, true); }, child: const Text('Enregistrer')),
          ],
        ),
      ),
    );
    if (res == true) {
      if (member == null) {
        ref.read(appStateProvider).addMember(firstName: fName.text, lastName: lName.text, email: email.text, avatarUrl: avatarData, hasVehicle: hasV, passengerCapacity: int.parse(cap.text));
      } else {
        ref.read(appStateProvider).updateMember(member.copyWith(firstName: fName.text, lastName: lName.text, email: email.text, avatarUrl: avatarData, hasVehicle: hasV, passengerCapacity: int.parse(cap.text)));
      }
    }
  }
}

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});
  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  late TextEditingController _name, _desc, _start, _end, _out, _ret;
  String? _groupImageData;

  @override
  void initState() {
    super.initState();
    final g = ref.read(appStateProvider).group;
    _name = TextEditingController(text: g.name);
    _desc = TextEditingController(text: g.description);
    _start = TextEditingController(text: g.startPoint);
    _end = TextEditingController(text: g.endPoint);
    _out = TextEditingController(text: g.outboundTime);
    _ret = TextEditingController(text: g.returnTime);
    _groupImageData = g.imageData;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _start.dispose();
    _end.dispose();
    _out.dispose();
    _ret.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    return ListView(padding: const EdgeInsets.fromLTRB(24, 20, 24, 100), children: [
      if (state.pastUnvalidatedTrips.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
              const SizedBox(width: 12),
              Expanded(child: Text('${state.pastUnvalidatedTrips.length} journée${state.pastUnvalidatedTrips.length > 1 ? 's' : ''} passée${state.pastUnvalidatedTrips.length > 1 ? 's' : ''} non validée${state.pastUnvalidatedTrips.length > 1 ? 's' : ''}.')),
              IconButton(
                icon: const Icon(Icons.calendar_month, color: Colors.orangeAccent),
                tooltip: 'Ouvrir le calendrier des alertes',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminUnvalidatedCalendarScreen())),
              ),
            ],
          ),
        ),
      Text('Infos du groupe', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
      Text(
        'Administrateur : ${state.group.members.where((member) => member.id == state.group.adminId).firstOrNull?.name ?? 'Non défini'}',
        style: const TextStyle(color: Colors.white70),
      ),
      const SizedBox(height: 12),
      Builder(
        builder: (context) {
          final candidates = state.activeMembers.where((member) => member.id != state.group.adminId).toList();
          return FilledButton.icon(
            onPressed: candidates.isEmpty ? null : () => _showAdminTransferDialog(context, ref, candidates),
            icon: const Icon(Icons.admin_panel_settings_outlined),
            label: const Text('Transférer les droits administrateur'),
          );
        },
      ),
      const SizedBox(height: 32),
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
        leading: _groupImageData == null
            ? const CircleAvatar(child: Icon(Icons.groups_outlined))
            : CircleAvatar(child: ClipOval(child: _ImageSource(source: _groupImageData!, size: 40))),
        title: const Text('Photo du groupe'),
        subtitle: Text(_groupImageData == null ? 'Aucune photo sélectionnée' : 'Photo sélectionnée'),
        trailing: const Icon(Icons.add_a_photo_outlined),
        onTap: () async {
          final image = await _pickImageData(context);
          if (image != null) setState(() => _groupImageData = image);
        },
      ),
      const SizedBox(height: 12),
      TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nom du groupe')),
      TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Description')),
      TextField(controller: _start, decoration: const InputDecoration(labelText: 'Point de départ')),
      TextField(controller: _end, decoration: const InputDecoration(labelText: 'Point de retour')),
      Row(children: [Expanded(child: TextField(controller: _out, decoration: const InputDecoration(labelText: 'Aller'))), const SizedBox(width: 16), Expanded(child: TextField(controller: _ret, decoration: const InputDecoration(labelText: 'Retour')))]),
      const SizedBox(height: 32),
      Text('Jours sans covoiturage', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        _DayChip(label: 'L', day: 1, isOff: state.group.offDays.contains(1), onToggle: (off) => _toggleDay(1, off)),
        _DayChip(label: 'M', day: 2, isOff: state.group.offDays.contains(2), onToggle: (off) => _toggleDay(2, off)),
        _DayChip(label: 'M', day: 3, isOff: state.group.offDays.contains(3), onToggle: (off) => _toggleDay(3, off)),
        _DayChip(label: 'J', day: 4, isOff: state.group.offDays.contains(4), onToggle: (off) => _toggleDay(4, off)),
        _DayChip(label: 'V', day: 5, isOff: state.group.offDays.contains(5), onToggle: (off) => _toggleDay(5, off)),
        _DayChip(label: 'S', day: 6, isOff: state.group.offDays.contains(6), onToggle: (off) => _toggleDay(6, off)),
        _DayChip(label: 'D', day: 7, isOff: state.group.offDays.contains(7), onToggle: (off) => _toggleDay(7, off)),
      ]),
      const SizedBox(height: 32),
      FilledButton.icon(onPressed: () { state.updateGroup(name: _name.text, description: _desc.text, startPoint: _start.text, endPoint: _end.text, outboundTime: _out.text, returnTime: _ret.text, offDays: state.group.offDays, imageData: _groupImageData); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuration du groupe enregistrée'))); }, icon: const Icon(Icons.save), label: const Text('Enregistrer tout')),
    ]);
  }
  Future<void> _showAdminTransferDialog(BuildContext context, WidgetRef ref, List<Member> candidates) async {
    var selectedId = candidates.first.id;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Transférer les droits'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedId,
            decoration: const InputDecoration(labelText: 'Nouveau administrateur'),
            items: candidates
                .map((member) => DropdownMenuItem(value: member.id, child: Text(member.name)))
                .toList(),
            onChanged: (value) {
              if (value != null) setDialogState(() => selectedId = value);
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, selectedId), child: const Text('Transférer')),
          ],
        ),
      ),
    );

    if (result == null || !context.mounted) return;
    final transferred = await ref.read(appStateProvider).transferAdmin(result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(transferred ? 'Droits administrateur transférés' : 'Transfert impossible : synchronisation échouée'),
      ),
    );
  }

  void _toggleDay(int day, bool off) { final days = List<int>.from(ref.read(appStateProvider).group.offDays); if (off && !days.contains(day)) days.add(day); else if (!off) days.remove(day); ref.read(appStateProvider).updateGroup(name: _name.text, description: _desc.text, startPoint: _start.text, endPoint: _end.text, outboundTime: _out.text, returnTime: _ret.text, offDays: days); }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label, required this.day, required this.isOff, required this.onToggle});
  final String label; final int day; final bool isOff; final ValueChanged<bool> onToggle;
  @override
  Widget build(BuildContext context) => FilterChip(label: Text(label), selected: isOff, onSelected: onToggle, selectedColor: Colors.redAccent.withValues(alpha: 0.3), checkmarkColor: Colors.redAccent);
}

class TripTrackingScreen extends ConsumerWidget {
  const TripTrackingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white), onPressed: () => Navigator.pop(context)), title: const Text('Suivi du trajet', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true, backgroundColor: Colors.transparent),
      body: FullPageBackground(
        imageUrl: 'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?q=80&w=1000',
        child: Column(children: [
          const SizedBox(height: 100),
          const Text('Départ dans 15 min', style: TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 20),
          Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 24), itemCount: state.activeMembers.length, itemBuilder: (context, index) => _TrackingMemberTile(member: state.activeMembers[index], status: _getMockTrackingStatus(index)))),
          Container(
            height: 250, margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white10)),
            child: Stack(children: [
              Center(child: Icon(Icons.map_outlined, size: 64, color: Colors.white.withValues(alpha: 0.1))),
              Positioned(bottom: 16, left: 20, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Point de départ', style: TextStyle(fontSize: 12, color: Colors.white54)), Text('Parking Anthea', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))])),
              const Center(child: Icon(Icons.directions_car_rounded, color: Color(0xFF24D58A), size: 32)),
            ]),
          ),
        ]),
      ),
    );
  }
  String _getMockTrackingStatus(int index) => switch (index % 4) { 0 => 'En route', 1 => 'À l\'heure', 2 => 'Retard 3 min', _ => 'Arrivé' };
}

class _TrackingMemberTile extends StatelessWidget {
  const _TrackingMemberTile({required this.member, required this.status});
  final Member member; final String status;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(children: [MemberAvatar(member: member, radius: 20), const SizedBox(width: 16), Expanded(child: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold))), Text(status, style: TextStyle(color: status.contains('Retard') ? Colors.orangeAccent : const Color(0xFF24D58A), fontWeight: FontWeight.w600, fontSize: 14))]),
  );
}

class CarAssignmentScreen extends StatelessWidget {
  const CarAssignmentScreen({super.key, required this.plan});
  final TripPlan plan;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: const Padding(padding: EdgeInsets.only(left: 16.0), child: Center(child: CovoiTourLogo(size: 20))), leadingWidth: 120, title: const Text('Répartition des voitures', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
    body: ListView(padding: const EdgeInsets.all(24), children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF24D58A).withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.check_circle, color: Color(0xFF24D58A)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Trajet validé !', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), Text('Tout le monde a été notifié.', style: TextStyle(color: Colors.white54, fontSize: 12))]))])),
      const SizedBox(height: 32),
      ...plan.assignments.asMap().entries.map((entry) => _CarCard(index: entry.key + 1, assignment: entry.value)),
    ]),
  );
}

class _CarCard extends ConsumerWidget {
  const _CarCard({required this.index, required this.assignment});
  final int index; final VehicleAssignment assignment;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final driver = state.group.members.firstWhere((m) => m.id == assignment.driverId);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Voiture $index', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF24D58A).withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text('${driver.passengerCapacity + 1} places', style: const TextStyle(color: Color(0xFF24D58A), fontSize: 12, fontWeight: FontWeight.bold)))]),
      const SizedBox(height: 16),
      _MemberTile(member: driver, isDriver: true),
      ...assignment.passengerIds.map((pid) => _MemberTile(member: state.group.members.firstWhere((m) => m.id == pid), isDriver: false)),
      const SizedBox(height: 32),
    ]);
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.isDriver});
  final Member member; final bool isDriver;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [MemberAvatar(member: member, radius: 20), const SizedBox(width: 16), Expanded(child: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600))), if (isDriver) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF24D58A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: const Text('Conducteur', style: TextStyle(color: Color(0xFF24D58A), fontSize: 12, fontWeight: FontWeight.bold)))]));
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final completedTrips = state.group.trips.where((t) => t.confirmedDriverIds.isNotEmpty).toList().reversed.toList();
    return ListView(padding: const EdgeInsets.fromLTRB(24, 20, 24, 100), children: [
      Text('Anciens trajets', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
      if (completedTrips.isEmpty) const Center(child: Text('Aucun trajet validé.')) else ...completedTrips.map((trip) {
        final driverNames = trip.confirmedDriverIds.map((id) => state.group.members.firstWhere((m) => m.id == id, orElse: () => Member(id: id, firstName: 'Inconnu', lastName: '', email: '')).name).join(', ');
        return Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(leading: const Icon(Icons.event_available, color: Color(0xFF24D58A)), title: Text(DateFormat('dd/MM/yyyy').format(trip.date)), subtitle: Text('Conducteur(s) : $driverNames\n${trip.presentMemberIds.length} passagers'), isThreeLine: true));
      }),
    ]);
  }
}
