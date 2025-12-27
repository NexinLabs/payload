import 'package:flutter/material.dart';

class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search collections...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune, size: 20),
                  onPressed: () {},
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _MethodChip(label: 'ALL', isSelected: true),
                _MethodChip(label: 'GET'),
                _MethodChip(label: 'POST'),
                _MethodChip(label: 'PUT'),
                _MethodChip(label: 'DELETE'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                return ExpansionTile(
                  leading: const Icon(Icons.folder_open, color: Colors.amber),
                  title: Text(
                    'Project Alpha ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${(index + 1) * 4} requests',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  children: List.generate(4, (reqIndex) {
                    return ListTile(
                      contentPadding: const EdgeInsets.only(
                        left: 32,
                        right: 16,
                      ),
                      leading: _MethodIndicator(
                        method: reqIndex % 2 == 0 ? 'GET' : 'POST',
                      ),
                      title: Text(
                        'Request ${reqIndex + 1}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: const Icon(Icons.more_vert, size: 18),
                      onTap: () {},
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.create_new_folder_outlined),
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _MethodChip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {},
        backgroundColor: Colors.white.withOpacity(0.05),
        selectedColor: Colors.blueAccent.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? Colors.blueAccent : Colors.white.withOpacity(0.5),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.blueAccent : Colors.transparent,
          ),
        ),
      ),
    );
  }
}

class _MethodIndicator extends StatelessWidget {
  final String method;

  const _MethodIndicator({required this.method});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (method) {
      case 'GET':
        color = Colors.green;
        break;
      case 'POST':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      width: 40,
      alignment: Alignment.center,
      child: Text(
        method,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
