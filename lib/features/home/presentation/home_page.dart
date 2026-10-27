import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/storage/onboarding_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/vetora_header.dart';

/// Página inicial do Vetora e destino final do fluxo inicial.
class HomePage extends StatelessWidget {
  const HomePage({super.key, this.storage = const OnboardingStorage()});

  final OnboardingStorage storage;

  static const _popularModules = [
    _StudyModule(
      title: 'Mecânica clássica',
      subject: 'FÍSICA',
      icon: Icons.motion_photos_on_outlined,
      color: AppColors.ciano,
    ),
    _StudyModule(
      title: 'Circuitos elétricos',
      subject: 'ELÉTRICA',
      icon: Icons.electrical_services_outlined,
      color: Color(0xFFFFC857),
    ),
    _StudyModule(
      title: 'Resistência dos materiais',
      subject: 'CIVIL',
      icon: Icons.foundation_outlined,
      color: Color(0xFF9BC7A4),
    ),
  ];

  static const _engineeringAreas = [
    _EngineeringArea(
      title: 'Engenharia Civil',
      topics: 'Estruturas · Materiais · Hidráulica',
      icon: Icons.foundation_outlined,
    ),
    _EngineeringArea(
      title: 'Engenharia Elétrica',
      topics: 'Circuitos · Eletromagnetismo · Energia',
      icon: Icons.electrical_services_outlined,
    ),
    _EngineeringArea(
      title: 'Engenharia Mecânica',
      topics: 'Mecânica · Termodinâmica · Fluidos',
      icon: Icons.precision_manufacturing_outlined,
    ),
  ];

  Future<void> _resetFirstAccess(BuildContext context) async {
    await storage.reset();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Primeiro acesso redefinido. Reabra o app para ver o onboarding.',
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String section) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$section estará disponível em breve.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const VetoraHeader(),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Notificações',
                    onPressed: () => _showComingSoon(context, 'Notificações'),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.superficie,
                      foregroundColor: AppColors.brancoTecnico,
                    ),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text('OLÁ, ESTUDANTE', style: AppTextStyles.rotulo),
              const SizedBox(height: 8),
              const Text(
                'O que vamos\naprender hoje?',
                style: AppTextStyles.titulo,
              ),
              const SizedBox(height: 8),
              const Text(
                'Explore conceitos, conecte ideias e avance no seu ritmo.',
                style: AppTextStyles.corpo,
              ),
              const SizedBox(height: 28),
              const _SectionHeading(
                title: 'Mais estudados',
                subtitle: 'Temas populares entre estudantes de engenharia',
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 164,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _popularModules.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => _PopularModuleCard(
                    module: _popularModules[index],
                    onTap: () =>
                        _showComingSoon(context, _popularModules[index].title),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const _SectionHeading(
                title: 'Explore por engenharia',
                subtitle: 'Encontre matérias da sua área',
              ),
              const SizedBox(height: 16),
              for (final area in _engineeringAreas) ...[
                _EngineeringAreaCard(
                  area: area,
                  onTap: () => _showComingSoon(context, area.title),
                ),
                const SizedBox(height: 12),
              ],
              if (kDebugMode) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => _resetFirstAccess(context),
                    child: const Text('REDEFINIR PRIMEIRO ACESSO (DEBUG)'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 0) return;
          const sections = ['Menu', 'Calculadora', 'Salvos', 'Perfil'];
          _showComingSoon(context, sections[index]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            label: 'Calculadora',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: 'Salvos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppTheme.fontText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.brancoTecnico,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: AppTheme.fontText,
            fontSize: 12,
            color: AppColors.textoSecundario,
          ),
        ),
      ],
    );
  }
}

class _StudyModule {
  const _StudyModule({
    required this.title,
    required this.subject,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subject;
  final IconData icon;
  final Color color;
}

class _PopularModuleCard extends StatelessWidget {
  const _PopularModuleCard({required this.module, required this.onTap});

  final _StudyModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(module.icon, color: module.color, size: 22),
                    const Spacer(),
                    Text(
                      module.subject,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontMono,
                        fontSize: 10,
                        letterSpacing: 1,
                        color: AppColors.textoTerciario,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  module.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brancoTecnico,
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Text(
                      'Explorar módulo',
                      style: TextStyle(
                        fontFamily: AppTheme.fontText,
                        fontSize: 11,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.ciano,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EngineeringArea {
  const _EngineeringArea({
    required this.title,
    required this.topics,
    required this.icon,
  });

  final String title;
  final String topics;
  final IconData icon;
}

class _EngineeringAreaCard extends StatelessWidget {
  const _EngineeringAreaCard({required this.area, required this.onTap});

  final _EngineeringArea area;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.superficieElevada,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(area.icon, color: AppColors.ciano, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.title,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brancoTecnico,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      area.topics,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontText,
                        fontSize: 11,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textoTerciario,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
