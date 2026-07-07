String timeAgo(DateTime from) {
  final diff = DateTime.now().difference(from);
  if (diff.inDays >= 1) return '${diff.inDays}d ago';
  if (diff.inHours >= 1) {
    final m = diff.inMinutes % 60;
    return m > 0 ? '${diff.inHours}h ${m}m ago' : '${diff.inHours}h ago';
  }
  if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
  return 'just now';
}
