import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/sporcu_model.dart';

class PDFReportService {
  static const String appName = 'IZLAB Sports Performance';
  static const String version = '1.0.0';
  
  // Font cache'i - bir kez yüklensin
  static pw.Font? _fontRegular;
  static pw.Font? _fontBold;
  
  /// Font cache'ini temizle
  static void clearFontCache() {
    _fontRegular = null;
    _fontBold = null;
  }

  /// Font yükleme - APK için güvenli metod
  Future<Map<String, pw.Font>> _loadFonts() async {
    if (_fontRegular != null && _fontBold != null) {
      return {
        'regular': _fontRegular!,
        'bold': _fontBold!,
      };
    }

    try {
      // Flutter asset'lerinden font yükleme
      final fontRegularData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final fontBoldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
      
      _fontRegular = pw.Font.ttf(fontRegularData);
      _fontBold = pw.Font.ttf(fontBoldData);
      
      debugPrint('Custom fontlar başarıyla yüklendi');
      
      return {
        'regular': _fontRegular!,
        'bold': _fontBold!,
      };
    } catch (e) {
      debugPrint('Custom font yüklenemedi: $e');
      
      // Fallback - Google Fonts'dan yükleme
      try {
        _fontRegular = await PdfGoogleFonts.notoSansRegular();
        _fontBold = await PdfGoogleFonts.notoSansBold();
        
        debugPrint('Google Fonts başarıyla yüklendi');
        
        return {
          'regular': _fontRegular!,
          'bold': _fontBold!,
        };
      } catch (e2) {
        debugPrint('Google Fonts da yüklenemedi: $e2');
        
        // Son çare - default fontlar
        debugPrint('Default fontlar kullanılacak');
        return {
          'regular': pw.Font.helvetica(),
          'bold': pw.Font.helveticaBold(),
        };
      }
    }
  }

