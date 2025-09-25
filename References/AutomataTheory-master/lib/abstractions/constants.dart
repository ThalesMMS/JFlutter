const epsilon = 'ε';
const sigma = 'Σ';
Set<String> get alphabet {
  final utf8 = <String>{};
  for (var i = 0; i < 127; i++) {
    utf8.add(String.fromCharCode(i));
  }
  return utf8;
}
