"""Static data for seed_test_people.py (TEST project only).

Cities (with the culture used for names / languages / bios), name banks,
short positive bios in each culture's own language, and the illustrated
avatar catalogue (Google Noto Emoji, Apache-2.0, served by jsDelivr with
`Access-Control-Allow-Origin: *` and no rate limit). No real person's photo
is used anywhere.
"""

# ---------------------------------------------------------------------------
# Cultures: bio language key, spoken languages (app's English names, first =
# native), ISO origin, skin-tone weights (Noto tones 1f3fb..1f3ff).
# ---------------------------------------------------------------------------
T_NORTH = [0.45, 0.35, 0.12, 0.06, 0.02]
T_SOUTH_EU = [0.25, 0.40, 0.25, 0.08, 0.02]
T_BR = [0.15, 0.30, 0.30, 0.17, 0.08]
T_US = [0.30, 0.30, 0.20, 0.12, 0.08]
T_LATAM = [0.10, 0.35, 0.40, 0.12, 0.03]
T_EAST_ASIA = [0.35, 0.45, 0.17, 0.03, 0.0]
T_SE_ASIA = [0.05, 0.30, 0.45, 0.17, 0.03]
T_SOUTH_ASIA = [0.0, 0.10, 0.40, 0.40, 0.10]
T_MENA = [0.05, 0.35, 0.45, 0.13, 0.02]
T_AFRICA = [0.0, 0.0, 0.05, 0.35, 0.60]

CULTURES = {
    # key: (bio_lang, [native, *likely second languages], tones)
    "br": ("pt_BR", ["Portuguese (Brazil)", "English", "Spanish"], T_BR),
    "pt": ("pt_PT", ["Portuguese", "English", "Spanish", "French"], T_SOUTH_EU),
    "it": ("it", ["Italian", "English", "Spanish", "French"], T_SOUTH_EU),
    "es": ("es", ["Spanish", "English", "French", "Italian"], T_SOUTH_EU),
    "latam": ("es", ["Spanish", "English", "Portuguese"], T_LATAM),
    "fr": ("fr", ["French", "English", "Spanish", "Italian"], T_SOUTH_EU),
    "de": ("de", ["German", "English", "French", "Spanish"], T_NORTH),
    "nl": ("nl", ["Dutch", "English", "German", "French"], T_NORTH),
    "us": ("en", ["English", "Spanish", "French"], T_US),
    "uk": ("en", ["English", "French", "Spanish", "German"], T_NORTH),
    "au": ("en", ["English", "Japanese", "Chinese", "Spanish"], T_US),
    "ca": ("en", ["English", "French", "Spanish"], T_US),
    "qc": ("fr", ["French", "English", "Spanish"], T_NORTH),
    "se": ("sv", ["Swedish", "English", "German", "Spanish"], T_NORTH),
    "dk": ("da", ["Danish", "English", "German"], T_NORTH),
    "no": ("no", ["Norwegian", "English", "Swedish"], T_NORTH),
    "fi": ("fi", ["Finnish", "English", "Swedish"], T_NORTH),
    "pl": ("pl", ["Polish", "English", "German"], T_NORTH),
    "cz": ("cs", ["Czech", "English", "German"], T_NORTH),
    "hu": ("hu", ["Hungarian", "English", "German"], T_NORTH),
    "gr": ("el", ["Greek", "English", "Italian"], T_SOUTH_EU),
    "tr": ("tr", ["Turkish", "English", "German"], T_MENA),
    "ie": ("en", ["English", "Irish", "French"], T_NORTH),
    "ch": ("de", ["German", "French", "Italian", "English"], T_NORTH),
    "at": ("de", ["German", "English", "Italian"], T_NORTH),
    "be": ("fr", ["French", "Dutch", "English"], T_NORTH),
    "jp": ("ja", ["Japanese", "English"], T_EAST_ASIA),
    "kr": ("ko", ["Korean", "English", "Japanese"], T_EAST_ASIA),
    "cn": ("zh", ["Chinese", "English"], T_EAST_ASIA),
    "tw": ("zh_hant", ["Chinese", "English", "Japanese"], T_EAST_ASIA),
    "hk": ("zh_hant", ["Chinese", "English"], T_EAST_ASIA),
    "sg": ("en", ["English", "Chinese", "Malay"], T_SE_ASIA),
    "th": ("th", ["Thai", "English"], T_SE_ASIA),
    "id": ("id", ["Indonesian", "English"], T_SE_ASIA),
    "ph": ("tl", ["Filipino", "English", "Spanish"], T_SE_ASIA),
    "in": ("hi", ["Hindi", "English"], T_SOUTH_ASIA),
    "in_en": ("en", ["English", "Hindi", "Kannada"], T_SOUTH_ASIA),
    "ae": ("ar", ["Arabic", "English", "Hindi"], T_MENA),
    "eg": ("ar", ["Arabic", "English", "French"], T_MENA),
    "ma": ("fr", ["Arabic", "French", "Spanish", "English"], T_MENA),
    "il": ("he", ["Hebrew", "English", "Arabic"], T_MENA),
    "ng": ("en", ["English", "Yoruba", "French"], T_AFRICA),
    "gh": ("en", ["English", "Twi", "French"], T_AFRICA),
    "ke": ("sw", ["Swahili", "English", "French"], T_AFRICA),
    "za": ("en", ["English", "Afrikaans", "Zulu"], [0.20, 0.10, 0.15, 0.25, 0.30]),
    "sn": ("fr", ["French", "Wolof", "English"], T_AFRICA),
}

