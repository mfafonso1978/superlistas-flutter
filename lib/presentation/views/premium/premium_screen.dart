// lib/presentation/views/premium/premium_screen.dart
import 'package:flutter/material.dart';
import 'package:superlistas/core/ui/widgets/app_background.dart';
import 'package:superlistas/core/ui/widgets/shared_widgets.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('Superlistas Premium')),
      body: Stack(
        children: [
          AppBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                Icon(Icons.workspace_premium_rounded, size: 80, color: Colors.amber.shade300),
                const SizedBox(height: 16),
                Text(
                  'Desbloqueie todo o poder do Superlistas!',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Leve sua organização de compras para o próximo nível com funcionalidades exclusivas.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 32),
                _buildFeatureTile(Icons.cloud_sync_rounded, 'Sincronização na Nuvem', 'Acesse e edite suas listas em qualquer dispositivo. Seus dados sempre seguros e disponíveis.'),
                _buildFeatureTile(Icons.bar_chart_rounded, 'Estatísticas Avançadas', 'Entenda seus hábitos de consumo com gráficos detalhados de gastos mensais e por categoria.'),
                _buildFeatureTile(Icons.analytics_outlined, 'Análise de Listas', 'Veja o custo total por categoria e identifique os itens mais caros de cada compra.'),
                _buildFeatureTile(Icons.copy_all_rounded, 'Reutilizar Listas', 'Economize tempo recriando listas de compras do seu histórico com um único toque.'),
                _buildFeatureTile(Icons.image_rounded, 'Planos de Fundo', 'Personalize a aparência do aplicativo com uma seleção de lindos planos de fundo.'),
                _buildFeatureTile(Icons.straighten_rounded, 'Unidades Customizadas', 'Adicione suas próprias unidades de medida, como "caixa", "fardo" ou "pacote".'),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    // TODO: Implementar lógica de compra (ex: com RevenueCat)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lógica de compra ainda não implementada.')),
                    );
                  },
                  child: const Text('Tornar-se Premium', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.amber.shade300, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}