import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wav/wav.dart';

// ==================== THEME ====================
class HoloTheme {
  static const Color bg = Color(0xFF05070A);
  static const Color panelBg = Color(0xA60A1428);
  static const Color cyan = Color(0xFF00F0FF);
  static const Color cyanDim = Color(0x4D00F0FF);
  static const Color blue = Color(0xFF0066FF);
  static const Color green = Color(0xFF00FF88);
  static const Color red = Color(0xFFFF3366);
  static const Color yellow = Color(0xFFFFCC00);
  static const Color glass = Color(0x660F1E3C);
  static const Color border = Color(0x4000F0FF);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HoloRadioApp());
}

class HoloRadioApp extends StatelessWidget {
  const HoloRadioApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HoloRadio',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: HoloTheme.bg,
        colorScheme: const ColorScheme.dark(
          primary: HoloTheme.cyan, secondary: HoloTheme.blue, surface: HoloTheme.panelBg,
        ),
      ),
      home: const HoloRadioHome(),
    );
  }
}

class HoloRadioHome extends StatefulWidget {
  const HoloRadioHome({super.key});
  @override
  State<HoloRadioHome> createState() => _HoloRadioHomeState();
}

class _HoloRadioHomeState extends State<HoloRadioHome>
    with SingleTickerProviderStateMixin {
  int _currentTab = 0;
  late AnimationController _radarController;
  final List<String> _tabs = ['SENDER', 'RECEIVER', 'SETTINGS', 'ANALYZER'];

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.storage.request();
    if (Platform.isAndroid) await Permission.manageExternalStorage.request();
  }

  @override
  void dispose() { _radarController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundGrid(),
          RadarSweep(controller: _radarController),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  _buildHeader(), const SizedBox(height: 20),
                  _buildTabs(), const SizedBox(height: 25),
                  _buildScreen(), const SizedBox(height: 20),
                  _buildFooter(),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: HoloTheme.border))),
      child: Column(children: [
        Text('◈ HOLO RADIO ◈',
          style: TextStyle(fontSize: 28, letterSpacing: 4, color: HoloTheme.cyan, fontFamily: 'Courier',
            shadows: [Shadow(color: HoloTheme.cyan.withOpacity(0.5), blurRadius: 20),
              Shadow(color: HoloTheme.blue.withOpacity(0.3), blurRadius: 40)],
          ),
        ),
        const SizedBox(height: 8),
        Text('DIGITAL MODEM SYSTEM // OFFLINE CAPABLE',
          style: TextStyle(fontSize: 12, letterSpacing: 6, color: HoloTheme.cyan.withOpacity(0.5), fontFamily: 'Courier'),
        ),
      ]),
    );
  }

  Widget _buildTabs() {
    return Row(mainAxisAlignment: MainAxisAlignment.center,
      children: _tabs.asMap().entries.map((entry) {
        final index = entry.key; final label = entry.value; final isActive = _currentTab == index;
        return Padding(padding: const EdgeInsets.symmetric(horizontal: 5),
          child: GestureDetector(
            onTap: () => setState(() => _currentTab = index),
            child: AnimatedContainer(duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: isActive ? HoloTheme.cyan.withOpacity(0.2) : HoloTheme.glass,
                border: Border.all(color: isActive ? HoloTheme.cyan : HoloTheme.border),
                boxShadow: isActive ? [BoxShadow(color: HoloTheme.cyan.withOpacity(0.3), blurRadius: 20)] : null,
              ),
              child: Text(label, style: const TextStyle(color: HoloTheme.cyan, fontFamily: 'Courier', fontSize: 13, letterSpacing: 2)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScreen() {
    switch (_currentTab) {
      case 0: return const SenderScreen();
      case 1: return const ReceiverScreen();
      case 2: return const SettingsScreen();
      case 3: return const AnalyzerScreen();
      default: return const SenderScreen();
    }
  }

  Widget _buildFooter() {
    return Container(padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: HoloTheme.border))),
      child: Text('HOLO RADIO v1.0 // OFFLINE DIGITAL MODEM // NO EXTERNAL DEPENDENCIES',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10, color: HoloTheme.cyan.withOpacity(0.5), letterSpacing: 2, fontFamily: 'Courier'),
      ),
    );
  }
}

class BackgroundGrid extends StatelessWidget {
  const BackgroundGrid({super.key});
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.infinite, painter: GridPainter());
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = HoloTheme.cyan.withOpacity(0.06)..strokeWidth = 1;
    const spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    for (double i = 0; i < size.height; i += spacing) canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RadarSweep extends StatelessWidget {
  final AnimationController controller;
  const RadarSweep({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(animation: controller,
        builder: (context, child) => Opacity(opacity: 0.15,
          child: Container(width: 600, height: 600,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: HoloTheme.cyanDim)),
            child: Transform.rotate(angle: controller.value * 2 * math.pi,
              child: CustomPaint(painter: RadarSweepPainter()),
            ),
          ),
        ),
      ),
    );
  }
}

class RadarSweepPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [HoloTheme.cyanDim, Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width / 2, size.height / 2));
    final path = Path()..moveTo(size.width / 2, 0)..lineTo(size.width, size.height / 2)..lineTo(size.width / 2, size.height / 2)..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HoloPanel extends StatelessWidget {
  final String title; final List<Widget> children;
  const HoloPanel({super.key, required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: HoloTheme.panelBg, border: Border.all(color: HoloTheme.border), borderRadius: BorderRadius.circular(4)),
      child: ClipRRect(borderRadius: BorderRadius.circular(4),
        child: Stack(children: [
          Positioned(top: 0, left: 0, right: 0, child: _Scanline()),
          Padding(padding: const EdgeInsets.all(15),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('◆', style: TextStyle(color: HoloTheme.cyan, fontSize: 10)),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(color: HoloTheme.cyan, fontSize: 12, letterSpacing: 3, fontFamily: 'Courier')),
              ]),
              const SizedBox(height: 12),
              ...children,
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Scanline extends StatefulWidget {
  @override
  State<_Scanline> createState() => _ScanlineState();
}

class _ScanlineState extends State<_Scanline> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _controller,
      builder: (context, child) => Opacity(
        opacity: math.sin(_controller.value * math.pi) * 0.5 + 0.5,
        child: Container(height: 1, decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.transparent, HoloTheme.cyan, Colors.transparent]),
        )),
      ),
    );
  }
}

