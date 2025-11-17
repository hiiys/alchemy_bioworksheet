import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../core/reference_id.dart';
import '../../core/routing.dart';
import '../../core/app_state.dart';
import '../../data/models.dart';

class OrderRegistrationPage extends StatefulWidget {
  final String specimenType;
  const OrderRegistrationPage({super.key, required this.specimenType});

  @override
  State<OrderRegistrationPage> createState() => _OrderRegistrationPageState();
}

class _OrderRegistrationPageState extends State<OrderRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _clientAddressController = TextEditingController();
  final _gearUsedController = TextEditingController();
  final _methodController = TextEditingController();
  final _reportNoController = TextEditingController();
  final _commentsController = TextEditingController();
  final _numSamplesController = TextEditingController(text: '1');
  final _numReplicatesController = TextEditingController(text: '1');

  // Type-specific
  final _areaOfGrabController = TextEditingController();
  final _sieveSizeController = TextEditingController();
  final _netDiameterController = TextEditingController();
  final _netMeshController = TextEditingController();
  final _towTypeController = TextEditingController();
  final _filteredVolumeController = TextEditingController();

  int _numberOfSamples = 1;
  int _numberOfReplicates = 1;

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientAddressController.dispose();
    _gearUsedController.dispose();
    _methodController.dispose();
    _reportNoController.dispose();
    _commentsController.dispose();
    _areaOfGrabController.dispose();
    _sieveSizeController.dispose();
    _netDiameterController.dispose();
    _netMeshController.dispose();
    _towTypeController.dispose();
    _filteredVolumeController.dispose();
    _numSamplesController.dispose();
    _numReplicatesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBenthos = widget.specimenType == 'Macrobenthos';
    final isZooOrPhyto =
        widget.specimenType == 'Zooplankton' ||
        widget.specimenType == 'Phytoplankton';
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Registration - ${widget.specimenType}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _textField(
                _clientNameController,
                'Client Name *',
                required: true,
              ),
              const SizedBox(height: 12),
              _textField(_clientAddressController, 'Client Address'),
              const SizedBox(height: 12),
              _readOnly('Type of Sample', widget.specimenType),
              const SizedBox(height: 12),
              // Removed Sample Marking Base per new requirements
              _numberFieldCtrl(
                _numSamplesController,
                'Number of samples *',
                (v) => setState(() => _numberOfSamples = v),
              ),
              if (isBenthos)
                Column(
                  children: [
                    const SizedBox(height: 12),
                    _numberFieldCtrl(
                      _numReplicatesController,
                      'Number of replicates',
                      (v) => setState(() => _numberOfReplicates = v),
                    ),
                  ],
                ),
              const SizedBox(height: 12),

              const SizedBox(height: 12),
              _textField(_gearUsedController, 'Gear used'),
              if (isBenthos) ...[
                const SizedBox(height: 12),
                _textField(_areaOfGrabController, 'Area of Grab'),
                const SizedBox(height: 12),
                _textField(_sieveSizeController, 'Sieve size'),
              ],
              if (isZooOrPhyto) ...[
                const SizedBox(height: 12),
                _textField(_netDiameterController, 'Net diameter'),
                const SizedBox(height: 12),
                _textField(_netMeshController, 'Net mesh'),
                const SizedBox(height: 12),
                _textField(_towTypeController, 'Tow type'),
                const SizedBox(height: 12),
                _textField(_filteredVolumeController, 'Filtered volume'),
              ],
              const SizedBox(height: 12),
              _textField(_methodController, 'Method of Analysis'),
              const SizedBox(height: 12),
              _textField(_reportNoController, 'Report No.'),
              const SizedBox(height: 12),
              _textField(_commentsController, 'Comments', maxLines: 3),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saveOrder,
                icon: const Icon(Icons.save),
                label: const Text('Save Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController c,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (v) => (v == null || v.isEmpty) ? 'Required' : null
          : null,
      maxLines: maxLines,
    );
  }

  Widget _readOnly(String label, String value) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Text(value),
    );
  }

  Widget _numberField(
    String label,
    void Function(int) onChanged, {
    int initial = 1,
  }) {
    final controller = TextEditingController(text: initial.toString());
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      onChanged: (v) {
        final n = int.tryParse(v) ?? initial;
        onChanged(n);
      },
    );
  }

  Widget _numberFieldCtrl(
    TextEditingController controller,
    String label,
    void Function(int) onSubmitted,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onFieldSubmitted: (v) {
        final n = int.tryParse(v.trim());
        if (n != null) {
          onSubmitted(n);
        }
      },
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    final appState = Provider.of<AppState>(context, listen: false);
    final order = OrderInfo(
      clientName: _clientNameController.text.trim(),
      clientAddress: _clientAddressController.text.trim().isEmpty
          ? null
          : _clientAddressController.text.trim(),
      specimenType: widget.specimenType,
      numberOfSamples: _numberOfSamples,
      numberOfReplicates: _numberOfReplicates,
      dateReceived: null,
      dateAnalysis: null,
      gearUsed: _gearUsedController.text.trim().isEmpty
          ? null
          : _gearUsedController.text.trim(),
      areaOfGrab: _areaOfGrabController.text.trim().isEmpty
          ? null
          : _areaOfGrabController.text.trim(),
      sieveSize: _sieveSizeController.text.trim().isEmpty
          ? null
          : _sieveSizeController.text.trim(),
      netDiameter: _netDiameterController.text.trim().isEmpty
          ? null
          : _netDiameterController.text.trim(),
      netMesh: _netMeshController.text.trim().isEmpty
          ? null
          : _netMeshController.text.trim(),
      towType: _towTypeController.text.trim().isEmpty
          ? null
          : _towTypeController.text.trim(),
      filteredVolume: _filteredVolumeController.text.trim().isEmpty
          ? null
          : _filteredVolumeController.text.trim(),
      methodAnalysis: _methodController.text.trim().isEmpty
          ? null
          : _methodController.text.trim(),
      reportNo: _reportNoController.text.trim().isEmpty
          ? null
          : _reportNoController.text.trim(),
      referenceId: null,
      comments: _commentsController.text.trim().isEmpty
          ? null
          : _commentsController.text.trim(),
    );
    final orderId = await appState.createOrderAndGenerateSamples(
      order: order,
      markingBase: '',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Order #$orderId created')));
    final orderWithId = OrderInfo(
      id: orderId,
      clientName: order.clientName,
      clientAddress: order.clientAddress,
      specimenType: order.specimenType,
      numberOfSamples: order.numberOfSamples,
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
    await _showAddMarkingsDialog(context, orderId, orderWithId);
  }

  Future<void> _showAddMarkingsDialog(
    BuildContext context,
    int orderId,
    OrderInfo order,
  ) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final markingController = TextEditingController();
    final receiveController = TextEditingController();
    final prefix = ReferenceId.prefixFor(order.specimenType);
    receiveController.text = prefix;
    DateTime? dateReceived = order.dateReceived;
    int added = 0;
    final expected = order.numberOfSamples * (order.numberOfReplicates ?? 1);
    final used = <String>{};
    var samples = await appState.getSamplesByOrder(orderId);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final inset = MediaQuery.of(context).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: inset),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.list_alt),
                          const SizedBox(width: 8),
                          Text('Added: ${samples.length} / $expected'),
                          const SizedBox(width: 16),
                          const Icon(Icons.timelapse),
                          const SizedBox(width: 8),
                          Text('Remaining: ${expected - samples.length}'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: markingController,
                        decoration: const InputDecoration(
                          labelText: 'Sample Marking *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: receiveController,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^[A-Z0-9]+$'),
                          ),
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
                              child: Text(
                                dateReceived == null ? '' : _fmt(dateReceived!),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: dateReceived ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null)
                                setState(() => dateReceived = picked);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 240,
                        child: ListView.builder(
                          itemCount: samples.length,
                          itemBuilder: (context, i) {
                            final s = samples[i];
                            return ListTile(
                              dense: true,
                              title: Text(s.sampleMarking ?? s.stationId),
                              subtitle: Text(
                                'Ref: ${s.receiveId ?? ''} • ${_fmt(s.date)}',
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                final updated = OrderInfo(
                                  id: order.id,
                                  clientName: order.clientName,
                                  clientAddress: order.clientAddress,
                                  specimenType: order.specimenType,
                                  numberOfSamples: samples.length,
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
                                await appState.saveOrder(updated);
                                Navigator.pop(context);
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.sampleInfo,
                                );
                              },
                              child: const Text('Done'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () async {
                          final marking = markingController.text.trim();
                          if (marking.isEmpty) return;
                          if (used.contains(marking)) return;
                          await appState.addSampleMarking(
                            orderId: orderId,
                            specimenType: order.specimenType,
                            clientName: order.clientName,
                            sampleMarking: marking,
                            receiveId: receiveController.text.trim().isEmpty
                                ? null
                                : receiveController.text.trim(),
                            dateAnalysis: dateReceived,
                          );
                          samples = await appState.getSamplesByOrder(orderId);
                          setState(() {
                            added = samples.length;
                            used.add(marking);
                            markingController.clear();
                            receiveController.text = prefix;
                          });
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
