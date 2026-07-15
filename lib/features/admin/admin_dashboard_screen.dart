import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:nusa_admin/core/theme.dart';
import 'package:nusa_admin/features/admin/admin_repository.dart';

final _dateFmt = DateFormat('d MMM yy HH:mm', 'id_ID');
String _fmtDate(String iso) { try { return _dateFmt.format(DateTime.parse(iso).toLocal()); } catch (_) { return iso; } }

Color _statusColor(String s) => switch (s) {
  'Generated' => NusaTheme.statusGenerated, 'Trial' => NusaTheme.statusTrial,
  'Active' => NusaTheme.statusActive, 'Cancelled' => NusaTheme.statusCancelled,
  'Expired' => NusaTheme.statusExpired, 'Suspended' => NusaTheme.statusSuspended,
  _ => NusaTheme.textSecondary,
};

String _statusLabel(String s) => switch (s) {
  'Generated' => 'Tersedia', 'Trial' => 'Trial', 'Active' => 'Aktif',
  'Cancelled' => 'Dibatalkan', 'Expired' => 'Kadaluarsa', 'Suspended' => 'Ditangguhkan',
  _ => s,
};

// ═══════════════════════════════════════════════════════════════════════
// Main Screen
// ═══════════════════════════════════════════════════════════════════════

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