class HoloButton extends StatelessWidget {
  final String label; final VoidCallback? onPressed; final bool isPrimary; final bool isDanger; final bool disabled;
  const HoloButton({super.key, required this.label, this.onPressed, this.isPrimary = false, this.isDanger = false, this.disabled = false});
  @override
  Widget build(BuildContext context) {
    Color borderColor = HoloTheme.border, bgColor = HoloTheme.glass, textColor = HoloTheme.cyan;
    if (isPrimary) { borderColor = HoloTheme.cyan; bgColor = HoloTheme.cyan.withOpacity(0.15); }
    else if (isDanger) { borderColor = HoloTheme.red; textColor = HoloTheme.red; bgColor = HoloTheme.red.withOpacity(0.1); }
    return GestureDetector(onTap: disabled ? null : onPressed,
      child: Opacity(opacity: disabled ? 0.4 : 1.0,
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: bgColor, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(2)),
          child: Text(label, style: TextStyle(color: textColor, fontFamily: 'Courier', fontSize: 12, letterSpacing: 2)),
        ),
      ),
    );
  }
}

class HoloTextField extends StatelessWidget {
  final String? label; final String? hint; final int? maxLines; final bool obscureText;
  final TextEditingController? controller; final bool enabled; final ValueChanged<String>? onChanged; final TextInputType? keyboardType;
  const HoloTextField({super.key, this.label, this.hint, this.maxLines = 1, this.obscureText = false, this.controller, this.enabled = true, this.onChanged, this.keyboardType});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (label != null) Text(label!, style: TextStyle(fontSize: 11, letterSpacing: 1, color: HoloTheme.cyan.withOpacity(0.5), fontFamily: 'Courier')),
      if (label != null) const SizedBox(height: 5),
      Container(decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), border: Border.all(color: HoloTheme.border), borderRadius: BorderRadius.circular(2)),
        child: TextField(controller: controller, maxLines: maxLines, obscureText: obscureText, enabled: enabled, keyboardType: keyboardType, onChanged: onChanged,
          style: const TextStyle(color: HoloTheme.cyan, fontFamily: 'Courier', fontSize: 13),
          decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: HoloTheme.cyan.withOpacity(0.3), fontFamily: 'Courier'),
            contentPadding: const EdgeInsets.all(12), border: InputBorder.none),
        ),
      ),
    ]);
  }
}

class HoloDisplayBox extends StatelessWidget {
  final String text; final double? minHeight; final double? maxHeight;
  const HoloDisplayBox({super.key, required this.text, this.minHeight = 80, this.maxHeight = 200});
  @override
  Widget build(BuildContext context) {
    return Container(width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight ?? 80, maxHeight: maxHeight ?? 200),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), border: Border.all(color: HoloTheme.border)),
      child: SingleChildScrollView(child: Text(text, style: const TextStyle(color: HoloTheme.green, fontFamily: 'Courier', fontSize: 12, height: 1.6))),
    );
  }
}

class HoloToggle extends StatefulWidget {
  final String label; final ValueChanged<bool>? onChanged; final bool initialValue;
  const HoloToggle({super.key, required this.label, this.onChanged, this.initialValue = false});
  @override
  State<HoloToggle> createState() => _HoloToggleState();
}

class _HoloToggleState extends State<HoloToggle> {
  late bool _value;
  @override
  void initState() { super.initState(); _value = widget.initialValue; }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: () { setState(() => _value = !_value); widget.onChanged?.call(_value); },
      child: Row(children: [
        Container(width: 44, height: 24,
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), border: Border.all(color: HoloTheme.border), borderRadius: BorderRadius.circular(12)),
          child: AnimatedAlign(duration: const Duration(milliseconds: 300),
            alignment: _value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(width: 18, height: 18, margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: _value ? HoloTheme.green : HoloTheme.cyanDim, shape: BoxShape.circle,
                boxShadow: _value ? [BoxShadow(color: HoloTheme.green, blurRadius: 10)] : null),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(widget.label, style: TextStyle(fontSize: 11, letterSpacing: 1,
          color: _value ? HoloTheme.green : HoloTheme.cyan.withOpacity(0.5), fontFamily: 'Courier')),
      ]),
    );
  }
}

class HoloSlider extends StatefulWidget {
  final String label; final double value; final ValueChanged<double>? onChanged;
  const HoloSlider({super.key, required this.label, required this.value, this.onChanged});
  @override
  State<HoloSlider> createState() => _HoloSliderState();
}

class _HoloSliderState extends State<HoloSlider> {
  late double _value;
  @override
  void initState() { super.initState(); _value = widget.value; }
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label, style: TextStyle(fontSize: 11, color: HoloTheme.cyan.withOpacity(0.5), fontFamily: 'Courier')),
      SliderTheme(data: SliderThemeData(activeTrackColor: HoloTheme.cyan, inactiveTrackColor: Colors.black.withOpacity(0.4),
        thumbColor: HoloTheme.cyan, overlayColor: HoloTheme.cyan.withOpacity(0.2), trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8)),
        child: Slider(value: _value, onChanged: (v) { setState(() => _value = v); widget.onChanged?.call(v); }),
      ),
    ]);
  }
}

class HoloMeter extends StatelessWidget {
  final double value; final double? height;
  const HoloMeter({super.key, required this.value, this.height = 20});
  @override
  Widget build(BuildContext context) {
    return Container(height: height,
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), border: Border.all(color: HoloTheme.border), borderRadius: BorderRadius.circular(2)),
      child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: value.clamp(0.0, 1.0),
        child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [HoloTheme.green, HoloTheme.cyan, HoloTheme.blue])),
          child: Align(alignment: Alignment.centerRight, child: Container(width: 2, color: Colors.white)),
        ),
      ),
    );
  }
}

