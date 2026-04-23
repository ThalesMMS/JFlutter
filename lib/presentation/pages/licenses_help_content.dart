part of 'help_page.dart';

class _LicensesHelpContent extends StatelessWidget {
  const _LicensesHelpContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Licenses & Attribution'),
          const SizedBox(height: 16),
          const Text(
            'JFlutter is a Flutter reimplementation inspired by and compatible '
            'with JFLAP. It is not an official JFLAP release.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('License Texts'),
          const SizedBox(height: 16),
          const _LicenseTextCard(
            title: 'Apache License 2.0',
            assetPath: 'LICENSE.txt',
            summary:
                'JFlutter original Flutter code is licensed under Apache 2.0.',
          ),
          const _LicenseTextCard(
            title: 'JFLAP 7.1 License',
            assetPath: 'LICENSE_JFLAP.txt',
            summary:
                'JFLAP-derived portions remain under the JFLAP 7.1 License.',
          ),
          const _LicenseTextCard(
            title: 'GraphView (MIT License)',
            assetPath: 'assets/LICENSE_GRAPHVIEW.txt',
            summary:
                'Graph visualization library, forked and modified for JFlutter. Original work by Nabil Mosharraf.',
          ),
          const _LicenseTextCard(
            title: 'Apple Platform Third-Party Notices',
            assetPath: 'THIRD_PARTY_NOTICES_APPLE.txt',
            summary:
                'Bundled notices for the vendored graphview fork and Apple-platform plugin dependencies.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('JFLAP Acknowledgments'),
          const SizedBox(height: 16),
          _buildCard(
            title: 'Susan H. Rodger',
            description:
                'Original JFLAP creator and maintainer, Duke University.',
          ),
          _buildCard(
            title: 'JFLAP Team',
            description:
                'Thomas Finley, Ryan Cavalcante, Stephen Reading, Bart '
                'Bressler, Jinghui Lim, Chris Morgan, Kyung Min (Jason) Lee, '
                'Jonathan Su, and Henry Qin.',
          ),
          _buildCard(
            title: 'Original Project',
            description: 'JFLAP website: http://www.jflap.org',
          ),
          _buildCard(
            title: 'GraphView Fork',
            description:
                'JFlutter vendors a maintained fork of graphview under the MIT '
                'license; Apple-platform third-party notices are bundled in '
                'the licenses section.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Distribution'),
          const SizedBox(height: 16),
          const Text(
            'JFlutter is distributed as a free, non-monetized educational app '
            'while it includes JFLAP-derived material.',
          ),
        ],
      ),
    );
  }
}