  /// Font test metodu - Debug için
  Future<void> testFontLoading() async {
    try {
      debugPrint('Font yükleme testi başlatılıyor...');
      
      final fonts = await _loadFonts();
      debugPrint('Font yükleme başarılı:');
      debugPrint('Regular font yüklendi');
      debugPrint('Bold font yüklendi');
      
      // Test PDF oluştur
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Text(
                  'Türkçe Test: ĞÜŞİÖÇ çğüşıö',
                  style: pw.TextStyle(font: fonts['regular'], fontSize: 16),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Bold Test: ĞÜŞİÖÇ çğüşıö',
                  style: pw.TextStyle(font: fonts['bold'], fontSize: 16),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Özel Karakterler: ıİğĞüÜöÖşŞçÇ',
                  style: pw.TextStyle(font: fonts['regular'], fontSize: 14),
                ),
              ],
            );
          },
        ),
      );
      
      final pdfBytes = await pdf.save();
      debugPrint('Test PDF oluşturuldu: ${pdfBytes.length} bytes');
      
      // Dosyaya kaydet
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/font_test.pdf');
      await file.writeAsBytes(pdfBytes);
      debugPrint('Test PDF kaydedildi: ${file.path}');
      
    } catch (e) {
      debugPrint('Font test hatası: $e');
    }
  }

  /// Performans analizi PDF raporu oluştur
  Future<Uint8List> generatePerformanceReport({
    required Sporcu sporcu,
    required String olcumTuru,
    required String degerTuru,
    required Map<String, dynamic> analysisData,
    String? additionalNotes,
    bool includeCharts = true,
  }) async {
    final pdf = pw.Document();

    // Font yükleme
    final fonts = await _loadFonts();
    final fontRegular = fonts['regular']!;
    final fontBold = fonts['bold']!;

    // Logo (varsa)
    pw.ImageProvider? logo;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Logo yüklenemedi: $e');
    }

    // PDF sayfaları oluştur
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return [
            // Başlık Sayfası
            _buildReportHeader(sporcu, olcumTuru, degerTuru, logo, fontBold, fontRegular),
            pw.SizedBox(height: 30),
            
            // Sporcu Bilgileri
            _buildAthleteInfo(sporcu, fontBold, fontRegular),
            pw.SizedBox(height: 20),
            
            // Test Bilgileri
            _buildTestInfo(olcumTuru, degerTuru, analysisData, fontBold, fontRegular),
            pw.SizedBox(height: 20),
            
            // Temel İstatistikler
            _buildBasicStatistics(analysisData, fontBold, fontRegular),
            pw.SizedBox(height: 20),
            
            // Gelişmiş Analizler
            _buildAdvancedAnalysis(analysisData, fontBold, fontRegular),
            pw.SizedBox(height: 20),
            
            // Güvenilirlik Metrikleri
            _buildReliabilityMetrics(analysisData, fontBold, fontRegular),
            pw.SizedBox(height: 20),
            
            // Performans Değerlendirmesi
            _buildPerformanceEvaluation(analysisData, olcumTuru, degerTuru, fontBold, fontRegular),
            pw.SizedBox(height: 20),
            
            // Performans Trendi Tablosu
            if (includeCharts) _buildPerformanceTable(analysisData, fontBold, fontRegular),
            
            // Ek Notlar
            if (additionalNotes != null && additionalNotes.isNotEmpty)
              _buildAdditionalNotes(additionalNotes, fontBold, fontRegular),
            
            pw.SizedBox(height: 30),
            
            // Rapor Alt Bilgisi
            _buildReportFooter(fontRegular),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  /// Başlık bölümü
  pw.Widget _buildReportHeader(
    Sporcu sporcu,
    String olcumTuru,
    String degerTuru,
    pw.ImageProvider? logo,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    appName,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 24,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'PERFORMANS ANALİZİ RAPORU',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18,
                      color: PdfColors.blue700,
                    ),
                  ),
                ],
              ),
              if (logo != null)
                pw.Container(
                  width: 80,
                  height: 80,
                  child: pw.Image(logo),
                ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Divider(color: PdfColors.blue200),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Sporcu: ${sporcu.ad} ${sporcu.soyad}',
                  style: pw.TextStyle(font: fontBold, fontSize: 14),
                ),
              ),
              pw.Text(
                'Test: $olcumTuru - $degerTuru',
                style: pw.TextStyle(font: fontBold, fontSize: 14),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Rapor Tarihi: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(font: fontRegular, fontSize: 12, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Sporcu bilgileri
  pw.Widget _buildAthleteInfo(Sporcu sporcu, pw.Font fontBold, pw.Font fontRegular) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SPORCU BİLGİLERİ',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blue800),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildInfoRow('Ad Soyad', '${sporcu.ad} ${sporcu.soyad}', fontBold, fontRegular),
                    ),
                    pw.Expanded(
                      child: _buildInfoRow('Yaş', '${sporcu.yas}', fontBold, fontRegular),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildInfoRow('Cinsiyet', sporcu.cinsiyet, fontBold, fontRegular),
                    ),
                    pw.Expanded(
                      child: _buildInfoRow('Branş', sporcu.brans ?? 'Belirtilmemiş', fontBold, fontRegular),
                    ),
                  ],
                ),
                if (sporcu.kulup != null || sporcu.boy != null) ...[
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _buildInfoRow('Kulüp', sporcu.kulup ?? 'Belirtilmemiş', fontBold, fontRegular),
                      ),
                      pw.Expanded(
                        child: _buildInfoRow('Boy', sporcu.boy != null ? '${sporcu.boy} cm' : 'Belirtilmemiş', fontBold, fontRegular),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Test bilgileri
  pw.Widget _buildTestInfo(
    String olcumTuru,
    String degerTuru,
    Map<String, dynamic> analysisData,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    final sampleCount = analysisData['count'] ?? 0;
    final analysisDate = analysisData['analysisDate'] ?? '';
    final dateRange = _getDateRange(analysisData);

    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TEST BİLGİLERİ',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blue800),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildInfoRow('Test Türü', olcumTuru, fontBold, fontRegular),
                    ),
                    pw.Expanded(
                      child: _buildInfoRow('Değer Türü', degerTuru, fontBold, fontRegular),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildInfoRow('Ölçüm Sayısı', '$sampleCount', fontBold, fontRegular),
                    ),
                    pw.Expanded(
                      child: _buildInfoRow('Analiz Tarihi', 
                        analysisDate.isNotEmpty ? DateFormat('dd/MM/yyyy').format(DateTime.parse(analysisDate)) : 'Bilinmiyor', 
                        fontBold, fontRegular),
                    ),
                  ],
                ),
                if (dateRange.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  _buildInfoRow('Tarih Aralığı', dateRange, fontBold, fontRegular),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Temel istatistikler
  pw.Widget _buildBasicStatistics(Map<String, dynamic> analysisData, pw.Font fontBold, pw.Font fontRegular) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TEMEL İSTATİSTİKLER',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blue800),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildStatCard('Ortalama', _formatNumber(analysisData['mean']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Medyan', _formatNumber(analysisData['median']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Std. Sapma', _formatNumber(analysisData['standardDeviation']), fontBold, fontRegular)),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildStatCard('Minimum', _formatNumber(analysisData['minimum']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Maksimum', _formatNumber(analysisData['maximum']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('CV (%)', _formatNumber(analysisData['coefficientOfVariation']), fontBold, fontRegular)),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildStatCard('Q25', _formatNumber(analysisData['q25']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Q75', _formatNumber(analysisData['q75']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('IQR', _formatNumber(analysisData['iqr']), fontBold, fontRegular)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Gelişmiş analizler
  pw.Widget _buildAdvancedAnalysis(Map<String, dynamic> analysisData, pw.Font fontBold, pw.Font fontRegular) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'GELİŞMİŞ ANALİZLER',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blue800),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildStatCard('Tutarlılık Skoru', '${_formatNumber(analysisData['typicalityIndex'])}/100', fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Momentum', _formatNumber(analysisData['momentum']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Trend Eğimi', _formatNumber(analysisData['trendSlope']), fontBold, fontRegular)),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildStatCard('Trend Kararlılığı', _formatNumber(analysisData['trendStability']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('R²', _formatNumber(analysisData['trendRSquared']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Outlier Sayısı', '${analysisData['outliersCount'] ?? 0}', fontBold, fontRegular)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Güvenilirlik metrikleri
  pw.Widget _buildReliabilityMetrics(Map<String, dynamic> analysisData, pw.Font fontBold, pw.Font fontRegular) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'GÜVENİLİRLİK METRİKLERİ',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blue800),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(child: _buildStatCard('SWC', _formatNumber(analysisData['swc']), fontBold, fontRegular)),
                pw.Expanded(child: _buildStatCard('MDC', _formatNumber(analysisData['mdc']), fontBold, fontRegular)),
                pw.Expanded(child: _buildStatCard('Test Güvenilirliği', _formatReliability(analysisData['reliability']), fontBold, fontRegular)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Performans değerlendirmesi
  pw.Widget _buildPerformanceEvaluation(
    Map<String, dynamic> analysisData,
    String olcumTuru,
    String degerTuru,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    final performanceClass = analysisData['performanceClass'] ?? 'Bilinmiyor';
    final performanceTrend = analysisData['performanceTrend'] ?? 'Kararlı';
    final recentChange = analysisData['recentChange'] ?? 0.0;
    final recentChangePercent = analysisData['recentChangePercent'] ?? 0.0;
    
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PERFORMANS DEĞERLENDİRMESİ',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blue800),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildStatCard('Performans Sınıfı', performanceClass, fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Trend', performanceTrend, fontBold, fontRegular)),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildStatCard('Son Değişim', _formatNumber(recentChange), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Değişim (%)', '${_formatNumber(recentChangePercent)}%', fontBold, fontRegular)),
                  ],
                ),
                pw.SizedBox(height: 15),
                _buildPerformanceInterpretation(analysisData, olcumTuru, degerTuru, fontBold, fontRegular),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Performans yorumu
  pw.Widget _buildPerformanceInterpretation(
    Map<String, dynamic> analysisData,
    String olcumTuru,
    String degerTuru,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    String interpretation = _generatePerformanceInterpretation(analysisData, olcumTuru, degerTuru);
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Uzman Yorumu:',
            style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blue800),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            interpretation,
            style: pw.TextStyle(font: fontRegular, fontSize: 11),
            textAlign: pw.TextAlign.justify,
          ),
        ],
      ),
    );
  }

  /// Performans tablosu
  pw.Widget _buildPerformanceTable(Map<String, dynamic> analysisData, pw.Font fontBold, pw.Font fontRegular) {
    final performanceValues = analysisData['performanceValues'] as List<dynamic>? ?? [];
    final dates = analysisData['dates'] as List<dynamic>? ?? [];
    
    if (performanceValues.length != dates.length || performanceValues.isEmpty) {
      return pw.Container();
    }

    // Son 10 ölçümü göster
    final displayCount = performanceValues.length > 10 ? 10 : performanceValues.length;
    final startIndex = performanceValues.length - displayCount;
    
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PERFORMANS DETAYLARI (Son $displayCount Ölçüm)',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blue800),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              // Başlık satırı
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('Sıra', fontBold, true),
                  _buildTableCell('Tarih', fontBold, true),
                  _buildTableCell('Değer', fontBold, true),
                  _buildTableCell('Z-Score', fontBold, true),
                ],
              ),
              // Veri satırları
              ...List.generate(displayCount, (index) {
                final dataIndex = startIndex + index;
                final value = performanceValues[dataIndex];
                final date = dates[dataIndex];
                final zScores = analysisData['zScores'] as List<dynamic>? ?? [];
                final zScore = dataIndex < zScores.length ? zScores[dataIndex] : 0.0;
                
                return pw.TableRow(
                  children: [
                    _buildTableCell('${dataIndex + 1}', fontRegular),
                    _buildTableCell(_formatDate(date.toString()), fontRegular),
                    _buildTableCell(_formatNumber(value), fontRegular),
                    _buildTableCell(_formatNumber(zScore), fontRegular),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  /// Ek notlar
  pw.Widget _buildAdditionalNotes(String notes, pw.Font fontBold, pw.Font fontRegular) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'EK NOTLAR',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blue800),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              notes,
              style: pw.TextStyle(font: fontRegular, fontSize: 11),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  /// Rapor alt bilgisi
  pw.Widget _buildReportFooter(pw.Font fontRegular) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            '$appName - $version',
            style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Bu rapor otomatik olarak oluşturulmuştur.',
            style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Rapor Tarihi: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
            style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  /// Dikey Kuvvet-Hız Profili özel raporu oluştur
  Future<Uint8List> generateVerticalProfileReport({
    required Sporcu sporcu,
    required Map<String, dynamic> dikeyProfilData,
    String? additionalNotes,
    bool includeCharts = true,
  }) async {
    final pdf = pw.Document();

    // Font yükleme
    final fonts = await _loadFonts();
    final fontRegular = fonts['regular']!;
    final fontBold = fonts['bold']!;

    // Logo (varsa)
    pw.ImageProvider? logo;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Logo yüklenemedi: $e');
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return [
            // Özel Dikey Profil Başlığı
            _buildVerticalProfileHeader(sporcu, logo, fontBold, fontRegular),
            pw.SizedBox(height: 30),
            
            // Sporcu Bilgileri
            _buildAthleteInfo(sporcu, fontBold, fontRegular),
            pw.SizedBox(height: 20),
            
            // Dikey Profil Test Bilgileri
            _buildVerticalProfileTestInfo(dikeyProfilData, fontBold, fontRegular),
            pw.SizedBox(height: 20),
            
            // Dikey Profil Ana Sonuçları
            _buildVerticalProfileResults(dikeyProfilData, fontBold, fontRegular),
            pw.SizedBox(height: 20),
            
            // Kuvvet-Hız Parametreleri
            _buildForceVelocityParameters(dikeyProfilData, fontBold, fontRegular),
            pw.SizedBox(height: 20),
            
            // Seçili Ölçümler Tablosu
            _buildSelectedMeasurementsTable(dikeyProfilData, fontBold, fontRegular),
            pw.SizedBox(height: 20),
            
            // Profil Yorumlama ve Öneriler
            _buildProfileInterpretationSection(dikeyProfilData, fontBold, fontRegular),
            
            // Ek Notlar
            if (additionalNotes != null && additionalNotes.isNotEmpty)
              _buildAdditionalNotes(additionalNotes, fontBold, fontRegular),
            
            pw.SizedBox(height: 30),
            
            // Rapor Alt Bilgisi
            _buildReportFooter(fontRegular),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  /// Dikey profil özel başlık
  pw.Widget _buildVerticalProfileHeader(
    Sporcu sporcu,
    pw.ImageProvider? logo,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.green200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    appName,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 24,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'DİKEY KUVVET-HIZ PROFİLİ RAPORU',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18,
                      color: PdfColors.green700,
                    ),
                  ),
                ],
              ),
              if (logo != null)
                pw.Container(
                  width: 80,
                  height: 80,
                  child: pw.Image(logo),
                ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Divider(color: PdfColors.green200),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Sporcu: ${sporcu.ad} ${sporcu.soyad}',
                  style: pw.TextStyle(font: fontBold, fontSize: 14),
                ),
              ),
              pw.Text(
                'Analiz Türü: Dikey Kuvvet-Hız Profili',
                style: pw.TextStyle(font: fontBold, fontSize: 14),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Rapor Tarihi: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(font: fontRegular, fontSize: 12, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Dikey profil test bilgileri
  pw.Widget _buildVerticalProfileTestInfo(
    Map<String, dynamic> data,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    final measurementCount = data['measurementCount'] ?? 0;
    final calculationDate = data['calculationDate'] ?? '';
    final analysisType = data['analysisType'] ?? 'Dikey Kuvvet-Hız Profili';

    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ANALİZ BİLGİLERİ',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.green800),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildInfoRow('Analiz Türü', analysisType, fontBold, fontRegular),
                    ),
                    pw.Expanded(
                      child: _buildInfoRow('Ölçüm Sayısı', '$measurementCount', fontBold, fontRegular),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                _buildInfoRow('Hesaplama Tarihi', 
                  calculationDate.isNotEmpty ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(calculationDate)) : 'Bilinmiyor', 
                  fontBold, fontRegular),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Dikey profil ana sonuçları
  pw.Widget _buildVerticalProfileResults(
    Map<String, dynamic> data,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DİKEY PROFİL SONUÇLARI',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.green800),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildStatCard('F0 (N/kg)', _formatNumber(data['f0PerKg']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('V0 (m/s)', _formatNumber(data['v0PerKg']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Pmax (W/kg)', _formatNumber(data['pmaxPerKg']), fontBold, fontRegular)),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildStatCard('SFV (N.s/m/kg)', _formatNumber(data['sfvPerKg']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('SFV Opt', _formatNumber(data['sfvOptPerKg']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('FVimb (%)', '${_formatNumber(data['fvimb'])}%', fontBold, fontRegular)),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildStatCard('R²', _formatNumber(data['rSquared']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Profil Tipi', data['profileType'] ?? 'Belirsiz', fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Performans Sınıfı', data['performanceClass'] ?? 'Belirsiz', fontBold, fontRegular)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kuvvet-Hız parametreleri
  pw.Widget _buildForceVelocityParameters(
    Map<String, dynamic> data,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ANTROPOMETRİK VE BİOMEKANİK PARAMETRELER',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.green800),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildStatCard('Vücut Ağırlığı', '${_formatNumber(data['bodyMass'])} kg', fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Bacak Boyu', '${_formatNumber(data['legLength'])} cm', fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('İtme Mesafesi', '${_formatNumber(data['pushOffDistance'])} m', fontBold, fontRegular)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Seçili ölçümler tablosu
  pw.Widget _buildSelectedMeasurementsTable(
    Map<String, dynamic> data,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    final measurements = data['selectedMeasurements'] as List<dynamic>? ?? [];
    
    if (measurements.isEmpty) {
      return pw.Container();
    }
    
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SEÇİLİ ÖLÇÜMLER',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.green800),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              // Başlık satırı
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('Sıra', fontBold, true),
                  _buildTableCell('Test Türü', fontBold, true),
                  _buildTableCell('Test ID', fontBold, true),
                  _buildTableCell('Yükseklik (cm)', fontBold, true),
                  _buildTableCell('Tarih', fontBold, true),
                ],
              ),
              // Veri satırları
              ...List.generate(measurements.length, (index) {
                final measurement = measurements[index] as Map<String, dynamic>;
                return pw.TableRow(
                  children: [
                    _buildTableCell('${index + 1}', fontRegular),
                    _buildTableCell(measurement['type']?.toString() ?? '-', fontRegular),
                    _buildTableCell(measurement['testId']?.toString() ?? '-', fontRegular),
                    _buildTableCell(_formatNumber(measurement['height']), fontRegular),
                    _buildTableCell(_formatDate(measurement['date']?.toString() ?? ''), fontRegular),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  /// Profil yorumlama ve öneriler
  pw.Widget _buildProfileInterpretationSection(
    Map<String, dynamic> data,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    final interpretation = data['interpretation']?.toString() ?? '';
    final recommendations = data['recommendations'] as List<dynamic>? ?? [];

    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PROFİL YORUMLAMA VE ÖNERİLER',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.green800),
          ),
          pw.SizedBox(height: 10),
          
          // Yorumlama
          if (interpretation.isNotEmpty) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                border: pw.Border.all(color: PdfColors.green200),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Uzman Yorumu:',
                    style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.green800),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    interpretation,
                    style: pw.TextStyle(font: fontRegular, fontSize: 12),
                    textAlign: pw.TextAlign.justify,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
          ],
          
          // Öneriler
          if (recommendations.isNotEmpty) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Antrenman Önerileri:',
                    style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.green800),
                  ),
                  pw.SizedBox(height: 8),
                  ...recommendations.map((rec) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('• ', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                        pw.Expanded(
                          child: pw.Text(
                            rec.toString(),
                            style: pw.TextStyle(font: fontRegular, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Yatay Kuvvet-Hız Profili özel raporu oluştur
  Future<Uint8List> generateHorizontalProfileReport({
    required Sporcu sporcu,
    required Map<String, dynamic> yatayProfilData,
    String? additionalNotes,
    bool includeCharts = true,
  }) async {
    final pdf = pw.Document();

    // Font yükleme
    final fonts = await _loadFonts();
    final fontRegular = fonts['regular']!;
    final fontBold = fonts['bold']!;

    // Logo (varsa)
    pw.ImageProvider? logo;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Logo yüklenemedi: $e');
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return [
            // Özel Yatay Profil Başlığı
            _buildHorizontalProfileHeader(sporcu, logo, fontBold, fontRegular),
            pw.SizedBox(height: 30),
            
            // Sporcu Bilgileri
            _buildAthleteInfo(sporcu, fontBold, fontRegular),
            pw.SizedBox(height: 20),
            
            // Yatay Profil Test Bilgileri
            _buildHorizontalProfileTestInfo(yatayProfilData, fontBold, fontRegular),
            pw.SizedBox(height: 20),
            
            // Yatay Profil Ana Sonuçları
            _buildHorizontalProfileResults(yatayProfilData, fontBold, fontRegular),
            pw.SizedBox(height: 20),
            
            // Sprint Parametreleri
            _buildSprintParameters(yatayProfilData, fontBold, fontRegular),
            pw.SizedBox(height: 20),
            
            // Sprint Zamanları Tablosu
            _buildSprintTimesTable(yatayProfilData, fontBold, fontRegular),
            pw.SizedBox(height: 20),
            
            // Profil Yorumlama ve Öneriler
            _buildHorizontalProfileInterpretationSection(yatayProfilData, fontBold, fontRegular),
            
            // Ek Notlar
            if (additionalNotes != null && additionalNotes.isNotEmpty)
              _buildAdditionalNotes(additionalNotes, fontBold, fontRegular),
            
            pw.SizedBox(height: 30),
            
            // Rapor Alt Bilgisi
            _buildReportFooter(fontRegular),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  /// Yatay profil özel başlık
  pw.Widget _buildHorizontalProfileHeader(
    Sporcu sporcu,
    pw.ImageProvider? logo,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.orange200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    appName,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 24,
                      color: PdfColors.orange800,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'YATAY KUVVET-HIZ PROFİLİ RAPORU',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18,
                      color: PdfColors.orange700,
                    ),
                  ),
                ],
              ),
              if (logo != null)
                pw.Container(
                  width: 80,
                  height: 80,
                  child: pw.Image(logo),
                ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Divider(color: PdfColors.orange200),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Sporcu: ${sporcu.ad} ${sporcu.soyad}',
                  style: pw.TextStyle(font: fontBold, fontSize: 14),
                ),
              ),
              pw.Text(
                'Analiz Türü: Yatay Kuvvet-Hız Profili',
                style: pw.TextStyle(font: fontBold, fontSize: 14),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Rapor Tarihi: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(font: fontRegular, fontSize: 12, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Yatay profil test bilgileri
  pw.Widget _buildHorizontalProfileTestInfo(
    Map<String, dynamic> data,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    final measurementCount = data['measurementCount'] ?? 0;
    final selectedTestId = data['selectedTestId'] ?? 0;
    final calculationDate = data['calculationDate'] ?? '';
    final analysisType = data['analysisType'] ?? 'Yatay Kuvvet-Hız Profili';

    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ANALİZ BİLGİLERİ',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.orange800),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildInfoRow('Analiz Türü', analysisType, fontBold, fontRegular),
                    ),
                    pw.Expanded(
                      child: _buildInfoRow('Test ID', '$selectedTestId', fontBold, fontRegular),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildInfoRow('Sprint Sayısı', '$measurementCount', fontBold, fontRegular),
                    ),
                    pw.Expanded(
                      child: _buildInfoRow('Hesaplama Tarihi', 
                        calculationDate.isNotEmpty ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(calculationDate)) : 'Bilinmiyor', 
                        fontBold, fontRegular),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Yatay profil ana sonuçları
  pw.Widget _buildHorizontalProfileResults(
    Map<String, dynamic> data,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'YATAY PROFİL SONUÇLARI',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.orange800),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildStatCard('F0 (N/kg)', _formatNumber(data['f0']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('V0 (m/s)', _formatNumber(data['v0']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Pmax (W/kg)', _formatNumber(data['pmax']), fontBold, fontRegular)),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildStatCard('SFV (N.s/m/kg)', _formatNumber(data['sfv']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('SFV Opt', _formatNumber(data['sfvOpt']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('FVimb (%)', '${_formatNumber(data['fvimb'])}%', fontBold, fontRegular)),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildStatCard('RFmax', _formatNumber(data['rfmax']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('DRF (%)', '${(_formatNumberAsDouble(data['drf']) * 100).toStringAsFixed(2)}%', fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('R²', _formatNumber(data['rSquared']), fontBold, fontRegular)),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildStatCard('Tau (s)', _formatNumber(data['tau']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Vmax (m/s)', _formatNumber(data['vmax']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Profil Tipi', data['profileType'] ?? 'Belirsiz', fontBold, fontRegular)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sprint parametreleri
  pw.Widget _buildSprintParameters(
    Map<String, dynamic> data,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SPRINT PARAMETRELER VE ÇEVRE KOŞULLARI',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.orange800),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildStatCard('Vücut Ağırlığı', '${_formatNumber(data['bodyMass'])} kg', fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Boy', '${_formatNumber(data['stature'])} m', fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Sıcaklık', '${_formatNumber(data['temperature'])} °C', fontBold, fontRegular)),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildStatCard('Basınç', '${_formatNumber(data['pressure'])} hPa', fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Performans Sınıfı', data['performanceClass'] ?? 'Belirsiz', fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('', '', fontBold, fontRegular)), // Boş alan
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      );
  }

  /// Sprint zamanları tablosu
  pw.Widget _buildSprintTimesTable(
    Map<String, dynamic> data,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    final sprintTimes = data['sprintTimes'] as List<dynamic>? ?? [];
    final sprintDistances = data['sprintDistances'] as List<dynamic>? ?? [];
    
    if (sprintTimes.isEmpty || sprintDistances.isEmpty) {
      return pw.Container();
    }

    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SPRINT ZAMANLAR VE MESAFELER',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.orange800),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              // Başlık satırı
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('Sıra', fontBold, true),
                  _buildTableCell('Mesafe (m)', fontBold, true),
                  _buildTableCell('Zaman (s)', fontBold, true),
                  _buildTableCell('Hız (m/s)', fontBold, true),
                ],
              ),
              // Veri satırları
              ...List.generate(math.min(sprintTimes.length, sprintDistances.length), (index) {
                final distance = sprintDistances[index];
                final time = sprintTimes[index];
                final velocity = distance != 0 && time != 0 ? distance / time : 0.0;
                
                return pw.TableRow(
                  children: [
                    _buildTableCell('${index + 1}', fontRegular),
                    _buildTableCell(_formatNumber(distance), fontRegular),
                    _buildTableCell(_formatNumber(time), fontRegular),
                    _buildTableCell(velocity.toStringAsFixed(2), fontRegular),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  /// Yatay profil yorumlama ve öneriler
  pw.Widget _buildHorizontalProfileInterpretationSection(
    Map<String, dynamic> data,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    final interpretation = data['interpretation']?.toString() ?? '';
    final recommendations = data['recommendations'] as List<dynamic>? ?? [];

    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PROFİL YORUMLAMA VE ÖNERİLER',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.orange800),
          ),
          pw.SizedBox(height: 10),
          
          // Yorumlama
          if (interpretation.isNotEmpty) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                border: pw.Border.all(color: PdfColors.orange200),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Uzman Yorumu:',
                    style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.orange800),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    interpretation,
                    style: pw.TextStyle(font: fontRegular, fontSize: 11),
                    textAlign: pw.TextAlign.justify,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
          ],
          
          // Öneriler
          if (recommendations.isNotEmpty) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Antrenman Önerileri:',
                    style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.orange800),
                  ),
                  pw.SizedBox(height: 8),
                  ...recommendations.map((rec) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('• ', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                        pw.Expanded(
                          child: pw.Text(
                            rec.toString(),
                            style: pw.TextStyle(font: fontRegular, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Load-Velocity Profili özel raporu oluştur
  Future<Uint8List> generateLoadVelocityProfileReport({
    required Sporcu sporcu,
    required Map<String, dynamic> loadVelocityData,
    String? additionalNotes,
    bool includeCharts = true,
  }) async {
    final pdf = pw.Document();

    // Font yükleme
    final fonts = await _loadFonts();
    final fontRegular = fonts['regular']!;
    final fontBold = fonts['bold']!;

    // Logo (varsa)
    pw.ImageProvider? logo;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Logo yüklenemedi: $e');
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return [
            // Özel Load-Velocity Profil Başlığı
            _buildLoadVelocityProfileHeader(sporcu, logo, fontBold, fontRegular),
            pw.SizedBox(height: 30),
            
            // Sporcu Bilgileri
            _buildAthleteInfo(sporcu, fontBold, fontRegular),
            pw.SizedBox(height: 20),
            
            // Load-Velocity Test Bilgileri
            _buildLoadVelocityTestInfo(loadVelocityData, fontBold, fontRegular),
            pw.SizedBox(height: 20),
            
            // Regresyon Sonuçları
            _buildRegressionResults(loadVelocityData, fontBold, fontRegular),
            pw.SizedBox(height: 20),
            
            // Test Verileri Tablosu
            _buildTestDataTable(loadVelocityData, fontBold, fontRegular),
            pw.SizedBox(height: 20),
            
            // %vDec Antrenman Tablosu
            _buildVDecTrainingTable(loadVelocityData, fontBold, fontRegular),
            pw.SizedBox(height: 20),
            
            // Antrenman Kategorileri
            _buildTrainingCategoriesSection(loadVelocityData, fontBold, fontRegular),
            pw.SizedBox(height: 20),
            
            // Profil Yorumlama
            _buildLoadVelocityInterpretation(loadVelocityData, fontBold, fontRegular),
            
            // Ek Notlar
            if (additionalNotes != null && additionalNotes.isNotEmpty)
              _buildAdditionalNotes(additionalNotes, fontBold, fontRegular),
            
            pw.SizedBox(height: 30),
            
            // Rapor Alt Bilgisi
            _buildReportFooter(fontRegular),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  /// Load-Velocity profil özel başlık
  pw.Widget _buildLoadVelocityProfileHeader(
    Sporcu sporcu,
    pw.ImageProvider? logo,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.orange200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    appName,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 24,
                      color: PdfColors.orange800,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'LOAD-VELOCITY PROFİLİ RAPORU',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18,
                      color: PdfColors.orange700,
                    ),
                  ),
                ],
              ),
              if (logo != null)
                pw.Container(
                  width: 80,
                  height: 80,
                  child: pw.Image(logo),
                ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Divider(color: PdfColors.orange200),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Sporcu: ${sporcu.ad} ${sporcu.soyad}',
                  style: pw.TextStyle(font: fontBold, fontSize: 14),
                ),
              ),
              pw.Text(
                'Analiz Türü: Load-Velocity Profili (Morin & Samozino)',
                style: pw.TextStyle(font: fontBold, fontSize: 14),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Rapor Tarihi: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(font: fontRegular, fontSize: 12, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Load-Velocity test bilgileri
  pw.Widget _buildLoadVelocityTestInfo(
    Map<String, dynamic> data,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    final measurementCount = data['measurementCount'] ?? 0;
    final bodyMass = data['bodyMass'] ?? 0.0;
    final maxVelocity = data['maxVelocity'] ?? 0.0;

    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TEST BİLGİLERİ',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.orange800),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildInfoRow('Test Türü', 'Load-Velocity Profili', fontBold, fontRegular),
                    ),
                    pw.Expanded(
                      child: _buildInfoRow('Ölçüm Sayısı', '$measurementCount', fontBold, fontRegular),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildInfoRow('Vücut Ağırlığı', '${_formatNumber(bodyMass)} kg', fontBold, fontRegular),
                    ),
                    pw.Expanded(
                      child: _buildInfoRow('Maksimal Hız', '${_formatNumber(maxVelocity)} m/s', fontBold, fontRegular),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Regresyon sonuçları
  pw.Widget _buildRegressionResults(
    Map<String, dynamic> data,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'LİNEER REGRESYON SONUÇLARI',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.orange800),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildStatCard('Eğim (m/s/kg)', '${_formatNumber(data['slope'])}', fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Y-kesim (m/s)', '${_formatNumber(data['intercept'])}', fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Sprint 1RM (kg)', '${_formatNumber(data['l0'])}', fontBold, fontRegular)),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Row(
                  children: [
                    pw.Expanded(child: _buildStatCard('R²', _formatNumber(data['rSquared']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Güvenilirlik', _getRSquaredInterpretation(data['rSquared']), fontBold, fontRegular)),
                    pw.Expanded(child: _buildStatCard('Profil Kalitesi', _getProfileQuality(data['rSquared']), fontBold, fontRegular)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Test verileri tablosu
  pw.Widget _buildTestDataTable(
    Map<String, dynamic> data,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    final testLoads = data['testLoads'] as List<dynamic>? ?? [];
    final testVelocities = data['testVelocities'] as List<dynamic>? ?? [];
    
    if (testLoads.isEmpty || testVelocities.isEmpty) {
      return pw.Container();
    }

    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TEST VERİLERİ',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.orange800),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              // Başlık satırı
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('Test No', fontBold, true),
                  _buildTableCell('Yük (kg)', fontBold, true),
                  _buildTableCell('Hız (m/s)', fontBold, true),
                  _buildTableCell('Vücut Ağ. %', fontBold, true),
                  _buildTableCell('Tahmini Hız', fontBold, true),
                ],
              ),
              // Veri satırları
              ...List.generate(testLoads.length, (index) {
                final load = testLoads[index] as double;
                final velocity = testVelocities[index] as double;
                final bodyMass = data['bodyMass'] as double? ?? 70.0;
                final bodyWeightPercent = bodyMass > 0 ? (load / bodyMass) * 100 : 0.0;
                
                // Tahmini hız hesapla
                final slope = data['slope'] as double? ?? 0.0;
                final intercept = data['intercept'] as double? ?? 0.0;
                final predictedVelocity = slope * load + intercept;
                
                return pw.TableRow(
                  children: [
                    _buildTableCell('${index + 1}', fontRegular),
                    _buildTableCell(_formatNumber(load), fontRegular),
                    _buildTableCell(_formatNumber(velocity), fontRegular),
                    _buildTableCell('${bodyWeightPercent.toStringAsFixed(0)}%', fontRegular),
                    _buildTableCell(_formatNumber(predictedVelocity), fontRegular),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  /// %vDec antrenman tablosu
  pw.Widget _buildVDecTrainingTable(
    Map<String, dynamic> data,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    final vDecTable = data['vDecTable'] as Map<String, dynamic>? ?? {};
    
    if (vDecTable.isEmpty) {
      return pw.Container();
    }

    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '%VDEC ANTRENMAN TABLOSU',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.orange800),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              // Başlık satırı
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('%vDec', fontBold, true),
                  _buildTableCell('Hedef Hız (m/s)', fontBold, true),
                  _buildTableCell('Yük (kg)', fontBold, true),
                  _buildTableCell('Vücut Ağ. %', fontBold, true),
                  _buildTableCell('Kategori', fontBold, true),
                ],
              ),
              // Veri satırları
              ...vDecTable.entries.map((entry) {
                try {
                  final vDecPercent = double.tryParse(entry.key.toString()) ?? 0.0;
                  final values = entry.value;
                  
                  // values'ın Map olduğundan emin ol
                  Map<String, dynamic> valueMap;
                  if (values is Map<String, dynamic>) {
                    valueMap = values;
                  } else if (values is Map) {
                    valueMap = Map<String, dynamic>.from(values);
                  } else {
                    return pw.TableRow(children: [
                      _buildTableCell('-', fontRegular),
                      _buildTableCell('-', fontRegular),
                      _buildTableCell('-', fontRegular),
                      _buildTableCell('-', fontRegular),
                      _buildTableCell('-', fontRegular),
                    ]);
                  }
                  
                  final category = _getTrainingCategoryString(vDecPercent);
                  final targetVelocity = valueMap['targetVelocity'] ?? 0.0;
                  final requiredLoad = valueMap['requiredLoad'] ?? 0.0;
                  final bodyWeightRatio = valueMap['bodyWeightRatio'] ?? 0.0;
                  
                  return pw.TableRow(
                    children: [
                      _buildTableCell('${vDecPercent.toStringAsFixed(0)}%', fontRegular),
                      _buildTableCell(_formatNumber(targetVelocity), fontRegular),
                      _buildTableCell(_formatNumber(requiredLoad), fontRegular),
                      _buildTableCell('${(bodyWeightRatio * 100).toStringAsFixed(0)}%', fontRegular),
                      _buildTableCell(category, fontRegular),
                    ],
                  );
                } catch (e) {
                  debugPrint('vDec table row error: $e');
                  return pw.TableRow(children: [
                    _buildTableCell('-', fontRegular),
                    _buildTableCell('-', fontRegular),
                    _buildTableCell('-', fontRegular),
                    _buildTableCell('-', fontRegular),
                    _buildTableCell('-', fontRegular),
                  ]);
                }
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  /// Antrenman kategorileri bölümü
  pw.Widget _buildTrainingCategoriesSection(
    Map<String, dynamic> data,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ANTRENMAN KATEGORİLERİ',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.orange800),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildCategoryInfo('Technical Competency (≤10% vDec)', 'Teknik yetkinlik, hareket kalitesi', fontBold, fontRegular),
                pw.SizedBox(height: 8),
                _buildCategoryInfo('Speed-Strength (11-30% vDec)', 'Hız-kuvvet, explosive güç geliştirme', fontBold, fontRegular),
                pw.SizedBox(height: 8),
                _buildCategoryInfo('Power (31-60% vDec)', 'Maksimal güç geliştirme', fontBold, fontRegular),
                pw.SizedBox(height: 8),
                _buildCategoryInfo('Strength-Speed (>60% vDec)', 'Kuvvet-hız, yüksek kuvvet uygulamaları', fontBold, fontRegular),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Load-Velocity profil yorumlama
  pw.Widget _buildLoadVelocityInterpretation(
    Map<String, dynamic> data,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    final interpretation = data['interpretation']?.toString() ?? '';

    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PROFİL YORUMLAMA VE ÖNERİLER',
            style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.orange800),
          ),
          pw.SizedBox(height: 10),
          
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange50,
              border: pw.Border.all(color: PdfColors.orange200),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Uzman Yorumu:',
                  style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.orange800),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  interpretation.isNotEmpty ? interpretation : 'Yorum oluşturulamadı.',
                  style: pw.TextStyle(font: fontRegular, fontSize: 12),
                  textAlign: pw.TextAlign.justify,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// PDF'i dosya olarak kaydet
  Future<String> savePDFToFile(Uint8List pdfData, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.pdf');
      await file.writeAsBytes(pdfData);
      return file.path;
    } catch (e) {
      throw Exception('PDF kaydedilemedi: $e');
    }
  }

  /// PDF'i paylaş
  Future<void> sharePDF(Uint8List pdfData, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName.pdf');
      await file.writeAsBytes(pdfData);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Performans Analizi Raporu - $fileName',
      );
    } catch (e) {
      throw Exception('PDF paylaşılamadı: $e');
    }
  }

  /// PDF'i yazdır
  Future<void> printPDF(Uint8List pdfData) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfData,
      );
    } catch (e) {
      throw Exception('PDF yazdırılamadı: $e');
    }
  }

  /// Toplu rapor oluştur (Birden fazla sporcu)
  Future<Uint8List> generateMultiAthleteReport({
    required List<Map<String, dynamic>> athleteReports,
    String title = 'Çoklu Sporcu Performans Raporu',
  }) async {
    final pdf = pw.Document();
    
    // Font yükleme
    final fonts = await _loadFonts();
    final fontBold = fonts['bold']!;
    final fontRegular = fonts['regular']!;

    // Özet sayfa
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(font: fontBold, fontSize: 24, color: PdfColors.blue800),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Rapor Tarihi: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: pw.TextStyle(font: fontRegular, fontSize: 12),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Toplam Sporcu Sayısı: ${athleteReports.length}',
                      style: pw.TextStyle(font: fontBold, fontSize: 14),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              
              // Sporcu özet tablosu
              pw.Text(
                'SPORCU ÖZETİ',
                style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blue800),
              ),
              pw.SizedBox(height: 10),
              
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  // Başlık
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _buildTableCell('Sporcu', fontBold, true),
                      _buildTableCell('Test', fontBold, true),
                      _buildTableCell('Ortalama', fontBold, true),
                      _buildTableCell('Trend', fontBold, true),
                      _buildTableCell('Tutarlılık', fontBold, true),
                    ],
                  ),
                  // Veri satırları
                  ...athleteReports.map((report) {
                    final analysisData = report['analysisData'] as Map<String, dynamic>;
                    return pw.TableRow(
                      children: [
                       _buildTableCell('${report['olcumTuru']}-${report['degerTuru']}', fontRegular),
                        _buildTableCell(_formatNumber(analysisData['mean']), fontRegular),
                        _buildTableCell(analysisData['performanceTrend'] ?? 'Kararlı', fontRegular),
                        _buildTableCell('${_formatNumber(analysisData['typicalityIndex'])}/100', fontRegular),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  /// Test karşılaştırma raporu
  Future<Uint8List> generateTestComparisonReport({
    required Sporcu sporcu,
    required List<Map<String, dynamic>> testComparisons,
    String title = 'Test Karşılaştırma Raporu',
  }) async {
    final pdf = pw.Document();
    
    // Font yükleme
    final fonts = await _loadFonts();
    final fontBold = fonts['bold']!;
    final fontRegular = fonts['regular']!;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return [
            // Başlık
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(font: fontBold, fontSize: 20, color: PdfColors.blue800),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Sporcu: ${sporcu.ad} ${sporcu.soyad}',
                    style: pw.TextStyle(font: fontBold, fontSize: 16),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Rapor Tarihi: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                    style: pw.TextStyle(font: fontRegular, fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Karşılaştırma tablosu
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildTableCell('Test Türü', fontBold, true),
                    _buildTableCell('Ortalama', fontBold, true),
                    _buildTableCell('CV%', fontBold, true),
                    _buildTableCell('Trend', fontBold, true),
                    _buildTableCell('SWC', fontBold, true),
                    _buildTableCell('MDC', fontBold, true),
                  ],
                ),
                ...testComparisons.map((comparison) {
                  final analysisData = comparison['analysisData'] as Map<String, dynamic>;
                  return pw.TableRow(
                    children: [
                      _buildTableCell('${comparison['olcumTuru']}-${comparison['degerTuru']}', fontRegular),
                      _buildTableCell(_formatNumber(analysisData['mean']), fontRegular),
                      _buildTableCell(_formatNumber(analysisData['coefficientOfVariation']), fontRegular),
                      _buildTableCell(analysisData['performanceTrend'] ?? 'Kararlı', fontRegular),
                      _buildTableCell(_formatNumber(analysisData['swc']), fontRegular),
                      _buildTableCell(_formatNumber(analysisData['mdc']), fontRegular),
                    ],
                  );
                }).toList(),
              ],
            ),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  /// Takım raporu oluştur
  Future<Uint8List> generateTeamReport({
    required String teamName,
    required List<Map<String, dynamic>> teamData,
    String? additionalNotes,
  }) async {
    final pdf = pw.Document();
    
    // Font yükleme
    final fonts = await _loadFonts();
    final fontBold = fonts['bold']!;
    final fontRegular = fonts['regular']!;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return [
            // Takım başlığı
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'TAKIM PERFORMANS RAPORU',
                    style: pw.TextStyle(font: fontBold, fontSize: 24, color: PdfColors.green800),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    teamName,
                    style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.green700),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Rapor Tarihi: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                    style: pw.TextStyle(font: fontRegular, fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Takım istatistikleri
            pw.Text(
              'TAKIM İSTATİSTİKLERİ',
              style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.green800),
            ),
            pw.SizedBox(height: 10),

            // Sporcu sayısı ve genel bilgiler
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(child: _buildStatCard('Toplam Sporcu', '${teamData.length}', fontBold, fontRegular)),
                  pw.Expanded(child: _buildStatCard('Analiz Tarihi', DateFormat('dd/MM/yyyy').format(DateTime.now()), fontBold, fontRegular)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Detaylı sporcu tablosu
            pw.Text(
              'DETAYLI SPORCU ANALİZİ',
              style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.green800),
            ),
            pw.SizedBox(height: 10),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildTableCell('Sporcu', fontBold, true),
                    _buildTableCell('Yaş', fontBold, true),
                    _buildTableCell('Test', fontBold, true),
                    _buildTableCell('Ortalama', fontBold, true),
                    _buildTableCell('Tutarlılık', fontBold, true),
                    _buildTableCell('Trend', fontBold, true),
                  ],
                ),
                ...teamData.map((data) {
                  final sporcu = data['sporcu'] as Sporcu;
                  final analysisData = data['analysisData'] as Map<String, dynamic>;
                  return pw.TableRow(
                    children: [
                      _buildTableCell('${sporcu.ad} ${sporcu.soyad}', fontRegular),
                      _buildTableCell('${sporcu.yas}', fontRegular),
                      _buildTableCell('${data['olcumTuru']}-${data['degerTuru']}', fontRegular),
                      _buildTableCell(_formatNumber(analysisData['mean']), fontRegular),
                      _buildTableCell('${_formatNumber(analysisData['typicalityIndex'])}/100', fontRegular),
                      _buildTableCell(analysisData['performanceTrend'] ?? 'Kararlı', fontRegular),
                    ],
                  );
                }).toList(),
              ],
            ),

            if (additionalNotes != null && additionalNotes.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _buildAdditionalNotes(additionalNotes, fontBold, fontRegular),
            ],

            pw.SizedBox(height: 30),
            _buildReportFooter(fontRegular),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  // Yardımcı metodlar
  pw.Widget _buildInfoRow(String label, String value, pw.Font fontBold, pw.Font fontRegular) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 80,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(font: fontBold, fontSize: 11),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(font: fontRegular, fontSize: 11),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildStatCard(String title, String value, pw.Font fontBold, pw.Font fontRegular) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(horizontal: 4),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blue800),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, pw.Font font, [bool isHeader = false]) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 11 : 10,
          color: isHeader ? PdfColors.blue800 : PdfColors.black,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Helper metodlar
  pw.Widget _buildCategoryInfo(String title, String description, pw.Font fontBold, pw.Font fontRegular) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.orange800),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          description,
          style: pw.TextStyle(font: fontRegular, fontSize: 11),
        ),
      ],
    );
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    if (value is num) {
      return value.toStringAsFixed(2);
    }
    if (value is String) {
      try {
        final parsed = double.parse(value);
        return parsed.toStringAsFixed(2);
      } catch (e) {
        return value;
      }
    }
    return value.toString();
  }

  double _formatNumberAsDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatReliability(dynamic reliability) {
    if (reliability is Map<String, dynamic>) {
      final testRetest = reliability['test_retest_reliability'];
      if (testRetest != null) {
        return _formatNumber(testRetest);
      }
    }
    return 'Bilinmiyor';
  }

  String _getDateRange(Map<String, dynamic> analysisData) {
    final dates = analysisData['dates'] as List<dynamic>? ?? [];
    if (dates.isEmpty) return '';
    
    try {
      final firstDate = DateTime.parse(dates.first.toString());
      final lastDate = DateTime.parse(dates.last.toString());
      return '${DateFormat('dd/MM/yyyy').format(firstDate)} - ${DateFormat('dd/MM/yyyy').format(lastDate)}';
    } catch (e) {
      return '';
    }
  }

  String _getRSquaredInterpretation(dynamic rSquared) {
    if (rSquared == null) return 'Bilinmiyor';
    
    double r2;
    if (rSquared is num) {
      r2 = rSquared.toDouble();
    } else if (rSquared is String) {
      try {
        r2 = double.parse(rSquared);
      } catch (e) {
        return 'Geçersiz';
      }
    } else {
      return 'Geçersiz';
    }
    
    if (r2 >= 0.90) return 'Mükemmel';
    if (r2 >= 0.80) return 'İyi';
    if (r2 >= 0.70) return 'Kabul Edilebilir';
    return 'Zayıf';
  }

  String _getProfileQuality(dynamic rSquared) {
    if (rSquared == null) return 'Bilinmiyor';
    
    double r2;
    if (rSquared is num) {
      r2 = rSquared.toDouble();
    } else if (rSquared is String) {
      try {
        r2 = double.parse(rSquared);
      } catch (e) {
        return 'Geçersiz';
      }
    } else {
      return 'Geçersiz';
    }
    
    if (r2 >= 0.85) return 'Yüksek Kalite';
    if (r2 >= 0.70) return 'Orta Kalite';
    return 'Düşük Kalite';
  }

  String _getTrainingCategoryString(double vDecPercent) {
    if (vDecPercent <= 10) return 'Technical Competency';
    if (vDecPercent <= 30) return 'Speed-Strength';
    if (vDecPercent <= 60) return 'Power';
    return 'Strength-Speed';
  }

  String _generatePerformanceInterpretation(
    Map<String, dynamic> analysisData,
    String olcumTuru,
    String degerTuru,
  ) {
    final cv = (analysisData['coefficientOfVariation'] as num?)?.toDouble() ?? 0;
    final typicalityIndex = (analysisData['typicalityIndex'] as num?)?.toDouble() ?? 0;
    final trendSlope = (analysisData['trendSlope'] as num?)?.toDouble() ?? 0;
    final swc = (analysisData['swc'] as num?)?.toDouble() ?? 0;
    final mdc = (analysisData['mdc'] as num?)?.toDouble() ?? 0;
    final recentChange = (analysisData['recentChange'] as num?)?.toDouble() ?? 0;
    final sampleCount = analysisData['count'] ?? 0;

    List<String> interpretations = [];

    // Tutarlılık yorumu
    if (typicalityIndex >= 80) {
      interpretations.add("Sporcu çok tutarlı bir performans sergilemektedir (Tutarlılık: ${typicalityIndex.toStringAsFixed(0)}/100).");
    } else if (typicalityIndex >= 60) {
      interpretations.add("Sporcu orta düzeyde tutarlı bir performans göstermektedir (Tutarlılık: ${typicalityIndex.toStringAsFixed(0)}/100).");
    } else {
      interpretations.add("Sporcu değişken bir performans sergilemektedir (Tutarlılık: ${typicalityIndex.toStringAsFixed(0)}/100). Antrenman programının tutarlılığı gözden geçirilmelidir.");
    }

    // Trend yorumu
    final isTimeBasedTest = ['kapi1', 'kapi2', 'kapi3', 'kapi4', 'kapi5', 'kapi6', 'kapi7', 'temassuresi'].any(
      (t) => degerTuru.toLowerCase().contains(t)
    );
    
    final adjustedTrend = isTimeBasedTest ? -trendSlope : trendSlope;
    
    if (adjustedTrend > 0.02) {
      interpretations.add("Performans pozitif yönde gelişim göstermektedir.");
    } else if (adjustedTrend < -0.02) {
      interpretations.add("Performansta düşüş eğilimi gözlenmektedir. Antrenman yükü ve recovery dengesinin değerlendirilmesi önerilir.");
    } else {
      interpretations.add("Performans kararlı seyretmektedir.");
    }

    // Değişim analizi
    if (swc > 0 && mdc > 0) {
      if (recentChange.abs() > mdc) {
        if (recentChange.abs() > swc) {
          interpretations.add("Son dönemde gerçek ve anlamlı bir performans değişimi tespit edilmiştir.");
        } else {
          interpretations.add("Son dönemde gerçek ancak küçük bir performans değişimi tespit edilmiştir.");
        }
      } else {
        interpretations.add("Son dönemdeki değişim ölçüm hatası sınırları içindedir.");
      }
    }

    // Örneklem büyüklüğü yorumu
    if (sampleCount < 5) {
      interpretations.add("Daha güvenilir analizler için daha fazla ölçüm verisi toplanması önerilir.");
    } else if (sampleCount >= 10) {
      interpretations.add("Yeterli sayıda ölçüm verisi mevcut olup, analizler güvenilirdir.");
    }

    // Test türüne özel öneriler
    switch (olcumTuru.toUpperCase()) {
      case 'CMJ':
      case 'SJ':
        if (cv > 10) {
          interpretations.add("Sıçrama testlerinde yüksek varyabilite tespit edilmiştir. Teknik tutarlılığın artırılması önerilir.");
        }
        break;
      case 'SPRINT':
        if (cv > 3) {
          interpretations.add("Sprint testlerinde yüksek varyabilite tespit edilmiştir. Start tekniği ve koşu tutarlılığının geliştirilmesi önerilir.");
        }
        break;
      case 'DJ':
        interpretations.add("Drop jump testleri reaktif kuvvet gelişimini değerlendirmek için uygundur. RSI değerlerinin takibi önerilir.");
        break;
      case 'RJ':
        interpretations.add("Repeated jump testleri kuvvet dayanıklılığını değerlendirmek için uygundur. Yorgunluk indeksinin takibi önemlidir.");
        break;
    }

    return interpretations.join(' ');
  }
}