class HoloDropdown extends StatefulWidget {
  final String label; final List<String> items; final ValueChanged<String?>? onChanged; final String? value;
  const HoloDropdown({super.key, required this.label, required this.items, this.onChanged, this.value});
  @override
  State<HoloDropdown> createState() => _HoloDropdownState();
}

class _HoloDropdownState extends State<HoloDropdown> {
  String? _selected;
  @override
  void initState() { super.initState(); _selected = widget.value ?? (widget.items.isNotEmpty ? widget.items.first : null); }
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label, style: TextStyle(fontSize: 11, color: HoloTheme.cyan.withOpacity(0.5), fontFamily: 'Courier')),
      const SizedBox(height: 5),
      Container(padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), border: Border.all(color: HoloTheme.border), borderRadius: BorderRadius.circular(2)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(value: _selected, isExpanded: true, dropdownColor: HoloTheme.bg,
            style: const TextStyle(color: HoloTheme.cyan, fontFamily: 'Courier', fontSize: 13),
            items: widget.items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: (v) { setState(() => _selected = v); widget.onChanged?.call(v); },
          ),
        ),
      ),
    ]);
  }
}

class LogBox extends StatefulWidget {
  final String logId;
  const LogBox({super.key, required this.logId});
  @override
  State<LogBox> createState() => _LogBoxState();
}

class _LogBoxState extends State<LogBox> {
  final List<String> _logs = [];
  void addLog(String msg) {
    final time = DateTime.now().toString().substring(11, 19);
    setState(() { _logs.add('[$time] $msg'); if (_logs.length > 50) _logs.removeAt(0); });
  }
  @override
  Widget build(BuildContext context) {
    return Container(constraints: const BoxConstraints(maxHeight: 150),
      child: ListView.builder(shrinkWrap: true, itemCount: _logs.length,
        itemBuilder: (context, index) => Padding(padding: const EdgeInsets.symmetric(vertical: 2),
          child: RichText(text: TextSpan(style: const TextStyle(fontFamily: 'Courier', fontSize: 12, height: 1.5), children: [
            TextSpan(text: _logs[index].split(']')[0] + '] ', style: const TextStyle(color: HoloTheme.cyan)),
            TextSpan(text: _logs[index].split(']').skip(1).join(']').trim(), style: TextStyle(color: HoloTheme.cyan.withOpacity(0.5))),
          ])),
        ),
      ),
    );
  }
}

final Map<String, _LogBoxState> _loggers = {};
void log(String id, String msg) { _loggers[id]?.addLog(msg); }

class SenderScreen extends StatefulWidget {
  const SenderScreen({super.key});
  @override
  State<SenderScreen> createState() => _SenderScreenState();
}

