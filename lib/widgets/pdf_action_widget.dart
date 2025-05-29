import 'package:flutter/material.dart';
import 'dart:typed_data'; 
import '../services/pdf_report_service.dart';
import '../models/sporcu_model.dart';
import 'package:flutter/services.dart';  // Bu var mı?

class PDFActionWidget extends StatefulWidget {
 final PDFReportConfig config;
 final VoidCallback? onSuccess;
 final Function(String)? onError;

 const PDFActionWidget({
   Key? key,
   required this.config,
   this.onSuccess,
   this.onError,
 }) : super(key: key);

 @override
 _PDFActionWidgetState createState() => _PDFActionWidgetState();
}

class _PDFActionWidgetState extends State<PDFActionWidget> {
 final _pdfService = PDFReportService();
 bool _isGenerating = false;

 @override
 Widget build(BuildContext context) {
   return Row(
     mainAxisAlignment: MainAxisAlignment.spaceAround,
     children: [
       _buildActionButton(
         'Paylaş',
         Icons.share,
         const Color(0xFF2196F3),
         () => _handlePDFAction(PDFAction.share),
       ),
       _buildActionButton(
         'Export',
         Icons.download,
         const Color(0xFF4CAF50),
         () => _showPDFOptionsDialog(),
       ),
       if (widget.config.showPrintButton)
         _buildActionButton(
           'Yazdır',
           Icons.print,
           const Color(0xFF9C27B0),
           () => _handlePDFAction(PDFAction.print),
         ),
     ],
   );
 }

 Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback? onTap) {
   return InkWell(
     onTap: _isGenerating ? null : onTap,
     borderRadius: BorderRadius.circular(12),
     child: Container(
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
       decoration: BoxDecoration(
         color: color.withOpacity(0.1),
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: color.withOpacity(0.3)),
       ),
       child: Column(
         mainAxisSize: MainAxisSize.min,
         children: [
           _isGenerating
               ? SizedBox(
                   width: 24,
                   height: 24,
                   child: CircularProgressIndicator(
                     strokeWidth: 2,
                     valueColor: AlwaysStoppedAnimation<Color>(color),
                   ),
                 )
               : Icon(icon, color: color, size: 24),
           const SizedBox(height: 4),
           Text(
             label,
             style: TextStyle(
               fontSize: 12,
               fontWeight: FontWeight.w600,
               color: color,
             ),
           ),
         ],
       ),
     ),
   );
 }

 void _showPDFOptionsDialog() {
   showDialog(
     context: context,
     builder: (context) => AlertDialog(
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
       title: const Row(
         children: [
           Icon(Icons.picture_as_pdf, color: Colors.red),
           SizedBox(width: 8),
           Text('PDF Seçenekleri'),
         ],
       ),
       content: Column(
         mainAxisSize: MainAxisSize.min,
         children: [
           ListTile(
             leading: const Icon(Icons.save, color: Color(0xFF4CAF50)),
             title: const Text('Cihaza Kaydet'),
             subtitle: const Text('PDF\'i cihazınıza kaydedin'),
             onTap: () {
               Navigator.pop(context);
               _handlePDFAction(PDFAction.save);
             },
           ),
           const Divider(),
           ListTile(
             leading: const Icon(Icons.share, color: Color(0xFF2196F3)),
             title: const Text('Paylaş'),
             subtitle: const Text('PDF\'i WhatsApp, Email vs. ile paylaşın'),
             onTap: () {
               Navigator.pop(context);
               _handlePDFAction(PDFAction.share);
             },
           ),
           const Divider(),
           ListTile(
             leading: const Icon(Icons.print, color: Color(0xFF9C27B0)),
             title: const Text('Yazdır'),
             subtitle: const Text('PDF\'i doğrudan yazdırın'),
             onTap: () {
               Navigator.pop(context);
               _handlePDFAction(PDFAction.print);
             },
           ),
         ],
       ),
       actions: [
         TextButton(
           onPressed: () => Navigator.pop(context),
           child: const Text('İptal'),
         ),
       ],
     ),
   );
 }

 Future<void> _handlePDFAction(PDFAction action) async {
   if (_isGenerating) return;

   setState(() => _isGenerating = true);

   try {
     final pdfData = await _generatePDF();
     
     switch (action) {
       case PDFAction.save:
         final fileName = _generateFileName();
         final filePath = await _pdfService.savePDFToFile(pdfData, fileName);
         _showSuccessMessage('PDF başarıyla kaydedildi: ${filePath.split('/').last}');
         break;
         
       case PDFAction.share:
         final fileName = _generateFileName();
         await _pdfService.sharePDF(pdfData, fileName);
         break;
         
       case PDFAction.print:
         await _pdfService.printPDF(pdfData);
         break;
     }

     widget.onSuccess?.call();
     
   } catch (e) {
     final errorMessage = 'PDF işlemi başarısız: $e';
     _showErrorMessage(errorMessage);
     widget.onError?.call(errorMessage);
   } finally {
     setState(() => _isGenerating = false);
   }
 }

