import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../core/app_state.dart';
import '../../core/routing.dart';
import '../../data/models.dart';
import '../widgets/app_scaffold.dart';

class SampleInfoPage extends StatefulWidget {
  const SampleInfoPage({super.key});

  @override
  State<SampleInfoPage> createState() => _SampleInfoPageState();
}

class _SampleInfoPageState extends State<SampleInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _stationIdController = TextEditingController();
  final _habitatController = TextEditingController();
  final _clientController = TextEditingController();
  final _remarksController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  double? _latitude;
  double? _longitude;
  String _sampleType = 'Macrobenthos';

  @override
  void initState() {
    super.initState();
    _loadCurrentSample();
  }

  void _loadCurrentSample() {
    final appState = Provider.of<AppState>(context, listen: false);
    final sample = appState.activeSample;
    
    if (sample != null) {
      _stationIdController.text = sample.stationId;
      _selectedDate = sample.date;
      _latitude = sample.lat;
      _longitude = sample.lon;
      _habitatController.text = sample.habitat ?? '';
      _clientController.text = sample.client ?? '';
      _remarksController.text = sample.remarks ?? '';
      _sampleType = sample.sampleType;
    }
  }

  @override
  void dispose() {
    _stationIdController.dispose();
    _habitatController.dispose();
    _clientController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: AppPageTitles.sampleInfo,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Client ID at top
              TextFormField(
                controller: _clientController,
                decoration: const InputDecoration(
                  labelText: 'Client ID *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a client ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Station ID
              TextFormField(
                controller: _stationIdController,
                decoration: const InputDecoration(
                  labelText: 'Station ID *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a station ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sample Type
              DropdownButtonFormField<String>(
                value: _sampleType,
                items: const [
                  DropdownMenuItem(value: 'Phytoplankton', child: Text('Phytoplankton')),
                  DropdownMenuItem(value: 'Zooplankton', child: Text('Zooplankton')),
                  DropdownMenuItem(value: 'Macrobenthos', child: Text('Macrobenthos')),
                ],
                onChanged: (v) => setState(() => _sampleType = v ?? 'Macrobenthos'),
                decoration: const InputDecoration(
                  labelText: 'Sample Type *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please select a sample type';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date picker
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date *',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_formatDate(_selectedDate)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _selectDate,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // GPS coordinates
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_latitude?.toStringAsFixed(6) ?? 'Not set'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_longitude?.toStringAsFixed(6) ?? 'Not set'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.location_on),
                    onPressed: _getCurrentLocation,
                    tooltip: 'Get current location',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _habitatController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Remarks
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saveSample,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Sample'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _setAsActive,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Set as Active'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _configurePin() async {
    final prefs = await SharedPreferences.getInstance();
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set/Change Access PIN'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New PIN'),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final pin = controller.text;
              if (pin.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN cannot be empty')),
                );
                return;
              }
              final hash = sha256.convert(utf8.encode(pin)).toString();
              prefs.setString('pin_hash', hash);
              prefs.setBool('pin_unlocked', false);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN set. Required to access Sample Registration.')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    // TODO: Implement geolocator integration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location capture not implemented yet')),
    );
  }

  void _saveSample() async {
    print('Save button tapped');
    print('Client ID: "${_clientController.text}"');
    print('Station ID: "${_stationIdController.text}"');
    
    if (_formKey.currentState!.validate()) {
      print('Form validation passed');
      final appState = Provider.of<AppState>(context, listen: false);
      final sample = Sample(
        stationId: _stationIdController.text,
        date: _selectedDate,
        lat: _latitude,
        lon: _longitude,
        habitat: _habitatController.text.isEmpty ? null : _habitatController.text,
        client: _clientController.text.isEmpty ? null : _clientController.text,
        remarks: _remarksController.text.isEmpty ? null : _remarksController.text,
        sampleType: _sampleType,
      );
      
      try {
        print('Save button pressed - creating sample...');
        final isDuplicate = appState.samples.any((s) =>
            (s.client ?? '').trim().toLowerCase() == (_clientController.text).trim().toLowerCase() &&
            s.stationId.trim().toLowerCase() == _stationIdController.text.trim().toLowerCase() &&
            s.sampleType == _sampleType &&
            _sameDay(s.date, _selectedDate));
        if (isDuplicate) {
          await showDialog(
            context: context,
            builder: (context) => const AlertDialog(
              title: Text('Duplicate Sample'),
              content: Text('A sample with the same Client ID, Sample ID, Sample Type and Date already exists.'),
            ),
          );
          return;
        }
        // Save sample but stay on this page and keep field values
        await appState.createSampleWithoutActivate(sample);
        print('Sample saved successfully');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sample saved successfully')),
          );
        }
      } catch (e) {
        print('Error saving sample: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving sample: $e')),
          );
        }
      }
    } else {
      print('Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields: Client ID and Station ID')),
      );
    }
  }

  void _setAsActive() async {
    print('Activate button tapped');
    print('Client ID: "${_clientController.text}"');
    print('Station ID: "${_stationIdController.text}"');
    
    if (_formKey.currentState!.validate()) {
      print('Form validation passed for activate');
      final appState = Provider.of<AppState>(context, listen: false);
      final sample = Sample(
        stationId: _stationIdController.text,
        date: _selectedDate,
        lat: _latitude,
        lon: _longitude,
        habitat: _habitatController.text.isEmpty ? null : _habitatController.text,
        client: _clientController.text.isEmpty ? null : _clientController.text,
        remarks: _remarksController.text.isEmpty ? null : _remarksController.text,
        sampleType: _sampleType,
      );

      try {
        print('Activate button pressed - creating and activating sample...');
        final isDuplicate = appState.samples.any((s) =>
            (s.client ?? '').trim().toLowerCase() == (_clientController.text).trim().toLowerCase() &&
            s.stationId.trim().toLowerCase() == _stationIdController.text.trim().toLowerCase() &&
            s.sampleType == _sampleType &&
            _sameDay(s.date, _selectedDate));
        if (isDuplicate) {
          await showDialog(
            context: context,
            builder: (context) => const AlertDialog(
              title: Text('Duplicate Sample'),
              content: Text('A sample with the same Client ID, Sample ID, Sample Type and Date already exists.'),
            ),
          );
          return;
        }
        // Create and activate sample, then go to Analysis
        await appState.createSample(sample);
        print('Sample activated successfully');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sample set as active')),
          );
          Navigator.pushNamed(context, AppRoutes.analysis);
        }
      } catch (e) {
        print('Error activating sample: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error setting sample as active: $e')),
          );
        }
      }
    } else {
      print('Form validation failed for activate');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields: Client ID and Station ID')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
