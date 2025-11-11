import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/settings_provider.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Menu'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Display Settings'),
          _buildGridLayoutSection(settingsProvider),
          const Divider(),
          _buildSectionHeader('Box Height'),
          _buildBoxHeightSection(settingsProvider),
          const Divider(),
          _buildSectionHeader('Color Settings'),
          SwitchListTile(
            title: const Text('Real Pigments Only'),
            subtitle: const Text('Apply ICC profile filtering to colors'),
            value: settingsProvider.useRealPigmentsOnly,
            onChanged: (value) {
              settingsProvider.setRealPigmentsOnly(value);
            },
          ),
          SwitchListTile(
            title: const Text('Pigment Mixing'),
            subtitle: const Text('Enable pigment-based color mixing'),
            value: settingsProvider.usePigmentMixing,
            onChanged: (value) {
              settingsProvider.setUsePigmentMixing(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildGridLayoutSection(SettingsProvider settingsProvider) {
    return Column(
      children: [
        RadioListTile<GridLayoutMode>(
          title: const Text('Responsive Grid'),
          subtitle: Text('${settingsProvider.responsiveColumnCount} columns, boxes resize to fill width'),
          value: GridLayoutMode.responsive,
          groupValue: settingsProvider.gridLayoutMode,
          onChanged: (value) {
            if (value != null) {
              settingsProvider.setGridLayoutMode(value);
            }
          },
        ),
        // Show column count slider when responsive mode is selected
        if (settingsProvider.gridLayoutMode == GridLayoutMode.responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate max columns based on 70px target size + 8px spacing
              // Using same calculation as fixedSize mode
              const itemSize = 70.0;
              const spacing = 8.0;
              final availableWidth = constraints.maxWidth - 72 - 16; // Subtract padding
              final columnWidth = itemSize + spacing;
              final maxColumns = (availableWidth / columnWidth).floor().clamp(1, 10);

              return Padding(
                padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
                child: Row(
                  children: [
                    const Text('Columns:'),
                    Expanded(
                      child: Slider(
                        value: settingsProvider.responsiveColumnCount.toDouble().clamp(1, maxColumns.toDouble()),
                        min: 1,
                        max: maxColumns.toDouble(),
                        divisions: maxColumns - 1,
                        label: settingsProvider.responsiveColumnCount.toString(),
                        onChanged: (value) {
                          settingsProvider.setResponsiveColumnCount(value.round());
                        },
                      ),
                    ),
                    SizedBox(
                      width: 30,
                      child: Text(
                        settingsProvider.responsiveColumnCount.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        RadioListTile<GridLayoutMode>(
          title: const Text('Fixed Size Grid'),
          subtitle: const Text('Dynamic columns based on 70px target size'),
          value: GridLayoutMode.fixedSize,
          groupValue: settingsProvider.gridLayoutMode,
          onChanged: (value) {
            if (value != null) {
              settingsProvider.setGridLayoutMode(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildBoxHeightSection(SettingsProvider settingsProvider) {
    return Column(
      children: [
        RadioListTile<BoxHeightMode>(
          title: const Text('Proportional (Square)'),
          subtitle: const Text('Height matches width (1:1 aspect ratio)'),
          value: BoxHeightMode.proportional,
          groupValue: settingsProvider.boxHeightMode,
          onChanged: (value) {
            if (value != null) {
              settingsProvider.setBoxHeightMode(value);
            }
          },
        ),
        RadioListTile<BoxHeightMode>(
          title: const Text('Fill Container'),
          subtitle: const Text('Height fills available space based on rows'),
          value: BoxHeightMode.fillContainer,
          groupValue: settingsProvider.boxHeightMode,
          onChanged: (value) {
            if (value != null) {
              settingsProvider.setBoxHeightMode(value);
            }
          },
        ),
        RadioListTile<BoxHeightMode>(
          title: const Text('Fixed Height'),
          subtitle: const Text('Fixed 140px height, independent of width'),
          value: BoxHeightMode.fixed,
          groupValue: settingsProvider.boxHeightMode,
          onChanged: (value) {
            if (value != null) {
              settingsProvider.setBoxHeightMode(value);
            }
          },
        ),
      ],
    );
  }
}