# ---------------------------------------------------------------------------
# Cities: (name, local name for bios, country (English, as stored), ISO,
#          lat, lng, culture, weight)
# ---------------------------------------------------------------------------
CITIES = [
    # Brazil
    ("São Paulo", "São Paulo", "Brazil", "BR", -23.5505, -46.6333, "br", 6),
    ("Rio de Janeiro", "Rio de Janeiro", "Brazil", "BR", -22.9068, -43.1729, "br", 5),
    ("Belo Horizonte", "Belo Horizonte", "Brazil", "BR", -19.9167, -43.9345, "br", 3),
    ("Curitiba", "Curitiba", "Brazil", "BR", -25.4284, -49.2733, "br", 3),
    ("Porto Alegre", "Porto Alegre", "Brazil", "BR", -30.0346, -51.2177, "br", 3),
    ("Salvador", "Salvador", "Brazil", "BR", -12.9777, -38.5016, "br", 3),
    ("Recife", "Recife", "Brazil", "BR", -8.0476, -34.8770, "br", 2),
    ("Fortaleza", "Fortaleza", "Brazil", "BR", -3.7319, -38.5267, "br", 2),
    ("Brasília", "Brasília", "Brazil", "BR", -15.7939, -47.8828, "br", 3),
    ("Florianópolis", "Florianópolis", "Brazil", "BR", -27.5954, -48.5480, "br", 2),
    ("Manaus", "Manaus", "Brazil", "BR", -3.1190, -60.0217, "br", 1),
    ("Campinas", "Campinas", "Brazil", "BR", -22.9099, -47.0626, "br", 2),
    # Europe
    ("Rome", "Roma", "Italy", "IT", 41.9028, 12.4964, "it", 4),
    ("Milan", "Milano", "Italy", "IT", 45.4642, 9.1900, "it", 4),
    ("Naples", "Napoli", "Italy", "IT", 40.8518, 14.2681, "it", 2),
    ("Florence", "Firenze", "Italy", "IT", 43.7696, 11.2558, "it", 2),
    ("Bologna", "Bologna", "Italy", "IT", 44.4949, 11.3426, "it", 1),
    ("Lisbon", "Lisboa", "Portugal", "PT", 38.7223, -9.1393, "pt", 4),
    ("Porto", "Porto", "Portugal", "PT", 41.1579, -8.6291, "pt", 2),
    ("Madrid", "Madrid", "Spain", "ES", 40.4168, -3.7038, "es", 4),
    ("Barcelona", "Barcelona", "Spain", "ES", 41.3874, 2.1686, "es", 4),
    ("Seville", "Sevilla", "Spain", "ES", 37.3891, -5.9845, "es", 2),
    ("Valencia", "Valencia", "Spain", "ES", 39.4699, -0.3763, "es", 2),
    ("Paris", "Paris", "France", "FR", 48.8566, 2.3522, "fr", 5),
    ("Lyon", "Lyon", "France", "FR", 45.7640, 4.8357, "fr", 2),
    ("Marseille", "Marseille", "France", "FR", 43.2965, 5.3698, "fr", 2),
    ("Berlin", "Berlin", "Germany", "DE", 52.5200, 13.4050, "de", 4),
    ("Munich", "München", "Germany", "DE", 48.1351, 11.5820, "de", 3),
    ("Hamburg", "Hamburg", "Germany", "DE", 53.5511, 9.9937, "de", 2),
    ("Cologne", "Köln", "Germany", "DE", 50.9375, 6.9603, "de", 2),
    ("Vienna", "Wien", "Austria", "AT", 48.2082, 16.3738, "at", 2),
    ("Zurich", "Zürich", "Switzerland", "CH", 47.3769, 8.5417, "ch", 2),
    ("Amsterdam", "Amsterdam", "Netherlands", "NL", 52.3676, 4.9041, "nl", 3),
    ("Rotterdam", "Rotterdam", "Netherlands", "NL", 51.9244, 4.4777, "nl", 1),
    ("Brussels", "Bruxelles", "Belgium", "BE", 50.8503, 4.3517, "be", 2),
    ("London", "London", "United Kingdom", "GB", 51.5074, -0.1278, "uk", 5),
    ("Manchester", "Manchester", "United Kingdom", "GB", 53.4808, -2.2426, "uk", 2),
    ("Edinburgh", "Edinburgh", "United Kingdom", "GB", 55.9533, -3.1883, "uk", 1),
    ("Dublin", "Dublin", "Ireland", "IE", 53.3498, -6.2603, "ie", 2),
    ("Stockholm", "Stockholm", "Sweden", "SE", 59.3293, 18.0686, "se", 2),
    ("Copenhagen", "København", "Denmark", "DK", 55.6761, 12.5683, "dk", 2),
    ("Oslo", "Oslo", "Norway", "NO", 59.9139, 10.7522, "no", 2),
    ("Helsinki", "Helsinki", "Finland", "FI", 60.1699, 24.9384, "fi", 1),
    ("Warsaw", "Warszawa", "Poland", "PL", 52.2297, 21.0122, "pl", 2),
    ("Krakow", "Kraków", "Poland", "PL", 50.0647, 19.9450, "pl", 1),
    ("Prague", "Praha", "Czech Republic", "CZ", 50.0755, 14.4378, "cz", 2),
    ("Budapest", "Budapest", "Hungary", "HU", 47.4979, 19.0402, "hu", 2),
    ("Athens", "Αθήνα", "Greece", "GR", 37.9838, 23.7275, "gr", 2),
    ("Istanbul", "İstanbul", "Turkey", "TR", 41.0082, 28.9784, "tr", 3),
    # USA
    ("New York", "New York", "United States", "US", 40.7128, -74.0060, "us", 6),
    ("Los Angeles", "Los Angeles", "United States", "US", 34.0522, -118.2437, "us", 4),
    ("San Francisco", "San Francisco", "United States", "US", 37.7749, -122.4194, "us", 3),
    ("Chicago", "Chicago", "United States", "US", 41.8781, -87.6298, "us", 3),
    ("Miami", "Miami", "United States", "US", 25.7617, -80.1918, "us", 3),
    ("Austin", "Austin", "United States", "US", 30.2672, -97.7431, "us", 2),
    ("Seattle", "Seattle", "United States", "US", 47.6062, -122.3321, "us", 2),
    ("Boston", "Boston", "United States", "US", 42.3601, -71.0589, "us", 2),
    ("Washington", "Washington", "United States", "US", 38.9072, -77.0369, "us", 2),
    ("Houston", "Houston", "United States", "US", 29.7604, -95.3698, "us", 2),
    # Americas (rest)
    ("Toronto", "Toronto", "Canada", "CA", 43.6532, -79.3832, "ca", 3),
    ("Vancouver", "Vancouver", "Canada", "CA", 49.2827, -123.1207, "ca", 2),
    ("Montreal", "Montréal", "Canada", "CA", 45.5017, -73.5673, "qc", 2),
    ("Mexico City", "Ciudad de México", "Mexico", "MX", 19.4326, -99.1332, "latam", 4),
    ("Guadalajara", "Guadalajara", "Mexico", "MX", 20.6597, -103.3496, "latam", 1),
    ("Buenos Aires", "Buenos Aires", "Argentina", "AR", -34.6037, -58.3816, "latam", 4),
    ("Santiago", "Santiago", "Chile", "CL", -33.4489, -70.6693, "latam", 2),
    ("Lima", "Lima", "Peru", "PE", -12.0464, -77.0428, "latam", 2),
    ("Bogotá", "Bogotá", "Colombia", "CO", 4.7110, -74.0721, "latam", 2),
    ("Medellín", "Medellín", "Colombia", "CO", 6.2442, -75.5812, "latam", 2),
    ("Montevideo", "Montevideo", "Uruguay", "UY", -34.9011, -56.1645, "latam", 1),
    # Asia
    ("Tokyo", "東京", "Japan", "JP", 35.6762, 139.6503, "jp", 4),
    ("Osaka", "大阪", "Japan", "JP", 34.6937, 135.5023, "jp", 2),
    ("Seoul", "서울", "South Korea", "KR", 37.5665, 126.9780, "kr", 3),
    ("Beijing", "北京", "China", "CN", 39.9042, 116.4074, "cn", 2),
    ("Shanghai", "上海", "China", "CN", 31.2304, 121.4737, "cn", 2),
    ("Hong Kong", "香港", "Hong Kong", "HK", 22.3193, 114.1694, "hk", 2),
    ("Taipei", "台北", "Taiwan", "TW", 25.0330, 121.5654, "tw", 2),
    ("Singapore", "Singapore", "Singapore", "SG", 1.3521, 103.8198, "sg", 2),
    ("Bangkok", "กรุงเทพฯ", "Thailand", "TH", 13.7563, 100.5018, "th", 3),
    ("Jakarta", "Jakarta", "Indonesia", "ID", -6.2088, 106.8456, "id", 2),
    ("Denpasar", "Bali", "Indonesia", "ID", -8.6705, 115.2126, "id", 2),
    ("Manila", "Maynila", "Philippines", "PH", 14.5995, 120.9842, "ph", 2),
    ("Mumbai", "मुंबई", "India", "IN", 19.0760, 72.8777, "in", 3),
    ("New Delhi", "दिल्ली", "India", "IN", 28.6139, 77.2090, "in", 2),
    ("Bangalore", "Bangalore", "India", "IN", 12.9716, 77.5946, "in_en", 2),
    ("Dubai", "دبي", "United Arab Emirates", "AE", 25.2048, 55.2708, "ae", 2),
    ("Tel Aviv", "תל אביב", "Israel", "IL", 32.0853, 34.7818, "il", 1),
    # Africa
    ("Lagos", "Lagos", "Nigeria", "NG", 6.5244, 3.3792, "ng", 2),
    ("Accra", "Accra", "Ghana", "GH", 5.6037, -0.1870, "gh", 1),
    ("Nairobi", "Nairobi", "Kenya", "KE", -1.2921, 36.8219, "ke", 2),
    ("Cape Town", "Cape Town", "South Africa", "ZA", -33.9249, 18.4241, "za", 2),
    ("Johannesburg", "Johannesburg", "South Africa", "ZA", -26.2041, 28.0473, "za", 1),
    ("Cairo", "القاهرة", "Egypt", "EG", 30.0444, 31.2357, "eg", 2),
    ("Marrakech", "Marrakech", "Morocco", "MA", 31.6295, -7.9811, "ma", 1),
    ("Casablanca", "Casablanca", "Morocco", "MA", 33.5731, -7.5898, "ma", 1),
    ("Dakar", "Dakar", "Senegal", "SN", 14.7167, -17.4677, "sn", 1),
    # Oceania
    ("Sydney", "Sydney", "Australia", "AU", -33.8688, 151.2093, "au", 3),
    ("Melbourne", "Melbourne", "Australia", "AU", -37.8136, 144.9631, "au", 2),
    ("Auckland", "Auckland", "New Zealand", "NZ", -36.8485, 174.7633, "au", 1),
]

