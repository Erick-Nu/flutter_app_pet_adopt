import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../core/widgets/dashboard_stat_card.dart';

class TabInicio extends StatelessWidget {
  const TabInicio({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(textTheme),
          const SizedBox(height: 24),
          _buildAlert(),
          const SizedBox(height: 22),
          _buildStatsGrid(),
          const SizedBox(height: 26),
          _buildQuickActions(textTheme),
          const SizedBox(height: 24),
          _buildHighlightsCard(context),
          const SizedBox(height: 26),
          _buildUpcomingVisits(textTheme),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, Fundación 👋',
              style: textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Panel de Control',
              style: textTheme.headlineSmall?.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryOrange, width: 2),
          ),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
            child: const Icon(Icons.pets, color: AppTheme.primaryOrange),
          ),
        ),
      ],
    );
  }

  Widget _buildAlert() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.2)),
      ),
      child: Row(
        children: const [
          Icon(Icons.lightbulb_outline, color: AppTheme.primaryOrange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Recuerda validar documentos de adoptantes antes de agendar visitas.',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            DashboardStatCard(
              title: 'En Adopción',
              count: '12',
              icon: Icons.pets,
              iconColor: AppTheme.primaryOrange,
              onTap: () {},
            ),
            const SizedBox(width: 15),
            DashboardStatCard(
              title: 'Solicitudes',
              count: '5',
              icon: Icons.mark_email_unread_rounded,
              iconColor: Colors.blueAccent,
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            DashboardStatCard(
              title: 'Adoptados',
              count: '48',
              icon: Icons.favorite_rounded,
              iconColor: Colors.pinkAccent,
              onTap: () {},
            ),
            const SizedBox(width: 15),
            DashboardStatCard(
              title: 'Visitas',
              count: '1.2k',
              icon: Icons.bar_chart_rounded,
              iconColor: Colors.purpleAccent,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Acciones rápidas', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _QuickActionChip(icon: Icons.add_a_photo, label: 'Publicar mascota'),
            _QuickActionChip(icon: Icons.calendar_today, label: 'Agendar visita'),
            _QuickActionChip(icon: Icons.verified_user, label: 'Validar adoptante'),
            _QuickActionChip(icon: Icons.description, label: 'Subir contratos'),
          ],
        ),
      ],
    );
  }

  Widget _buildHighlightsCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
              showAppSnackBar(
                context,
                message: 'Navegar a publicar mascota',
                type: AppSnackBarType.info,
              );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryOrange, Color(0xFFFFB74D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryOrange.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Publicar Mascota',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sube fotos y encuentra un hogar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: const Text('Ir ahora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingVisits(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Próximas visitas', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            TextButton(onPressed: () {}, child: const Text('Ver todas')),
          ],
        ),
        const SizedBox(height: 8),
        _VisitTile(
          title: 'Visita para Luna',
          subtitle: 'Hoy · 5:30 PM · Bogotá',
          color: AppTheme.primaryOrange,
        ),
        _VisitTile(
          title: 'Visita para Rocky',
          subtitle: 'Mañana · 10:00 AM · Chía',
          color: Colors.blueAccent,
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickActionChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppTheme.primaryOrange),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: Colors.grey.shade100,
      onPressed: () {},
      elevation: 0,
      pressElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}

class _VisitTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const _VisitTile({required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(Icons.calendar_month, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}