enum _Tab { overview, licenses, generate }

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  _Tab _tab = _Tab.overview;
  bool _checking = true;
  bool _authed = false;

  @override
  void initState() {
    super.initState();
    _checkStoredKey();
  }

  Future<void> _checkStoredKey() async {
    final key = await AdminRepository.getStoredKey();
    if (key != null) {
      try {
        final ok = await AdminRepository.verifyAdminKey(key);
        if (mounted) setState(() { _authed = ok; _checking = false; });
      } catch (e) {
        // Network/server error — show login screen with error
        if (mounted) {
          setState(() => _checking = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal terhubung: $e'), backgroundColor: NusaTheme.primaryColor, duration: const Duration(seconds: 3)),
          );
        }
      }
    } else {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _login(String key) async {
    try {
      final ok = await AdminRepository.verifyAdminKey(key);
      if (ok) {
        await AdminRepository.saveKey(key);
        if (mounted) setState(() => _authed = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin key tidak valid'), backgroundColor: NusaTheme.primaryColor, duration: Duration(seconds: 2)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal terhubung ke server: $e'), backgroundColor: NusaTheme.primaryColor, duration: const Duration(seconds: 3)),
        );
      }
    }
  }

  Future<void> _logout() async {
    await AdminRepository.clearKey();
    if (mounted) setState(() => _authed = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_authed) return _LoginView(onLogin: _login);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [NusaTheme.primaryColor, NusaTheme.primaryDark]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text('N', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('NUSA Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                  TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Logout', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: NusaTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Tab bar
            _TabBar(selected: _tab, onChanged: (t) => setState(() => _tab = t)),
            const Divider(height: 1),
            // Body
            Expanded(
              child: switch (_tab) {
                _Tab.overview => const _OverviewTab(),
                _Tab.licenses => const _LicensesTab(),
                _Tab.generate => const _GenerateTab(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Login View
// ═══════════════════════════════════════════════════════════════════════

class _LoginView extends StatefulWidget {
  final Future<void> Function(String) onLogin;
  const _LoginView({required this.onLogin});
  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final key = _ctrl.text.trim();
    if (key.isEmpty) return;
    setState(() => _loading = true);
    await widget.onLogin(key);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NusaTheme.bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [NusaTheme.primaryColor, NusaTheme.primaryDark]),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: NusaTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                alignment: Alignment.center,
                child: const Text('N', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 20),
              const Text('NUSA Admin', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: NusaTheme.textPrimary)),
              const SizedBox(height: 6),
              const Text('Manajemen Lisensi Aktivasi', style: TextStyle(fontSize: 14, color: NusaTheme.textSecondary)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NusaTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Admin Key', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: NusaTheme.textSecondary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ctrl, obscureText: true,
                      onSubmitted: (_) => _submit(),
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Masukkan admin key...',
                        hintStyle: const TextStyle(color: NusaTheme.textTertiary, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: NusaTheme.dividerColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: NusaTheme.dividerColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: NusaTheme.primaryColor)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(backgroundColor: NusaTheme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Login'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Tab Bar
// ═══════════════════════════════════════════════════════════════════════

class _TabBar extends StatelessWidget {
  final _Tab selected;
  final ValueChanged<_Tab> onChanged;
  const _TabBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _TabChip(label: 'Overview',  value: _Tab.overview, selected: selected, onChanged: onChanged),
          const SizedBox(width: 8),
          _TabChip(label: 'Lisensi',   value: _Tab.licenses, selected: selected, onChanged: onChanged),
          const SizedBox(width: 8),
          _TabChip(label: 'Generate',  value: _Tab.generate, selected: selected, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final _Tab value, selected;
  final ValueChanged<_Tab> onChanged;
  const _TabChip({required this.label, required this.value, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final active = selected == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? NusaTheme.primaryColor : NusaTheme.borderColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : NusaTheme.textSecondary)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Overview Tab
// ═══════════════════════════════════════════════════════════════════════

class _OverviewTab extends StatefulWidget {
  const _OverviewTab();
  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  LicenseStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final stats = await AdminRepository.getStats();
      if (mounted) setState(() { _stats = stats; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _ShimmerOverview();

    if (_error != null) return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, size: 48, color: NusaTheme.primaryColor.withValues(alpha: 0.5)),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: NusaTheme.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh, size: 18), label: const Text('Coba Lagi'), style: ElevatedButton.styleFrom(backgroundColor: NusaTheme.primaryColor, foregroundColor: Colors.white)),
      ]),
    );

    final stats = _stats!;
    final statusCards = [
      ('Tersedia', stats.generated, NusaTheme.statusGenerated, Icons.auto_awesome_outlined),
      ('Trial', stats.trial, NusaTheme.statusTrial, Icons.timer_outlined),
      ('Aktif', stats.active, NusaTheme.statusActive, Icons.check_circle_outline),
      ('Dibatalkan', stats.cancelled, NusaTheme.statusCancelled, Icons.cancel_outlined),
      ('Kadaluarsa', stats.expired, NusaTheme.statusExpired, Icons.schedule_outlined),
      ('Ditangguhkan', stats.suspended, NusaTheme.statusSuspended, Icons.block_outlined),
    ];
    final activityCards = [
      ('Total Lisensi', stats.total, NusaTheme.accentBlue, Icons.inventory_2_outlined),
      ('Total Aktivasi', stats.totalActivations, NusaTheme.accentPurple, Icons.devices_outlined),
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 4 : 2;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Status Lisensi section ──
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('Status Lisensi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: NusaTheme.textSecondary, letterSpacing: 0.5)),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.6),
            itemCount: statusCards.length,
            itemBuilder: (_, i) {
              final c = statusCards[i];
              return _StatCard(label: c.$1, value: c.$2, color: c.$3, icon: c.$4);
            },
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          // ── Aktivitas section ──
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('Aktivitas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: NusaTheme.textSecondary, letterSpacing: 0.5)),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.6),
            itemCount: activityCards.length,
            itemBuilder: (_, i) {
              final c = activityCards[i];
              return _StatCard(label: c.$1, value: c.$2, color: c.$3, icon: c.$4);
            },
          ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton loader for overview cards.
class _ShimmerOverview extends StatefulWidget {
  const _ShimmerOverview();
  @override
  State<_ShimmerOverview> createState() => _ShimmerOverviewState();
}

class _ShimmerOverviewState extends State<_ShimmerOverview> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _anim = Tween<double>(begin: -2, end: 2).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 4 : 2;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _shimmerBlock(80, 14),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.6),
            itemCount: 6,
            itemBuilder: (_, __) => _shimmerBlock(double.infinity, double.infinity),
          ),
          const SizedBox(height: 24),
          _shimmerBlock(60, 14),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.6),
            itemCount: 2,
            itemBuilder: (_, __) => _shimmerBlock(double.infinity, double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBlock(double w, double h) {
    return Container(
      width: w, height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment(_anim.value - 1, 0),
          end: Alignment(_anim.value + 1, 0),
          colors: const [Color(0xFFE5E7EB), Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
              Text('$value', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color, height: 1)),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: NusaTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Licenses Tab
// ═══════════════════════════════════════════════════════════════════════

class _LicensesTab extends StatefulWidget {
  const _LicensesTab();
  @override
  State<_LicensesTab> createState() => _LicensesTabState();
}

class _LicensesTabState extends State<_LicensesTab> {
  final _searchCtrl = TextEditingController();
  String? _statusFilter;
  String? _searchQuery;
  String? _error;
  bool _loading = true;
  LicenseListResponse? _resp;
  int _page = 0;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await AdminRepository.listLicenses(page: _page, status: _statusFilter, search: _searchQuery);
      if (mounted) setState(() { _resp = resp; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  void _applySearch() {
    final s = _searchCtrl.text.trim();
    _searchQuery = s.isNotEmpty ? s : null;
    _page = 0;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: NusaTheme.dividerColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _statusFilter,
                      isExpanded: true,
                      hint: const Text('Semua Status', style: TextStyle(fontSize: 13)),
                      style: const TextStyle(fontSize: 13, color: NusaTheme.textPrimary),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Semua Status', style: TextStyle(fontSize: 13))),
                        ...['Generated','Trial','Active','Cancelled','Expired','Suspended'].map((s) => DropdownMenuItem(value: s, child: Text(_statusLabel(s), style: const TextStyle(fontSize: 13)))),
                      ],
                      onChanged: (v) { setState(() => _statusFilter = v); _page = 0; _load(); },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) => _applySearch(),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Cari key atau email...',
                      hintStyle: const TextStyle(color: NusaTheme.textTertiary, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      suffixIcon: GestureDetector(onTap: _applySearch, child: const Icon(Icons.search, size: 20, color: NusaTheme.primaryColor)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: NusaTheme.dividerColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: NusaTheme.dividerColor)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: NusaTheme.textSecondary), textAlign: TextAlign.center)))
                  : _resp == null || _resp!.licenses.isEmpty
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.search_off_rounded, size: 56, color: NusaTheme.textTertiary.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text('Tidak ada lisensi ditemukan.', style: TextStyle(color: NusaTheme.textTertiary, fontSize: 14)),
                            const SizedBox(height: 4),
                            const Text('Coba ubah filter atau kata kunci pencarian.', style: TextStyle(color: NusaTheme.textTertiary, fontSize: 12)),
                          ]),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            itemCount: _resp!.licenses.length + 1,
                            itemBuilder: (_, i) {
                              if (i < _resp!.licenses.length) {
                                return _LicenseTile(lic: _resp!.licenses[i], onChanged: _load);
                              }
                              final totalPages = (_resp!.total / 30).ceil();
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _PageBtn(
                                      icon: Icons.chevron_left,
                                      onTap: _page > 0 ? () { _page--; _load(); } : null,
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(color: NusaTheme.borderColor, borderRadius: BorderRadius.circular(10)),
                                      child: Text('${_page + 1} / ${totalPages > 0 ? totalPages : 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: NusaTheme.textSecondary)),
                                    ),
                                    const SizedBox(width: 4),
                                    _PageBtn(
                                      icon: Icons.chevron_right,
                                      onTap: (_page + 1) < totalPages ? () { _page++; _load(); } : null,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// License Tile
// ═══════════════════════════════════════════════════════════════════════

class _LicenseTile extends StatelessWidget {
  final LicenseRecord lic;
  final VoidCallback onChanged;
  const _LicenseTile({required this.lic, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor(lic.status);
    final keyShort = lic.key.length > 22 ? '${lic.key.substring(0, 22)}...' : lic.key;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NusaTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(keyShort, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w600))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: sc.withValues(alpha: 0.3))),
                child: Text(_statusLabel(lic.status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sc)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (lic.ownerEmail != null && lic.ownerEmail!.isNotEmpty) ...[
                const Icon(Icons.email_outlined, size: 13, color: NusaTheme.textTertiary),
                const SizedBox(width: 4),
                Flexible(child: Text(lic.ownerEmail!, style: const TextStyle(fontSize: 12, color: NusaTheme.textSecondary), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 12),
              ],
              const Icon(Icons.devices, size: 13, color: NusaTheme.textTertiary),
              const SizedBox(width: 4),
              Text('${lic.activationCount} aktivasi', style: const TextStyle(fontSize: 12, color: NusaTheme.textSecondary)),
              const Spacer(),
              Text(_fmtDate(lic.createdAt), style: const TextStyle(fontSize: 11, color: NusaTheme.textTertiary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ActionBtn(label: 'Detail', color: NusaTheme.textSecondary, onTap: () => _showDetail(context, lic.id, onChanged)),
              const SizedBox(width: 6),
              if (lic.status != 'Cancelled' && lic.status != 'Expired' && lic.status != 'Suspended')
                _ActionBtn(label: 'Cancel', color: NusaTheme.primaryColor, onTap: () => _confirmCancel(context, lic.id, onChanged)),
              if (lic.status == 'Generated' && lic.activationCount == 0) ...[
                const SizedBox(width: 6),
                _ActionBtn(label: 'Hapus', color: Colors.red, onTap: () => _confirmDelete(context, lic.id, onChanged)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ActionBtn({required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Detail Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════

Future<void> _showDetail(BuildContext parentContext, String id, VoidCallback onChanged) async {
  try {
    final detail = await AdminRepository.getLicenseDetail(id);
    if (!parentContext.mounted) return;
    _showDetailSheet(parentContext, detail);
  } catch (e) {
    if (parentContext.mounted) {
      ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: NusaTheme.primaryColor));
    }
  }
}

void _showDetailSheet(BuildContext context, LicenseDetail detail) {
  final sc = _statusColor(detail.status);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.3, expand: false,
      builder: (ctx, scrollCtrl) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: ListView(
          controller: scrollCtrl,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: NusaTheme.dividerColor, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: sc.withValues(alpha: 0.3))),
                  child: Text(_statusLabel(detail.status), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sc)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () { Clipboard.setData(ClipboardData(text: detail.key)); ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Key disalin'), duration: Duration(seconds: 1))); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: NusaTheme.borderColor, borderRadius: BorderRadius.circular(8)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.copy, size: 14, color: NusaTheme.primaryColor),
                      SizedBox(width: 4),
                      Text('Salin', style: TextStyle(fontSize: 12, color: NusaTheme.primaryColor, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Dtl('Key', detail.key, mono: true),
            _Dtl('Serial', detail.serial),
            _Dtl('Produk', detail.product),
            if (detail.ownerEmail != null && detail.ownerEmail!.isNotEmpty) _Dtl('Pemilik', detail.ownerEmail!),
            if (detail.googleUserId != null && detail.googleUserId!.isNotEmpty) _Dtl('Google ID', detail.googleUserId!),
            _Dtl('Dibuat', _fmtDate(detail.createdAt)),
            if (detail.expiresAt != null && detail.expiresAt!.isNotEmpty) _Dtl('Expires', _fmtDate(detail.expiresAt!)),
            const SizedBox(height: 20),
            const Text('Aktivasi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (detail.activations.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Belum ada aktivasi', style: TextStyle(fontSize: 13, color: NusaTheme.textTertiary)))
            else
              ...detail.activations.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: NusaTheme.borderColor, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.phone_android, size: 16, color: NusaTheme.textTertiary),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.deviceId, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    if (a.googleUserId != null && a.googleUserId!.isNotEmpty) Text(a.googleUserId!, style: const TextStyle(fontSize: 11, color: NusaTheme.textTertiary)),
                  ])),
                  Text(_fmtDate(a.createdAt), style: const TextStyle(fontSize: 11, color: NusaTheme.textTertiary)),
                ]),
              )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}

Widget _Dtl(String label, String value, {bool mono = false}) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 12, color: NusaTheme.textTertiary))),
    Expanded(child: Text(value, style: TextStyle(fontSize: 12, fontFamily: mono ? 'monospace' : null, fontWeight: FontWeight.w500, color: NusaTheme.textPrimary))),
  ]),
);

// ═══════════════════════════════════════════════════════════════════════
// Confirmation Dialogs
// ═══════════════════════════════════════════════════════════════════════

Future<void> _confirmCancel(BuildContext context, String id, VoidCallback onChanged) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cancel Lisensi?'),
      content: const Text('Lisensi akan di-cancel dan tidak bisa diaktivasi kembali.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: NusaTheme.primaryColor, foregroundColor: Colors.white), onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel Lisensi')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await AdminRepository.revokeLicense(id);
    if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lisensi di-cancel'), backgroundColor: NusaTheme.accentGreen, duration: Duration(seconds: 1))); onChanged(); }
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: NusaTheme.primaryColor));
  }
}

