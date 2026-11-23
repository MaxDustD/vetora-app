import 'package:flutter/material.dart';

import '../../../core/storage/profile_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/vetora_header.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    required this.profile,
    required this.onSaved,
    super.key,
    this.storage = const ProfileStorage(),
  });

  final UserProfile profile;
  final ValueChanged<UserProfile> onSaved;
  final ProfileStorage storage;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _nameController;
  late final Set<String> _selectedPreferences;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _selectedPreferences = {...widget.profile.preferences};
  }

  /// O perfil chega de forma assíncrona (a aba é criada antes de ele ser
  /// lido). Quando um perfil novo chega de fora, o formulário o acompanha.
  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.profile, widget.profile)) {
      _nameController.text = widget.profile.name;
      _selectedPreferences
        ..clear()
        ..addAll(widget.profile.preferences);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final profile = UserProfile(
      name: _nameController.text.trim(),
      preferences: UserProfile.suggestions
          .where(_selectedPreferences.contains)
          .toList(),
    );

    try {
      await widget.storage.save(profile);
      if (!mounted) return;
      widget.onSaved(profile);
      _showMessage('Perfil atualizado com sucesso.');
    } catch (_) {
      // Mensagem humana: o erro técnico não ajuda quem usa o app.
      if (!mounted) return;
      _showMessage('Não foi possível salvar o perfil. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Center(
          // Mesma largura máxima de leitura da Home.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const VetoraHeader(),
                  const SizedBox(height: 32),
                  const Text('SEU ESPAÇO', style: AppTextStyles.rotulo),
                  const SizedBox(height: 8),
                  const Text('Perfil', style: AppTextStyles.titulo),
                  const SizedBox(height: 8),
                  const Text(
                    'Conte como podemos chamar você e escolha temas para deixar sua página inicial com a sua cara.',
                    style: AppTextStyles.corpo,
                  ),
                  const SizedBox(height: 28),
                  _sectionTitle('Como podemos chamar você?'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    maxLength: 40,
                    decoration: const InputDecoration(
                      hintText: 'Seu nome ou apelido',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                      counterText: '',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Digite um nome para continuar.'
                        : null,
                  ),
                  const SizedBox(height: 28),
                  _sectionTitle('O que você gosta de estudar?'),
                  const SizedBox(height: 6),
                  const Text(
                    'Escolha quantos temas quiser. São sugestões — você pode mudar quando quiser.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final preference in UserProfile.suggestions)
                        FilterChip(
                          label: Text(preference),
                          selected: _selectedPreferences.contains(preference),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedPreferences.add(preference);
                              } else {
                                _selectedPreferences.remove(preference);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(_isSaving ? 'Salvando...' : 'Salvar perfil'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: AppTheme.fontText,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.brancoTecnico,
        ),
      ),
    );
  }
}
