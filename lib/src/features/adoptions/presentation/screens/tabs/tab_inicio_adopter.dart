import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/widgets/pet_card.dart';
import '../../../../pets/presentation/bloc/pet_bloc.dart';
import '../../../../pets/presentation/bloc/pet_event.dart';
import '../../../../pets/presentation/bloc/pet_state.dart';
import '../../../../pets/presentation/screens/pet_detail_screen.dart';

class TabInicioAdopter extends StatefulWidget {
  const TabInicioAdopter({super.key});

  @override
  State<TabInicioAdopter> createState() => _TabInicioAdopterState();
}

class _TabInicioAdopterState extends State<TabInicioAdopter> {
  @override
  void initState() {
    super.initState();
    // Cargar TODAS las mascotas disponibles
    context.read<PetBloc>().add(LoadAllAvailablePets());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Encuentra tu compañero", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: BlocBuilder<PetBloc, PetState>(
        builder: (context, state) {
          if (state is PetsLoading) return const Center(child: CircularProgressIndicator());
          if (state is PetsError) return Center(child: Text(state.message));
          
          if (state is PetsLoaded) {
            if (state.pets.isEmpty) {
              return const Center(child: Text("No hay mascotas disponibles por ahora 😔"));
            }
            return RefreshIndicator(
              onRefresh: () async => context.read<PetBloc>().add(LoadAllAvailablePets()),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.pets.length,
                itemBuilder: (context, index) {
                  final pet = state.pets[index];
                  return PetCard(
                    pet: pet,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<PetBloc>(), // Pasamos el BLoC
                            child: PetDetailScreen(
                              pet: pet, 
                              isAdopterView: true, // <--- Bandera para vista de adoptante
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
