import 'package:flutter/material.dart';
import 'package:poligrain_app/screens/home/home_screen.dart'
    show formatNaira, Project;

/// Reusable project card for crowdfunding preview.
/// Displays a green header with project name, goal/min-invest, progress bar and stats.
class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;
  const ProjectCard({Key? key, required this.project, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.62).clamp(180, 320).toDouble();
    final cardPadding = (screenWidth * 0.03).clamp(10, 20).toDouble();
    final nameFontSize = (screenWidth * 0.042).clamp(14, 20).toDouble();
    final infoFontSize = (screenWidth * 0.032).clamp(10, 15).toDouble();
    final progress =
        project.goal > 0
            ? (project.raised / project.goal).clamp(0.0, 1.0)
            : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(right: 16),
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Green header
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: cardPadding,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF18813A),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  project.name,
                  style: TextStyle(
                    fontSize: nameFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Goal: ${formatNaira(project.goal)}',
                          style: TextStyle(
                            fontSize: infoFontSize,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          'Min: ${formatNaira(project.minInvest)}',
                          style: TextStyle(
                            fontSize: infoFontSize,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      color: const Color(0xFF18813A),
                      minHeight: (screenWidth * 0.015).clamp(4, 8).toDouble(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${formatNaira(project.raised)} raised',
                          style: TextStyle(
                            fontSize: infoFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          '${project.returnPercent.toStringAsFixed(0)}% Return',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: infoFontSize,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