Future<Uint8List> _generatePDF() async {
  // DEBUG: Veriyi kontrol et
  debugPrint('PDF Generation - Report Type: ${widget.config.reportType}');
  debugPrint('PDF Generation - Analysis Data Keys: ${widget.config.analysisData?.keys}');
  debugPrint('PDF Generation - Contains dikeyProfil: ${widget.config.analysisData?.containsKey('dikeyProfil')}');
  debugPrint('PDF Generation - dikeyProfil Value: ${widget.config.analysisData?['dikeyProfil']}');
  debugPrint('PDF Generation - Contains yatayProfil: ${widget.config.analysisData?.containsKey('yatayProfil')}');
  debugPrint('PDF Generation - yatayProfil Value: ${widget.config.analysisData?['yatayProfil']}');
  debugPrint('PDF Generation - Contains loadVelocityProfil: ${widget.config.analysisData?.containsKey('loadVelocityProfil')}');
  debugPrint('PDF Generation - loadVelocityProfil Value: ${widget.config.analysisData?['loadVelocityProfil']}');

  switch (widget.config.reportType) {
    case PDFReportType.performance:
      // KONTROL: Eğer dikeyProfil verisi varsa özel rapor oluştur
      if (widget.config.analysisData?.containsKey('dikeyProfil') == true && 
          widget.config.analysisData?['dikeyProfil'] == true) {
        debugPrint('PDF Generation - Creating Vertical Profile Report');
        return await _pdfService.generateVerticalProfileReport(
          sporcu: widget.config.sporcu!,
          dikeyProfilData: widget.config.analysisData!,
          additionalNotes: widget.config.additionalNotes,
          includeCharts: widget.config.includeCharts,
        );
      }
      
      // KONTROL: Eğer yatayProfil verisi varsa özel rapor oluştur
      if (widget.config.analysisData?.containsKey('yatayProfil') == true && 
          widget.config.analysisData?['yatayProfil'] == true) {
        debugPrint('PDF Generation - Creating Horizontal Profile Report');
        return await _pdfService.generateHorizontalProfileReport(
          sporcu: widget.config.sporcu!,
          yatayProfilData: widget.config.analysisData!,
          additionalNotes: widget.config.additionalNotes,
          includeCharts: widget.config.includeCharts,
        );
      }
      
      // KONTROL: Eğer loadVelocityProfil verisi varsa özel rapor oluştur  
      if (widget.config.analysisData?.containsKey('loadVelocityProfil') == true && 
          widget.config.analysisData?['loadVelocityProfil'] == true) {
        debugPrint('PDF Generation - Creating Load-Velocity Profile Report');
        return await _pdfService.generateLoadVelocityProfileReport(
          sporcu: widget.config.sporcu!,
          loadVelocityData: widget.config.analysisData!,
          additionalNotes: widget.config.additionalNotes,
          includeCharts: widget.config.includeCharts,
        );
      }
      
      // Normal performance raporu
      debugPrint('PDF Generation - Creating Normal Performance Report');
      return await _pdfService.generatePerformanceReport(
        sporcu: widget.config.sporcu!,
        olcumTuru: widget.config.olcumTuru!,
        degerTuru: widget.config.degerTuru!,
        analysisData: widget.config.analysisData!,
        additionalNotes: widget.config.additionalNotes,
        includeCharts: widget.config.includeCharts,
      );
       
     case PDFReportType.comparison:
       return await _pdfService.generateTestComparisonReport(
         sporcu: widget.config.sporcu!,
         testComparisons: widget.config.comparisonData!,
         title: widget.config.title ?? 'Test Karşılaştırma Raporu',
       );
       
     case PDFReportType.team:
       return await _pdfService.generateTeamReport(
         teamName: widget.config.teamName!,
         teamData: widget.config.teamData!,
         additionalNotes: widget.config.additionalNotes,
       );
       
     case PDFReportType.multiAthlete:
       return await _pdfService.generateMultiAthleteReport(
         athleteReports: widget.config.multiAthleteData!,
         title: widget.config.title ?? 'Çoklu Sporcu Raporu',
       );
       
     case PDFReportType.custom:
       if (widget.config.customPDFGenerator != null) {
         return await widget.config.customPDFGenerator!();
       }
       throw Exception('Custom PDF generator tanımlanmamış');
   }
 }


