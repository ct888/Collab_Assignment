import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SpotifyLauncher {
  static Future<void> openSpotify(
    BuildContext context, {
    required String spotifyUri,
    required String fallbackUrl,
  }) async {
    try {
      // First try to open the Spotify app using URI scheme
      final uri = Uri.parse(spotifyUri);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
      
      // If Spotify app is not installed, open in web browser
      final url = Uri.parse(fallbackUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      }
      
      // Could not launch
      throw 'Could not launch Spotify';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open Spotify: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Install',
            onPressed: () async {
              final url = Uri.parse(
                'https://play.google.com/store/apps/details?id=com.spotify.music'
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
          ),
        ),
      );
    }
  }
}