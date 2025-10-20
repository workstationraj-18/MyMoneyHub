import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_controller.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(thickness: 1, color: Colors.black12, height: 20),

          // 🪙 Branding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.deepPurple, size: 20),
              SizedBox(width: 5),
              Text(
                "MyMoneyHub",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            "Smart personal finance and lending tracker",
            style: TextStyle(color: Colors.grey, fontSize: 12.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // 🧾 Company info
          const Text(
            "MyMoneyHub Technologies © 2025",
            style: TextStyle(fontSize: 11.5, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          const Text(
            "Made with ❤️ in India 🇮🇳",
            style: TextStyle(fontSize: 11.5, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // 🔗 Links
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 4,
            children: const [
              _FooterLink("About Us"),
              _FooterLink("Premium"),
              _FooterLink("Learn"),
              _FooterLink("Team"),
              _FooterLink("Support"),
              _FooterLink("Terms & Privacy"),
            ],
          ),
          const SizedBox(height: 10),

          // 🎨 Theme toggle
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  _ThemeOption(
                    label: "Light",
                    icon: Icons.light_mode,
                    isSelected: themeProvider.appTheme == AppThemeMode.light,
                    onTap: () => themeProvider.setTheme(AppThemeMode.light),
                  ),
                  _ThemeOption(
                    label: "Dark",
                    icon: Icons.dark_mode,
                    isSelected: themeProvider.appTheme == AppThemeMode.dark,
                    onTap: () => themeProvider.setTheme(AppThemeMode.dark),
                  ),
                  _ThemeOption(
                    label: "Auto",
                    icon: Icons.brightness_auto,
                    isSelected: themeProvider.appTheme == AppThemeMode.system,
                    onTap: () => themeProvider.setTheme(AppThemeMode.system),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// 🔗 Footer Link
class _FooterLink extends StatelessWidget {
  final String text;
  const _FooterLink(this.text);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$text page coming soon...')),
        );
      },
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.deepPurple,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// 🎨 Theme Option Button
class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepPurple.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isSelected ? Colors.deepPurple : Colors.grey.shade600),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color:
                isSelected ? Colors.deepPurple : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
