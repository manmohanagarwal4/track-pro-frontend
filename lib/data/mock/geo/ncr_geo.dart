import 'package:latlong2/latlong.dart';

/// Static geography of the Delhi NCR demo region, used both to draw the
/// simulated map and to route simulated vehicles. Coordinates are approximate.
class Place {
  const Place(this.id, this.name, this.city, this.lat, this.lng, {this.major = false});

  final String id;
  final String name;
  final String city;
  final double lat;
  final double lng;

  /// Shown at lower zoom levels.
  final bool major;

  LatLng get point => LatLng(lat, lng);
}

enum RoadClass { highway, arterial }

class Road {
  const Road(this.name, this.roadClass, this.nodes);

  final String name;
  final RoadClass roadClass;
  final List<String> nodes;
}

class Area {
  const Area(this.name, this.points, {this.isPark = false});

  final String name;
  final List<LatLng> points;
  final bool isPark;
}

class CityLabel {
  const CityLabel(this.name, this.point, {this.primary = true});

  final String name;
  final LatLng point;
  final bool primary;
}

abstract final class NcrGeo {
  static const defaultCenter = LatLng(28.585, 77.27);
  static const defaultZoom = 10.6;

  /// The demo user's (simulated) current location: Noida Sector 50.
  static const userLocation = LatLng(28.5690, 77.3640);