Future<void> _confirmDelete(BuildContext context, String id, VoidCallback onChanged) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Hapus Lisensi?'),
      content: const Text('Lisensi yang belum diaktivasi akan dihapus permanen.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await AdminRepository.deleteLicense(id);
    if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lisensi dihapus'), backgroundColor: NusaTheme.accentGreen, duration: Duration(seconds: 1))); onChanged(); }
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: NusaTheme.primaryColor));
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Generate Tab
// ═══════════════════════════════════════════════════════════════════════

class _GenerateTab extends StatefulWidget {
  const _GenerateTab();
  @override
  State<_GenerateTab> createState() => _GenerateTabState();
}

class _GenerateTabState extends State<_GenerateTab> {
  final _countCtrl = TextEditingController(text: '1');
  final _buyerNameCtrl = TextEditingController();
  final _buyerEmailCtrl = TextEditingController();
  bool _isTrial = false, _sendEmail = false, _genLoading = false;

  final _manualKeyCtrl = TextEditingController();
  final _manualSerialCtrl = TextEditingController();
  final _manualEmailCtrl = TextEditingController();
  bool _addLoading = false;
  String? _addResult;
  bool _addOk = false;

  // Generate result
  int? _genCount;
  List<String>? _genKeys;
  bool _genIsTrial = false;
  String? _genExpires;
  bool _genEmailSent = false;
  String? _genEmailError;