# Dense clusters so Discovery "nearby" shows people (radius km, count).
CLUSTERS = [("São Paulo", 60, 25.0), ("Rome", 60, 22.0), ("Lisbon", 60, 20.0), ("New York", 60, 22.0)]

# ---------------------------------------------------------------------------
# Names: culture -> (male first, female first, surnames)
# ---------------------------------------------------------------------------
_N = {
    "br": ("Lucas Gabriel Rafael Matheus Pedro Gustavo Felipe Bruno Thiago Diego Caio Vinícius Leonardo João Henrique",
           "Ana Beatriz Camila Juliana Larissa Mariana Fernanda Letícia Gabriela Isabela Amanda Júlia Carolina Bruna Luana",
           "Silva Santos Oliveira Souza Lima Pereira Costa Rodrigues Almeida Nascimento Carvalho Ribeiro Gomes Martins Araújo"),
    "pt": ("João Tiago Miguel Rodrigo Duarte Gonçalo Rui Nuno Diogo André Francisco Ricardo",
           "Inês Beatriz Mariana Catarina Sofia Rita Leonor Joana Marta Carolina Teresa Matilde",
           "Ferreira Santos Pereira Costa Martins Rodrigues Sousa Fernandes Gonçalves Lopes Marques Almeida"),
    "it": ("Marco Luca Alessandro Matteo Lorenzo Giovanni Andrea Francesco Davide Simone Riccardo Stefano Paolo",
           "Giulia Chiara Francesca Sara Martina Alessia Valentina Elena Federica Sofia Aurora Beatrice Ilaria",
           "Rossi Russo Ferrari Esposito Bianchi Romano Colombo Ricci Marino Greco Bruno Gallo Conti De Luca Costa"),
    "es": ("Pablo Javier Alejandro Daniel Sergio Adrián Álvaro Carlos Hugo Marcos Diego Iván",
           "Lucía María Paula Laura Marta Carmen Elena Sara Andrea Irene Claudia Nerea",
           "García Martínez López Sánchez González Pérez Rodríguez Fernández Gómez Ruiz Díaz Moreno"),
    "latam": ("Santiago Mateo Sebastián Nicolás Diego Juan Andrés Felipe Emiliano Joaquín Tomás Gabriel",
              "Valentina Camila Sofía Isabella Daniela Mariana Fernanda Gabriela Catalina Renata Florencia Ximena",
              "Hernández García Martínez López González Rodríguez Pérez Sánchez Ramírez Torres Flores Vargas Castro Rojas"),
    "fr": ("Lucas Hugo Louis Gabriel Arthur Jules Théo Nathan Raphaël Antoine Maxime Julien",
           "Emma Léa Chloé Manon Camille Inès Sarah Juliette Louise Clara Margaux Pauline",
           "Martin Bernard Dubois Thomas Robert Richard Petit Durand Leroy Moreau Laurent Lefebvre"),
    "qc": ("William Olivier Félix Samuel Gabriel Mathis Étienne Xavier Antoine Zachary",
           "Florence Alice Rosalie Charlotte Léa Juliette Béatrice Maude Émilie Noémie",
           "Tremblay Gagnon Roy Côté Bouchard Gauthier Morin Lavoie Fortin Gagné"),
    "be": ("Arthur Louis Noah Jules Victor Lucas Adam Liam Mathis Nathan",
           "Olivia Emma Louise Alice Mila Lina Elena Juliette Camille Chloé",
           "Peeters Janssens Maes Jacobs Mertens Willems Claes Goossens Dubois Lambert"),
    "de": ("Lukas Jonas Leon Felix Maximilian Paul Niklas Tim Jan Moritz Florian Tobias",
           "Anna Lena Laura Lea Sophie Hannah Marie Julia Lisa Johanna Katharina Clara",
           "Müller Schmidt Schneider Fischer Weber Meyer Wagner Becker Schulz Hoffmann Koch Richter"),
    "at": ("Lukas Tobias David Florian Simon Elias Fabian Julian Stefan Michael",
           "Anna Lena Sarah Katharina Julia Magdalena Theresa Viktoria Lisa Sophie",
           "Gruber Huber Bauer Wagner Pichler Steiner Moser Mayer Hofer Leitner"),
    "ch": ("Noah Luca Leon David Nico Gian Lars Jonas Fabio Reto",
           "Mia Lara Lea Nina Elena Selina Alina Seraina Laura Anja",
           "Müller Meier Schmid Keller Weber Huber Schneider Meyer Steiner Fischer"),
    "nl": ("Daan Sem Lucas Milan Thijs Jesse Bram Ruben Lars Niels",
           "Emma Sanne Lotte Fleur Julia Anouk Lieke Femke Isa Eva",
           "de Jong Jansen de Vries van den Berg van Dijk Bakker Visser Smit Meijer de Boer"),
    "us": ("James Michael Ethan Noah Liam Mason Logan Jacob Tyler Brandon Marcus Jordan Kevin Daniel Ryan",
           "Emily Olivia Madison Ava Sophia Hannah Abigail Ashley Jessica Taylor Brianna Chloe Maya Grace Natalie",
           "Smith Johnson Williams Brown Jones Miller Davis Wilson Anderson Taylor Thomas Moore Jackson Martin Lee"),
    "uk": ("Oliver Harry George Jack Charlie Thomas Oscar James William Alfie Henry Freddie",
           "Amelia Olivia Isla Emily Poppy Ava Isabella Jessica Lily Sophie Grace Evie",
           "Smith Jones Taylor Brown Williams Wilson Johnson Davies Robinson Wright Thompson Evans"),
    "ie": ("Seán Conor Cian Darragh Oisín Liam Eoin Ciarán Patrick Rory",
           "Aoife Ciara Niamh Saoirse Siobhán Róisín Orla Emma Sinéad Clodagh",
           "Murphy Kelly O'Sullivan Walsh Smith O'Brien Byrne Ryan O'Connor Doyle"),
    "au": ("Jack William Oliver Thomas Lachlan Cooper Riley Mitchell Hamish Liam",
           "Charlotte Olivia Mia Chloe Isla Matilda Ruby Sienna Harper Zoe",
           "Smith Jones Williams Brown Wilson Taylor Nguyen Johnson Martin White"),
    "ca": ("Liam Noah Ethan Logan Owen Benjamin Lucas Nathan Ryan Connor",
           "Olivia Emma Charlotte Ava Sophie Chloe Abigail Emily Hannah Madison",
           "Smith Brown Tremblay Martin Roy Wilson MacDonald Taylor Campbell Anderson"),
    "se": ("Erik Lars Johan Oscar William Lucas Elias Hugo Axel Filip",
           "Emma Maja Elsa Alice Ebba Wilma Saga Astrid Linnea Klara",
           "Andersson Johansson Karlsson Nilsson Eriksson Larsson Olsson Persson Svensson Gustafsson"),
    "dk": ("Mikkel Rasmus Frederik Mads Emil Oliver Christian Magnus Anders Jonas",
           "Sofie Ida Freja Emma Clara Laura Mathilde Anna Signe Cecilie",
           "Nielsen Jensen Hansen Pedersen Andersen Christensen Larsen Sørensen Rasmussen Jørgensen"),
    "no": ("Jakob Emil Henrik Sander Magnus Ola Håkon Sindre Even Kristian",
           "Nora Emma Ingrid Sara Thea Ida Maja Silje Hanna Marte",
           "Hansen Johansen Olsen Larsen Andersen Pedersen Nilsen Kristiansen Jensen Berg"),
    "fi": ("Juho Mikko Eero Aleksi Ville Antti Joonas Lauri Onni Elias",
           "Aino Emilia Sofia Venla Ella Aada Iida Siiri Helmi Kaisa",
           "Korhonen Virtanen Mäkinen Nieminen Mäkelä Hämäläinen Laine Heikkinen Koskinen Järvinen"),
    "pl": ("Jakub Kacper Szymon Mateusz Michał Bartosz Piotr Tomasz Paweł Kamil",
           "Zuzanna Julia Maja Aleksandra Natalia Wiktoria Karolina Magdalena Agnieszka Kinga",
           "Nowak Kowalski Wiśniewski Wójcik Kowalczyk Kamiński Lewandowski Zieliński Szymański Dąbrowski"),
    "cz": ("Jakub Jan Tomáš Lukáš Matěj Ondřej Petr Vojtěch Martin David",
           "Tereza Eliška Anna Adéla Karolína Natálie Kateřina Lucie Barbora Klára",
           "Novák Svoboda Novotný Dvořák Černý Procházka Kučera Veselý Horák Němec"),
    "hu": ("Bence Máté Levente Dávid Ádám Balázs Gergő Péter Zoltán Márk",
           "Hanna Anna Zsófia Luca Réka Eszter Dóra Nóra Petra Fanni",
           "Nagy Kovács Tóth Szabó Horváth Varga Kiss Molnár Németh Farkas"),
    "gr": ("Giorgos Dimitris Nikos Kostas Giannis Christos Panagiotis Alexandros Vasilis Stavros",
           "Maria Eleni Katerina Sofia Georgia Dimitra Anna Ioanna Christina Despina",
           "Papadopoulos Papadakis Georgiou Nikolaidis Konstantinidis Pappas Dimitriou Ioannou Vlachos Karagiannis"),
    "tr": ("Emre Mehmet Can Burak Mert Ahmet Kerem Deniz Murat Onur",
           "Elif Zeynep Ayşe Defne Ece Selin Merve Esra Büşra Deniz",
           "Yılmaz Kaya Demir Şahin Çelik Yıldız Yıldırım Öztürk Aydın Özdemir"),
    "jp": ("Haruto Ren Sota Yuto Kaito Takumi Riku Hiroshi Kenji Daiki",
           "Yui Aoi Hina Sakura Yuna Mio Rin Haruka Akari Nanami",
           "Sato Suzuki Takahashi Tanaka Watanabe Ito Yamamoto Nakamura Kobayashi Kato"),
    "kr": ("Minjun Seojun Doyun Jiho Hyunwoo Jiwon Taeyang Junho Seungmin Donghyun",
           "Seoyeon Jiwoo Haeun Minseo Yuna Jiyeon Soyeon Eunji Hayoung Dahye",
           "Kim Lee Park Choi Jung Kang Cho Yoon Jang Lim"),
    "cn": ("Wei Hao Jie Lei Yang Chen Ming Tao Bo Jun",
           "Li Na Fang Mei Xin Yan Jing Hui Ying Xiu",
           "Wang Li Zhang Liu Chen Yang Huang Zhao Wu Zhou"),
    "tw": ("Chih-Hao Wei-Lun Yu-Ting Chia-Hsin Po-Wei Cheng-Han Kuan-Yu Yi-Hsuan Tzu-Yang Hsin-Yu",
           "Yi-Ting Shu-Fen Hsin-Yi Pei-Shan Ya-Ting Chia-Yi Wan-Ting Hui-Chun Yu-Chen Mei-Ling",
           "Chen Lin Huang Chang Lee Wang Wu Liu Tsai Yang"),
    "hk": ("Ka-Ho Chun-Kit Wing-Hong Ho-Yin Tsz-Hin Kevin Jason Ryan Marcus Edmund",
           "Wing-Yan Hoi-Yee Ka-Man Tsz-Ching Sze-Wing Michelle Karen Vivian Cherry Joyce",
           "Chan Wong Lee Cheung Lau Ng Ho Leung Tsang Yip"),
    "sg": ("Wei Jie Jun Hao Zhi Hao Ryan Marcus Arjun Hafiz Daniel Ethan Darren",
           "Hui Min Xin Yi Jia Hui Priya Nur Aisyah Rachel Sarah Michelle Charmaine Shu Ting",
           "Tan Lim Lee Ng Ong Wong Goh Chua Koh Teo"),
    "th": ("Somchai Anan Thanakorn Krit Nattapong Pong Chai Wichai Arthit Kittisak",
           "Siriporn Nicha Pimchanok Kanya Malee Ploy Naree Achara Dao Suda",
           "Saetang Srisuk Wongsakul Chaiyaporn Rattanakorn Boonmee Sukjai Thongdee Phrommin Kaewkla"),
    "id": ("Budi Agus Rizky Dimas Fajar Arif Yoga Bayu Andi Reza",
           "Siti Dewi Putri Ayu Rina Intan Wulan Fitri Nadia Sari",
           "Santoso Wijaya Pratama Saputra Hidayat Kusuma Nugroho Setiawan Gunawan Halim"),
    "ph": ("Juan Jose Mark Paolo Carlo Miguel Rafael Gabriel Angelo Jericho",
           "Maria Angel Princess Joy Kristine Andrea Bea Nicole Patricia Camille",
           "Santos Reyes Cruz Bautista Ocampo Garcia Mendoza Torres Villanueva Ramos"),
    "in": ("Aarav Vihaan Arjun Rohan Aditya Kabir Ishaan Rahul Karan Siddharth",
           "Ananya Aadhya Diya Priya Kavya Isha Neha Riya Saanvi Meera",
           "Sharma Verma Gupta Patel Singh Kumar Mehta Joshi Iyer Reddy"),
    "in_en": ("Arjun Karthik Vikram Rohan Pranav Nikhil Aditya Varun Suresh Abhishek",
              "Ananya Divya Lakshmi Sneha Pooja Shreya Kavya Nandini Aishwarya Deepa",
              "Rao Reddy Iyer Nair Shetty Menon Kumar Hegde Pillai Krishnan"),
    "ae": ("Mohammed Ahmed Omar Khalid Rashid Saeed Yousef Hamdan Sultan Faisal",
           "Fatima Mariam Aisha Noura Hessa Sara Latifa Maitha Shamma Amna",
           "Al Mansouri Al Nuaimi Al Hashimi Al Mazrouei Al Suwaidi Al Falasi Al Ketbi Al Zaabi Al Shamsi Al Marri"),
    "eg": ("Ahmed Mohamed Mahmoud Omar Youssef Karim Mostafa Tarek Amr Hassan",
           "Nour Salma Yasmin Mariam Farida Habiba Dina Rana Aya Laila",
           "Hassan Ibrahim Mahmoud Ali Abdelrahman Mostafa Salem Fathy Gamal Nasser"),
    "ma": ("Youssef Amine Mehdi Hamza Omar Anas Ayoub Karim Rachid Adil",
           "Salma Imane Yasmine Khadija Fatima Zineb Meryem Hajar Leila Sanaa",
           "Alaoui Bennani Tazi El Idrissi Benjelloun Chraibi Berrada El Amrani Lahlou Fassi"),
    "il": ("Noam Itai Yonatan Omer Eitan Daniel Ariel Lior Amit Yuval",
           "Noa Maya Tamar Yael Shira Michal Roni Talia Adi Hila",
           "Cohen Levi Mizrahi Peretz Biton Friedman Avraham Katz Azoulay Shapiro"),
    "ng": ("Chinedu Emeka Tunde Oluwaseun Babatunde Ifeanyi Uche Segun Kelechi Femi",
           "Chiamaka Adaeze Ngozi Funmilayo Temitope Aisha Blessing Yetunde Ifeoma Bisola",
           "Okafor Adeyemi Okonkwo Balogun Eze Adebayo Nwosu Ogunleye Chukwu Afolabi"),
    "gh": ("Kwame Kofi Kojo Yaw Kwabena Nana Kwesi Kweku Ebo Fiifi",
           "Ama Akosua Abena Esi Efua Adwoa Yaa Afua Akua Araba",
           "Mensah Asante Owusu Boateng Osei Agyeman Appiah Ansah Darko Badu"),
    "ke": ("Brian Kevin Dennis Collins Victor Felix Kamau Otieno Mwangi Kiprop",
           "Faith Mercy Wanjiru Akinyi Achieng Njeri Wambui Chebet Atieno Grace",
           "Mwangi Otieno Kamau Wanjiku Odhiambo Kariuki Ochieng Njoroge Kiprotich Mutua"),
    "za": ("Thabo Sipho Liam Pieter Johan Lwazi Kagiso Tshepo Ruan Mandla",
           "Lerato Naledi Thandi Zanele Anika Lindiwe Nomvula Chloé Refilwe Megan",
           "Nkosi Dlamini Van der Merwe Botha Mokoena Khumalo Naidoo Pretorius Ndlovu Smith"),
    "sn": ("Mamadou Moussa Ibrahima Cheikh Abdou Ousmane Modou Pape Babacar Aliou",
           "Fatou Aminata Awa Mariama Khady Aïssatou Ndeye Coumba Binta Rokhaya",
           "Diop Ndiaye Fall Sow Ba Gueye Sarr Diallo Faye Mbaye"),
}


