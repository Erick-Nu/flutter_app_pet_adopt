import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/pets/domain/entities/pet_entity.dart';

class PdfGeneratorService {
  /// Genera el PDF y abre la vista previa de impresión/compartir
  static Future<void> generateAndPrintPetSheet(PetEntity pet) async {
    final pdf = pw.Document();

    // 1. Cargar imagen principal (Avatar) desde internet
    pw.MemoryImage? profileImage;
    if (pet.avatarUrl != null && pet.avatarUrl!.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(pet.avatarUrl!));
        if (response.statusCode == 200) {
          profileImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {
        // Ignoramos error de carga de imagen y usamos placeholder visual
      }
    }

    // 2. Estilos
    final titleStyle = pw.TextStyle(
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.orange800,
    );
    final labelStyle = pw.TextStyle(fontSize: 12, color: PdfColors.grey700);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('FICHA DE ADOPCIÓN', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey)),
                  pw.Text('PetAdopt', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.orange)),
                ],
              ),
              pw.Divider(thickness: 2, color: PdfColors.orange),
              pw.SizedBox(height: 20),

              // PERFIL
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 120,
                    height: 120,
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(8),
                      color: PdfColors.grey200,
                      image: profileImage != null
                          ? pw.DecorationImage(image: profileImage, fit: pw.BoxFit.cover)
                          : null,
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(pet.nombre.toUpperCase(), style: titleStyle),
                        pw.SizedBox(height: 5),
                        pw.Text('ID: ${pet.id.isNotEmpty ? pet.id.substring(0, 8) : '-'}', style: labelStyle),
                        pw.SizedBox(height: 10),
                        pw.Row(children: [
                          _buildPdfBadge('Edad: ${pet.edad ?? '-'} años'),
                          pw.SizedBox(width: 10),
                          _buildPdfBadge('Sexo: ${pet.sexo}'),
                          if (pet.tamano != null) ...[
                            pw.SizedBox(width: 10),
                            _buildPdfBadge('Tamaño: ${pet.tamano}')
                          ]
                        ]),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // DETALLES MÉDICOS
              pw.Text('Información Médica', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: ['Atributo', 'Estado', 'Observaciones'],
                data: [
                  ['Esterilizado', (pet.fichaMedica?.esEsterilizado ?? false) ? 'SI' : 'NO', ''],
                  ['Desparasitado', (pet.fichaMedica?.esDesparasitado ?? false) ? 'SI' : 'NO', ''],
                  ['Vacunas', (pet.fichaMedica?.tieneVacunas ?? false) ? 'AL DÍA' : 'PENDIENTE', ''],
                  ['Peso', '${pet.fichaMedica?.pesoKg ?? 0} Kg', ''],
                  ['Observaciones', (pet.fichaMedica?.observaciones ?? '-') , ''],
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.orange),
                cellAlignment: pw.Alignment.centerLeft,
              ),

              pw.SizedBox(height: 20),

              // HISTORIA
              pw.Text('Historia / Descripción', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Paragraph(text: pet.descripcion ?? 'Sin descripción.', style: const pw.TextStyle(fontSize: 12)),

              pw.Spacer(),

              // COMPROMISO Y FIRMA
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('COMPROMISO DE ADOPCIÓN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Al firmar este documento, el adoptante se compromete a cuidar, proteger y brindar bienestar a la mascota arriba descrita, aceptando el seguimiento por parte de la fundación.',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 40),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        pw.Column(children: [
                          pw.Container(width: 150, height: 1, color: PdfColors.black),
                          pw.SizedBox(height: 5),
                          pw.Text('Firma Fundación'),
                        ]),
                        pw.Column(children: [
                          pw.Container(width: 150, height: 1, color: PdfColors.black),
                          pw.SizedBox(height: 5),
                          pw.Text('Firma Adoptante'),
                        ]),
                      ],
                    )
                  ],
                ),
              ),

              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'Generado por PetAdopt App - ${DateTime.now().toString().split(' ').first}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Abrir vista previa / compartir
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Ficha_${pet.nombre}.pdf',
    );
  }

  static pw.Widget _buildPdfBadge(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange100,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }
}
