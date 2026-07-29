import 'dart:async';
import 'package:flutter/material.dart';

enum EstadoParcela { vacia, conMaleza, preparada, sembrada }

class ParcelaModel {
  final int id;
  int? dbId;
  final Offset position;
  EstadoParcela estado;
  int etapa;
  String cultivo;
  bool necesitaAgua;
  Timer? timerCrecimiento;
  int tiempoRestante;

  ParcelaModel({
    required this.id,
    required this.position,
    this.dbId,
    this.estado = EstadoParcela.vacia,
    this.etapa = 0,
    this.cultivo = '',
    this.necesitaAgua = false,
    this.tiempoRestante = 0,
  });
}
