import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/adoptions/domain/entities/adoption_request_entity.dart';
import '../../features/chat/presentation/screens/chat_detail_screen.dart';

class AdopterRequestCard extends StatelessWidget {
  final AdoptionRequestEntity request;
  final String adopterId; // current user id for chat navigation

  const AdopterRequestCard({
    super.key,
    required this.request,
    required this.adopterId,
  });

  @override
  Widget build(BuildContext context) {
    final bool isApproved = request.status == 'aprobada';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Foundation avatar
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                  image: DecorationImage(
                    image: (request.foundationAvatar != null && request.foundationAvatar!.isNotEmpty)
                        ? NetworkImage(request.foundationAvatar!)
                        : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.foundationName ?? "Fundación",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        children: [
                          const TextSpan(text: "Solicitud por "),
                          TextSpan(
                            text: request.petName ?? "mascota",
                            style: const TextStyle(color: AppTheme.primaryOrange, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              _buildStatusOrChat(context, isApproved),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOrChat(BuildContext context, bool isApproved) {
    if (!isApproved) {
      return _buildStatusIcon(request.status);
    }
    return _buildSquareButton(
      icon: Icons.chat_bubble_outline_rounded,
      color: const Color(0xFF2D3436),
      isAction: true,
      isFilled: true,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              petId: request.petId,
              adopterId: adopterId,
              foundationId: request.foundationId,
              otherUserName: request.foundationName ?? 'Fundación',
              otherUserAvatar: request.foundationAvatar,
              petName: request.petName ?? 'Mascota',
              petImage: request.petImage,
              petSize: request.petSize,
              petAge: request.petAge,
              petSex: request.petSex,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(String status) {
    if (status == 'rechazada') {
      return _buildSquareButton(icon: Icons.close_rounded, color: Colors.redAccent);
    }
    return _buildSquareButton(icon: Icons.access_time_rounded, color: Colors.orange);
  }

  Widget _buildSquareButton({
    required IconData icon,
    required Color color,
    bool isAction = false,
    bool isFilled = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isFilled ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: isFilled ? Colors.white : color),
        ),
      ),
    );
  }
}
