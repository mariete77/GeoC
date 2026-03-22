/// Datos manuales de ríos para preguntas
///
/// Este archivo contiene datos de ríos para generar preguntas
/// Puedes añadir más ríos según sea necesario

final riversData = [
  {
    'question': '¿Cuál es el río más largo de España?',
    'correct': 'Tajo',
    'options': ['Ebro', 'Tajo', 'Duero', 'Guadalquivir'],
    'difficulty': 'medium',
  },
  {
    'question': '¿Cuál es el río más largo del mundo?',
    'correct': 'Amazonas',
    'options': ['Nilo', 'Amazonas', 'Yangtsé', 'Misisipi'],
    'difficulty': 'easy',
  },
  {
    'question': '¿Cuál es el río que atraviesa París?',
    'correct': 'Sena',
    'options': ['Ródano', 'Sena', 'Loira', 'Garona'],
    'difficulty': 'medium',
  },
  {
    'question': '¿Cuál es el río que atraviesa Londres?',
    'correct': 'Támesis',
    'options': ['Támesis', 'Severn', 'Trent', 'Mersey'],
    'difficulty': 'medium',
  },
  {
    'question': '¿Cuál es el río más largo de Francia?',
    'correct': 'Loira',
    'options': ['Ródano', 'Loira', 'Garona', 'Sena'],
    'difficulty': 'medium',
  },
  {
    'question': '¿Cuál es el río más largo de Alemania?',
    'correct': 'Rin',
    'options': ['Rin', 'Danubio', 'Elba', 'Mosa'],
    'difficulty': 'medium',
  },
  {
    'question': '¿Cuál es el río que atraviesa El Cairo?',
    'correct': 'Nilo',
    'options': ['Nilo', 'Amazonas', 'Yangtsé', 'Mekong'],
    'difficulty': 'easy',
  },
  {
    'question': '¿Cuál es el río más largo de Italia?',
    'correct': 'Po',
    'options': ['Po', 'Tíber', 'Adige', 'Arno'],
    'difficulty': 'medium',
  },
  {
    'question': '¿Cuál es el río que atraviesa Budapest?',
    'correct': 'Danubio',
    'options': ['Danubio', 'Tisza', 'Drava', 'Sava'],
    'difficulty': 'medium',
  },
  {
    'question': '¿Cuál es el río más largo de Portugal?',
    'correct': 'Tajo',
    'options': ['Tajo', 'Duero', 'Guadiana', 'Miño'],
    'difficulty': 'medium',
  },
  {
    'question': '¿Cuál es el río más largo de Argentina?',
    'correct': 'Paraná',
    'options': ['Paraná', 'Uruguay', 'Río Negro', 'Colorado'],
    'difficulty': 'medium',
  },
  {
    'question': '¿Cuál es el río más largo de Brasil?',
    'correct': 'Amazonas',
    'options': ['Amazonas', 'Paraná', 'São Francisco', 'Tocantins'],
    'difficulty': 'easy',
  },
  {
    'question': '¿Cuál es el río que atraviza Moscú?',
    'correct': 'Moscova',
    'options': ['Volga', 'Moscova', 'Don', 'Dniéper'],
    'difficulty': 'medium',
  },
  {
    'question': '¿Cuál es el río más largo de Rusia?',
    'correct': 'Lena',
    'options': ['Lena', 'Ob', 'Yenisei', 'Amur'],
    'difficulty': 'hard',
  },
  {
    'question': '¿Cuál es el río más largo de China?',
    'correct': 'Yangtsé',
    'options': ['Yangtsé', 'Amarillo', 'Mekong', 'Perla'],
    'difficulty': 'easy',
  },
  {
    'question': '¿Cuál es el río que atraviza Roma?',
    'correct': 'Tíber',
    'options': ['Tíber', 'Po', 'Arno', 'Adige'],
    'difficulty': 'medium',
  },
  {
    'question': '¿Cuál es el río más largo de Estados Unidos?',
    'correct': 'Misisipi',
    'options': ['Misisipi', 'Misuri', 'Ohio', 'Colorado'],
    'difficulty': 'medium',
  },
  {
    'question': '¿Cuál es el río que atraviza Viena?',
    'correct': 'Danubio',
    'options': ['Danubio', 'Rin', 'Elba', 'Moldava'],
    'difficulty': 'medium',
  },
  {
    'question': '¿Cuál es el río más largo del Reino Unido?',
    'correct': 'Severn',
    'options': ['Severn', 'Támesis', 'Trent', 'Wye'],
    'difficulty': 'hard',
  },
  {
    'question': '¿Cuál es el río que atraviza Nueva York?',
    'correct': 'Hudson',
    'options': ['Hudson', 'East River', 'Harlem River', 'Misisipi'],
    'difficulty': 'medium',
  },
  {
    'question': '¿Cuál es el río más largo de Canadá?',
    'correct': 'Mackenzie',
    'options': ['Mackenzie', 'San Lorenzo', 'Churchill', 'Nelson'],
    'difficulty': 'hard',
  },
  {
    'question': '¿Cuál es el río que atraviza Ámsterdam?',
    'correct': 'Amstel',
    'options': ['Rin', 'Mosa', 'Amstel', 'Escalda'],
    'difficulty': 'medium',
  },
  {
    'question': '¿Cuál es el río más largo de los Países Bajos?',
    'correct': 'Rin',
    'options': ['Rin', 'Mosa', 'Escalda', 'IJssel'],
    'difficulty': 'medium',
  },
  {
    'question': '¿Cuál es el río que atraviza Praga?',
    'correct': 'Moldava',
    'options': ['Moldava', 'Elba', 'Danubio', 'Vltava'],
    'difficulty': 'medium',
  },
  {
    'question': '¿Cuál es el río más largo de la República Checa?',
    'correct': 'Vltava',
    'options': ['Vltava', 'Elba', 'Moldava', 'Dyje'],
    'difficulty': 'hard',
  },
];

/// Generar preguntas de ríos
List<Map<String, dynamic>> generateRiverQuestions({required int ref}) {
  final questions = <Map<String, dynamic>>[];

  for (int i = 0; i < riversData.length; i++) {
    final river = riversData[i];

    questions.add({
      'id': 'river_${ref + i}',
      'type': 'river',
      'difficulty': river['difficulty'],
      'questionText': river['question'],
      'correctAnswer': river['correct'],
      'options': river['options'],
    });
  }

  return questions;
}