class _SenderScreenState extends State<SenderScreen> {
  final _textController = TextEditingController(text: 'Hello, HoloRadio! This is a test transmission.');
  String _txBinary = '';
  List<String> _txFrames = [];
  bool _encryptionOn = false;
  double _volume = 0.8;
  double _noise = 0.0;
  final _passphraseController = TextEditingController();
  final _freqController = TextEditingController(text: '1500');
  final _baudController = TextEditingController(text: '300');
  final _frameSizeController = TextEditingController(text: '32');
  String _modulation = 'Binary FSK';
  String _sampleRate = '22050 Hz';
  final _audioPlayer = AudioPlayer();
  final GlobalKey<_LogBoxState> _txLogKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_txLogKey.currentState != null) _loggers['tx'] = _txLogKey.currentState!;
      log('tx', 'HoloRadio initialized');
      log('tx', 'System ready • Offline capable');
    });
  }

  @override
  void dispose() {
    _textController.dispose(); _passphraseController.dispose(); _freqController.dispose();
    _baudController.dispose(); _frameSizeController.dispose(); _audioPlayer.dispose();
    super.dispose();
  }

  void _encodeText() {
    final text = _textController.text;
    final bytes = utf8.encode(text);
    final bits = bytes.map((b) => b.toRadixString(2).padLeft(8, '0')).join('');
    setState(() => _txBinary = bits);
    log('tx', 'Encoded ${bytes.length} bytes → ${bits.length} bits');
  }

  void _clearTx() {
    _textController.clear();
    setState(() { _txBinary = ''; _txFrames = []; });
    log('tx', 'Cleared all TX data');
  }

  void _loadSample() {
    _textController.text = 'HoloRadio Test Message #42. Signal check. Over.';
    _encodeText();
    log('tx', 'Sample message loaded');
  }

  Future<void> _copyBinary() async {
    if (_txBinary.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _txBinary));
    log('tx', 'Binary copied to clipboard');
  }

  Future<void> _downloadBinary() async {
    if (_txBinary.isEmpty) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/holodata.bin.txt');
    await file.writeAsString(_txBinary);
    await Share.shareXFiles([XFile(file.path)], text: 'HoloRadio Binary Data');
    log('tx', 'Binary exported');
  }

  void _buildFrames() {
    if (_txBinary.isEmpty) _encodeText();
    final frameSize = (int.tryParse(_frameSizeController.text) ?? 32) * 8;
    final frames = <String>[];
    for (int i = 0; i < _txBinary.length; i += frameSize) {
      frames.add(_txBinary.substring(i, math.min(i + frameSize, _txBinary.length)));
    }
    setState(() => _txFrames = frames);
    log('tx', 'Built ${frames.length} frames @ ${frameSize ~/ 8} bytes each');
  }

  Future<void> _exportFrames() async {
    if (_txFrames.isEmpty) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/holoframes.txt');
    await file.writeAsString(_txFrames.join('\n'));
    await Share.shareXFiles([XFile(file.path)], text: 'HoloRadio Frames');
    log('tx', 'Frames exported');
  }

  Future<void> _downloadEncrypted() async {
    final passphrase = _passphraseController.text;
    if (passphrase.isEmpty) { log('tx', 'ERROR: Passphrase required'); return; }
    final text = _textController.text;
    if (text.isEmpty) { log('tx', 'ERROR: No text to encrypt'); return; }
    try {
      final salt = Uint8List.fromList(utf8.encode('HoloRadioSalt_v1'));
      final key = encrypt.Key.fromBase64(base64Encode(_pbkdf2(utf8.encode(passphrase), salt, 100000, 32)));
      final iv = encrypt.IV.fromSecureRandom(12);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      final encrypted = encrypter.encrypt(text, iv: iv);
      final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
      combined.setRange(0, iv.bytes.length, iv.bytes);
      combined.setRange(iv.bytes.length, combined.length, encrypted.bytes);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/holomessage.enc');
      await file.writeAsBytes(combined);
      await Share.shareXFiles([XFile(file.path)], text: 'HoloRadio Encrypted Message');
      log('tx', 'Encrypted file exported: ${combined.length} bytes');
    } catch (e) { log('tx', 'Encryption failed: $e'); }
  }

  List<int> _pbkdf2(List<int> password, List<int> salt, int iterations, int keyLength) {
    var key = password;
    for (int i = 0; i < iterations; i++) { final hmac = Hmac(sha256, key); key = hmac.convert(salt).bytes; }
    return key.sublist(0, keyLength);
  }

  List<double> _generateSignalData() {
    if (_txBinary.isEmpty) _encodeText();
    final rate = int.parse(_sampleRate.split(' ')[0]);
    final freq = int.tryParse(_freqController.text) ?? 1500;
    final baud = int.tryParse(_baudController.text) ?? 300;
    final vol = _volume; final noise = _noise; final mod = _modulation;
    final samplesPerSymbol = (rate / baud).floor();
    final totalSamples = _txBinary.length * samplesPerSymbol;
    final data = List<double>.filled(totalSamples, 0.0);
    List<double> freqs = [], phases = [];
    switch (mod) {
      case 'Binary FSK': freqs = [freq - 500, freq + 500]; break;
      case '4-FSK': freqs = [freq - 750, freq - 250, freq + 250, freq + 750]; break;
      case '8-FSK': for (int i = 0; i < 8; i++) freqs.add(freq - 875 + i * 250); break;
      case 'BPSK': freqs = [freq]; phases = [0, math.pi]; break;
      case 'QPSK': freqs = [freq]; phases = [math.pi / 4, 3 * math.pi / 4, 5 * math.pi / 4, 7 * math.pi / 4]; break;
      case 'OOK': freqs = [0, freq]; break;
      default: freqs = [freq - 500, freq + 500];
    }
    double prevPhase = 0;
    for (int i = 0; i < _txBinary.length; i++) {
      final bit = int.parse(_txBinary[i]);
      double f = freq, phase = 0;
      if (mod == 'Binary FSK') f = freqs[bit];
      else if (mod == 'BPSK') { f = freq; phase = phases[bit]; }
      else if (mod == 'OOK') f = bit > 0 ? freq : 0;
      else if (mod == 'QPSK') { f = freq; final sym = (i % 2 == 0) ? (bit > 0 ? 1 : 0) : (bit > 0 ? 3 : 2); phase = phases[sym % 4]; }
      for (int s = 0; s < samplesPerSymbol; s++) {
        final t = (i * samplesPerSymbol + s) / rate;
        double sample = 0;
        if (mod == 'BPSK') sample = math.sin(2 * math.pi * f * t + phase);
        else if (mod == 'QPSK') sample = math.sin(2 * math.pi * f * t + phase);
        else sample = f > 0 ? math.sin(2 * math.pi * f * t) : 0;
        sample *= vol;
        if (noise > 0) sample += (math.Random().nextDouble() * 2 - 1) * noise;
        data[i * samplesPerSymbol + s] = sample;
      }
    }
    return data;
  }

  Future<void> _transmit() async {
    final signal = _generateSignalData();
    final rate = int.parse(_sampleRate.split(' ')[0]);
    final wavBytes = await _signalToWavBytes(signal, rate);
    final dir = await getTemporaryDirectory();
    final tempFile = File('${dir.path}/temp_tx.wav');
    await tempFile.writeAsBytes(wavBytes);
    log('tx', 'Starting audio transmission...');
    await _audioPlayer.play(DeviceFileSource(tempFile.path));
    log('tx', 'Transmission complete');
  }

  Future<void> _generateWAV() async {
    final signal = _generateSignalData();
    final rate = int.parse(_sampleRate.split(' ')[0]);
    final wavBytes = await _signalToWavBytes(signal, rate);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/holotx.wav');
    await file.writeAsBytes(wavBytes);
    await Share.shareXFiles([XFile(file.path)], text: 'HoloRadio TX WAV');
    log('tx', 'WAV file generated and downloaded');
  }

  Future<Uint8List> _signalToWavBytes(List<double> signal, int sampleRate) async {
    final wavFile = Wav([signal], sampleRate, WavFormat.pcm16);
    final buffer = BytesBuilder();
    wavFile.write(buffer);
    return buffer.toBytes();
  }

  void _showConstellation() {
    showDialog(context: context,
      builder: (context) => Dialog(backgroundColor: HoloTheme.panelBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: Container(padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(border: Border.all(color: HoloTheme.cyan), boxShadow: [BoxShadow(color: HoloTheme.cyanDim, blurRadius: 40)]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Row(children: [
              Text('◆', style: TextStyle(color: HoloTheme.cyan, fontSize: 10)),
              SizedBox(width: 8),
              Text('CONSTELLATION DIAGRAM', style: TextStyle(color: HoloTheme.cyan, fontSize: 12, letterSpacing: 3, fontFamily: 'Courier')),
            ]),
            const SizedBox(height: 15),
            SizedBox(width: 400, height: 200, child: CustomPaint(painter: ConstellationPainter(mod: _modulation))),
            const SizedBox(height: 15),
            HoloButton(label: 'CLOSE', onPressed: () => Navigator.pop(context)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: HoloPanel(title: 'Text Input', children: [
          HoloTextField(maxLines: 5, controller: _textController),
          const SizedBox(height: 10),
          Wrap(spacing: 10, children: [
            HoloButton(label: 'ENCODE', onPressed: _encodeText),
            HoloButton(label: 'CLEAR', onPressed: _clearTx),
            HoloButton(label: 'SAMPLE', onPressed: _loadSample),
          ]),
        ])),
        const SizedBox(width: 15),
        Expanded(child: HoloPanel(title: 'Binary Output', children: [
          HoloDisplayBox(text: _txBinary.isEmpty ? 'Awaiting encoding...' : _txBinary),
          const SizedBox(height: 10),
          Wrap(spacing: 10, children: [
            HoloButton(label: 'COPY BINARY', onPressed: _copyBinary),
            HoloButton(label: 'EXPORT BIN', onPressed: _downloadBinary),
          ]),
        ])),
      ]),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: HoloPanel(title: 'Frame Builder', children: [
          HoloDisplayBox(text: _txFrames.isEmpty ? 'No frames generated' : 'Generated ${_txFrames.length} frames'),
          const SizedBox(height: 10),
          Wrap(spacing: 10, children: [
            HoloButton(label: 'BUILD FRAMES', onPressed: _buildFrames),
            HoloButton(label: 'EXPORT FRAMES', onPressed: _exportFrames),
          ]),
        ])),
        const SizedBox(width: 15),
        Expanded(child: HoloPanel(title: 'Packet Monitor', children: [
          Container(constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(shrinkWrap: true,
              itemCount: _txFrames.isEmpty ? 1 : _txFrames.length,
              itemBuilder: (context, index) {
                if (_txFrames.isEmpty) return const _PacketItem(label: 'No packets');
                return _PacketItem(label: 'FRAME ${(index + 1).toString().padLeft(3, '0')}', detail: '${_txFrames[index].length} bits', isOk: true);
              },
            ),
          ),
        ])),
      ]),
      HoloPanel(title: 'Security Layer', children: [
        Row(children: [
          Expanded(child: HoloToggle(label: 'ENCRYPTION OFF', onChanged: (v) => setState(() => _encryptionOn = v))),
          const SizedBox(width: 15),
          Expanded(child: HoloTextField(label: 'Passphrase', hint: 'Enter key...', obscureText: true, enabled: _encryptionOn, controller: _passphraseController)),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Key Status', style: TextStyle(fontSize: 11, color: HoloTheme.cyan.withOpacity(0.5), fontFamily: 'Courier')),
            const SizedBox(height: 5),
            Container(height: 36, padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), border: Border.all(color: HoloTheme.border)),
              alignment: Alignment.centerLeft,
              child: Text(_encryptionOn ? 'Awaiting key input...' : 'No key loaded',
                style: TextStyle(color: _encryptionOn ? HoloTheme.yellow : HoloTheme.cyan.withOpacity(0.5), fontFamily: 'Courier', fontSize: 12)),
            ),
          ])),
          const SizedBox(width: 15),
          Expanded(child: HoloButton(label: '⬇ DOWNLOAD ENCRYPTED (.ENC)', isPrimary: true, disabled: !_encryptionOn, onPressed: _downloadEncrypted)),
        ]),
      ]),
      HoloPanel(title: 'Transmission Controls', children: [
        Row(children: [
          Expanded(child: HoloDropdown(label: 'Modulation',
            items: const ['Binary FSK', '4-FSK', '8-FSK', '16-FSK', 'BPSK', 'QPSK', '8PSK', 'OOK', 'ASK', 'MSK', 'GMSK', 'MFSK', 'Differential BPSK', 'Differential QPSK'],
            onChanged: (v) => setState(() => _modulation = v ?? 'Binary FSK'))),
          const SizedBox(width: 15),
          Expanded(child: HoloDropdown(label: 'Sample Rate', items: const ['8000 Hz', '16000 Hz', '22050 Hz', '44100 Hz', '48000 Hz'],
            value: _sampleRate, onChanged: (v) => setState(() => _sampleRate = v ?? '22050 Hz'))),
          const SizedBox(width: 15),
          Expanded(child: HoloTextField(label: 'Center Freq (Hz)', controller: _freqController, keyboardType: TextInputType.number)),
          const SizedBox(width: 15),
          Expanded(child: HoloTextField(label: 'Symbol Rate', controller: _baudController, keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: HoloTextField(label: 'Frame Size (bytes)', controller: _frameSizeController, keyboardType: TextInputType.number)),
          const SizedBox(width: 15),
          Expanded(child: HoloSlider(label: 'Volume', value: _volume, onChanged: (v) => setState(() => _volume = v))),
          const SizedBox(width: 15),
          Expanded(child: HoloSlider(label: 'Noise Level', value: _noise, onChanged: (v) => setState(() => _noise = v))),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Checkbox(value: true, onChanged: (_) {}, fillColor: WidgetStateProperty.all(HoloTheme.cyan)),
              const Text('CRC-16', style: TextStyle(color: HoloTheme.cyan, fontFamily: 'Courier', fontSize: 12))]),
            Row(children: [Checkbox(value: false, onChanged: (_) {}, fillColor: WidgetStateProperty.all(HoloTheme.cyan)),
              const Text('FEC', style: TextStyle(color: HoloTheme.cyan, fontFamily: 'Courier', fontSize: 12))]),
          ])),
        ]),
        const SizedBox(height: 15),
        Wrap(spacing: 10, children: [
          HoloButton(label: '▶ TRANSMIT AUDIO', isPrimary: true, onPressed: _transmit),
          HoloButton(label: '⬇ GENERATE WAV', isPrimary: true, onPressed: _generateWAV),
          HoloButton(label: 'CONSTELLATION', onPressed: _showConstellation),
        ]),
      ]),
      Row(children: [
        Expanded(child: HoloPanel(title: 'Spectrum Analyzer', children: [
          SizedBox(height: 150, child: CustomPaint(size: Size.infinite, painter: SpectrumPainter())),
        ])),
        const SizedBox(width: 15),
        Expanded(child: HoloPanel(title: 'Waterfall Display', children: [
          SizedBox(height: 150, child: CustomPaint(size: Size.infinite, painter: WaterfallPainter())),
        ])),
      ]),
      Row(children: [
        Expanded(child: HoloPanel(title: 'Oscilloscope', children: [
          SizedBox(height: 150, child: CustomPaint(size: Size.infinite, painter: OscilloscopePainter())),
        ])),
        const SizedBox(width: 15),
        Expanded(child: HoloPanel(title: 'Bit Stream', children: [
          SizedBox(height: 150, child: CustomPaint(size: Size.infinite, painter: BitStreamPainter(binary: _txBinary))),
        ])),
      ]),
      HoloPanel(title: 'System Log', children: [LogBox(key: _txLogKey, logId: 'tx')]),
    ]);
  }
}