def _split(s: str):
    return s.split()


def _names(culture: str):
    m, f, s = _N[culture]
    if culture in ("ae",):
        return _split(m), _split(f), [x.replace("_", " ") for x in s.replace("Al ", "Al_").split()]
    if culture in ("nl",):
        sur = ["de Jong", "Jansen", "de Vries", "van den Berg", "van Dijk", "Bakker", "Visser", "Smit", "Meijer", "de Boer"]
        return _split(m), _split(f), sur
    if culture in ("sg",):
        mm = ["Wei Jie", "Jun Hao", "Zhi Hao", "Ryan", "Marcus", "Arjun", "Hafiz", "Daniel", "Ethan", "Darren"]
        ff = ["Hui Min", "Xin Yi", "Jia Hui", "Priya", "Nur Aisyah", "Rachel", "Sarah", "Michelle", "Charmaine", "Shu Ting"]
        return mm, ff, _split(s)
    if culture in ("za",):
        sur = ["Nkosi", "Dlamini", "van der Merwe", "Botha", "Mokoena", "Khumalo", "Naidoo", "Pretorius", "Ndlovu", "Smith"]
        return _split(m), _split(f), sur
    if culture == "ma":
        sur = ["Alaoui", "Bennani", "Tazi", "El Idrissi", "Benjelloun", "Chraibi", "Berrada", "El Amrani", "Lahlou", "Fassi"]
        return _split(m), _split(f), sur
    if culture == "it":
        sur = _split(s.replace("De Luca", "De_Luca"))
        return _split(m), _split(f), [x.replace("_", " ") for x in sur]
    return _split(m), _split(f), _split(s)


