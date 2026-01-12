import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> init() async {
    // 1. Configuración Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 2. Configuración iOS (opcional si expandes luego)
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // 3. Inicializar plugin
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // 4. SOLICITAR PERMISOS (Vital para Android 13+)
    final androidImplementation = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
        
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'pet_adopt_channel', // ID único del canal
      'Notificaciones Generales', // Nombre visible para el usuario
      channelDescription: 'Avisos sobre adopciones y mensajes',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, // ID único basado en timestamp
      title, 
      body, 
      platformChannelSpecifics,
    );
  }

  // Método alternativo que acepta Named parameters
  static Future<void> showSimpleNotification({
    required String title,
    required String body,
  }) async {
    final instance = NotificationService();
    await instance.showNotification(title, body);
  }
}