class ReceiverScreen extends StatefulWidget {
  const ReceiverScreen({super.key});
  @override
  State<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  final _record = AudioRecorder();
  bool _isRecording = false;
  String _rxText = 'Awaiting decode...';
  String _rxBinary = 'No data received';
  bool _decryptionOn = false;
  final _passphraseController = TextEditingController();
  double _bufferLevel = 0.0;
  bool _syncActive = false;
  bool _crcActive = false;
  bool _receivingActive = false;
  Uint8List? _rxEncBuffer;
  final GlobalKey<_LogBoxState> _rxLogKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rxLogKey.currentState != null) _loggers['rx'] = _rxLogKey.currentState!;
      log('rx', 'Receiver ready');
    });
  }

  @override
  void dispose() { _record.dispose(); _passphraseController.dispose(); super.dispose(); }

  Future<void> _toggleMic() async {
    if (_isRecording) {
      final path = await _record.stop();
      setState(() => _isRecording = false);
      _receivingActive = false;
      log('rx', 'Microphone stopped');
      if (path != null) {
        final file = File(path);
        final bytes = await file.readAsBytes();
        try {
          final wav = Wav.read(bytes);
          if (wav.channels.isNotEmpty) {
            setState(() { _rxBinary = wav.channels[0].map((s) => s > 0 ? '1' : '0').join(); _bufferLevel = 1.0; });
          }
        } catch (e) { log('rx', 'WAV parse error: $e'); }
      }
      return;
    }
    if (await _record.hasPermission()) {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/rx_recording.wav';
      await _record.start(const RecordConfig(), path: path);
      setState(() { _isRecording = true; _receivingActive = true; });
      log('rx', 'Microphone active');
    } else { log('rx', 'Mic permission denied'); }
  }

  Future<void> _loadWAV() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['wav'], withData: true);
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        try {
          final wav = Wav.read(file.bytes!);
          if (wav.channels.isNotEmpty) {
            setState(() { _rxBinary = wav.channels[0].map((s) => s > 0 ? '1' : '0').join(); _bufferLevel = 1.0; });
            log('rx', 'Loaded WAV: ${wav.channels[0].length} samples');
          }
        } catch (e) { log('rx', 'WAV load error: $e'); }
      }
    }
  }

  void _decodeRx() {
    if (_rxBinary == 'No data received' || _rxBinary.isEmpty) { log('rx', 'No signal to decode'); return; }
    String text = '';
    for (int i = 0; i < _rxBinary.length; i += 8) {
      final byte = _rxBinary.substring(i, math.min(i + 8, _rxBinary.length));
      if (byte.length == 8) text += String.fromCharCode(int.parse(byte, radix: 2));
    }
    setState(() { _rxText = text.isEmpty ? 'Decode error' : text; _syncActive = true; _crcActive = true; });
    log('rx', 'Decode complete');
  }

  void _stopRx() {
    if (_isRecording) { _record.stop(); setState(() => _isRecording = false); }
    setState(() { _rxBinary = 'No data received'; _bufferLevel = 0.0; _syncActive = false; _crcActive = false; _receivingActive = false; });
    log('rx', 'Receiver stopped');
  }

  Future<void> _downloadRxWAV() async {
    if (_rxBinary == 'No data received') { log('rx', 'No RX data to export'); return; }
    final samples = _rxBinary.split('').map((b) => b == '1' ? 0.8 : -0.8).toList();
    final wavFile = Wav([samples], 44100, WavFormat.pcm16);
    final buffer = BytesBuilder(); wavFile.write(buffer);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/holorx.wav');
    await file.writeAsBytes(buffer.toBytes());
    await Share.shareXFiles([XFile(file.path)], text: 'HoloRadio RX WAV');
    log('rx', 'RX WAV exported');
  }

  Future<void> _copyRxBinary() async {
    if (_rxBinary != 'No data received') { await Clipboard.setData(ClipboardData(text: _rxBinary)); log('rx', 'RX binary copied'); }
  }

  Future<void> _copyRxText() async {
    if (_rxText != 'Awaiting decode...') { await Clipboard.setData(ClipboardData(text: _rxText)); log('rx', 'RX text copied'); }
  }

  Future<void> _saveRxText() async {
    if (_rxText == 'Awaiting decode...') return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/holod_rx.txt');
    await file.writeAsString(_rxText);
    await Share.shareXFiles([XFile(file.path)], text: 'HoloRadio RX Text');
    log('rx', 'RX text saved');
  }

  Future<void> _loadEncFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['enc', 'bin'], withData: true);
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) { setState(() => _rxEncBuffer = file.bytes); log('rx', 'Encrypted file loaded: ${file.bytes!.length} bytes'); }
    }
  }

  Future<void> _attemptDecrypt() async {
    final passphrase = _passphraseController.text;
    if (passphrase.isEmpty) { log('rx', 'ERROR: No passphrase'); return; }
    if (_rxEncBuffer == null) { log('rx', 'No encrypted file loaded'); return; }
    try {
      final salt = Uint8List.fromList(utf8.encode('HoloRadioSalt_v1'));
      final key = encrypt.Key.fromBase64(base64Encode(_pbkdf2(utf8.encode(passphrase), salt, 100000, 32)));
      final iv = encrypt.IV(Uint8List.fromList(_rxEncBuffer!.sublist(0, 12)));
      final ciphertext = _rxEncBuffer!.sublist(12);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      final decrypted = encrypter.decrypt64(base64Encode(ciphertext), iv: iv);
      setState(() => _rxText = decrypted);
      log('rx', 'Decryption successful • Message recovered');
    } catch (e) { log('rx', 'Decryption failed: $e'); }
  }

  List<int> _pbkdf2(List<int> password, List<int> salt, int iterations, int keyLength) {
    var key = password;
    for (int i = 0; i < iterations; i++) { final hmac = Hmac(sha256, key); key = hmac.convert(salt).bytes; }
    return key.sublist(0, keyLength);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: HoloPanel(title: 'Signal Input', children: [
          Wrap(spacing: 10, children: [
            HoloButton(label: _isRecording ? '⏹ STOP MIC' : '🎤 START MIC', isPrimary: !_isRecording, isDanger: _isRecording, onPressed: _toggleMic),
            HoloButton(label: '📁 LOAD WAV', onPressed: _loadWAV),
            HoloButton(label: '🔓 DECODE', isPrimary: true, onPressed: _decodeRx),
            HoloButton(label: '⬇ DOWNLOAD WAV', onPressed: _downloadRxWAV),
            HoloButton(label: '📋 COPY BINARY', onPressed: _copyRxBinary),
            HoloButton(label: '⏹ STOP', isDanger: true, onPressed: _stopRx),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Text('BUFFER:', style: TextStyle(fontSize: 12, color: HoloTheme.cyan.withOpacity(0.5), fontFamily: 'Courier')),
            const SizedBox(width: 10),
            Expanded(child: HoloMeter(value: _bufferLevel, height: 12)),
            const SizedBox(width: 10),
            Text('${(_bufferLevel * 10).toStringAsFixed(1)}s', style: TextStyle(fontSize: 12, color: HoloTheme.cyan.withOpacity(0.5), fontFamily: 'Courier')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _StatusDot(label: 'SYNC', active: _syncActive), const SizedBox(width: 15),
            _StatusDot(label: 'CRC', active: _crcActive), const SizedBox(width: 15),
            _StatusDot(label: 'RECEIVING', active: _receivingActive),
          ]),
        ])),
        const SizedBox(width: 15),
        Expanded(child: HoloPanel(title: 'Decoded Text', children: [
          HoloDisplayBox(text: _rxText),
          const SizedBox(height: 10),
          Wrap(spacing: 10, children: [
            HoloButton(label: 'COPY TEXT', onPressed: _copyRxText),
            HoloButton(label: 'SAVE TXT', onPressed: _saveRxText),
          ]),
        ])),
      ]),
      HoloPanel(title: 'Decryption Layer', children: [
        Row(children: [
          Expanded(child: HoloToggle(label: 'DECRYPTION OFF', onChanged: (v) => setState(() => _decryptionOn = v))),
          const SizedBox(width: 15),
          Expanded(child: HoloTextField(label: 'Passphrase', hint: 'Enter key...', obscureText: true, enabled: _decryptionOn, controller: _passphraseController)),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Decryption Status', style: TextStyle(fontSize: 11, color: HoloTheme.cyan.withOpacity(0.5), fontFamily: 'Courier')),
            const SizedBox(height: 5),
            Container(height: 36, padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), border: Border.all(color: HoloTheme.border)),
              alignment: Alignment.centerLeft,
              child: Text(_decryptionOn ? 'Awaiting key input...' : 'No decryption active',
                style: TextStyle(color: _decryptionOn ? HoloTheme.yellow : HoloTheme.cyan.withOpacity(0.5), fontFamily: 'Courier', fontSize: 12)),
            ),
          ])),
          const SizedBox(width: 15),
          Expanded(child: HoloButton(label: '🔓 DECRYPT BUFFER', isPrimary: true, disabled: !_decryptionOn, onPressed: _attemptDecrypt)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          HoloButton(label: '📁 LOAD ENC FILE', onPressed: _loadEncFile),
          const SizedBox(width: 10),
          Text(_rxEncBuffer != null ? 'Loaded: ${_rxEncBuffer!.length} bytes' : 'No encrypted file loaded',
            style: TextStyle(fontSize: 12, color: HoloTheme.cyan.withOpacity(0.5), fontFamily: 'Courier')),
        ]),
      ]),
      Row(children: [
        Expanded(child: HoloPanel(title: 'Binary Input', children: [HoloDisplayBox(text: _rxBinary)])),
        const SizedBox(width: 15),
        Expanded(child: HoloPanel(title: 'Packet Log', children: [
          Container(constraints: const BoxConstraints(maxHeight: 200),
            child: ListView(shrinkWrap: true, children: const [_PacketItem(label: 'No packets')]),
          ),
        ])),
      ]),
      Row(children: [
        Expanded(child: HoloPanel(title: 'Signal Scope', children: [
          SizedBox(height: 150, child: CustomPaint(size: Size.infinite, painter: OscilloscopePainter())),
        ])),
        const SizedBox(width: 15),
        Expanded(child: HoloPanel(title: 'Constellation', children: [
          SizedBox(height: 150, child: CustomPaint(size: Size.infinite, painter: ConstellationPainter(mod: 'QPSK'))),
        ])),
      ]),
      HoloPanel(title: 'Receiver Log', children: [LogBox(key: _rxLogKey, logId: 'rx')]),
    ]);
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      HoloPanel(title: 'System Configuration', children: [
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(width: 200, child: HoloDropdown(label: 'Audio Output Device', items: const ['Default'])),
          SizedBox(width: 200, child: HoloSlider(label: 'Input Gain (dB)', value: 0.5)),
          SizedBox(width: 200, child: HoloDropdown(label: 'AGC', items: const ['Fast', 'Slow', 'Off'])),
          SizedBox(width: 200, child: HoloTextField(label: 'Squelch (dB)', controller: TextEditingController(text: '-40'))),
          SizedBox(width: 200, child: HoloTextField(label: 'Preamble Length', controller: TextEditingController(text: '64'))),
          SizedBox(width: 200, child: HoloTextField(label: 'Postamble Length', controller: TextEditingController(text: '32'))),
        ]),
      ]),
      HoloPanel(title: 'Encryption Defaults', children: [
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(width: 200, child: HoloDropdown(label: 'Algorithm', items: const ['AES-GCM-256', 'ChaCha20-Poly1305'])),
          SizedBox(width: 200, child: HoloDropdown(label: 'Key Derivation', items: const ['PBKDF2 (100k iter)', 'Argon2id (sim)'])),
        ]),
      ]),
    ]);
  }
}