  static const places = <Place>[
    // Delhi
    Place('cp', 'Connaught Place', 'New Delhi', 28.6315, 77.2167, major: true),
    Place('indiaGate', 'India Gate', 'New Delhi', 28.6129, 77.2295),
    Place('karolBagh', 'Karol Bagh', 'Delhi', 28.6519, 77.1909),
    Place('punjabiBagh', 'Punjabi Bagh', 'Delhi', 28.6720, 77.1300),
    Place('rajouri', 'Rajouri Garden', 'Delhi', 28.6490, 77.1220),
    Place('naraina', 'Naraina', 'Delhi', 28.6280, 77.1400),
    Place('dhaulaKuan', 'Dhaula Kuan', 'New Delhi', 28.5918, 77.1615),
    Place('aiims', 'AIIMS', 'New Delhi', 28.5672, 77.2100),
    Place('moolchand', 'Moolchand', 'New Delhi', 28.5650, 77.2350),
    Place('ashram', 'Ashram Chowk', 'New Delhi', 28.5710, 77.2590),
    Place('saraiKaleKhan', 'Sarai Kale Khan', 'New Delhi', 28.5890, 77.2580),
    Place('pragati', 'Pragati Maidan', 'New Delhi', 28.6180, 77.2450),
    Place('ito', 'ITO', 'New Delhi', 28.6280, 77.2410),
    Place('rajghat', 'Rajghat', 'Delhi', 28.6400, 77.2490),
    Place('kashmereGate', 'Kashmere Gate', 'Delhi', 28.6670, 77.2280, major: true),
    Place('azadpur', 'Azadpur', 'Delhi', 28.7070, 77.1750),
    Place('rohini', 'Rohini', 'Delhi', 28.7383, 77.0822, major: true),
    Place('saket', 'Saket', 'New Delhi', 28.5245, 77.2066, major: true),
    Place('chhatarpur', 'Chhatarpur', 'New Delhi', 28.4950, 77.1800),
    Place('ghitorni', 'Ghitorni', 'New Delhi', 28.4950, 77.1450),
    Place('mahipalpur', 'Mahipalpur', 'New Delhi', 28.5450, 77.1230),
    Place('airportT3', 'IGI Airport T3', 'New Delhi', 28.5562, 77.1000, major: true),
    Place('dwarka', 'Dwarka', 'New Delhi', 28.5921, 77.0460, major: true),
    Place('rajokri', 'Rajokri', 'New Delhi', 28.5160, 77.1050),
    Place('akshardham', 'Akshardham', 'Delhi', 28.6127, 77.2773),
    Place('laxmiNagar', 'Laxmi Nagar', 'Delhi', 28.6304, 77.2777),
    Place('mayurVihar', 'Mayur Vihar', 'Delhi', 28.5800, 77.2950),
    Place('ghazipur', 'Ghazipur', 'Delhi', 28.6270, 77.3220),
    Place('anandVihar', 'Anand Vihar', 'Delhi', 28.6469, 77.3159),
    Place('badarpur', 'Badarpur', 'New Delhi', 28.5030, 77.3010),
    // Noida
    Place('noida15a', 'Sector 15A', 'Noida', 28.5800, 77.3110),
    Place('noida18', 'Sector 18', 'Noida', 28.5708, 77.3261, major: true),
    Place('noida37', 'Sector 37', 'Noida', 28.5450, 77.3420),
    Place('noida50', 'Sector 50', 'Noida', 28.5690, 77.3640),
    Place('noidaCityCentre', 'City Centre', 'Noida', 28.5747, 77.3560),
    Place('noida62', 'Sector 62', 'Noida', 28.6270, 77.3650, major: true),
    Place('noida135', 'Sector 135', 'Noida', 28.5150, 77.3780),
    Place('noida150', 'Sector 150', 'Noida', 28.4800, 77.4400),
    Place('pariChowk', 'Pari Chowk', 'Greater Noida', 28.4666, 77.5130, major: true),
    Place('gnLink', 'Kasna', 'Greater Noida', 28.5100, 77.5350),
    // Ghaziabad
    Place('upGate', 'UP Gate', 'Ghaziabad', 28.6280, 77.3330),
    Place('vaishali', 'Vaishali', 'Ghaziabad', 28.6497, 77.3404),
    Place('indirapuram', 'Indirapuram', 'Ghaziabad', 28.6460, 77.3713, major: true),
    Place('vijayNagar', 'Vijay Nagar', 'Ghaziabad', 28.6440, 77.4250),
    Place('ghaziabad', 'Raj Nagar', 'Ghaziabad', 28.6560, 77.4540, major: true),
    Place('lalKuan', 'Lal Kuan', 'Ghaziabad', 28.6080, 77.4720),
    Place('dasna', 'Dasna', 'Ghaziabad', 28.6800, 77.5200),
    Place('pilkhuwa', 'Pilkhuwa', 'Hapur', 28.7120, 77.6550),
    Place('hapur', 'Hapur', 'Hapur', 28.7306, 77.7759, major: true),
    Place('dadri', 'Dadri', 'Gautam Buddh Nagar', 28.5520, 77.5530, major: true),
    Place('sikandrabad', 'Sikandrabad', 'Bulandshahr', 28.4517, 77.6950),
    Place('bulandshahr', 'Bulandshahr', 'Bulandshahr', 28.4069, 77.8498, major: true),
    // Gurugram / Faridabad
    Place('cyberCity', 'Cyber City', 'Gurugram', 28.4950, 77.0895, major: true),
    Place('iffco', 'IFFCO Chowk', 'Gurugram', 28.4720, 77.0720),
    Place('mgRoad', 'MG Road', 'Gurugram', 28.4800, 77.0800),
    Place('huda', 'Huda City Centre', 'Gurugram', 28.4593, 77.0725),
    Place('rajivChowk', 'Rajiv Chowk', 'Gurugram', 28.4480, 77.0420),
    Place('manesar', 'Manesar', 'Gurugram', 28.3540, 76.9400, major: true),
    Place('faridabad', 'Faridabad', 'Faridabad', 28.4089, 77.3178, major: true),
  ];

  static final Map<String, Place> placeById = {for (final p in places) p.id: p};