NAMES = {c: _names(c) for c in _N}

# ---------------------------------------------------------------------------
# Bios: language -> (openers with {city}, closers). Short and positive.
# ---------------------------------------------------------------------------
BIOS = {
    "pt_BR": (["Moro em {city} e adoro conhecer gente nova.", "De {city} para o mundo 🌎",
               "Curto um bom café e conversas sem pressa em {city}.", "Sempre sonhando com a próxima viagem, mas {city} é minha casa."],
              ["Bora trocar dicas de viagem?", "Quero praticar inglês e espanhol.",
               "Topo um rolê cultural no fim de semana.", "Me chama para um café! ☕"]),
    "pt_PT": (["Vivo em {city} e gosto de conhecer pessoas de outras culturas.", "De {city}, com um sorriso.",
               "Sempre à procura de um bom café e de uma boa conversa em {city}.", "Adoro viajar, mas {city} é a minha casa."],
              ["Vamos trocar dicas de viagem?", "Quero praticar o meu inglês.",
               "Um passeio pela cidade? Conta comigo.", "Manda mensagem! 😊"]),
    "it": (["Vivo a {city} e amo conoscere persone nuove.", "Da {city} con il sorriso.",
            "Sempre in cerca di un buon caffè e di belle chiacchiere a {city}.", "Amo viaggiare, ma {city} resta casa mia."],
           ["Scambiamo consigli di viaggio?", "Vorrei migliorare il mio inglese.",
            "Un aperitivo in centro? Ci sto!", "Scrivimi pure! 😊"]),
    "es": (["Vivo en {city} y me encanta conocer gente nueva.", "Desde {city} con buena onda.",
            "Siempre buscando un buen café y una buena charla en {city}.", "Me encanta viajar, pero {city} es mi hogar."],
           ["¿Intercambiamos consejos de viaje?", "Quiero practicar mi inglés.",
            "¿Un paseo por la ciudad? ¡Me apunto!", "¡Escríbeme! 😊"]),
    "fr": (["J'habite à {city} et j'adore rencontrer de nouvelles personnes.", "De {city}, avec le sourire.",
            "Toujours à la recherche d'un bon café et d'une belle conversation à {city}.", "J'adore voyager, mais {city} reste ma maison."],
           ["On échange des conseils de voyage ?", "J'aimerais améliorer mon anglais.",
            "Une balade en ville ? Avec plaisir !", "Écris-moi ! 😊"]),
    "de": (["Ich lebe in {city} und lerne gern neue Leute kennen.", "Viele Grüße aus {city}!",
            "Immer auf der Suche nach gutem Kaffee und guten Gesprächen in {city}.", "Ich reise gern, aber {city} ist mein Zuhause."],
           ["Lust auf einen Austausch von Reisetipps?", "Ich möchte mein Spanisch verbessern.",
            "Ein Spaziergang durch die Stadt? Sehr gern!", "Schreib mir einfach! 😊"]),
    "en": (["Living in {city} and always happy to meet new people.", "Hello from {city}!",
            "Always hunting for good coffee and great conversations in {city}.", "Love to travel, but {city} is home."],
           ["Let's swap travel tips!", "Learning Spanish, happy to help with English.",
            "Up for a city walk or a museum day.", "Say hi! 😊"]),
    "nl": (["Ik woon in {city} en ontmoet graag nieuwe mensen.", "Groetjes uit {city}!",
            "Altijd op zoek naar goede koffie en fijne gesprekken in {city}.", "Ik reis graag, maar {city} is thuis."],
           ["Zullen we reistips uitwisselen?", "Ik wil mijn Spaans oefenen.",
            "Zin in een stadswandeling? Ik ben erbij!", "Stuur gerust een berichtje! 😊"]),
    "sv": (["Jag bor i {city} och gillar att träffa nya människor.", "Hälsningar från {city}!",
            "Alltid på jakt efter gott kaffe och bra samtal i {city}.", "Jag älskar att resa, men {city} är hemma."],
           ["Ska vi byta resetips?", "Jag vill öva min spanska.", "En promenad i stan? Gärna!", "Skriv till mig! 😊"]),
    "da": (["Jeg bor i {city} og elsker at møde nye mennesker.", "Hilsner fra {city}!",
            "Altid på jagt efter god kaffe og gode samtaler i {city}.", "Jeg elsker at rejse, men {city} er hjemme."],
           ["Skal vi bytte rejsetips?", "Jeg vil gerne øve mit spansk.", "En gåtur i byen? Jeg er med!", "Skriv endelig! 😊"]),
    "no": (["Jeg bor i {city} og liker å møte nye mennesker.", "Hilsen fra {city}!",
            "Alltid på jakt etter god kaffe og gode samtaler i {city}.", "Jeg elsker å reise, men {city} er hjemme."],
           ["Skal vi bytte reisetips?", "Jeg vil øve på spansken min.", "En tur i byen? Jeg er med!", "Send meg en melding! 😊"]),
    "fi": (["Kotikaupunkini on {city}, ja tapaan mielelläni uusia ihmisiä.", "Terveisiä kaupungista {city}!",
            "Etsin aina hyvää kahvia ja mukavia keskusteluja.", "Rakastan matkustamista, mutta {city} on kotini."],
           ["Vaihdetaanko matkavinkkejä?", "Haluan harjoitella espanjaa.", "Kävelylle kaupungille? Mielelläni!", "Laita viestiä! 😊"]),
    "pl": (["Moje miasto to {city} i uwielbiam poznawać nowych ludzi.", "Pozdrowienia z miasta {city}!",
            "Zawsze szukam dobrej kawy i ciekawych rozmów.", "Kocham podróże, ale {city} to mój dom."],
           ["Wymienimy się wskazówkami podróżniczymi?", "Chcę poćwiczyć hiszpański.", "Spacer po mieście? Chętnie!", "Napisz do mnie! 😊"]),
    "cs": (["Moje město je {city} a baví mě poznávat nové lidi.", "Pozdrav z města {city}!",
            "Pořád hledám dobrou kávu a dobré rozhovory.", "Miluju cestování, ale {city} je můj domov."],
           ["Vyměníme si cestovatelské tipy?", "Chci si procvičit angličtinu.", "Procházka po městě? Jasně!", "Napiš mi! 😊"]),
    "hu": (["A városom {city}, és szeretek új embereket megismerni.", "Üdvözlet innen: {city}!",
            "Mindig keresem a jó kávét és a jó beszélgetéseket.", "Imádok utazni, de {city} az otthonom."],
           ["Cseréljünk utazási tippeket?", "Szeretném gyakorolni az angolt.", "Egy séta a városban? Benne vagyok!", "Írj nyugodtan! 😊"]),
    "el": (["Η πόλη μου είναι η {city} και μου αρέσει να γνωρίζω νέους ανθρώπους.", "Χαιρετίσματα από την {city}!",
            "Πάντα ψάχνω καλό καφέ και ωραίες κουβέντες.", "Λατρεύω τα ταξίδια, αλλά η {city} είναι το σπίτι μου."],
           ["Ανταλλάσσουμε ταξιδιωτικές συμβουλές;", "Θέλω να εξασκήσω τα αγγλικά μου.", "Μια βόλτα στην πόλη; Μέσα!", "Στείλε μου μήνυμα! 😊"]),
    "tr": (["Şehrim {city}, yeni insanlarla tanışmayı seviyorum.", "{city} şehrinden selamlar!",
            "Her zaman iyi bir kahve ve güzel bir sohbet peşindeyim.", "Seyahat etmeyi çok seviyorum ama evim {city}."],
           ["Seyahat önerileri paylaşalım mı?", "İngilizcemi geliştirmek istiyorum.", "Şehirde bir yürüyüş? Varım!", "Yazmaktan çekinme! 😊"]),
    "ja": (["{city}に住んでいます。新しい人と出会うのが好きです。", "{city}からこんにちは！",
            "おいしいコーヒーと楽しい会話が大好きです。", "旅行が大好きだけど、やっぱり{city}が一番。"],
           ["旅行のおすすめを交換しませんか？", "英語を練習したいです。", "一緒に街歩きしましょう！", "気軽にメッセージください😊"]),
    "ko": (["{city}에 살고 있어요. 새로운 사람들을 만나는 걸 좋아해요.", "{city}에서 인사드려요!",
            "맛있는 커피와 즐거운 대화를 좋아해요.", "여행을 좋아하지만 {city}에서 사는 게 제일 좋아요."],
           ["여행 팁 공유해요!", "영어를 연습하고 싶어요.", "같이 산책해요!", "편하게 메시지 주세요 😊"]),
    "zh": (["我住在{city}，喜欢认识新朋友。", "来自{city}的问候！", "总在寻找好喝的咖啡和有趣的聊天。", "我热爱旅行，但{city}是我的家。"],
           ["一起交流旅行心得吧！", "想练习英语。", "一起去城市散步吧！", "欢迎给我发消息😊"]),
    "zh_hant": (["我住在{city}，喜歡認識新朋友。", "來自{city}的問候！", "總在尋找好喝的咖啡和有趣的聊天。", "我熱愛旅行，但{city}是我的家。"],
                ["一起交流旅行心得吧！", "想練習英文。", "一起去城市散步吧！", "歡迎傳訊息給我😊"]),
    "th": (["อาศัยอยู่ที่{city} ชอบรู้จักเพื่อนใหม่", "สวัสดีจาก{city}!", "ชอบกาแฟอร่อยๆ และการพูดคุยดีๆ", "ชอบเที่ยวมาก แต่{city}คือบ้าน"],
           ["มาแลกเปลี่ยนทริปเที่ยวกัน!", "อยากฝึกภาษาอังกฤษ", "ไปเดินเล่นในเมืองกันไหม?", "ทักมาได้เลยนะ 😊"]),
    "id": (["Aku tinggal di {city} dan senang kenalan dengan orang baru.", "Salam dari {city}!",
            "Selalu cari kopi enak dan obrolan seru.", "Suka jalan-jalan, tapi {city} tetap rumahku."],
           ["Yuk tukar tips traveling!", "Mau latihan bahasa Inggris.", "Jalan-jalan keliling kota? Ayo!", "Sapa aku ya! 😊"]),
    "tl": (["Nakatira ako sa {city} at mahilig akong makakilala ng mga bagong kaibigan.", "Kumusta mula sa {city}!",
            "Laging naghahanap ng masarap na kape at masayang kuwentuhan.", "Mahilig akong maglakbay, pero {city} pa rin ang tahanan ko."],
           ["Palitan tayo ng travel tips!", "Gusto kong mag-practice ng Spanish.", "Lakad-lakad sa siyudad? Tara!", "Mag-message ka lang! 😊"]),
    "hi": (["{city} मेरा घर है और मुझे नए लोगों से मिलना पसंद है।", "{city} से नमस्ते!",
            "अच्छी कॉफ़ी और अच्छी बातचीत की तलाश में हमेशा।", "घूमना बहुत पसंद है, पर दिल {city} में ही है।"],
           ["चलो ट्रैवल टिप्स शेयर करें!", "स्पैनिश सीखने में दिलचस्पी है।", "शहर में घूमने चलें?", "बेझिझक मैसेज करें 😊"]),
    "ar": (["أعيش في {city} وأحب التعرف على أشخاص جدد.", "تحية من {city}!",
            "أبحث دائماً عن قهوة جيدة وحديث ممتع.", "أحب السفر، لكن {city} هي بيتي."],
           ["هل نتبادل نصائح السفر؟", "أريد ممارسة اللغة الإنجليزية.", "جولة في المدينة؟ لمَ لا!", "راسلني بكل سرور 😊"]),
    "he": (["{city} זה הבית, ותמיד כיף להכיר אנשים חדשים.", "שלום מ{city}!",
            "תמיד מחפשים קפה טוב ושיחה טובה.", "אוהבים לטייל, אבל {city} זה הבית."],
           ["נחליף המלצות לטיולים?", "רוצה לתרגל ספרדית.", "סיבוב בעיר? בכיף!", "מוזמנים לכתוב לי 😊"]),
    "sw": (["Ninaishi {city} na napenda kukutana na watu wapya.", "Salamu kutoka {city}!",
            "Ninapenda kahawa nzuri na mazungumzo mazuri.", "Ninapenda kusafiri, lakini {city} ni nyumbani."],
           ["Tubadilishane vidokezo vya safari?", "Ninataka kujifunza Kifaransa.", "Matembezi mjini? Twende!", "Niandikie! 😊"]),
}

