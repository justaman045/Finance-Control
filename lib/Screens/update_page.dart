import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UpdatePage extends StatefulWidget {
  const UpdatePage({super.key});

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  Map<String, dynamic>? releaseData;
  bool loading = true;
  bool error = false;

  @override
  void initState() {
    super.initState();
    fetchLatestRelease();
  }

  Future<void> fetchLatestRelease() async {
    try {
      final url = Uri.parse(
          "https://api.github.com/repos/justaman045/Money_Control/releases/latest");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          releaseData = jsonDecode(response.body);
          loading = false;
        });
      } else {
        setState(() {
          error = true;
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = true;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text("Update Available"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error
          ? _errorContent()
          : _content(scheme),
    );
  }

  Widget _content(ColorScheme scheme) {
    final tag = releaseData?["tag_name"] ?? "Unknown";
    final notes = releaseData?["body"] ?? "No release notes";
    final publishedRaw = releaseData?["published_at"] ?? "";
    final publishedDate = DateTime.tryParse(publishedRaw);

    final downloadUrl = releaseData?["assets"]?.isNotEmpty == true
        ? releaseData!["assets"][0]["browser_download_url"]
        : "https://github.com/justaman045/Money_Control/releases";

    final fullReleaseUrl = releaseData?["html_url"] ??
        "https://github.com/justaman045/Money_Control/releases";

    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: ListView(
        children: [
          // ------------------------------------------------------------
          // HEADER CARD
          // ------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: scheme.onSurface.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "New Version Available",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Version: $tag",
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: .7),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Published: ${publishedDate != null ? publishedDate.toLocal().toString().split(' ')[0] : 'Unknown'}",
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: .6),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ------------------------------------------------------------
          // CHANGELOG TITLE
          // ------------------------------------------------------------
          Text(
            "What’s New",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          // ------------------------------------------------------------
          // RELEASE NOTES BOX
          // ------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
            ),
            child: Text(
              notes,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.35,
                color: scheme.onSurface.withValues(alpha: .9),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // ------------------------------------------------------------
          // DOWNLOAD BUTTON
          // ------------------------------------------------------------
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => launchUrl(Uri.parse(downloadUrl),
                  mode: LaunchMode.externalApplication),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                "Download Update",
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ------------------------------------------------------------
          // FULL CHANGELOG
          // ------------------------------------------------------------
          Center(
            child: TextButton(
              onPressed: () =>
                  launchUrl(Uri.parse(fullReleaseUrl), mode: LaunchMode.externalApplication),
              child: const Text("View Full Changelog on GitHub →"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorContent() {
    return Center(
      child: Text(
        "Failed to load release information.",
        style: TextStyle(color: Colors.red.shade400),
      ),
    );
  }
}
