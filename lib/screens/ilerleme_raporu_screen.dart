import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/sporcu_model.dart';
import '../models/olcum_model.dart';
import '../services/database_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class IlerlemeRaporuScreen extends StatefulWidget {
  final int sporcuId;
  
  const IlerlemeRaporuScreen({
    Key? key, 
    required this.sporcuId,
  }) : super(key: key);

  @override
  _IlerlemeRaporuScreenState createState() => _IlerlemeRaporuScreenState();
}

class _IlerlemeRaporuScreenState extends State<IlerlemeRaporuScreen> with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  Sporcu? _sporcu;
  List<Olcum> _tumOlcumler = [];
  bool _isLoading = true;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Seçilen test türü
  String _selectedTestType = 'Tümü';
  final List<String> _testTypes = ['Tümü', 'Sprint', 'CMJ', 'SJ', 'DJ', 'RJ'];
  
  // Seçilen zaman aralığı
  String _selectedTimeRange = 'Son 6 Ay';
  final List<String> _timeRanges = ['Son 1 Ay', 'Son 3 Ay', 'Son 6 Ay', 'Son 1 Yıl', 'Tümü'];
  
  // Seçilen metrik
  String _selectedMetric = 'Yükseklik';
  List<String> _availableMetrics = ['Yükseklik', 'Uçuş Süresi', 'Güç'];
  
  // PDF için eklenen değişkenler
  final GlobalKey _pdfCaptureKey = GlobalKey();
  bool _isGeneratingPDF = false;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }
  
  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final sporcuFuture = _databaseService.getSporcu(widget.sporcuId);
      final olcumlerFuture = _databaseService.getOlcumlerBySporcuId(widget.sporcuId);
      
      final results = await Future.wait([sporcuFuture, olcumlerFuture]);
      
      if (!mounted) return;
      
      _sporcu = results[0] as Sporcu;
      _tumOlcumler = results[1] as List<Olcum>;
      
      _tumOlcumler.sort((a, b) => a.olcumTarihi.compareTo(b.olcumTarihi));
      
      _updateAvailableMetrics();
      
      _animationController.forward();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler yüklenirken hata: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _updateAvailableMetrics() {
    _availableMetrics = ['Yükseklik', 'Uçuş Süresi', 'Güç'];
    
    if (_selectedTestType.toUpperCase() == 'SPRINT') {
      _availableMetrics = ['Süre', 'Hız'];
      _selectedMetric = 'Süre';
    } else if (_selectedTestType.toUpperCase() == 'DJ' || _selectedTestType.toUpperCase() == 'RJ') {
      _availableMetrics.addAll(['Temas Süresi', 'RSI']);
    }
    
    if (!_availableMetrics.contains(_selectedMetric)) {
      _selectedMetric = _availableMetrics.first;
    }
  }
  
  List<Olcum> get _filteredOlcumler {
    List<Olcum> filtered = _tumOlcumler;
    
    if (_selectedTestType != 'Tümü') {
      filtered = filtered.where((o) => o.olcumTuru.toUpperCase() == _selectedTestType.toUpperCase()).toList();
    }
    
    if (_selectedTimeRange != 'Tümü') {
      final now = DateTime.now();
      DateTime startDate;
      
      switch (_selectedTimeRange) {
        case 'Son 1 Ay':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'Son 3 Ay':
          startDate = DateTime(now.year, now.month - 3, now.day);
          break;
        case 'Son 6 Ay':
          startDate = DateTime(now.year, now.month - 6, now.day);
          break;
        case 'Son 1 Yıl':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        default:
          startDate = DateTime(2000);
      }
      
      filtered = filtered.where((olcum) {
        try {
          final olcumDate = DateTime.parse(olcum.olcumTarihi);
          return olcumDate.isAfter(startDate);
        } catch (e) {
          return false;
        }
      }).toList();
    }
    
    return filtered;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'İlerleme Raporu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0288D1),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Ana içerik RepaintBoundary ile sarılı
                Expanded(
                  child: RepaintBoundary(
                    key: _pdfCaptureKey,
                    child: Container(
                      color: const Color(0xFFF5F7FA), // Arka plan rengi
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: RefreshIndicator(
                            onRefresh: _loadData,
                            child: CustomScrollView(
                              slivers: [
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildSporcuBilgisi(),
                                        const SizedBox(height: 20),
                                        _buildFiltreler(),
                                        const SizedBox(height: 20),
                                        _buildIlerlemeGrafik(),
                                        const SizedBox(height: 24),
                                        if (_filteredOlcumler.isNotEmpty) _buildIstatistikler(),
                                        const SizedBox(height: 24),
                                        if (_filteredOlcumler.isNotEmpty) _buildSonOlcumler(),
                                        const SizedBox(height: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Alt PDF butonu
                _buildPDFActionBar(),
              ],
            ),
    );
  }
  
  // PDF Alt Buton Çubuğu
  Widget _buildPDFActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isGeneratingPDF ? null : _generateProgressReportPDF,
            icon: _isGeneratingPDF 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.picture_as_pdf, color: Colors.white),
            label: Text(
              _isGeneratingPDF ? 'PDF Oluşturuluyor...' : 'İlerleme Raporu PDF',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 234, 80, 80),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
      ),
    );
  }
  
  // Ana PDF oluşturma metodu (Analiz Screen yöntemi)
  Future<void> _generateProgressReportPDF() async {
    if (_isGeneratingPDF) return;
    
    await _shareScreenshotAsPDF(_pdfCaptureKey);
  }

  // Analiz Screen'den uyarlanan gelişmiş PDF sistemi
  Future<void> _shareScreenshotAsPDF(GlobalKey repaintKey) async {
    try {
      setState(() => _isGeneratingPDF = true);
      print('PDF oluşturma başladı');
      
      // 1. Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('PDF oluşturuluyor...'),
            ],
          ),
        ),
      );

      // 2. Sporcu bilgisi kontrolü
      print('Sporcu bilgisi alınıyor...');
      if (_sporcu == null) {
        throw Exception('Sporcu bilgisi bulunamadı');
      }
      
      print('Sporcu alındı: ${_sporcu!.ad} ${_sporcu!.soyad}');

      // 3. RepaintBoundary kontrol et
      print('RepaintBoundary kontrol ediliyor...');
      final renderObject = repaintKey.currentContext?.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        throw Exception('RepaintBoundary bulunamadı');
      }

      final boundary = renderObject;
      print('Ekran görüntüleri yakalanıyor...');
      
      // 4. Çoklu ekran görüntüsü al
      final screenshots = await _captureScrollableContent(boundary, repaintKey);
      print('${screenshots.length} adet ekran görüntüsü alındı');

      // 5. Çok sayfalı PDF oluştur
      print('PDF oluşturuluyor...');
      final pdf = pw.Document();