  static const roads = <Road>[
    Road('NH 48', RoadClass.highway,
        ['dhaulaKuan', 'mahipalpur', 'rajokri', 'cyberCity', 'iffco', 'rajivChowk', 'manesar']),
    Road('Ring Road', RoadClass.highway, [
      'dhaulaKuan', 'aiims', 'moolchand', 'ashram', 'saraiKaleKhan', 'pragati', 'rajghat',
      'kashmereGate', 'azadpur', 'punjabiBagh', 'rajouri', 'naraina', 'dhaulaKuan'
    ]),
    Road('NH 9', RoadClass.highway, [
      'saraiKaleKhan', 'akshardham', 'ghazipur', 'upGate', 'indirapuram', 'vijayNagar',
      'ghaziabad', 'dasna', 'pilkhuwa', 'hapur'
    ]),
    Road('DND Flyway', RoadClass.highway, ['ashram', 'mayurVihar', 'noida15a', 'noida18']),
    Road('Noida-Greater Noida Expressway', RoadClass.highway,
        ['noida18', 'noida37', 'noida135', 'noida150', 'pariChowk']),
    Road('NH 34', RoadClass.highway, ['ghaziabad', 'lalKuan', 'dadri', 'sikandrabad', 'bulandshahr']),
    Road('Mathura Road', RoadClass.highway, ['ashram', 'badarpur', 'faridabad']),
    Road('Noida Main Road', RoadClass.arterial,
        ['noida18', 'noida50', 'noidaCityCentre', 'noida62', 'indirapuram']),
    Road('Kasna Road', RoadClass.arterial, ['pariChowk', 'gnLink', 'dadri']),
    Road('MG Road', RoadClass.arterial, ['saket', 'chhatarpur', 'ghitorni', 'mgRoad', 'iffco']),
    Road('Aurobindo Marg', RoadClass.arterial, ['aiims', 'saket']),
    Road('Airport Road', RoadClass.arterial, ['mahipalpur', 'airportT3', 'dwarka']),
    Road('Outer Ring Road', RoadClass.arterial, ['azadpur', 'rohini']),
    Road('Pusa Road', RoadClass.arterial, ['ito', 'cp', 'karolBagh', 'punjabiBagh']),
    Road('Rajpath', RoadClass.arterial, ['cp', 'indiaGate', 'pragati', 'ito']),
    Road('Vikas Marg', RoadClass.arterial, ['ito', 'laxmiNagar', 'anandVihar', 'vaishali', 'indirapuram']),
    Road('Golf Course Road', RoadClass.arterial, ['cyberCity', 'mgRoad', 'huda', 'iffco']),
    Road('Ghazipur Road', RoadClass.arterial, ['ghazipur', 'noida15a']),
  ];

  /// The Yamuna river centre line.
  static const yamuna = <LatLng>[
    LatLng(28.80, 77.205),
    LatLng(28.76, 77.215),
    LatLng(28.72, 77.228),
    LatLng(28.68, 77.243),
    LatLng(28.645, 77.256),
    LatLng(28.61, 77.265),
    LatLng(28.58, 77.278),
    LatLng(28.55, 77.292),
    LatLng(28.52, 77.305),
    LatLng(28.48, 77.325),
    LatLng(28.43, 77.35),
    LatLng(28.38, 77.37),
    LatLng(28.30, 77.40),
  ];

  static const hindon = <LatLng>[
    LatLng(28.78, 77.40),
    LatLng(28.70, 77.405),
    LatLng(28.66, 77.40),
    LatLng(28.62, 77.395),
    LatLng(28.57, 77.43),
    LatLng(28.52, 77.45),
    LatLng(28.47, 77.43),
  ];

