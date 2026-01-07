import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ddp_sender.dart';
import '../services/command_sender.dart';

enum ActiveMode { controller, mirroring, video }

// FPP IP Address Provider
final fppIpProvider = StateProvider<String>((ref) {
  return '192.168.1.68';
});

// Active Mode Provider
final activeModeProvider = StateProvider<ActiveMode>((ref) {
  return ActiveMode.controller;
});

// DDP Sender Provider
final ddpSenderProvider = FutureProvider<DdpSender>((ref) async {
  final fppIp = ref.watch(fppIpProvider);
  final ddpSender = DdpSender(host: fppIp, port: 4048);
  await ddpSender.initialize();
  return ddpSender;
});

// Command Sender Provider
final commandSenderProvider = FutureProvider<CommandSender>((ref) async {
  final fppIp = ref.watch(fppIpProvider);
  final commandSender = CommandSender(host: fppIp, port: 5000);
  await commandSender.initialize();
  return commandSender;
});
