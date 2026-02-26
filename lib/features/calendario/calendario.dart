import 'package:flutter/material.dart';
import '../../shared/widgets/common/menu_lateral.dart';

enum VistaCalendario { mes, semana, dia }

class CalendarioPage extends StatefulWidget {
  const CalendarioPage({super.key});

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  VistaCalendario _vistaActual = VistaCalendario.mes;
  DateTime _fechaSeleccionada = DateTime.now();
  int _semanaSeleccionada = 1;

  final Map<String, List<double>> _dbHoras = {};

  final List<String> _mesesNames = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  // Rango de años solicitado
  final List<int> _anios = List.generate(
    9,
    (index) => 2022 + index,
  ); // 2022 a 2030

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: const MenuLateral(),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.blue, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: _buildSelectorVistaSuperior(),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildCabeceraFiltros(),
          Expanded(child: _renderizarCuerpo()),
        ],
      ),
    );
  }

  // --- SELECTOR SUPERIOR ---
  Widget _buildSelectorVistaSuperior() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: VistaCalendario.values.map((v) {
          bool sel = _vistaActual == v;
          return GestureDetector(
            onTap: () => setState(() => _vistaActual = v),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                v.name.toUpperCase(),
                style: TextStyle(
                  color: sel ? Colors.black : Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- CABECERA DE FILTROS DINÁMICA ---
  Widget _buildCabeceraFiltros() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Wrap(
        // Wrap permite que si no caben los 3 cuadros, bajen de línea suavemente
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          // Selector de Mes (Siempre visible)
          _botonSelectorFiltro(
            ancho: 120,
            label: _mesesNames[_fechaSeleccionada.month - 1],
            onTap: _abrirSelectorMeses,
          ),

          // Selector de Semana (Solo en vista SEMANA)
          if (_vistaActual == VistaCalendario.semana)
            _botonSelectorFiltro(
              ancho: 110,
              label: "Sem. $_semanaSeleccionada",
              onTap: _mostrarSelectorSemanas,
            ),

          // Selector de Año (Visible en todas las pestañas)
          _botonSelectorFiltro(
            ancho: 90,
            label: "${_fechaSeleccionada.year}",
            onTap: _abrirSelectorAnios,
          ),
        ],
      ),
    );
  }

  Widget _botonSelectorFiltro({
    required double ancho,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: ancho,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0x1A2196F3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x332196F3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.blue, size: 18),
          ],
        ),
      ),
    );
  }

  // --- SELECTORES (BOTTOM SHEETS) ---
  void _abrirSelectorAnios() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ListView(
        shrinkWrap: true,
        children: _anios
            .map(
              (anio) => ListTile(
                title: Text(
                  "$anio",
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  setState(
                    () => _fechaSeleccionada = DateTime(
                      anio,
                      _fechaSeleccionada.month,
                      1,
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  void _abrirSelectorMeses() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ListView.builder(
        itemCount: 12,
        itemBuilder: (context, i) => ListTile(
          title: Text(
            _mesesNames[i],
            style: const TextStyle(color: Colors.white),
          ),
          onTap: () {
            setState(() {
              _fechaSeleccionada = DateTime(_fechaSeleccionada.year, i + 1, 1);
              _semanaSeleccionada = 1;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _mostrarSelectorSemanas() {
    int totalDias = DateTime(
      _fechaSeleccionada.year,
      _fechaSeleccionada.month + 1,
      0,
    ).day;
    int numSemanas = (totalDias / 7).ceil();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: numSemanas,
        itemBuilder: (context, i) => ListTile(
          title: Text(
            "Semana ${i + 1}",
            style: const TextStyle(color: Colors.white),
          ),
          onTap: () {
            setState(() => _semanaSeleccionada = i + 1);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  // --- RENDERIZADO CUERPO ---
  Widget _renderizarCuerpo() {
    switch (_vistaActual) {
      case VistaCalendario.mes:
        return _vistaMes();
      case VistaCalendario.semana:
        return _vistaSemana();
      case VistaCalendario.dia:
        return _vistaDiaLista();
    }
  }

  // VISTA MES
  Widget _vistaMes() {
    final int diasEnMes = DateTime(
      _fechaSeleccionada.year,
      _fechaSeleccionada.month + 1,
      0,
    ).day;
    final int primerDia =
        DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month, 1).weekday -
        1;

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: (diasEnMes + (primerDia > 0 ? primerDia : 0)).clamp(0, 42),
      itemBuilder: (context, index) {
        if (index < primerDia) return const SizedBox();
        int dia = index - primerDia + 1;
        if (dia > diasEnMes) return const SizedBox();
        String key =
            "${_fechaSeleccionada.year}-${_fechaSeleccionada.month}-$dia";
        bool esHoy =
            DateTime.now().day == dia &&
            DateTime.now().month == _fechaSeleccionada.month &&
            DateTime.now().year == _fechaSeleccionada.year;

        return GestureDetector(
          onTap: () => _mostrarDetallePopup(dia, _dbHoras[key], key),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: esHoy ? Colors.white : const Color(0x1AFFFFFF),
                width: esHoy ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$dia",
                  style: TextStyle(
                    color: esHoy ? Colors.white : Colors.white70,
                  ),
                ),
                if (_dbHoras.containsKey(key))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _punto(Colors.blue),
                        const SizedBox(width: 2),
                        _punto(Colors.orange),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // VISTA SEMANA
  Widget _vistaSemana() {
    int diaInicio = (_semanaSeleccionada - 1) * 7 + 1;
    int diasEnMes = DateTime(
      _fechaSeleccionada.year,
      _fechaSeleccionada.month + 1,
      0,
    ).day;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: 7,
      itemBuilder: (context, i) {
        int diaActual = diaInicio + i;
        if (diaActual > diasEnMes) return const SizedBox();
        String k =
            "${_fechaSeleccionada.year}-${_fechaSeleccionada.month}-$diaActual";
        bool esHoy =
            DateTime.now().day == diaActual &&
            DateTime.now().month == _fechaSeleccionada.month &&
            DateTime.now().year == _fechaSeleccionada.year;

        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: esHoy ? Colors.white : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0x0DFFFFFF),
            ),
            child: Text(
              "$diaActual",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            "${_mesesNames[_fechaSeleccionada.month - 1]} ${_fechaSeleccionada.year}",
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          trailing: Text(
            _dbHoras.containsKey(k) ? "${_dbHoras[k]![0]}h" : "Detalle",
            style: TextStyle(
              color: _dbHoras.containsKey(k) ? Colors.blue : Colors.white24,
            ),
          ),
          onTap: () => _mostrarDetallePopup(diaActual, _dbHoras[k], k),
        );
      },
    );
  }

  // VISTA DÍA
  Widget _vistaDiaLista() {
    final int diasEnMes = DateTime(
      _fechaSeleccionada.year,
      _fechaSeleccionada.month + 1,
      0,
    ).day;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      itemCount: diasEnMes,
      itemBuilder: (context, i) {
        int diaActual = i + 1;
        String k =
            "${_fechaSeleccionada.year}-${_fechaSeleccionada.month}-$diaActual";
        bool tieneData = _dbHoras.containsKey(k);
        bool esHoy =
            DateTime.now().day == diaActual &&
            DateTime.now().month == _fechaSeleccionada.month &&
            DateTime.now().year == _fechaSeleccionada.year;

        return Card(
          color: const Color(0x0DFFFFFF),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: esHoy ? Colors.white : Colors.transparent,
              width: 1,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0x1A2196F3),
              child: Text(
                "$diaActual",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              "${_mesesNames[_fechaSeleccionada.month - 1]} $diaActual, ${_fechaSeleccionada.year}",
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            subtitle: Text(
              tieneData ? "Trabajo: ${_dbHoras[k]![0]}h" : "Sin registrar",
              style: TextStyle(
                color: tieneData ? Colors.blue : Colors.white24,
                fontSize: 11,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white24,
              size: 14,
            ),
            onTap: () => _mostrarDetallePopup(diaActual, _dbHoras[k], k),
          ),
        );
      },
    );
  }

  // --- DIÁLOGOS ---
  void _mostrarDetallePopup(int dia, List<double>? datos, String key) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        title: Text(
          "Día $dia de ${_mesesNames[_fechaSeleccionada.month - 1]}",
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _filaPopup(
              "Trabajo",
              datos != null ? "${datos[0]}h" : "0h",
              Colors.blue,
            ),
            _filaPopup(
              "Descanso",
              datos != null ? "${datos[1]}h" : "0h",
              Colors.orange,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "REGISTRAR",
              style: TextStyle(color: Colors.blue),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CERRAR"),
          ),
        ],
      ),
    );
  }

  Widget _filaPopup(String t, String v, Color c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(t, style: TextStyle(color: c)),
        Text(v, style: const TextStyle(color: Colors.white)),
      ],
    ),
  );

  Widget _punto(Color c) => Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );
}
