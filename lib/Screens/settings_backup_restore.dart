// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

import 'package:money_control/Services/local_backup_service.dart';

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({super.key});

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  bool working = false;

  void _setWorking(bool v) => setState(() => working = v);

  Future<void> _backupNow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _setWorking(true);
    await LocalBackupService.backupUserTransactions(user.email!);
    _setWorking(false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Backup completed successfully!")),
    );
  }

  Future<void> _exportBackup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 🔥 Always create/update the latest backup BEFORE exporting
    await LocalBackupService.backupUserTransactions(user.email!);

    final backup = await LocalBackupService.readUserTransactionsBackup(user.email!);

    if (backup.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No transactions found to backup")),
      );
      return;
    }

    final file = await LocalBackupService.exportBackupFile(user.email!);

    await Share.shareXFiles([XFile(file.path)], text: "Finance Control Backup");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Backup exported!")),
    );
  }


  Future<void> _restoreBackup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (picked == null) return;

    final path = picked.files.single.path;
    if (path == null) return;

    try {
      _setWorking(true);

      final raw = await File(path).readAsString();
      final decoded = jsonDecode(raw);

      if (decoded is! List) throw "Invalid backup format";

      final col = FirebaseFirestore.instance
          .collection("users")
          .doc(user.email)
          .collection("transactions");

      final batch = FirebaseFirestore.instance.batch();

      for (var tx in decoded) {
        final map = Map<String, dynamic>.from(tx);
        final id = map['id'];
        map.remove('id');

        if (map.containsKey('date') && map['date'] is String) {
          map['date'] = DateTime.parse(map['date']);
        }
        if (map.containsKey('createdAt') && map['createdAt'] is String) {
          map['createdAt'] = DateTime.parse(map['createdAt']);
        }

        final docRef = col.doc(id);
        batch.set(docRef, map, SetOptions(merge: true));
      }

      await batch.commit();

      _setWorking(false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Restore successful!")),
      );
    } catch (e) {
      _setWorking(false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Restore failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Backup & Restore"),
        backgroundColor: scheme.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: working
            ? Center(
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                "Processing...",
                style:
                TextStyle(color: scheme.onSurface.withOpacity(0.7)),
              )
            ],
          ),
        )
            : Column(
          children: [
            _item(
              icon: Icons.backup,
              title: "Backup Transactions",
              subtitle: "Save a secure offline copy",
              onTap: _backupNow,
            ),
            const SizedBox(height: 12),
            _item(
              icon: Icons.file_upload,
              title: "Export Backup",
              subtitle: "Share or store the backup file",
              onTap: _exportBackup,
            ),
            const SizedBox(height: 12),
            _item(
              icon: Icons.restore,
              title: "Restore Backup",
              subtitle: "Import a saved JSON backup",
              onTap: _restoreBackup,
            ),
          ],
        ),
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            Icon(icon, size: 30, color: scheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurface.withOpacity(0.6))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 18, color: scheme.onSurface.withOpacity(0.6))
          ],
        ),
      ),
    );
  }
}