  static const areas = <Area>[
    Area('Delhi', [
      LatLng(28.80, 77.05), LatLng(28.78, 77.20), LatLng(28.70, 77.235), LatLng(28.62, 77.255),
      LatLng(28.55, 77.28), LatLng(28.49, 77.26), LatLng(28.49, 77.10), LatLng(28.56, 77.00),
      LatLng(28.66, 76.98), LatLng(28.74, 77.01),
    ]),
    Area('East Delhi', [
      LatLng(28.71, 77.26), LatLng(28.69, 77.33), LatLng(28.62, 77.335), LatLng(28.58, 77.30),
      LatLng(28.60, 77.272),
    ]),
    Area('Noida', [
      LatLng(28.635, 77.30), LatLng(28.635, 77.41), LatLng(28.55, 77.43), LatLng(28.49, 77.41),
      LatLng(28.49, 77.33), LatLng(28.56, 77.30),
    ]),
    Area('Ghaziabad', [
      LatLng(28.71, 77.37), LatLng(28.70, 77.52), LatLng(28.61, 77.50), LatLng(28.62, 77.36),
    ]),
    Area('Greater Noida', [
      LatLng(28.52, 77.45), LatLng(28.51, 77.56), LatLng(28.43, 77.56), LatLng(28.43, 77.46),
    ]),
    Area('Gurugram', [
      LatLng(28.53, 77.00), LatLng(28.52, 77.13), LatLng(28.42, 77.12), LatLng(28.39, 77.00),
      LatLng(28.44, 76.95),
    ]),
    Area('Faridabad', [
      LatLng(28.46, 77.27), LatLng(28.46, 77.34), LatLng(28.35, 77.34), LatLng(28.35, 77.27),
    ]),
    Area('Hapur', [
      LatLng(28.75, 77.75), LatLng(28.75, 77.80), LatLng(28.71, 77.80), LatLng(28.71, 77.75),
    ]),
    Area('Bulandshahr', [
      LatLng(28.43, 77.82), LatLng(28.43, 77.88), LatLng(28.38, 77.88), LatLng(28.38, 77.82),
    ]),
    Area('Dadri', [
      LatLng(28.57, 77.53), LatLng(28.57, 77.575), LatLng(28.535, 77.575), LatLng(28.535, 77.53),
    ]),
    Area('Sikandrabad', [
      LatLng(28.465, 77.68), LatLng(28.465, 77.71), LatLng(28.44, 77.71), LatLng(28.44, 77.68),
    ]),
    Area('Central Ridge', [
      LatLng(28.645, 77.185), LatLng(28.64, 77.20), LatLng(28.61, 77.19), LatLng(28.60, 77.17),
      LatLng(28.62, 77.165),
    ], isPark: true),
    Area('Aravalli Park', [
      LatLng(28.52, 77.12), LatLng(28.515, 77.15), LatLng(28.49, 77.15), LatLng(28.485, 77.12),
    ], isPark: true),
    Area('Okhla Sanctuary', [
      LatLng(28.555, 77.30), LatLng(28.548, 77.315), LatLng(28.535, 77.31), LatLng(28.54, 77.297),
    ], isPark: true),
  ];

  static const cityLabels = <CityLabel>[
    CityLabel('DELHI', LatLng(28.69, 77.15)),
    CityLabel('NEW DELHI', LatLng(28.595, 77.195)),
    CityLabel('NOIDA', LatLng(28.545, 77.38)),
    CityLabel('GHAZIABAD', LatLng(28.685, 77.45)),
    CityLabel('GREATER NOIDA', LatLng(28.485, 77.50)),
    CityLabel('GURUGRAM', LatLng(28.43, 77.04)),
    CityLabel('FARIDABAD', LatLng(28.385, 77.305)),
    CityLabel('HAPUR', LatLng(28.745, 77.775)),
    CityLabel('BULANDSHAHR', LatLng(28.39, 77.85)),
    CityLabel('DADRI', LatLng(28.565, 77.555), primary: false),
  ];

  static const stateByCity = {
    'New Delhi': 'Delhi',
    'Delhi': 'Delhi',
    'Noida': 'Uttar Pradesh',
    'Greater Noida': 'Uttar Pradesh',
    'Ghaziabad': 'Uttar Pradesh',
    'Hapur': 'Uttar Pradesh',
    'Gautam Buddh Nagar': 'Uttar Pradesh',
    'Bulandshahr': 'Uttar Pradesh',
    'Gurugram': 'Haryana',
    'Faridabad': 'Haryana',
  };
}