// Yerel fontları kullan
final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
final fontBoldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
final fontRegular = pw.Font.ttf(fontData);
final fontBold = pw.Font.ttf(fontBoldData);

      // Her ekran görüntüsü için ayrı sayfa
      for (int i = 0; i < screenshots.length; i++) {
        final screenshot = screenshots[i];
        final isFirstPage = i == 0;
        
        // Görüntü boyutlarını hesapla
        final image = pw.MemoryImage(screenshot);
        
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(15), // Margin'i azalttık
            build: (pw.Context context) {
              // Sayfa boyutları
              final pageWidth = PdfPageFormat.a4.width - 30; // 15*2 margin
              
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Sadece ilk sayfada başlık göster
                  if (isFirstPage) ...[
                    pw.Text(
                      'İzLab Sports - İlerleme Raporu',
                      style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blue800),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${_sporcu!.ad} ${_sporcu!.soyad} - $_selectedTestType ($_selectedMetric)',
                      style: pw.TextStyle(font: fontRegular, fontSize: 12),
                    ),
                    pw.Text(
                      'Tarih: ${DateTime.now().toLocal().toString().split(' ')[0]} | Zaman Aralığı: $_selectedTimeRange',
                      style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey600),
                    ),
                    pw.SizedBox(height: 12),
                    // Kalan yüksekliği hesapla
                    pw.Expanded(
                      child: pw.Container(
                        width: pageWidth,
                        child: pw.Image(
                          image,
                          fit: pw.BoxFit.fill, // Oranları koruyarak sığdır
                          alignment: pw.Alignment.topCenter,
                        ),
                      ),
                    ),
                  ] else ...[
                    // Diğer sayfalarda küçük başlık
                    pw.Text(
                      'İlerleme Raporu - Sayfa ${i + 1}',
                      style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blue800),
                    ),
                    pw.SizedBox(height: 8),
                    // Kalan alanın tamamını kullan
                    pw.Expanded(
                      child: pw.Container(
                        width: pageWidth,
                        child: pw.Image(
                          image,
                          fit: pw.BoxFit.fill, // Oranları koruyarak sığdır
                          alignment: pw.Alignment.topCenter,
                        ),
                      ),
                    ),
                  ],
                  
                  // Alt bilgi
                  pw.SizedBox(height: 8),
                  pw.Center(
                    child: pw.Text(
                      'Sayfa ${i + 1} / ${screenshots.length}',
                      style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey600),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      // İstatistik sayfası ekle
      final stats = _calculateReportStatistics();
      if (stats.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return _buildPDFStatisticsPage(fontBold, fontRegular, stats);
            },
          ),
        );
      }

      // 6. PDF'i kaydet
      print('PDF kaydediliyor...');
      final fileName = 'ilerleme_raporu_${_sporcu!.ad}_${_sporcu!.soyad}_${_selectedTestType}_${DateTime.now().millisecondsSinceEpoch}';
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName.pdf');
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      print('PDF kaydedildi: ${file.path}');

      // 7. Dialogları kapat
      if (mounted) Navigator.pop(context); // Loading dialogunu kapat
      print('Dialoglar kapatıldı');

      // 8. PDF'yi paylaş
      print('PDF paylaşılıyor...');
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'İlerleme Raporu - ${_sporcu!.ad} ${_sporcu!.soyad}',
        subject: 'İzLab Sports İlerleme Raporu',
      );

      // 9. Başarı mesajı
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İlerleme raporu PDF olarak paylaşıldı!'),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
    } catch (e, stackTrace) {
      print('PDF oluşturma hatası: $e');
      print('StackTrace: $stackTrace');
      
      // Hata durumunda dialogları kapat
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // Loading dialogunu kapat
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF oluşturulurken hata: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPDF = false);
      }
    }
  }

  // Düzeltilmiş çoklu ekran görüntüsü alma fonksiyonu (Analiz Screen'den)
  Future<List<Uint8List>> _captureScrollableContent(
    RenderRepaintBoundary boundary, 
    GlobalKey repaintKey
  ) async {
    List<Uint8List> screenshots = [];
    
    try {
      print('Kaydırılabilir içerik yakalama başlatılıyor...');
      
      // İlk olarak mevcut görüntüyü al
      final ui.Image initialImage = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? initialByteData = await initialImage.toByteData(format: ui.ImageByteFormat.png);
      if (initialByteData != null) {
        screenshots.add(initialByteData.buffer.asUint8List());
        print('İlk ekran görüntüsü alındı');
      }

      // Context'i al
      final context = repaintKey.currentContext;
      if (context == null) {
        print('Context bulunamadı, tek görüntü döndürülüyor');
        return screenshots;
      }

      // ScrollableState'i bul
      ScrollableState? scrollableState;
      
      void findScrollableState(Element element) {
        if (element.renderObject is RenderViewport ||
            element.renderObject is RenderSliverList ||
            element.renderObject is RenderBox) {
          
          // Element'in state'ini kontrol et
          if (element is StatefulElement && element.state is ScrollableState) {
            scrollableState = element.state as ScrollableState;
            print('ScrollableState bulundu: ${scrollableState.runtimeType}');
            return;
          }
        }
        
        // Child element'leri de kontrol et
        element.visitChildren(findScrollableState);
      }

      // Context'ten başlayarak ScrollableState'i ara
      if (context is Element) {
        findScrollableState(context);
      }

      // Alternatif olarak, context.findAncestorStateOfType kullan
      if (scrollableState == null) {
        scrollableState = context.findAncestorStateOfType<ScrollableState>();
        print('findAncestorStateOfType ile ScrollableState: ${scrollableState != null ? "bulundu" : "bulunamadı"}');
      }

      if (scrollableState == null) {
        print('ScrollableState bulunamadı, tek görüntü döndürülüyor');
        return screenshots;
      }

      // Scroll pozisyon bilgilerini al
      final position = scrollableState!.position;
      final maxScroll = position.maxScrollExtent;
      final minScroll = position.minScrollExtent;
      final viewportHeight = position.viewportDimension;
      
      print('Scroll bilgileri - Min: $minScroll, Max: $maxScroll, Viewport: $viewportHeight');

      // Eğer kaydırılabilir içerik yoksa tek görüntü döndür
      if (maxScroll <= 0) {
        print('Kaydırılabilir içerik yok, tek görüntü döndürülüyor');
        return screenshots;
      }

      // Orijinal pozisyonu kaydet
      final originalPosition = position.pixels;
      print('Orijinal pozisyon: $originalPosition');

      // İçeriğin yüksekliğine göre adım sayısını belirle
      final totalHeight = maxScroll + viewportHeight;
      final stepSize = viewportHeight * 0.8; // %80 overlap için
      final stepCount = math.max(2, (maxScroll / stepSize).ceil() + 1);
      final actualStepCount = math.min(stepCount, 8); // Maksimum 8 sayfa
      
      print('Toplam yükseklik: $totalHeight, Step boyutu: $stepSize, Adım sayısı: $actualStepCount');

      // Adım adım kaydır ve her adımda görüntü al
      for (int step = 1; step < actualStepCount; step++) {
        try {
          // Her adımda viewport yüksekliğinin %80'i kadar kaydır
          final targetPosition = math.min(step * stepSize, maxScroll);
          
          print('$step. adım: $targetPosition pozisyonuna kaydırılıyor');
          
          // Pozisyonu doğrudan ayarla (animasyon olmadan)
          scrollableState!.position.jumpTo(targetPosition);
          
          // Widget tree'nin yeniden render edilmesi için bekle
          await Future.delayed(const Duration(milliseconds: 300));
          
          // Force rebuild
          if (context.mounted) {
            (context as Element).markNeedsBuild();
            await WidgetsBinding.instance.endOfFrame;
          }
          
          // Ek render beklemesi
          await Future.delayed(const Duration(milliseconds: 200));
          
          // Görüntüyü al
          final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
          final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          
          if (byteData != null) {
            screenshots.add(byteData.buffer.asUint8List());
            print('${step + 1}. ekran görüntüsü alındı (pozisyon: $targetPosition)');
          }
          
        } catch (e) {
          print('$step. adım hatası: $e');
          // Hata durumunda devam et
        }
      }

      // Son pozisyona git (en alt)
      try {
        scrollableState!.position.jumpTo(maxScroll);
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (context.mounted) {
          (context as Element).markNeedsBuild();
          await WidgetsBinding.instance.endOfFrame;
        }
        
        await Future.delayed(const Duration(milliseconds: 200));
        
        final ui.Image finalImage = await boundary.toImage(pixelRatio: 2.0);
        final ByteData? finalByteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
        
        if (finalByteData != null) {
          screenshots.add(finalByteData.buffer.asUint8List());
          print('Son ekran görüntüsü alındı (en alt)');
        }
      } catch (e) {
        print('Son adım hatası: $e');
      }

      // Orijinal pozisyona geri dön
      try {
        scrollableState!.position.jumpTo(originalPosition);
        await Future.delayed(const Duration(milliseconds: 200));
        
        if (context.mounted) {
          (context as Element).markNeedsBuild();
          await WidgetsBinding.instance.endOfFrame;
        }
        
        print('Orijinal pozisyona geri dönüldü');
      } catch (e) {
        print('Geri dönüş hatası: $e');
      }

      print('Toplam ${screenshots.length} ekran görüntüsü alındı');
      return screenshots;
      
    } catch (e, stackTrace) {
      print('Genel hata: $e');
      print('StackTrace: $stackTrace');
      
      // Hata durumunda en az bir görüntü döndür
      if (screenshots.isEmpty) {
        try {
          final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
          final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            screenshots.add(byteData.buffer.asUint8List());
          }
        } catch (fallbackError) {
          print('Fallback görüntü alma hatası: $fallbackError');
        }
      }
      return screenshots;
    }
  }
  
  // PDF başlığı
  
  // İstatistik sayfası
  pw.Widget _buildPDFStatisticsPage(
    pw.Font fontBold, 
    pw.Font fontRegular, 
    Map<String, dynamic> stats
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Detaylı İstatistikler',
          style: pw.TextStyle(font: fontBold, fontSize: 18),
        ),
        pw.SizedBox(height: 20),
        
        // İstatistik tablosu
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // Başlık satırı
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Metrik', style: pw.TextStyle(font: fontBold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Değer', style: pw.TextStyle(font: fontBold)),
                ),
              ],
            ),
            
            // Veri satırları
            ...stats.entries.map((entry) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(entry.key, style: pw.TextStyle(font: fontRegular)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(entry.value.toString(), style: pw.TextStyle(font: fontRegular)),
                ),
              ],
            )).toList(),
          ],
        ),
        
        pw.Spacer(),
        
        // Alt bilgi
        pw.Center(
          child: pw.Text(
            'Bu rapor İzLab Sports uygulaması tarafından otomatik olarak oluşturulmuştur.',
            style: pw.TextStyle(
              font: fontRegular,
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ),
      ],
    );
  }
  
  // İstatistik hesaplama
  Map<String, dynamic> _calculateReportStatistics() {
    if (_filteredOlcumler.isEmpty) return {};
    
    final metrikDegerler = _filteredOlcumler
        .map((o) => _getMetricValue(o))
        .where((d) => d != 0)
        .toList();
    
    if (metrikDegerler.isEmpty) return {};
    
    final birim = _getMetricBirim();
    final baslangicDeger = metrikDegerler.first;
    final sonDeger = metrikDegerler.last;
    final enYuksekDeger = metrikDegerler.reduce((a, b) => a > b ? a : b);
    final enDusukDeger = metrikDegerler.reduce((a, b) => a < b ? a : b);
    final ortalama = metrikDegerler.reduce((a, b) => a + b) / metrikDegerler.length;
    final degisim = sonDeger - baslangicDeger;
    final degisimYuzde = baslangicDeger != 0 ? (degisim / baslangicDeger) * 100 : 0;
    
    return {
      'Toplam Ölçüm Sayısı': '${_filteredOlcumler.length}',
      'İlk Değer': '${baslangicDeger.toStringAsFixed(2)} $birim',
      'Son Değer': '${sonDeger.toStringAsFixed(2)} $birim',
      'En Yüksek': '${enYuksekDeger.toStringAsFixed(2)} $birim',
      'En Düşük': '${enDusukDeger.toStringAsFixed(2)} $birim',
      'Ortalama': '${ortalama.toStringAsFixed(2)} $birim',
      'Toplam Değişim': '${degisim.toStringAsFixed(2)} $birim',
      'Değişim Yüzdesi': '${degisimYuzde.toStringAsFixed(1)}%',
    };
  }
  
  // PDF paylaşma
  
  // Orijinal widget metodları aşağıda devam ediyor...
  
  Widget _buildSporcuBilgisi() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0288D1).withOpacity(0.1),
            const Color(0xFF01579B).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0288D1).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0288D1), Color(0xFF01579B)],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_sporcu?.ad ?? ''} ${_sporcu?.soyad ?? ''}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.cake, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${_sporcu?.yas ?? ''} yaş',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.height, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${_sporcu?.boy ?? ''} cm',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.monitor_weight, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${_sporcu?.kilo ?? ''} kg',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (_sporcu?.brans != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.sports, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _sporcu!.brans!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
  
  Widget _buildFiltreler() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: const Color(0xFF0288D1)),
              const SizedBox(width: 8),
              const Text(
                'Filtreler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // İlk satır: Test Türü ve Zaman Aralığı
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Test Türü',
                  value: _selectedTestType,
                  items: _testTypes,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedTestType = value;
                        _updateAvailableMetrics();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'Zaman Aralığı',
                  value: _selectedTimeRange,
                  items: _timeRanges,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedTimeRange = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // İkinci satır: Metrik
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Analiz Edilen Metrik',
                  value: _selectedMetric,
                  items: _availableMetrics,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedMetric = value;
                      });
                    }
                  },
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: Container(),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
  
  Widget _buildIlerlemeGrafik() {
    if (_filteredOlcumler.isEmpty) {
      return _buildEmptyDataMessage();
    }
    
    final spots = <FlSpot>[];
    final dates = <DateTime>[];
    
    for (var olcum in _filteredOlcumler) {
      try {
        DateTime date = DateTime.parse(olcum.olcumTarihi);
        dates.add(date);
        
        double value = _getMetricValue(olcum);
        if (value != 0) {
          spots.add(FlSpot(dates.length.toDouble() - 1, value));
        }
      } catch (e) {
        debugPrint('Tarih ayrıştırma hatası: $e');
      }
    }
    
    if (spots.isEmpty) {
      return _buildEmptyDataMessage();
    }
    
    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.9;
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.1;
    
    if (maxY - minY < maxY * 0.1) {
      minY = maxY * 0.8;
    }
    
    String birim = _getMetricBirim();
    String metrikAdi = _selectedMetric;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up, color: const Color(0xFF0288D1)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$metrikAdi İlerleme Grafiği',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Zaman içindeki performans değişimi',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0288D1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_filteredOlcumler.length} ölçüm',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0288D1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: (maxY - minY) / 5,
                  verticalInterval: dates.length > 10 ? 2 : 1,
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: dates.length > 10 ? 2 : 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < dates.length) {
                          final date = dates[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('dd.MM').format(date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (maxY - minY) / 5,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                      reservedSize: 45,
                    ),
                    axisNameWidget: Text(
                      birim,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.grey.withOpacity(0.3)),
                    bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  ),
                ),
                minX: 0,
                maxX: dates.length.toDouble() - 1,
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: const Color(0xFF0288D1),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 5,
                        color: const Color(0xFF0288D1),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF0288D1).withOpacity(0.3),
                          const Color(0xFF0288D1).withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final date = dates[spot.x.toInt()];
                        return LineTooltipItem(
                          '${DateFormat('dd.MM.yyyy').format(date)}\n${spot.y.toStringAsFixed(2)} $birim',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIstatistikler() {
    if (_filteredOlcumler.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final metrikDegerler = _filteredOlcumler
        .map((o) => _getMetricValue(o))
        .where((d) => d != 0)
        .toList();
    
    if (metrikDegerler.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final baslangicDeger = metrikDegerler.first;
    final sonDeger = metrikDegerler.last;
    final enYuksekDeger = metrikDegerler.reduce((a, b) => a > b ? a : b);
    final enDusukDeger = metrikDegerler.reduce((a, b) => a < b ? a : b);
    
    double ortalama = metrikDegerler.reduce((a, b) => a + b) / metrikDegerler.length;
    double degisim = sonDeger - baslangicDeger;
    double degisimYuzde = 0;
    
    if (baslangicDeger != 0) {
      degisimYuzde = (degisim / baslangicDeger) * 100;
    }
    
    String birim = _getMetricBirim();
    bool yuksekDegerDahaIyi = _isHigherBetter();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: const Color(0xFF0288D1)),
              const SizedBox(width: 8),
              const Text(
                'İstatistiksel Analiz',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Ana istatistik kartları - tek satır yerine iki satır
          _buildStatCardRow([
            _buildStatCard(
              'Toplam Değişim',
              '${degisimYuzde.toStringAsFixed(1)}%',
              _getDegisimIcon(degisim, yuksekDegerDahaIyi),
              _getDegisimColor(degisim, yuksekDegerDahaIyi),
            ),
            _buildStatCard(
              'Ortalama $_selectedMetric',
              '${ortalama.toStringAsFixed(2)} $birim',
              Icons.bar_chart,
              const Color(0xFF0288D1),
            ),
          ]),
          
          const SizedBox(height: 12),
          
          _buildStatCardRow([
            _buildStatCard(
              'En Yüksek',
              '${enYuksekDeger.toStringAsFixed(2)} $birim',
              Icons.arrow_upward,
              Colors.green,
            ),
            _buildStatCard(
              'En Düşük',
              '${enDusukDeger.toStringAsFixed(2)} $birim',
              Icons.arrow_downward,
              Colors.red,
            ),
          ]),
          
          const SizedBox(height: 20),
          _buildIlerlemeOzeti(degisim, degisimYuzde, yuksekDegerDahaIyi),
        ],
      ),
    );
  }

  Widget _buildStatCardRow(List<Widget> cards) {
    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
  
  Widget _buildIlerlemeOzeti(double degisim, double degisimYuzde, bool yuksekDegerDahaIyi) {
    final bool iyilesti = (yuksekDegerDahaIyi && degisim > 0) || (!yuksekDegerDahaIyi && degisim < 0);
    final Color color = iyilesti ? Colors.green : Colors.orange;
    
    String mesaj;
    IconData icon;
    
    if (degisim.abs() < 0.001) {
      mesaj = 'Bu periyotta ${_selectedMetric.toLowerCase()} değerlerinde önemli bir değişim görülmüyor.';
      icon = Icons.trending_flat;
    } else if (iyilesti) {
      mesaj = 'Sporcu bu periyotta ${_selectedMetric.toLowerCase()} değerlerinde ${degisimYuzde.abs().toStringAsFixed(1)}% iyileşme gösterdi.';
      icon = Icons.trending_up;
    } else {
      mesaj = 'Sporcu bu periyotta ${_selectedMetric.toLowerCase()} değerlerinde ${degisimYuzde.abs().toStringAsFixed(1)}% düşüş gösterdi.';
      icon = Icons.trending_down;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mesaj,
              style: TextStyle(
                fontSize: 14,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildSonOlcumler() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: const Color(0xFF0288D1)),
                  const SizedBox(width: 8),
                  const Text(
                    'Son Ölçümler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Son 5',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ...List.generate(
            _filteredOlcumler.length > 5 ? 5 : _filteredOlcumler.length,
            (index) {
              final reversedIndex = _filteredOlcumler.length - 1 - index;
              if (reversedIndex >= 0 && reversedIndex < _filteredOlcumler.length) {
                return _buildOlcumSatiri(_filteredOlcumler[reversedIndex], index);
              }
              return const SizedBox.shrink();
            },
          ),
          
          if (_filteredOlcumler.length > 5) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tüm ölçümler görüntülemesi yakında eklenecek!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.expand_more),
                label: Text('${_filteredOlcumler.length - 5} ölçüm daha göster'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0288D1),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
 
  Widget _buildOlcumSatiri(Olcum olcum, int index) {
    DateTime olcumTarihi;
    try {
      olcumTarihi = DateTime.parse(olcum.olcumTarihi);
    } catch (e) {
      olcumTarihi = DateTime.now();
    }
    
    final deger = _getMetricValue(olcum);
    final birim = _getMetricBirim();
    final color = _getTestTypeColor(olcum.olcumTuru);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: index == 0 ? color.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: index == 0 ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getTestTypeIcon(olcum.olcumTuru), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${olcum.olcumTuru} - ${olcum.olcumSirasi}. Ölçüm',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd.MM.yyyy - HH:mm').format(olcumTarihi),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${deger.toStringAsFixed(2)} $birim',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
              if (index == 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Son',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
 
  Widget _buildEmptyDataMessage() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Seçilen kriterlere uygun veri bulunamadı',
              style: TextStyle(
                fontSize: 16, 
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Farklı filtre seçeneklerini deneyebilirsiniz',
              style: TextStyle(
                fontSize: 14, 
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
 
  // Yardımcı metodlar
  double _getMetricValue(Olcum olcum) {
    if (olcum.olcumTuru.toUpperCase() == 'SPRINT') {
      if (_selectedMetric == 'Süre') {
        final kapi7 = olcum.degerler.firstWhere(
          (d) => d.degerTuru.toUpperCase() == 'KAPI7',
          orElse: () => OlcumDeger(olcumId: 0, degerTuru: '', deger: 0),
        );
        return kapi7.deger;
      } else if (_selectedMetric == 'Hız') {
        final kapi6 = olcum.degerler.firstWhere(
          (d) => d.degerTuru.toUpperCase() == 'KAPI6',
          orElse: () => OlcumDeger(olcumId: 0, degerTuru: '', deger: 0),
        );
        
        final kapi7 = olcum.degerler.firstWhere(
          (d) => d.degerTuru.toUpperCase() == 'KAPI7',
          orElse: () => OlcumDeger(olcumId: 0, degerTuru: '', deger: 0),
        );
        
        if (kapi6.deger != 0 && kapi7.deger != 0) {
          final sureFark = kapi7.deger - kapi6.deger;
          if (sureFark > 0) {
            return 10 / sureFark;
          }
        }
        return 0;
      }
    } else {
      switch (_selectedMetric) {
        case 'Yükseklik':
          final yukseklik = olcum.degerler.firstWhere(
            (d) => d.degerTuru.toLowerCase() == 'yukseklik',
            orElse: () => OlcumDeger(olcumId: 0, degerTuru: '', deger: 0),
          );
          return yukseklik.deger;
          
        case 'Uçuş Süresi':
          final ucusSuresi = olcum.degerler.firstWhere(
            (d) => d.degerTuru.toLowerCase() == 'ucussuresi',
            orElse: () => OlcumDeger(olcumId: 0, degerTuru: '', deger: 0),
          );
          return ucusSuresi.deger;
          
        case 'Güç':
          final guc = olcum.degerler.firstWhere(
            (d) => d.degerTuru.toLowerCase() == 'guc',
            orElse: () => OlcumDeger(olcumId: 0, degerTuru: '', deger: 0),
          );
          return guc.deger;
          
        case 'Temas Süresi':
          final temasSuresi = olcum.degerler.firstWhere(
            (d) => d.degerTuru.toLowerCase() == 'temassuresi',
            orElse: () => OlcumDeger(olcumId: 0, degerTuru: '', deger: 0),
          );
          return temasSuresi.deger;
          
        case 'RSI':
          final rsi = olcum.degerler.firstWhere(
            (d) => d.degerTuru.toLowerCase() == 'rsi',
            orElse: () => OlcumDeger(olcumId: 0, degerTuru: '', deger: 0),
          );
          return rsi.deger;
      }
    }
    
    return 0;
  }
 
  String _getMetricBirim() {
    switch (_selectedMetric) {
      case 'Yükseklik': return 'cm';
      case 'Uçuş Süresi': return 's';
      case 'Temas Süresi': return 's';
      case 'Süre': return 's';
      case 'Hız': return 'm/s';
      case 'Güç': return 'W';
      case 'RSI': return '';
      default: return '';
    }
  }
 
  bool _isHigherBetter() {
    switch (_selectedMetric) {
      case 'Yükseklik': return true;
      case 'Uçuş Süresi': return true;
      case 'Güç': return true;
      case 'Hız': return true;
      case 'RSI': return true;
      case 'Temas Süresi': return false;
      case 'Süre': return false;
      default: return true;
    }
  }
 
  IconData _getDegisimIcon(double degisim, bool yuksekDegerDahaIyi) {
    if (degisim.abs() < 0.001) return Icons.trending_flat;
    
    final bool iyilesti = (yuksekDegerDahaIyi && degisim > 0) || (!yuksekDegerDahaIyi && degisim < 0);
    return iyilesti ? Icons.trending_up : Icons.trending_down;
  }
 
  Color _getDegisimColor(double degisim, bool yuksekDegerDahaIyi) {
    if (degisim.abs() < 0.001) return Colors.grey;
    
    final bool iyilesti = (yuksekDegerDahaIyi && degisim > 0) || (!yuksekDegerDahaIyi && degisim < 0);
    return iyilesti ? Colors.green : Colors.red;
  }
 
  Color _getTestTypeColor(String testType) {
    switch (testType.toUpperCase()) {
      case 'SPRINT': return const Color(0xFFE57373);
      case 'CMJ': return const Color(0xFF64B5F6);
      case 'SJ': return const Color(0xFF81C784);
      case 'DJ': return const Color(0xFFFFB74D);
      case 'RJ': return const Color(0xFFA1887F);
      default: return Colors.grey;
    }
  }

  IconData _getTestTypeIcon(String testType) {
    switch (testType.toUpperCase()) {
      case 'SPRINT': return Icons.directions_run;
      case 'CMJ': return Icons.height;
      case 'SJ': return Icons.height;
      case 'DJ': return Icons.height;
      case 'RJ': return Icons.height;
      default: return Icons.analytics;
    }
  }
}