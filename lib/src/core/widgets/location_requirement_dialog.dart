import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/app_theme.dart';
import '../../features/foundations/domain/entities/foundation_entity.dart';
import '../../features/foundations/presentation/bloc/profile/foundation_profile_bloc.dart';
import '../../features/foundations/presentation/screens/profile/edit_foundation_profile_screen.dart';

class LocationRequirementDialog extends StatelessWidget {
  final FoundationEntity foundation;

  const LocationRequirementDialog({super.key, required this.foundation});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded, size: 48, color: AppTheme.primaryOrange),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ubicación Requerida',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                'Para que los adoptantes encuentren tu fundación y puedan ver la distancia hacia tus mascotas, es necesario que definas tu ubicación exacta en el mapa.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    final profileBloc = context.read<FoundationProfileBloc>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: profileBloc,
                          child: EditFoundationProfileScreen(foundation: foundation),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_location_alt_rounded, color: Colors.white),
                  label: const Text('Configurar Ubicación', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Hacerlo más tarde', style: TextStyle(color: Colors.grey.shade500)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
