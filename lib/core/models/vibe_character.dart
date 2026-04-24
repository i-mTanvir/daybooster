import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class VibeCharacter {
  final String name;
  final String personality;
  final String message;
  final String visualDescription;
  final Color color;

  const VibeCharacter({
    required this.name,
    required this.personality,
    required this.message,
    required this.visualDescription,
    required this.color,
  });

  static VibeCharacter getForScore(double score, AppThemeColors themeColors) {
    if (score < 40) {
      return VibeCharacter(
        name: 'THE HOLLOW MAN',
        personality: 'The Defeated · The Drifter · The Excuse Maker',
        message: 'You are not living. You are just existing. Your potential is rotting inside you while time buries it. This is the path to a life you will regret every single morning. Wake up — or stay hollow forever.',
        visualDescription: 'A hunched, faded silhouette. Barely visible. Edges dissolving into black smoke.',
        color: themeColors.perfCritical,
      );
    } else if (score < 60) {
      return VibeCharacter(
        name: 'THE SLEEPWALKER',
        personality: 'The Inconsistent · The Almost-Tryer · The Comfort Seeker',
        message: 'You showed up — barely. You are walking through life with your eyes half closed. Mediocrity is not a destination. It is a trap.',
        visualDescription: 'A standing silhouette, but slouched. Dim orange outline. Mid-step but going nowhere.',
        color: themeColors.perfWeak,
      );
    } else if (score < 80) {
      return VibeCharacter(
        name: 'THE STRUGGLING SOLDIER',
        personality: 'The Potential Waster · The Inconsistent Fighter · The Half-Committed',
        message: 'You have something inside you — but you keep leaving it on the floor. Stop negotiating with your own discipline.',
        visualDescription: 'A standing figure. Yellow-tinted glow. Holding something unsure. Battle scars visible.',
        color: themeColors.perfBelowTarget,
      );
    } else if (score < 90) {
      return VibeCharacter(
        name: 'THE RISING HUNTER',
        personality: 'The Disciplined Beginner · The Focused Climber · The Almost-Elite',
        message: 'You are close. Very close. The gap between you and greatness is not talent — it is just a few more minutes of effort each day.',
        visualDescription: 'A tall, straight figure. Blue electric glow. Armor forming around the silhouette.',
        color: themeColors.perfAlmost,
      );
    } else if (score <= 110) {
      return VibeCharacter(
        name: 'THE ARCHITECT',
        personality: 'The Disciplined · The System Builder · The Consistent One',
        message: 'Insha\'Allah — you will shine. This week, you proved that you are not just dreaming. You are building. Trust the process.',
        visualDescription: 'A powerful standing figure. Green glowing aura. Full armor visible. Sharp, defined, clean.',
        color: themeColors.perfTarget,
      );
    } else if (score <= 130) {
      return VibeCharacter(
        name: 'THE OVERDRIVE WARRIOR',
        personality: 'The Elite · The Obsessed Builder · The Unstoppable',
        message: 'You didn\'t just hit the target — you demolished it. You operated in a frequency most people never reach.',
        visualDescription: 'A dynamic figure — leaning forward. Purple electric aura crackling. Eyes glowing.',
        color: themeColors.perfOverdrive,
      );
    } else {
      return VibeCharacter(
        name: 'THE IRON ARCHITECT (LEGENDARY)',
        personality: 'The Visionary · The Legend · The Self-Made Force of Nature',
        message: 'This is it. You didn\'t just follow a schedule — you became the schedule. You have earned the title: LEGENDARY.',
        visualDescription: 'A full standing figure — glowing gold from within. Light bursting from the chest like a reactor core.',
        color: themeColors.perfLegendary,
      );
    }
  }
}