STOREFRONT_BIOS = {
    "pt_BR": "Venha nos visitar! Ambiente acolhedor para viajantes e moradores.",
    "pt_PT": "Venha visitar-nos! Um espaço acolhedor para viajantes e locais.",
    "it": "Vieni a trovarci! Un posto accogliente per viaggiatori e gente del posto.",
    "es": "¡Ven a visitarnos! Un lugar acogedor para viajeros y locales.",
    "fr": "Venez nous rendre visite ! Un lieu chaleureux pour voyageurs et locaux.",
    "de": "Besuche uns! Ein gemütlicher Ort für Reisende und Einheimische.",
    "en": "Come visit us! A welcoming spot for travellers and locals alike.",
}

INTERESTS = [
    "Travel", "Photography", "Music", "Movies", "Sports", "Fitness", "Cooking", "Reading", "Art", "Gaming",
    "Technology", "Fashion", "Dancing", "Yoga", "Hiking", "Swimming", "Running", "Cycling", "Meditation",
    "Writing", "Poetry", "Coffee", "Wine", "Beer", "Food", "Vegetarian", "Vegan", "Pets", "Dogs", "Cats",
    "Nature", "Environment", "Volunteering", "Languages", "History", "Science", "Politics", "Business",
    "Entrepreneurship", "Investing",
]

