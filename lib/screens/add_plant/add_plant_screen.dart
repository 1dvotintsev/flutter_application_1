import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/rooms_provider.dart';
import '../../providers/plants_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/species.dart';

class AddPlantScreen extends ConsumerStatefulWidget {
  final Species? initialSpecies;

  const AddPlantScreen({super.key, this.initialSpecies});

  @override
  ConsumerState<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends ConsumerState<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _searchController = TextEditingController();

  Species? _selectedSpecies;
  int? _selectedRoomId;
  String _potType = 'Пластик';
  String _soilType = 'Универсальный';
  List<Species> _searchResults = [];
  bool _searching = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedSpecies = widget.initialSpecies;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchSpecies(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await ref.read(apiServiceProvider).searchSpecies(query);
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } catch (_) {
      setState(() => _searching = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedSpecies == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите вид растения')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final plant = await ref.read(apiServiceProvider).createPlant({
        'species_id': _selectedSpecies!.id,
        if (_selectedRoomId != null) 'room_id': _selectedRoomId,
        if (_nicknameController.text.isNotEmpty)
          'nickname': _nicknameController.text,
        'pot_type': _potType,
        'soil_type': _soilType,
      });
      if (mounted) {
        ref.invalidate(plantsProvider);
        context.push('/plant/${plant.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Добавление растения')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedSpecies != null) ...[
                Card(
                  child: ListTile(
                    title: Text(_selectedSpecies!.commonName ?? ''),
                    subtitle: Text(_selectedSpecies!.scientificName ?? ''),
                    trailing: widget.initialSpecies == null
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                setState(() => _selectedSpecies = null),
                          )
                        : null,
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Поиск вида...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _searchSpecies,
                ),
                if (_searching)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ),
                if (_searchResults.isNotEmpty)
                  Card(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final s = _searchResults[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: s.imageUrl != null
                                  ? CachedNetworkImageProvider(s.imageUrl!)
                                  : null,
                              child: s.imageUrl == null
                                  ? const Icon(Icons.eco)
                                  : null,
                            ),
                            title: Text(s.commonName ?? ''),
                            subtitle: Text(s.scientificName ?? ''),
                            onTap: () => setState(() {
                              _selectedSpecies = s;
                              _searchResults = [];
                              _searchController.clear();
                            }),
                          );
                        },
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Название растения',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              roomsAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
                data: (rooms) => DropdownButtonFormField<int?>(
                  key: ValueKey(_selectedRoomId),
                  initialValue: _selectedRoomId,
                  decoration: const InputDecoration(
                    labelText: 'Комната',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Без комнаты')),
                    ...rooms.map((r) => DropdownMenuItem(
                          value: r.id,
                          child: Text(r.name ?? ''),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedRoomId = v),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey(_potType),
                initialValue: _potType,
                decoration: const InputDecoration(
                  labelText: 'Тип горшка',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Пластик', child: Text('Пластик')),
                  DropdownMenuItem(value: 'Керамика', child: Text('Керамика')),
                  DropdownMenuItem(value: 'Глина', child: Text('Глина')),
                  DropdownMenuItem(value: 'Стекло', child: Text('Стекло')),
                ],
                onChanged: (v) => setState(() => _potType = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey(_soilType),
                initialValue: _soilType,
                decoration: const InputDecoration(
                  labelText: 'Тип грунта',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'Универсальный', child: Text('Универсальный')),
                  DropdownMenuItem(
                      value: 'Для суккулентов',
                      child: Text('Для суккулентов')),
                  DropdownMenuItem(
                      value: 'Для орхидей', child: Text('Для орхидей')),
                  DropdownMenuItem(
                      value: 'Торфяной', child: Text('Торфяной')),
                ],
                onChanged: (v) => setState(() => _soilType = v!),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Добавить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
