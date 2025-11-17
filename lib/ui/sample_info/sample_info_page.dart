import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/reference_id.dart';
import '../../core/routing.dart';
import '../../data/models.dart';
import '../widgets/app_scaffold.dart';

class SampleInfoPage extends StatefulWidget {
  const SampleInfoPage({super.key});

  @override
  State<SampleInfoPage> createState() => _SampleInfoPageState();
}

class _SampleInfoPageState extends State<SampleInfoPage> {
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSample();
  }

  void _loadCurrentSample() {}

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: AppPageTitles.sampleInfo,
      actions: const [],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<AppState>(
          builder: (context, appState, _) {
            final orders = appState.orders;
            if (orders.isEmpty) {
              return const Center(child: Text('No registrations yet'));
            }
            return ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final o = orders[i];
                return Card(
                  child: ListTile(
                    leading: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      tooltip: 'Delete Registration',
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Registration'),
                            content: const Text(
                              'Delete this registration and all its samples?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await Provider.of<AppState>(
                            context,
                            listen: false,
                          ).deleteOrder(o.id!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Registration deleted'),
                            ),
                          );
                        }
                      },
                    ),
                    title: Text(
                      '${o.clientName} (${o.numberOfSamples} samples)',
                    ),
                    subtitle: null,
                    trailing: Text(o.specimenType),
                    onTap: () {
                      _showOrderDetails(context, o, edit: true);
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _showOrderDetails(
    BuildContext context,
    OrderInfo order, {
    bool edit = false,
  }) async {
    final appState = Provider.of<AppState>(context, listen: false);
    // Editable controllers
    final cName = TextEditingController(text: order.clientName);
    final cAddr = TextEditingController(text: order.clientAddress ?? '');

    final method = TextEditingController(text: order.methodAnalysis ?? '');
    final reportNo = TextEditingController(text: order.reportNo ?? '');
    final gear = TextEditingController(text: order.gearUsed ?? '');
    final area = TextEditingController(text: order.areaOfGrab ?? '');
    final sieve = TextEditingController(text: order.sieveSize ?? '');
    final netDia = TextEditingController(text: order.netDiameter ?? '');
    final netMesh = TextEditingController(text: order.netMesh ?? '');
    final towType = TextEditingController(text: order.towType ?? '');
    final filtVol = TextEditingController(text: order.filteredVolume ?? '');
    final comments = TextEditingController(text: order.comments ?? '');

    _editMode = edit;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          Widget field(String label, TextEditingController c) {
            return _editMode
                ? TextField(
                    controller: c,
                    decoration: InputDecoration(
                      labelText: label,
                      border: const OutlineInputBorder(),
                    ),
                  )
                : InputDecorator(
                    decoration: InputDecoration(
                      labelText: label,
                      border: const OutlineInputBorder(),
                    ),
                    child: Text(c.text),
                  );
          }

          return AlertDialog(
            title: Text('${order.specimenType} Registration'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  field('Client', cName),
                  const SizedBox(height: 8),
                  field('Client Address', cAddr),
                  const SizedBox(height: 8),

                  const SizedBox.shrink(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Number of samples',
                            border: OutlineInputBorder(),
                          ),
                          child: InkWell(
                            onTap: () async {
                              final updated = await _manageSamples(
                                context,
                                order,
                                cName.text.trim(),
                              );
                              if (updated != null) {
                                setState(() {
                                  order = OrderInfo(
                                    id: order.id,
                                    clientName: order.clientName,
                                    clientAddress: order.clientAddress,
                                    specimenType: order.specimenType,
                                    numberOfSamples: updated,
                                    numberOfReplicates:
                                        order.numberOfReplicates,
                                    dateReceived: order.dateReceived,
                                    dateAnalysis: order.dateAnalysis,
                                    gearUsed: order.gearUsed,
                                    areaOfGrab: order.areaOfGrab,
                                    sieveSize: order.sieveSize,
                                    netDiameter: order.netDiameter,
                                    netMesh: order.netMesh,
                                    towType: order.towType,
                                    filteredVolume: order.filteredVolume,
                                    methodAnalysis: order.methodAnalysis,
                                    reportNo: order.reportNo,
                                    referenceId: order.referenceId,
                                    comments: order.comments,
                                  );
                                });
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(order.numberOfSamples.toString()),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  field('Gear used', gear),
                  if (order.specimenType == 'Macrobenthos') ...[
                    const SizedBox(height: 8),
                    field('Area of Grab', area),
                    const SizedBox(height: 8),
                    field('Sieve size', sieve),
                  ],
                  if (order.specimenType != 'Macrobenthos') ...[
                    const SizedBox(height: 8),
                    field('Net diameter', netDia),
                    const SizedBox(height: 8),
                    field('Net mesh', netMesh),
                    const SizedBox(height: 8),
                    field('Tow type', towType),
                    const SizedBox(height: 8),
                    field('Filtered volume', filtVol),
                  ],
                  const SizedBox(height: 8),
                  field('Method of Analysis', method),
                  const SizedBox(height: 8),
                  field('Report No.', reportNo),
                  const SizedBox(height: 8),
                  field('Comments', comments),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              if (_editMode)
                FilledButton(
                  onPressed: () async {
                    final updated = OrderInfo(
                      id: order.id,
                      clientName: cName.text.trim(),
                      clientAddress: cAddr.text.trim().isEmpty
                          ? null
                          : cAddr.text.trim(),
                      specimenType: order.specimenType,
                      numberOfSamples: order.numberOfSamples,
                      numberOfReplicates: order.numberOfReplicates,
                      dateReceived: order.dateReceived,
                      dateAnalysis: order.dateAnalysis,
                      gearUsed: gear.text.trim().isEmpty
                          ? null
                          : gear.text.trim(),
                      areaOfGrab: area.text.trim().isEmpty
                          ? null
                          : area.text.trim(),
                      sieveSize: sieve.text.trim().isEmpty
                          ? null
                          : sieve.text.trim(),
                      netDiameter: netDia.text.trim().isEmpty
                          ? null
                          : netDia.text.trim(),
                      netMesh: netMesh.text.trim().isEmpty
                          ? null
                          : netMesh.text.trim(),
                      towType: towType.text.trim().isEmpty
                          ? null
                          : towType.text.trim(),
                      filteredVolume: filtVol.text.trim().isEmpty
                          ? null
                          : filtVol.text.trim(),
                      methodAnalysis: method.text.trim().isEmpty
                          ? null
                          : method.text.trim(),
                      reportNo: reportNo.text.trim().isEmpty
                          ? null
                          : reportNo.text.trim(),

                      comments: comments.text.trim().isEmpty
                          ? null
                          : comments.text.trim(),
                    );
                    await appState.saveOrder(updated);
                    await appState.updateClientForOrder(
                      order.id!,
                      cName.text.trim(),
                    );
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<int?> _manageSamples(
    BuildContext context,
    OrderInfo order,
    String clientName,
  ) async {
    final appState = Provider.of<AppState>(context, listen: false);
    var samples = await appState.getSamplesByOrder(order.id!);
    final addController = TextEditingController();
    final recvController = TextEditingController();
    final prefix = ReferenceId.prefixFor(order.specimenType);
    recvController.text = prefix;
    DateTime date = DateTime.now();
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Manage Samples'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: addController,
                          decoration: const InputDecoration(
                            labelText: 'New Sample Marking',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          final m = addController.text.trim();
                          if (m.isEmpty) return;
                          await appState.addSampleMarking(
                            orderId: order.id!,
                            specimenType: order.specimenType,
                            clientName: clientName,
                            sampleMarking: m,
                            receiveId: recvController.text.trim().isEmpty
                                ? null
                                : recvController.text.trim(),
                            dateAnalysis: date,
                          );
                          samples = await appState.getSamplesByOrder(order.id!);
                          setState(() {});
                          addController.clear();
                          recvController.text = prefix;
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: recvController,
                    inputFormatters: [
                      ReferenceId.formatterForType(order.specimenType),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Reference ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date Received',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(_formatDate(date)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => date = picked);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: samples.length,
                      itemBuilder: (context, i) {
                        final s = samples[i];
                        return ListTile(
                          title: Text(s.sampleMarking ?? s.stationId),
                          subtitle: Text(
                            'Reference ID: ${s.receiveId ?? ''} • Date Received: ${_formatDate(s.date)}${s.analyzedDate != null ? ' • Analyzed: ${_formatDate(s.analyzedDate!)}' : ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Edit Sample',
                                onPressed: () async {
                                  final recv = TextEditingController(
                                    text: s.receiveId ?? '',
                                  );
                                  DateTime date = s.date;
                                  final formatter =
                                      ReferenceId.formatterForType(
                                        order.specimenType,
                                      );
                                  if ((recv.text).isEmpty)
                                    recv.text = ReferenceId.prefixFor(
                                      order.specimenType,
                                    );
                                  await showDialog(
                                    context: context,
                                    builder: (context) => StatefulBuilder(
                                      builder: (context, setState2) => AlertDialog(
                                        title: const Text('Edit Sample'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(
                                              controller: recv,
                                              inputFormatters: [formatter],
                                              decoration: const InputDecoration(
                                                labelText: 'Reference ID',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: InputDecorator(
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText:
                                                              'Date Received',
                                                          border:
                                                              OutlineInputBorder(),
                                                        ),
                                                    child: Text(
                                                      _formatDate(date),
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.calendar_today,
                                                  ),
                                                  onPressed: () async {
                                                    final picked =
                                                        await showDatePicker(
                                                          context: context,
                                                          initialDate: date,
                                                          firstDate: DateTime(
                                                            2000,
                                                          ),
                                                          lastDate: DateTime(
                                                            2100,
                                                          ),
                                                        );
                                                    if (picked != null)
                                                      setState2(
                                                        () => date = picked,
                                                      );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () async {
                                              final updated = Sample(
                                                id: s.id,
                                                orderId: s.orderId,
                                                stationId: s.stationId,
                                                date: date,
                                                lat: s.lat,
                                                lon: s.lon,
                                                habitat: s.habitat,
                                                client: s.client,
                                                biologistId: s.biologistId,
                                                remarks: s.remarks,
                                                completed: s.completed,
                                                sampleType: s.sampleType,
                                                sampleMarking: s.sampleMarking,
                                                receiveId:
                                                    recv.text.trim().isEmpty
                                                    ? null
                                                    : recv.text.trim(),
                                              );
                                              await Provider.of<AppState>(
                                                context,
                                                listen: false,
                                              ).updateSample(updated);
                                              samples = await appState
                                                  .getSamplesByOrder(order.id!);
                                              // ignore: use_build_context_synchronously
                                              Navigator.pop(context);
                                              setState(() {});
                                            },
                                            child: const Text('Save'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () async {
                                  if (s.id != null) {
                                    await Provider.of<AppState>(
                                      context,
                                      listen: false,
                                    ).deleteSample(s.id!);
                                    samples = await appState.getSamplesByOrder(
                                      order.id!,
                                    );
                                    setState(() {});
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final updatedCount = samples.length;
                  final updated = OrderInfo(
                    id: order.id,
                    clientName: order.clientName,
                    clientAddress: order.clientAddress,
                    specimenType: order.specimenType,
                    numberOfSamples: updatedCount,
                    numberOfReplicates: order.numberOfReplicates,
                    dateReceived: order.dateReceived,
                    dateAnalysis: order.dateAnalysis,
                    gearUsed: order.gearUsed,
                    areaOfGrab: order.areaOfGrab,
                    sieveSize: order.sieveSize,
                    netDiameter: order.netDiameter,
                    netMesh: order.netMesh,
                    towType: order.towType,
                    filteredVolume: order.filteredVolume,
                    methodAnalysis: order.methodAnalysis,
                    reportNo: order.reportNo,
                    referenceId: order.referenceId,
                    comments: order.comments,
                  );
                  await Provider.of<AppState>(
                    context,
                    listen: false,
                  ).saveOrder(updated);
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
    return samples.length;
  }

  Widget _editableDate(
    String label,
    DateTime? current,
    void Function(DateTime) onPick,
  ) {
    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
            child: Text(current == null ? '' : _formatDate(current)),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: current ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) onPick(picked);
          },
        ),
      ],
    );
  }

  void _getCurrentLocation() {}

  void _saveSample() {}

  void _setAsActive() {}

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _saveOrder(OrderInfo order) async {
    await Provider.of<AppState>(context, listen: false).saveOrder(order);
  }
}
