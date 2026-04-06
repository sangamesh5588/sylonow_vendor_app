import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';
import 'providers/splash_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  String _version = '';
  late AnimationController _animationController;
  bool _animationCompleted = false;
  bool _minDelayCompleted = false;
  bool _routerNotified = false;
  Timer? _splashGuardTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
    _initPackageInfo();
    _startMinimumDelay();
    _startSplashGuardTimeout();
  }

  @override
  void dispose() {
    _splashGuardTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = 'v${info.version}';
        });
      }
    } catch (e) {
      // If package info fails, just use empty version
      // This can happen during hot restart or when platform channels are unavailable
      if (mounted) {
        setState(() {
          _version = '';
        });
      }
    }
  }

  void _startMinimumDelay() async {
    // Keep branding delay in release, but make hot restart snappier in debug/profile.
    const debugDelay = Duration(milliseconds: 300);
    const delay = kReleaseMode ? Duration(seconds: 2) : debugDelay;
    await Future.delayed(delay);
    if (mounted) {
      setState(() {
        _minDelayCompleted = true;
      });
      _maybeNotifyRouterSplashComplete();
    }
  }

  void _startSplashGuardTimeout() {
    // Safety net: if Lottie never completes (asset/animation issue), unblock router.
    _splashGuardTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && !_routerNotified) {
        _notifyRouterSplashComplete();
      }
    });
  }

  void _notifyRouterSplashComplete() {
    if (_routerNotified || !mounted) return;
    _routerNotified = true;
    ref.read(splashAnimationCompletedProvider.notifier).state = true;
  }

  void _maybeNotifyRouterSplashComplete() {
    if (_animationCompleted && _minDelayCompleted) {
      _notifyRouterSplashComplete();
    }
  }

  void _onAnimationComplete() {
    if (!mounted) return;
    setState(() {
      _animationCompleted = true;
    });
    _maybeNotifyRouterSplashComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Lottie.asset(
                'assets/animations/splash2.json',
                controller: _animationController,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                fit: BoxFit.cover,
                repeat: false,
                onLoaded: (composition) {
                  _animationController.duration = composition.duration;
                  _animationController
                      .forward()
                      .whenComplete(_onAnimationComplete);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Text(
                _version.isEmpty ? '' : _version,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