class AnalyzerScreen extends StatefulWidget {
  const AnalyzerScreen({super.key});
  @override
  State<AnalyzerScreen> createState() => _AnalyzerScreenState();
}

class _AnalyzerScreenState extends State<AnalyzerScreen> {
  double _snr = 0; double _ber = 0; String _lock = 'UNLOCKED'; Timer? _updateTimer;
  @override
  void initState() {
    super.initState();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() { _snr = 15 + math.Random().nextDouble() * 10; _ber = math.Random().nextDouble() * 0.01; _lock = math.Random().nextBool() ? 'LOCKED' : 'UNLOCKED'; });
    });
  }
  @override
  void dispose() { _updateTimer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Expanded(child: HoloPanel(title: 'Frequency Domain', children: [
          SizedBox(height: 200, child: CustomPaint(size: Size.infinite, painter: SpectrumPainter())),
        ])),
        const SizedBox(width: 15),
        Expanded(child: HoloPanel(title: 'Spectrogram', children: [
          SizedBox(height: 200, child: CustomPaint(size: Size.infinite, painter: WaterfallPainter())),
        ])),
      ]),
      HoloPanel(title: 'Statistics', children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _StatItem(label: 'SNR', value: '${_snr.toStringAsFixed(1)} dB'),
          _StatItem(label: 'BER', value: _ber.toStringAsFixed(4)),
          _StatItem(label: 'FER', value: '--'),
          _StatItem(label: 'Lock', value: _lock),
        ]),
      ]),
    ]);
  }
}

