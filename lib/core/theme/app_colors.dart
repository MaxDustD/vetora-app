import 'package:flutter/material.dart';

/// Paleta do Vetora (Trabalho 1, seção 03 — Identidade visual mínima).
abstract final class AppColors {
  // Cores principais
  static const grafite = Color(0xFF0D1114); // fundo de todas as telas
  static const ciano = Color(0xFF009FBC); // acento único
  static const brancoTecnico = Color(0xFFF4F7F8); // títulos, valores e logotipo

  // Cores secundárias e de apoio
  static const superficie = Color(0xFF13171A); // cards e painéis
  static const superficieElevada = Color(0xFF1A1F22); // teclas e chips
  static const borda = Color(0xFF23292D); // contorno de 1 px dos cards
  static const cianoProfundo = Color(0xFF0A3038); // teclas de operação e selo
  static const verdeConfirmacao = Color(0xFF334C48); // borda do resultado validado
  static const textoSecundario = Color(0xFFA0A6A8); // mensagens e descrições
  static const textoTerciario = Color(0xFF6A7072); // rótulos, "Pular"
  static const trilhoProgresso = Color(0xFF21262A); // trilho da barra da Splash
  static const cinzaEngrenagem = Color(0xFF767676); // exclusivo do ícone
}