  @override
  void dispose() {
    _countCtrl.dispose(); _buyerNameCtrl.dispose(); _buyerEmailCtrl.dispose();
    _manualKeyCtrl.dispose(); _manualSerialCtrl.dispose(); _manualEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final count = int.tryParse(_countCtrl.text) ?? 1;
    if (count < 1 || count > 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jumlah harus 1-100'), backgroundColor: NusaTheme.primaryColor));
      return;
    }
    setState(() { _genLoading = true; _genKeys = null; });
    try {
      final r = await AdminRepository.generateKeys(
        count: count, buyerName: _buyerNameCtrl.text.trim(),
        ownerEmail: _buyerEmailCtrl.text.trim(),
        sendEmail: _sendEmail, isTrial: _isTrial,
      );
      if (mounted) setState(() {
        _genLoading = false; _genCount = r.count; _genKeys = r.keys;
        _genIsTrial = r.isTrial; _genExpires = r.expiresAt;
        _genEmailSent = r.emailSent; _genEmailError = r.emailError;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _genLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: NusaTheme.primaryColor));
      }
    }
  }

  Future<void> _addManual() async {
    final key = _manualKeyCtrl.text.trim();
    final serial = _manualSerialCtrl.text.trim();
    if (key.isEmpty || serial.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Key dan serial wajib diisi'), backgroundColor: NusaTheme.primaryColor));
      return;
    }
    setState(() { _addLoading = true; _addResult = null; });
    try {
      final result = await AdminRepository.addKey(key: key, serial: serial, ownerEmail: _manualEmailCtrl.text.trim());
      if (mounted) {
        setState(() { _addOk = true; _addResult = 'Key berhasil ditambahkan: ${result['key']}'; _addLoading = false; });
        _manualKeyCtrl.clear(); _manualSerialCtrl.clear(); _manualEmailCtrl.clear();
      }
    } catch (e) {
      if (mounted) setState(() { _addOk = false; _addResult = 'Gagal: $e'; _addLoading = false; });
    }
  }

  InputDecoration _deco(String h) => InputDecoration(
    hintText: h, hintStyle: const TextStyle(color: NusaTheme.textTertiary, fontSize: 13),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: NusaTheme.dividerColor)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: NusaTheme.dividerColor)),
  );

  @override
  Widget build(BuildContext context) {
    final hasEmail = _buyerEmailCtrl.text.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Auto Generate
        const Text('Auto Generate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _Fld('Jumlah', TextField(controller: _countCtrl, keyboardType: TextInputType.number, style: const TextStyle(fontSize: 14), decoration: _deco('1-100'))),
        const SizedBox(height: 10),
        _Fld('Nama Pembeli (opsional)', TextField(controller: _buyerNameCtrl, style: const TextStyle(fontSize: 14), decoration: _deco('Nama pembeli'))),
        const SizedBox(height: 10),
        _Fld('Email Pembeli (opsional)', TextField(controller: _buyerEmailCtrl, keyboardType: TextInputType.emailAddress, style: const TextStyle(fontSize: 14), decoration: _deco('email@example.com'), onChanged: (_) => setState(() {}))),
        const SizedBox(height: 12),
        Row(children: [
          _Chk('Trial 30 Hari', _isTrial, (v) => setState(() => _isTrial = v)),
          const SizedBox(width: 16),
          _Chk('Kirim Email', _sendEmail && hasEmail, hasEmail ? (v) => setState(() => _sendEmail = v) : null),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _genLoading ? null : _generate,
            style: ElevatedButton.styleFrom(backgroundColor: NusaTheme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            child: _genLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Generate'),
          ),
        ),
        if (_genKeys != null) ...[
          const SizedBox(height: 16),
          _GenResultCard(count: _genCount!, keys: _genKeys!, isTrial: _genIsTrial, expiresAt: _genExpires, emailSent: _genEmailSent, emailError: _genEmailError),
        ],
        const SizedBox(height: 28), const Divider(), const SizedBox(height: 20),
        // Manual Add
        const Text('Tambah Key Manual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Untuk key yang di-generate via CLI (keygen.dart)', style: TextStyle(fontSize: 12, color: NusaTheme.textTertiary)),
        const SizedBox(height: 12),
        _Fld('Key (NUSA-XXXX-...)', TextField(controller: _manualKeyCtrl, style: const TextStyle(fontFamily: 'monospace', fontSize: 13), decoration: _deco('NUSA-XXXX-XXXX-...'))),
        const SizedBox(height: 10),
        _Fld('Serial (8 karakter)', TextField(controller: _manualSerialCtrl, maxLength: 8, style: const TextStyle(fontFamily: 'monospace', fontSize: 13), decoration: _deco('XXXXXXXX').copyWith(counterText: ''))),
        const SizedBox(height: 10),
        _Fld('Email Pemilik (opsional)', TextField(controller: _manualEmailCtrl, style: const TextStyle(fontSize: 14), decoration: _deco('email@example.com'))),
        const SizedBox(height: 14),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _addLoading ? null : _addManual,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF374151), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            child: _addLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Tambah Key'),
          ),
        ),
        if (_addResult != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: (_addOk ? NusaTheme.accentGreen : NusaTheme.primaryColor).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: (_addOk ? NusaTheme.accentGreen : NusaTheme.primaryColor).withValues(alpha: 0.2))),
            child: Row(children: [
              Icon(_addOk ? Icons.check_circle : Icons.error_outline, color: _addOk ? NusaTheme.accentGreen : NusaTheme.primaryColor, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_addResult!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _addOk ? NusaTheme.accentGreen : NusaTheme.primaryColor))),
            ]),
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }
}

