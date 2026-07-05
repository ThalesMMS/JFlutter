part of 'help_page.dart';

class HelpSection {
  final String title;
  final IconData icon;
  final Widget content;

  const HelpSection({
    required this.title,
    required this.icon,
    required this.content,
  });
}

Widget _buildSectionTitle(String title) {
  return Text(
    title,
    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  );
}

Widget _buildCard({
  required String title,
  String? description,
  Widget? leading,
  Widget? trailing,
  Widget? subtitle,
  Color? backgroundColor,
  bool expandable = false,
  Widget? expandedChild,
}) {
  if (expandable) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      color: backgroundColor,
      child: ExpansionTile(
        leading: leading,
        title: Text(title),
        subtitle: subtitle ?? (description == null ? null : Text(description)),
        trailing: trailing,
        children: [
          if (expandedChild != null)
            expandedChild
          else if (description != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(description),
            ),
        ],
      ),
    );
  }

  return Card(
    margin: const EdgeInsets.only(bottom: 8.0),
    color: backgroundColor,
    child: ListTile(
      leading: leading,
      title: Text(title),
      subtitle: subtitle ?? (description == null ? null : Text(description)),
      trailing: trailing,
    ),
  );
}

class _HelpArticleContent extends StatelessWidget {
  const _HelpArticleContent({
    required this.articleId,
  });

  final String articleId;

  @override
  Widget build(BuildContext context) {
    final l10n = jflapLocalizationsOf(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(l10n.helpSectionTitle(articleId)),
          const SizedBox(height: 16),
          Text(
            l10n.helpArticleBody(articleId),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
