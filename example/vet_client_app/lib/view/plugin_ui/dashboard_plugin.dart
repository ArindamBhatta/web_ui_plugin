import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_ui_plugin/web_ui_plugin.dart';

import '../../domain/enums/vet_application_enums.dart';
import '../../domain/models/dashboard_model.dart';
import '../../domain/models/doctor_model.dart';
import '../../domain/models/pet_owner_model.dart';
import '../../domain/models/pet_model.dart';
import '../../domain/models/booking_model.dart';
import 'doctor_plugin.dart';
import 'pet_owner_plugin.dart';

/// Single source of truth for Booking state. This enables real-time booking updates.
class BookingPluginState {
  static final DefaultPluginDescription<BookingModel> descriptor =
      DefaultPluginDescription<BookingModel>(
    moduleId: 'bookings',
    title: 'Bookings',
    icon: FontAwesomeIcons.calendarCheck,
    color: Colors.amber,
    dataBinding: PluginDataBinding<BookingModel>(
      collectionName: 'bookings',
      fromJson: BookingModel.fromJson,
      createEmpty: BookingModel.new,
    ),
  );

  static final SectionRepo<BookingModel> repo =
      SectionRepo<BookingModel>.fromDescriptor(descriptor);

  static final FormCubit<BookingModel> cubit = FormCubit<BookingModel>(
    repo: repo,
  );
}

/// Dashboard plugin descriptor registered in bootstrap.
final DefaultPluginDescription<DashboardModel> dashboardPlugin =
    DefaultPluginDescription<DashboardModel>(
  moduleId: 'dashboard',
  title: VetAppSection.dashboard.label,
  icon: VetAppSection.dashboard.icon,
  color: VetAppSection.dashboard.color,
  order: VetAppSection.dashboard.order,
  features: const PluginFeatureFlags(
    supportsCrud: false,
    supportsRealtime: false,
    supportsUpload: false,
  ),
  visibilityPolicy: PersonaPermissionPolicy({
    VetApplicationEnums.admin.label,
    VetApplicationEnums.operator.label,
  }),
  dataBinding: PluginDataBinding<DashboardModel>(
    collectionName: 'dashboard',
    fromJson: (_) => DashboardModel(),
    createEmpty: () => DashboardModel(),
  ),
  routes: [
    SingleRouteDescriptionAndPolicy(
      path: '/dashboard',
      builder: (BuildContext ctx, GoRouterState state) => const DashboardPage(),
    ),
  ],
);