Widget _Fld(String label, Widget child) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: NusaTheme.textSecondary)),
  const SizedBox(height: 4), child,
]);

Widget _Chk(String label, bool value, ValueChanged<bool>? onChanged) => GestureDetector(
  onTap: onChanged != null ? () => onChanged(!value) : null,
  child: Row(mainAxisSize: MainAxisSize.min, children: [
    SizedBox(width: 20, height: 20, child: Checkbox(value: value, onChanged: onChanged != null ? (v) => onChanged(v ?? false) : null, activeColor: NusaTheme.primaryColor, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
    const SizedBox(width: 6),
    Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: onChanged != null ? NusaTheme.textSecondary : NusaTheme.textTertiary)),
  ]),
);

// ═══════════════════════════════════════════════════════════════════════
// Generate Result Card
// ═══════════════════════════════════════════════════════════════════════

class _GenResultCard extends StatelessWidget {
  final int count;
  final List<String> keys;
  final bool isTrial;
  final String? expiresAt;
  final bool emailSent;
  final String? emailError;

  const _GenResultCard({required this.count, required this.keys, required this.isTrial, this.expiresAt, required this.emailSent, this.emailError});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: NusaTheme.accentGreen.withValues(alpha: 0.4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.check_circle, color: NusaTheme.accentGreen, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text('$count key ${isTrial ? "trial" : ""} berhasil di-generate', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: NusaTheme.accentGreen))),
          GestureDetector(
            onTap: () { Clipboard.setData(ClipboardData(text: keys.join('\n'))); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua key disalin'), duration: Duration(seconds: 1))); },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: NusaTheme.accentGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.copy_all, size: 14, color: NusaTheme.accentGreen), SizedBox(width: 4), Text('Copy All', style: TextStyle(fontSize: 11, color: NusaTheme.accentGreen, fontWeight: FontWeight.w600))])),
          ),
        ]),
        if (expiresAt != null) ...[const SizedBox(height: 6), Text('⏳ Expires: ${_fmtDate(expiresAt!)}', style: const TextStyle(fontSize: 12, color: NusaTheme.accentGold))],
        if (emailError != null) ...[const SizedBox(height: 6), Text('⚠️ Email gagal: $emailError', style: const TextStyle(fontSize: 12, color: NusaTheme.accentGold))] else if (emailSent) ...[const SizedBox(height: 6), const Text('✅ Email terkirim', style: TextStyle(fontSize: 12, color: NusaTheme.accentGreen))],
        const SizedBox(height: 10),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(10),
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: keys.map((k) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: GestureDetector(
                onTap: () { Clipboard.setData(ClipboardData(text: k)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Key disalin'), duration: Duration(seconds: 1))); },
                child: Text(k, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.4)),
              ),
            )).toList()),
          ),
        ),
      ]),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _PageBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: onTap != null ? NusaTheme.primaryColor : NusaTheme.borderColor,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: onTap != null ? Colors.white : NusaTheme.textTertiary),
      ),
    );
  }
}