String _generateFileName() {
   final now = DateTime.now();
   final dateStr = '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}';
   
   switch (widget.config.reportType) {
     case PDFReportType.performance:
       // Dikey profil kontrolü
       if (widget.config.analysisData?['dikeyProfil'] == true) {
         return 'DikeyProfilRaporu_${widget.config.sporcu?.ad}_${widget.config.sporcu?.soyad}_$dateStr';
       }
       
       // Yatay profil kontrolü  
       if (widget.config.analysisData?['yatayProfil'] == true) {
         return 'YatayProfilRaporu_${widget.config.sporcu?.ad}_${widget.config.sporcu?.soyad}_$dateStr';
       }
       
       // Load-Velocity profil kontrolü
       if (widget.config.analysisData?['loadVelocityProfil'] == true) {
         return 'LoadVelocityProfilRaporu_${widget.config.sporcu?.ad}_${widget.config.sporcu?.soyad}_$dateStr';
       }
       
       // Normal performans raporu
       return 'PerformansRaporu_${widget.config.sporcu?.ad}_${widget.config.sporcu?.soyad}_${widget.config.olcumTuru}_$dateStr';
       
     case PDFReportType.comparison:
       return 'KarsilastirmaRaporu_${widget.config.sporcu?.ad}_${widget.config.sporcu?.soyad}_$dateStr';
     case PDFReportType.team:
       return 'TakimRaporu_${widget.config.teamName}_$dateStr';
     case PDFReportType.multiAthlete:
       return 'CokluSporcuRaporu_$dateStr';
     case PDFReportType.custom:
       return widget.config.customFileName ?? 'OzelRapor_$dateStr';
   }
 }

 void _showSuccessMessage(String message) {
   ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(
       content: Text(message),
       backgroundColor: const Color(0xFF4CAF50),
       behavior: SnackBarBehavior.floating,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
     ),
   );
 }

 void _showErrorMessage(String message) {
   ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(
       content: Text(message),
       backgroundColor: Colors.red,
       behavior: SnackBarBehavior.floating,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
       duration: const Duration(seconds: 4),
     ),
   );
 }
}

// Enum'lar ve Config sınıfları (aynı kalıyor)
enum PDFReportType {
 performance,
 comparison,
 team,
 multiAthlete,
 custom,
}

enum PDFAction {
 save,
 share,
 print,
}

class PDFReportConfig {
 final PDFReportType reportType;
 final String? title;
 final bool includeCharts;
 final bool showPrintButton;
 final String? additionalNotes;
 
 // Performance Report
 final Sporcu? sporcu;
 final String? olcumTuru;
 final String? degerTuru;
 final Map<String, dynamic>? analysisData;
 
 // Comparison Report
 final List<Map<String, dynamic>>? comparisonData;
 
 // Team Report
 final String? teamName;
 final List<Map<String, dynamic>>? teamData;
 
 // Multi Athlete Report
 final List<Map<String, dynamic>>? multiAthleteData;
 
 // Custom Report
 final Future<Uint8List> Function()? customPDFGenerator;
 final String? customFileName;

 const PDFReportConfig({
   required this.reportType,
   this.title,
   this.includeCharts = true,
   this.showPrintButton = true,
   this.additionalNotes,
   this.sporcu,
   this.olcumTuru,
   this.degerTuru,
   this.analysisData,
   this.comparisonData,
   this.teamName,
   this.teamData,
   this.multiAthleteData,
   this.customPDFGenerator,
   this.customFileName,
 });

 // Factory constructors (aynı kalıyor)
 factory PDFReportConfig.performance({
   required Sporcu sporcu,
   required String olcumTuru,
   required String degerTuru,
   required Map<String, dynamic> analysisData,
   String? additionalNotes,
   bool includeCharts = true,
   bool showPrintButton = true,
 }) {
   return PDFReportConfig(
     reportType: PDFReportType.performance,
     sporcu: sporcu,
     olcumTuru: olcumTuru,
     degerTuru: degerTuru,
     analysisData: analysisData,
     additionalNotes: additionalNotes,
     includeCharts: includeCharts,
     showPrintButton: showPrintButton,
   );
 }

 factory PDFReportConfig.comparison({
   required Sporcu sporcu,
   required List<Map<String, dynamic>> comparisonData,
   String? title,
   String? additionalNotes,
   bool showPrintButton = true,
 }) {
   return PDFReportConfig(
     reportType: PDFReportType.comparison,
     sporcu: sporcu,
     comparisonData: comparisonData,
     title: title,
     additionalNotes: additionalNotes,
     showPrintButton: showPrintButton,
   );
 }

 factory PDFReportConfig.team({
   required String teamName,
   required List<Map<String, dynamic>> teamData,
   String? additionalNotes,
   bool showPrintButton = true,
 }) {
   return PDFReportConfig(
     reportType: PDFReportType.team,
     teamName: teamName,
     teamData: teamData,
     additionalNotes: additionalNotes,
     showPrintButton: showPrintButton,
   );
 }

 factory PDFReportConfig.custom({
   required Future<Uint8List> Function() pdfGenerator,
   String? title,
   String? fileName,
   bool showPrintButton = true,
 }) {
   return PDFReportConfig(
     reportType: PDFReportType.custom,
     customPDFGenerator: pdfGenerator,
     title: title,
     customFileName: fileName,
     showPrintButton: showPrintButton,
   );
 }
}