OCCUPATIONS = [
    "Software Engineer", "Teacher", "Nurse", "Designer", "Architect", "Student", "Photographer", "Chef",
    "Marketing Manager", "Doctor", "Lawyer", "Musician", "Tour Guide", "Entrepreneur", "Accountant",
    "Journalist", "Barista", "Translator", "Researcher", "Product Manager", "Artist", "Engineer",
    "Data Analyst", "Sales Manager", "Flight Attendant", "Pharmacist", "Physiotherapist", "Writer",
]
EDUCATION = ["High school", "Bachelor's degree", "Master's degree", "PhD", "Technical course", "University student"]
LOOKING_FOR = [
    "Friends and language exchange", "Travel buddies", "Cultural exchange", "Local tips and meetups",
    "Language practice", "Networking", "New friends in town",
]
TRAVEL_PREFS = ["learn_travel", "help_travelers", "both"]

BUSINESS_CATEGORIES = [
    ("Cafe", "2615"), ("Restaurant", "1f37d"), ("Bar", "1f378"), ("Hotel", "1f3e8"), ("Hostel", "1f6cf"),
    ("Yoga Studio", "1f9d8"), ("Gym", "1f3cb"), ("Spa", "1f486"), ("Art Gallery", "1f5bc"), ("Museum", "1f3db"),
    ("Theater", "1f3ad"), ("Live Music Venue", "1f3b5"), ("Barbershop", "1f488"), ("Bakery", "1f950"),
]
BUSINESS_NAME_PARTS = {
    "Cafe": ["Café", "Coffee House", "Espresso Bar"], "Restaurant": ["Kitchen", "Bistro", "Table"],
    "Bar": ["Bar", "Lounge", "Taproom"], "Hotel": ["Hotel", "Suites", "Inn"], "Hostel": ["Hostel", "Backpackers", "House"],
    "Yoga Studio": ["Yoga", "Yoga Loft", "Flow Studio"], "Gym": ["Fitness", "Gym", "Training Club"],
    "Spa": ["Spa", "Wellness", "Day Spa"], "Art Gallery": ["Gallery", "Art Space", "Studio"],
    "Museum": ["Museum", "Heritage House", "Collection"], "Theater": ["Theatre", "Stage", "Playhouse"],
    "Live Music Venue": ["Music Hall", "Jazz Club", "Live Room"], "Barbershop": ["Barbers", "Barber Shop", "Cuts"],
    "Bakery": ["Bakery", "Bread & Co", "Pâtisserie"],
}
STREETS = ["Main Street", "Central Avenue", "Market Square", "Harbour Road", "Park Lane", "Old Town Street", "Riverside Walk"]

