import 'package:flutter/material.dart';

class GeneratedLayout extends StatelessWidget {
  const GeneratedLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 333,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 333,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 333,
                          child: Container(
                            color: Colors.grey.shade200,
                            child: const Center(child: Text('Somthing')),
                          ),
                        ),
                        Expanded(
                          flex: 334,
                          child: Container(
                            color: Colors.grey.shade200,
                            child: const Center(child: Text('not')),
                          ),
                        ),
                        Expanded(
                          flex: 333,
                          child: Container(
                            color: Colors.grey.shade200,
                            child: const Center(child: Text('here')),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 334,
                    child: Container(
                      color: Colors.grey.shade200,
                      child: const Center(child: Text('Split 2')),
                    ),
                  ),
                  Expanded(
                    flex: 333,
                    child: Container(
                      color: Colors.grey.shade200,
                      child: const Center(child: Text('Split 3')),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 334,
              child: Container(
                color: Colors.grey.shade200,
                child: const Center(child: Text('Split 2')),
              ),
            ),
            Expanded(
              flex: 333,
              child: Container(
                color: Colors.grey.shade200,
                child: const Center(child: Text('Split 3')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
