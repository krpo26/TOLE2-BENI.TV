import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'TV Gratis',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple, brightness: Brightness.dark),
          focusColor: Colors.white24,
        ),
        home: const Home(),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final Future<Map<String, dynamic>> datos = rootBundle
      .loadString('assets/catalogo.json')
      .then((s) => jsonDecode(s) as Map<String, dynamic>);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TV Gratis Argentina'),
          bottom: const TabBar(
              tabs: [Tab(text: 'Plataformas'), Tab(text: 'Películas')]),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: datos,
          builder: (c, s) {
            if (!s.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final d = s.data!;
            return TabBarView(children: [
              Grilla(items: d['plataformas']),
              Grilla(items: d['peliculas']),
            ]);
          },
        ),
      ),
    );
  }
}

class Grilla extends StatelessWidget {
  final List items;
  const Grilla({super.key, required this.items});

  @override
  Widget build(BuildContext context) => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 320,
          mainAxisExtent: 170,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (c, i) {
          final it = items[i] as Map<String, dynamic>;
          return Card(
            child: InkWell(
              autofocus: i == 0,
              borderRadius: BorderRadius.circular(12),
              onTap: () => showDialog(
                  context: c, builder: (_) => Detalle(it: it)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it['nombre'],
                        style: Theme.of(c).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Expanded(
                        child: Text(it['descripcion'],
                            overflow: TextOverflow.fade)),
                    Text(it['etiqueta'] ?? '',
                        style:
                            TextStyle(color: Theme.of(c).colorScheme.primary)),
                  ],
                ),
              ),
            ),
          );
        },
      );
}

class Detalle extends StatelessWidget {
  final Map<String, dynamic> it;
  const Detalle({super.key, required this.it});

  @override
  Widget build(BuildContext context) {
    final reproducir = it['tipo'] == 'reproducir';
    return AlertDialog(
      title: Text(it['nombre']),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(it['descripcion']),
            if (it['contenido'] != null) ...[
              const SizedBox(height: 8),
              Text('Contenido: ${it['contenido']}'),
            ],
            if (it['registro'] != null) Text('Registro: ${it['registro']}'),
            if (it['limitaciones'] != null)
              Text('Limitaciones: ${it['limitaciones']}'),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar')),
        FilledButton(
          autofocus: true,
          onPressed: () {
            final nav = Navigator.of(context);
            nav.pop();
            if (reproducir) {
              nav.push(MaterialPageRoute(
                  builder: (_) =>
                      Player(titulo: it['nombre'], url: it['url'])));
            } else {
              launchUrl(Uri.parse(it['url']),
                  mode: LaunchMode.externalApplication);
            }
          },
          child: Text(reproducir ? 'Reproducir' : 'Abrir sitio oficial'),
        ),
      ],
    );
  }
}

class Player extends StatefulWidget {
  final String titulo, url;
  const Player({super.key, required this.titulo, required this.url});
  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  late final VideoPlayerController c;

  @override
  void initState() {
    super.initState();
    c = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {});
        c.play();
      });
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.titulo)),
        body: Center(
          child: c.value.isInitialized
              ? AspectRatio(
                  aspectRatio: c.value.aspectRatio, child: VideoPlayer(c))
              : const CircularProgressIndicator(),
        ),
        floatingActionButton: FloatingActionButton(
          autofocus: true,
          onPressed: () =>
              setState(() => c.value.isPlaying ? c.pause() : c.play()),
          child: Icon(c.value.isPlaying ? Icons.pause : Icons.play_arrow),
        ),
      );
}
