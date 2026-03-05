import 'package:flutter/material.dart';

class StatisticsWidget extends StatefulWidget {
  const StatisticsWidget({super.key});

  @override
  State<StatisticsWidget> createState() => _StatisticsWidgetState();
}

class _StatisticsWidgetState extends State<StatisticsWidget> {
  String _selectedPeriod = 'Hoy';
  final List<String> _periods = [
    'Hoy',
    'Semana actual',
    'Mes actual',
    'Año actual',
  ];

  final Map<String, dynamic> _dummyData = {
    'Hoy': {
      'horasTrabajadas': '00:00:00',
      'porcentajeTrabajado': '0%',
      'horasTeoricas': '08:00:00',
      'porcentajeTeorico': '100%',
      'excedente': '00:00:00',
      'porcentajeExcedente': '0%',
      'fichajes': '0',
      'pausas': '00:00:00',
      'numPausas': '0',
      'vacacionesCogidas': '0',
      'vacacionesRestantes': '30',
      'diasTrabajados': '3',
      'ausencias': '0',
      'bajas': '0',
    },
    'Semana actual': {
      'horasTrabajadas': '24:30:00',
      'porcentajeTrabajado': '61%',
      'horasTeoricas': '40:00:00',
      'porcentajeTeorico': '100%',
      'excedente': '00:30:00',
      'porcentajeExcedente': '2%',
      'fichajes': '6',
      'pausas': '01:15:00',
      'numPausas': '8',
      'vacacionesCogidas': '0',
      'vacacionesRestantes': '30',
      'diasTrabajados': '3',
      'ausencias': '0',
      'bajas': '0',
    },
    'Mes actual': {
      'horasTrabajadas': '112:45:00',
      'porcentajeTrabajado': '70%',
      'horasTeoricas': '160:00:00',
      'porcentajeTeorico': '100%',
      'excedente': '02:45:00',
      'porcentajeExcedente': '1.7%',
      'fichajes': '42',
      'pausas': '08:30:00',
      'numPausas': '40',
      'vacacionesCogidas': '2',
      'vacacionesRestantes': '28',
      'diasTrabajados': '14',
      'ausencias': '0',
      'bajas': '0',
    },
    'Año actual': {
      'horasTrabajadas': '450:20:00',
      'porcentajeTrabajado': '25%',
      'horasTeoricas': '1800:00:00',
      'porcentajeTeorico': '100%',
      'excedente': '15:20:00',
      'porcentajeExcedente': '3%',
      'fichajes': '120',
      'pausas': '30:00:00',
      'numPausas': '110',
      'vacacionesCogidas': '5',
      'vacacionesRestantes': '25',
      'diasTrabajados': '56',
      'ausencias': '2',
      'bajas': '0',
    },
  };

  @override
  Widget build(BuildContext context) {
    final currentData = _dummyData[_selectedPeriod]!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withAlpha(76), // 0.3 * 255 ≈ 76
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(76),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withAlpha(128)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPeriod,
                dropdownColor: const Color(0xFF374151),
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                ),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                items: _periods.map((String period) {
                  return DropdownMenuItem<String>(
                    value: period,
                    child: Text(period),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedPeriod = newValue;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard(
                title: 'Horas trabajadas',
                value: currentData['horasTrabajadas'],
                subtitle: '${currentData['porcentajeTrabajado']} objetivo',
                valueColor: Colors.blueAccent,
              ),
              _buildStatCard(
                title: 'Horas teóricas',
                value: currentData['horasTeoricas'],
                subtitle: '${currentData['porcentajeTeorico']} referencia',
                valueColor: const Color(0xFF2FA344), // Green from screenshot
              ),
              _buildStatCard(
                title: 'Excedente',
                value: currentData['excedente'],
                subtitle: '${currentData['porcentajeExcedente']} extra',
                valueColor: const Color(0xFFF7B71D), // Orange from screenshot
              ),
              _buildStatCard(
                title: 'Fichajes / mes',
                value: currentData['fichajes'],
                subtitle: ' ',
                valueColor: Colors.white,
              ),
              _buildStatCard(
                title: 'Pausas',
                value: currentData['pausas'],
                subtitle: '${currentData['numPausas']} pausas',
                valueColor: Colors.white,
              ),
              _buildStatCard(
                title: 'Vacaciones',
                value: '${currentData['vacacionesCogidas']} días',
                subtitle: '${currentData['vacacionesRestantes']} restantes',
                valueColor: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.grey),
          const SizedBox(height: 8),
          _buildBottomSummary(currentData),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(51), // 0.2 * 255 = 51
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'PERIODO SELECCIONADO',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor == Colors.white ? Colors.white : valueColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary(Map<String, dynamic> data) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(Colors.blueAccent, 'Trabajados'),
            _buildLegendItem(Colors.redAccent, 'Ausencias'),
            _buildLegendItem(const Color(0xFFF7B71D), 'Bajas'),
            _buildLegendItem(const Color(0xFF2FA344), 'Vacaciones'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryCount('Días Trabajados:', data['diasTrabajados']),
            _buildSummaryCount('Ausencias:', data['ausencias']),
            _buildSummaryCount('Bajas:', data['bajas']),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildSummaryCount(String label, String count) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          count,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
