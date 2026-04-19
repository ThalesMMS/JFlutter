part of graphview;

class AccumulatorTree {
  late List<int> tree;
  late int firstIndex;
  late int treeSize;

  AccumulatorTree(int size) {
    firstIndex = 1;
    while (firstIndex < size) {
      firstIndex *= 2;
    }
    treeSize = 2 * firstIndex - 1;
    firstIndex--;
    tree = List.filled(treeSize, 0);
  }

  int crossCount(List<int> southSequence) {
    var crossCount = 0;
    for (var k = 0; k < southSequence.length; k++) {
      var index = southSequence[k] + firstIndex;
      tree[index]++;
      while (index > 0) {
        if (index % 2 != 0) {
          crossCount += tree[index + 1];
        }
        index = (index - 1) ~/ 2;
        tree[index]++;
      }
    }
    return crossCount;
  }
}