/// A beautifully crafted dashboard screen that aggregates data across:
/// 1. DoctorsPluginState.repo (Active Doctors)
/// 2. PetOwnerPluginState.repo (Registered Clients/Owners)
/// 3. PetPluginState.repo (Registered Pets)
/// 4. BookingPluginState.repo (Bookings / Appointments)
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  StreamSubscription? _doctorsSub;
  StreamSubscription? _clientsSub;
  StreamSubscription? _bookingsSub;
  StreamSubscription? _petsSub;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initDataAndStreams();
  }

  Future<void> _initDataAndStreams() async {
    // Prime the repositories to fetch initial values from Firestore
    await Future.wait([
      DoctorsPluginState.repo.readAll(),
      PetOwnerPluginState.repo.readAll(),
      BookingPluginState.repo.readAll(),
      PetPluginState.repo.readAll(),
    ]);

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }

    // Connect real-time change triggers so the dashboard reflects updates instantly
    _doctorsSub = DoctorsPluginState.repo.dataStream.listen((_) {
      if (mounted) setState(() {});
    });
    _clientsSub = PetOwnerPluginState.repo.dataStream.listen((_) {
      if (mounted) setState(() {});
    });
    _bookingsSub = BookingPluginState.repo.dataStream.listen((_) {
      if (mounted) setState(() {});
    });
    _petsSub = PetPluginState.repo.dataStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _doctorsSub?.cancel();
    _clientsSub?.cancel();
    _bookingsSub?.cancel();
    _petsSub?.cancel();
    super.dispose();
  }

  Future<void> _seedMockData() async {
    setState(() => _loading = true);
    try {
      // 1. Seed doctors if empty
      if (DoctorsPluginState.repo.items.isEmpty) {
        final doctors = [
          DoctorModel(id: 'doc1', active: 'true', name: 'Dr. Helen Carter', qualifications: 'DVM, Ph.D', mobile: '9876543210', email: 'helen.carter@vet.com', fee: '150'),
          DoctorModel(id: 'doc2', active: 'true', name: 'Dr. Alex Mercer', qualifications: 'DVM, Specialist', mobile: '9876543211', email: 'alex.mercer@vet.com', fee: '120'),
          DoctorModel(id: 'doc3', active: 'false', name: 'Dr. Sarah Connor', qualifications: 'B.V.Sc', mobile: '9876543212', email: 'sarah.connor@vet.com', fee: '100'),
        ];
        for (var doc in doctors) {
          await DoctorsPluginState.repo.create(doc);
        }
      }

      // 2. Seed pet owners if empty
      if (PetOwnerPluginState.repo.items.isEmpty) {
        final owners = [
          PetOwnerModel(id: 'owner1', name: 'Alice Smith', address: '123 Pine St', mobile: '9988776655', email: 'alice@gmail.com'),
          PetOwnerModel(id: 'owner2', name: 'Bob Johnson', address: '456 Elm St', mobile: '9988776656', email: 'bob@gmail.com'),
        ];
        for (var owner in owners) {
          await PetOwnerPluginState.repo.create(owner);
        }

        // Seed pets
        final pets = [
          PetModel(id: 'pet1', ownerId: 'owner1', name: 'Max', species: 'Dog', breed: 'Golden Retriever', age: 3),
          PetModel(id: 'pet2', ownerId: 'owner1', name: 'Luna', species: 'Cat', breed: 'Siamese', age: 2),
          PetModel(id: 'pet3', ownerId: 'owner2', name: 'Rocky', species: 'Dog', breed: 'German Shepherd', age: 5),
        ];
        for (var pet in pets) {
          await PetPluginState.repo.create(pet);
        }
      }

      // 3. Seed bookings if empty
      if (BookingPluginState.repo.items.isEmpty) {
        final bookings = [
          BookingModel(id: 'book1', petOwnerId: 'owner1', petOwnerName: 'Alice Smith', doctorId: 'doc1', doctorName: 'Dr. Helen Carter', date: '2026-06-02', time: '10:00 AM', status: 'scheduled'),
          BookingModel(id: 'book2', petOwnerId: 'owner2', petOwnerName: 'Bob Johnson', doctorId: 'doc2', doctorName: 'Dr. Alex Mercer', date: '2026-06-02', time: '11:30 AM', status: 'inProgress'),
          BookingModel(id: 'book3', petOwnerId: 'owner1', petOwnerName: 'Alice Smith', doctorId: 'doc2', doctorName: 'Dr. Alex Mercer', date: '2026-06-01', time: '03:00 PM', status: 'completed'),
        ];
        for (var booking in bookings) {
          await BookingPluginState.repo.create(booking);
        }
      }

      CustomSnackBar.show(context, 'Mock clinical data seeded successfully!', category: SnackBarCategory.success);
    } catch (e) {
      CustomSnackBar.show(context, 'Failed to seed mock data: $e', category: SnackBarCategory.error);
    } finally {
      await _initDataAndStreams();
    }
  }

  void _showQuickBookDialog() {
    final doctors = DoctorsPluginState.repo.items;
    final clients = PetOwnerPluginState.repo.items;

    if (doctors.isEmpty || clients.isEmpty) {
      CustomSnackBar.show(
        context,
        'Cannot book appointment. Please add at least 1 Doctor and 1 Client/Pet Owner first.',
        category: SnackBarCategory.warning,
      );
      return;
    }

    String? selectedDoctorId = doctors.first.id;
    String? selectedClientId = clients.first.id;
    final dateController = TextEditingController(text: DateTime.now().toString().split(' ').first);
    final timeController = TextEditingController(text: '10:00 AM');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(FontAwesomeIcons.calendarPlus, color: Theme.of(context).colorScheme.primary, size: 22),
                  const SizedBox(width: 12),
                  Text('Quick Appointment Booking', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Doctor', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedDoctorId,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    items: doctors.map((doc) {
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(doc.name ?? 'Unknown Doctor'),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedDoctorId = val),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(FontAwesomeIcons.userDoctor, size: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Client', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedClientId,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    items: clients.map((client) {
                      return DropdownMenuItem<String>(
                        value: client.id,
                        child: Text(client.name ?? 'Unknown Client'),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedClientId = val),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(FontAwesomeIcons.solidUser, size: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Date', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: dateController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.calendar_today, size: 16),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Time', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: timeController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.access_time, size: 16),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final selectedDoctor = doctors.firstWhere((d) => d.id == selectedDoctorId);
                    final selectedClient = clients.firstWhere((c) => c.id == selectedClientId);

                    final newBooking = BookingModel(
                      id: 'book_${DateTime.now().millisecondsSinceEpoch}',
                      doctorId: selectedDoctorId,
                      doctorName: selectedDoctor.name,
                      petOwnerId: selectedClientId,
                      petOwnerName: selectedClient.name,
                      date: dateController.text,
                      time: timeController.text,
                      status: 'scheduled',
                    );

                    await BookingPluginState.repo.create(newBooking);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      CustomSnackBar.show(context, 'Appointment booked successfully!', category: SnackBarCategory.success);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Book Now', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Extracted live stats for real-time reactivity
    final activeDoctors = DoctorsPluginState.repo.items.where((doc) => doc.active == 'true').toList();
    final registeredClients = PetOwnerPluginState.repo.items;
    final pendingBookings = BookingPluginState.repo.items.where((b) => b.status == 'scheduled' || b.status == 'inProgress').toList();
    final totalPets = PetPluginState.repo.items;

    // Specialty or Species calculations
    final Map<String, int> petSpeciesCounts = {};
    for (var pet in totalPets) {
      final species = pet.species ?? 'Other';
      petSpeciesCounts[species] = (petSpeciesCounts[species] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF9FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinical Analytics Dashboard',
                      style: GoogleFonts.outfit(
                        textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Real-time aggregation across medical modules and appointment schedules.',
                      style: GoogleFonts.outfit(
                        textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (DoctorsPluginState.repo.items.isEmpty && registeredClients.isEmpty)
                      ElevatedButton.icon(
                        onPressed: _seedMockData,
                        icon: const Icon(FontAwesomeIcons.database, size: 14, color: Colors.white),
                        label: const Text('Seed Database', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _showQuickBookDialog,
                      icon: const Icon(FontAwesomeIcons.calendarPlus, size: 14, color: Colors.white),
                      label: const Text('Quick Book', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // KPI Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final bool useGrid = constraints.maxWidth > 900;
                
                if (useGrid) {
                  return Row(
                    children: [
                      Expanded(
                        child: KpiCardWidget(
                          title: 'Active Doctors',
                          value: '${activeDoctors.length} / ${DoctorsPluginState.repo.items.length}',
                          icon: FontAwesomeIcons.userDoctor,
                          color: Colors.green,
                          trendPercent: activeDoctors.isEmpty ? 0 : (activeDoctors.length / DoctorsPluginState.repo.items.length) * 100,
                          trendSuffix: 'online',
                          sparklineData: const [4.0, 5.0, 5.0, 6.0, 6.0, 7.0, 8.0],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: KpiCardWidget(
                          title: 'Registered Clients',
                          value: '${registeredClients.length}',
                          icon: FontAwesomeIcons.solidUser,
                          color: Colors.blue,
                          trendPercent: 12.5,
                          trendSuffix: 'growth',
                          sparklineData: const [10.0, 12.0, 15.0, 18.0, 24.0, 32.0, 40.0],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: KpiCardWidget(
                          title: 'Pending Bookings',
                          value: '${pendingBookings.length}',
                          icon: FontAwesomeIcons.clock,
                          color: Colors.amber,
                          trendPercent: pendingBookings.isEmpty ? 0 : -3.5,
                          trendSuffix: 'today',
                          sparklineData: const [14.0, 12.0, 10.0, 8.0, 9.0, 11.0, 9.0],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: KpiCardWidget(
                          title: 'Total Pets Managed',
                          value: '${totalPets.length}',
                          icon: FontAwesomeIcons.paw,
                          color: Colors.pink,
                          trendPercent: 24.1,
                          trendSuffix: 'growth',
                          sparklineData: const [8.0, 11.0, 14.0, 19.0, 22.0, 25.0, 30.0],
                        ),
                      ),
                    ],
                  );
                } else {
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: constraints.maxWidth > 550 ? 2 : 1,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 1.6,
                    children: [
                      KpiCardWidget(
                        title: 'Active Doctors',
                        value: '${activeDoctors.length} / ${DoctorsPluginState.repo.items.length}',
                        icon: FontAwesomeIcons.userDoctor,
                        color: Colors.green,
                        trendPercent: activeDoctors.isEmpty ? 0 : (activeDoctors.length / DoctorsPluginState.repo.items.length) * 100,
                        trendSuffix: 'online',
                        sparklineData: const [4.0, 5.0, 5.0, 6.0, 6.0, 7.0, 8.0],
                      ),
                      KpiCardWidget(
                        title: 'Registered Clients',
                        value: '${registeredClients.length}',
                        icon: FontAwesomeIcons.solidUser,
                        color: Colors.blue,
                        trendPercent: 12.5,
                        trendSuffix: 'growth',
                        sparklineData: const [10.0, 12.0, 15.0, 18.0, 24.0, 32.0, 40.0],
                      ),
                      KpiCardWidget(
                        title: 'Pending Bookings',
                        value: '${pendingBookings.length}',
                        icon: FontAwesomeIcons.clock,
                        color: Colors.amber,
                        trendPercent: pendingBookings.isEmpty ? 0 : -3.5,
                        trendSuffix: 'today',
                        sparklineData: const [14.0, 12.0, 10.0, 8.0, 9.0, 11.0, 9.0],
                      ),
                      KpiCardWidget(
                        title: 'Total Pets Managed',
                        value: '${totalPets.length}',
                        icon: FontAwesomeIcons.paw,
                        color: Colors.pink,
                        trendPercent: 24.1,
                        trendSuffix: 'growth',
                        sparklineData: const [8.0, 11.0, 14.0, 19.0, 22.0, 25.0, 30.0],
                      ),
                    ],
                  );
                }
              },
            ),
            
            const SizedBox(height: 32),
            
            // Second Row: Recent Appointments list and Species distribution
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 950;
                
                final recentAppointmentsWidget = Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF16161D) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[900]! : Colors.grey[200]!,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Clinical Schedules',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Realtime',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (BookingPluginState.repo.items.isEmpty)
                        SizedBox(
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(FontAwesomeIcons.calendar, size: 36, color: Colors.grey[500]),
                                const SizedBox(height: 12),
                                Text(
                                  'No schedules found.',
                                  style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: BookingPluginState.repo.items.length.clamp(0, 5),
                          separatorBuilder: (_, __) => Divider(color: isDark ? Colors.grey[850] : Colors.grey[100]),
                          itemBuilder: (context, index) {
                            // Reverse order for recency
                            final list = BookingPluginState.repo.items.reversed.toList();
                            final booking = list[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                child: Icon(FontAwesomeIcons.calendarDay, size: 16, color: Theme.of(context).colorScheme.primary),
                              ),
                              title: Text(
                                booking.petOwnerName ?? 'Unknown Client',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Slot: ${booking.date} at ${booking.time} | Doctor: ${booking.doctorName}',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              ),
                              trailing: _buildStatusPill(booking.status ?? 'scheduled'),
                            );
                          },
                        ),
                    ],
                  ),
                );

                final sidebarWidget = Column(
                  children: [
                    // Species Distribution
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF16161D) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.grey[900]! : Colors.grey[200]!,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient Species Distribution',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (petSpeciesCounts.isEmpty)
                            const SizedBox(
                              height: 100,
                              child: Center(
                                child: Text('No patient data to analyze.', style: TextStyle(color: Colors.grey)),
                              ),
                            )
                          else
                            Column(
                              children: petSpeciesCounts.entries.map((entry) {
                                final percent = (entry.value / totalPets.length) * 100;
                                Color barColor = Colors.blue;
                                if (entry.key.toLowerCase() == 'cat') barColor = Colors.orange;
                                if (entry.key.toLowerCase() == 'bird') barColor = Colors.teal;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            entry.key,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                          Text(
                                            '${entry.value} (${percent.toStringAsFixed(1)}%)',
                                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: LinearProgressIndicator(
                                          value: entry.value / totalPets.length,
                                          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                                          color: barColor,
                                          minHeight: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Action Cards
                    Container(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark 
                              ? [Colors.deepPurple[900]!, Colors.purple[800]!] 
                              : [Colors.purple[500]!, Colors.deepPurple[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(FontAwesomeIcons.rocket, color: Colors.white, size: 24),
                          const SizedBox(height: 16),
                          Text(
                            'Expand Your Clinic!',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Instantly configure new views, tables, and roles in seconds.',
                            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => context.go('/doctors'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: Text(
                              'Go to Doctor Module',
                              style: TextStyle(
                                color: Colors.deepPurple[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: recentAppointmentsWidget),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: sidebarWidget),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      recentAppointmentsWidget,
                      const SizedBox(height: 24),
                      sidebarWidget,
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case 'inprogress':
        bg = Colors.orange.withOpacity(0.12);
        text = Colors.orange[800]!;
        label = 'In Progress';
        break;
      case 'completed':
        bg = Colors.green.withOpacity(0.12);
        text = Colors.green[800]!;
        label = 'Completed';
        break;
      case 'cancelled':
        bg = Colors.red.withOpacity(0.12);
        text = Colors.red[800]!;
        label = 'Cancelled';
        break;
      case 'scheduled':
      default:
        bg = Colors.blue.withOpacity(0.12);
        text = Colors.blue[800]!;
        label = 'Scheduled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: text.withOpacity(0.25), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}