class _PacketItem extends StatelessWidget {
  final String label; final String? detail; final bool isOk;
  const _PacketItem({required this.label, this.detail, this.isOk = true});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: HoloTheme.cyan.withOpacity(0.1)))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: isOk ? HoloTheme.green : HoloTheme.red, fontFamily: 'Courier', fontSize: 12)),
        if (detail != null) Text(detail!, style: TextStyle(color: HoloTheme.cyan.withOpacity(0.5), fontFamily: 'Courier', fontSize: 12)),
      ]),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String label; final bool active;
  const _StatusDot({required this.label, this.active = false});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle,
          color: active ? HoloTheme.green : HoloTheme.cyanDim,
          boxShadow: active ? [BoxShadow(color: HoloTheme.green, blurRadius: 8)] : [BoxShadow(color: HoloTheme.cyanDim, blurRadius: 5)],
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: HoloTheme.cyan, fontFamily: 'Courier', fontSize: 11)),
    ]);
  }
}

class _StatItem extends StatelessWidget {
  final String label; final String value;
  const _StatItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Text('$label: $value', style: const TextStyle(color: HoloTheme.cyan, fontFamily: 'Courier', fontSize: 13));
}

class SpectrumPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = HoloTheme.cyan..strokeWidth = 1;
    final random = math.Random(42);
    final path = Path()..moveTo(0, size.height);
    for (double x = 0; x < size.width; x += 2) { final y = size.height - (random.nextDouble() * size.height * 0.6); path.lineTo(x, y); }
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WaterfallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); final paint = Paint();
    for (double x = 0; x < size.width; x += 2) {
      final val = random.nextDouble();
      paint.color = HoloTheme.cyan.withOpacity(val * 0.3);
      final barH = val * size.height;
      canvas.drawRect(Rect.fromLTWH(x, size.height - barH, 2, barH), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter) => false;
}

class OscilloscopePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = HoloTheme.green..strokeWidth = 1;
    final path = Path()..moveTo(0, size.height / 2);
    for (double x = 0; x < size.width; x++) { final y = size.height / 2 + math.sin(x * 0.05) * size.height / 3; path.lineTo(x, y); }
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BitStreamPainter extends CustomPainter {
  final String binary;
  BitStreamPainter({this.binary = ''});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.black);
    if (binary.isEmpty) return;
    final paint = Paint()..color = HoloTheme.cyan;
    final bitsToShow = math.min(binary.length, (size.width / 4).floor());
    for (int i = 0; i < bitsToShow; i++) {
      final x = i * 4.0; final bit = int.tryParse(binary[i]) ?? 0;
      canvas.drawRect(Rect.fromLTWH(x, bit > 0 ? 2 : size.height / 2 + 2, 2, size.height / 2 - 4), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ConstellationPainter extends CustomPainter {
  final String mod;
  ConstellationPainter({this.mod = 'QPSK'});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.black.withOpacity(0.6));
    final gridPaint = Paint()..color = HoloTheme.cyan.withOpacity(0.3)..strokeWidth = 1;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), gridPaint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), gridPaint);
    List<List<double>> points = [];
    if (mod == 'QPSK' || mod == 'Differential QPSK') points = [[1, 1], [1, -1], [-1, 1], [-1, -1]];
    else if (mod == 'BPSK' || mod == 'Differential BPSK') points = [[1, 0], [-1, 0]];
    else if (mod.contains('FSK')) points = [[0, 1], [0, -1], [1, 0], [-1, 0]];
    final pointPaint = Paint()..color = HoloTheme.green;
    for (final p in points) { canvas.drawCircle(Offset(size.width / 2 + p[0] * 40, size.height / 2 - p[1] * 40), 6, pointPaint); }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
