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
          subtitle: const Text('Fixed 4 columns, boxes resize to fill width'),
          value: GridLayoutMode.responsive,
          groupValue: settingsProvider.gridLayoutMode,
          onChanged: (value) {
            if (value != null) {
              settingsProvider.setGridLayoutMode(value);
            }
          },
        ),
        RadioListTile<GridLayoutMode>(
          title: const Text('Fixed Size Grid'),
          subtitle: const Text('Dynamic columns based on 80px target size'),
          value: GridLayoutMode.fixedSize,
          groupValue: settingsProvider.gridLayoutMode,
          onChanged: (value) {
            if (value != null) {
              settingsProvider.setGridLayoutMode(value);
            }
          },
        ),
        RadioListTile<GridLayoutMode>(
          title: const Text('Horizontal Layout'),
          subtitle: const Text('1 column, boxes fill full width'),
          value: GridLayoutMode.horizontal,
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
          subtitle: const Text('Fixed 80px height, independent of width'),
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