# ---------------------------------------------------------------------------
# Avatars: Google Noto Emoji 512 px PNG (Apache-2.0) via jsDelivr (CORS *).
# ---------------------------------------------------------------------------
NOTO_BASE = "https://cdn.jsdelivr.net/gh/googlefonts/noto-emoji@v2.047/png/512"
TONES = ["1f3fb", "1f3fc", "1f3fd", "1f3fe", "1f3ff"]
ZWJ_VARIANTS = [
    "1f9b0", "1f9b1", "1f9b3", "1f9b2",  # red / curly / white hair, bald
    "2695", "1f393", "1f3eb", "1f33e", "1f373", "1f527", "1f4bc", "1f52c",
    "1f4bb", "1f3a4", "1f3a8", "2708", "1f680", "1f692",
]
OLD_HAIR = {"1f9b3", "1f9b2"}


def noto_url(name: str) -> str:
    return f"{NOTO_BASE}/emoji_u{name}.png"


def avatar_candidates():
    """(gender_bucket, tone_index or -1, variant, filename) for every candidate."""
    out = []
    bases = {"m": "1f468", "f": "1f469", "x": "1f9d1"}
    for g, cp in bases.items():
        for ti, t in [(-1, None)] + list(enumerate(TONES)):
            stem = cp if t is None else f"{cp}_{t}"
            out.append((g, ti, "base", stem))
            for v in ZWJ_VARIANTS:
                out.append((g, ti, v, f"{stem}_200d_{v}"))
    # Single-codepoint extras (older people, blond, beard, turban, headscarf).
    extras = [("m", "1f474", "older"), ("f", "1f475", "older"), ("x", "1f9d3", "older"),
              ("x", "1f471", "blond"), ("m", "1f9d4", "beard"), ("m", "1f473", "turban"), ("f", "1f9d5", "headscarf"),
              ("m", "1f471_200d_2642", "blond"), ("f", "1f471_200d_2640", "blond"),
              ("m", "1f9d4_200d_2642", "beard"), ("m", "1f473_200d_2642", "turban"), ("f", "1f473_200d_2640", "turban")]
    for g, cp, v in extras:
        for ti, t in [(-1, None)] + list(enumerate(TONES)):
            if "_200d_" in cp:
                head, tail = cp.split("_200d_")
                name = cp if t is None else f"{head}_{t}_200d_{tail}"
            else:
                name = cp if t is None else f"{cp}_{t}"
            out.append((g, ti, v, name))
    return out
