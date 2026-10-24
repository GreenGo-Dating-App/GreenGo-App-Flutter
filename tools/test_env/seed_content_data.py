"""Static multilingual content for seed_test_content.py (TEST project only).

Positive, realistic texts in the members' own languages. Keys of every bank
are content language codes: pt_BR, pt_PT, it, es, fr, de, en (other cultures
fall back to English, which is what a mixed international group would use).

Images: Google Noto Emoji (Apache-2.0) via jsDelivr - CORS `*`, immutable,
no real people. Same CDN the people seed uses.
"""

NOTO_BASE = "https://cdn.jsdelivr.net/gh/googlefonts/noto-emoji@v2.047/png/512"


def noto(cp: str) -> str:
    return f"{NOTO_BASE}/emoji_u{cp}.png"


LANGS = ["pt_BR", "pt_PT", "it", "es", "fr", "de", "en"]

# bio_lang (seed_data.CULTURES) -> content language
CONTENT_LANG = {"pt_BR": "pt_BR", "pt_PT": "pt_PT", "it": "it", "es": "es", "fr": "fr", "de": "de"}


def content_lang(bio_lang: str) -> str:
    return CONTENT_LANG.get(bio_lang, "en")


# ISO-639-1 code used by the app for a content language.
ISO = {"pt_BR": "pt", "pt_PT": "pt", "it": "it", "es": "es", "fr": "fr", "de": "de", "en": "en"}
# App language display names (profiles.languages vocabulary).
LANG_NAME = {"pt_BR": "Portuguese", "pt_PT": "Portuguese", "it": "Italian", "es": "Spanish",
             "fr": "French", "de": "German", "en": "English"}

# ---------------------------------------------------------------------------
# Themes: (key, cover emoji codepoints)
# ---------------------------------------------------------------------------
THEME_EMOJI = {
    "language": ["1f5e3", "1f4ac", "1f30d", "1f4da"],
    "food": ["1f35d", "1f372", "1f96f", "1f9c0", "1f35c", "1f32e"],
    "music": ["1f3b6", "1f3b8", "1f3b7", "1f941", "1f3b9"],
    "outdoor": ["1f3de", "26f0", "1f3d5", "1f332", "1f304"],
    "culture": ["1f3db", "1f5bc", "1f3ad", "1f3f0", "1f5fa"],
    "social": ["1f942", "1f389", "1f37b", "1f483", "1f38a"],
    "sports": ["26bd", "1f3c3", "1f6b4", "1f3d0", "1f3be"],
    "wellness": ["1f9d8", "1f33f", "1f9d6", "1f343"],
    "art": ["1f3a8", "1f58c", "1f9f6", "1f3fa"],
    "tech": ["1f4bb", "1f4a1", "1f680", "1f916"],
    "photo": ["1f4f7", "1f4f8", "1f305", "1f307"],
    "travel": ["2708", "1f9f3", "1f5fa", "1f30e", "1f9ed"],
    "coffee": ["2615", "1f950", "1f9c1"],
    "wine": ["1f377", "1f347", "1f9c0"],
    "volunteer": ["1f91d", "1f49a", "1f331", "267b"],
}
THEMES = list(THEME_EMOJI)

# ---------------------------------------------------------------------------
# Event titles / descriptions: THEME -> lang -> [(title, description)]
# {city} is the city name in the local form.
# ---------------------------------------------------------------------------
EVENTS = {
    "language": {
        "pt_BR": [("Encontro de troca de idiomas", "Pratique inglês, espanhol e outros idiomas num clima descontraído em {city}. Mesas por idioma, todos os níveis são bem-vindos!"),
                  ("Language Exchange no bar", "Um happy hour para conversar em vários idiomas e fazer amigos do mundo todo em {city}.")],
        "pt_PT": [("Encontro de troca de línguas", "Conversa em inglês, francês ou italiano com locais e viajantes em {city}. Todos os níveis são bem-vindos!")],
        "it": [("Scambio linguistico al tramonto", "Pratica inglese, spagnolo e portoghese con gente da tutto il mondo a {city}. Tavoli per lingua, tutti i livelli!"),
               ("Aperitivo poliglotta", "Un aperitivo per chiacchierare in tante lingue e conoscere nuovi amici a {city}.")],
        "es": [("Intercambio de idiomas", "Practica inglés, portugués y francés con locales y viajeros en {city}. ¡Todos los niveles son bienvenidos!")],
        "fr": [("Café des langues", "Pratiquez l'anglais, l'espagnol ou le portugais avec des gens du monde entier à {city}. Tous niveaux bienvenus !")],
        "de": [("Sprachtandem-Abend", "Übe Englisch, Spanisch oder Italienisch mit Locals und Reisenden in {city}. Alle Niveaus willkommen!")],
        "en": [("Language Exchange Night", "Practice Spanish, Portuguese, French and more with locals and travellers in {city}. Tables by language, every level welcome!"),
               ("Polyglot Meetup", "Meet people from all over the world and swap languages over drinks in {city}.")],
    },
    "food": {
        "pt_BR": [("Tour gastronômico de rua", "Vamos provar pastel, coxinha e caldo de cana pelas ruas de {city}. Traga fome e bom humor!"),
                  ("Noite de feijoada entre amigos", "Feijoada completa, samba de fundo e muita conversa boa em {city}.")],
        "pt_PT": [("Rota dos petiscos", "Uma volta pelas tascas de {city} para provar petiscos tradicionais e conhecer gente nova.")],
        "it": [("Cena condivisa: pasta fatta in casa", "Impariamo a fare la pasta fresca insieme e poi ceniamo tutti a {city}. Buon appetito!"),
               ("Tour dello street food", "Supplì, pizza al taglio e gelato: giro gastronomico per le vie di {city}.")],
        "es": [("Ruta de tapas", "Recorremos los mejores bares de tapas de {city}. ¡Ven con hambre y ganas de conocer gente!")],
        "fr": [("Pique-nique international", "Chacun apporte un plat de son pays ! Rendez-vous au parc à {city}.")],
        "de": [("Internationales Potluck", "Jeder bringt ein Gericht aus seiner Heimat mit. Gemeinsam essen und quatschen in {city}.")],
        "en": [("Street Food Crawl", "Let's taste the best street food in {city} together. Bring an appetite and good vibes!"),
               ("International Potluck Dinner", "Bring a dish from your home country and share stories around the table in {city}.")],
    },
    "music": {
        "pt_BR": [("Roda de samba aberta", "Samba de raiz ao vivo, todo mundo cantando junto em {city}. Venha curtir!"),
                  ("Sarau de MPB", "Violão, voz e boas canções brasileiras numa noite acolhedora em {city}.")],
        "pt_PT": [("Noite de fado", "Uma noite íntima de fado numa casa típica de {city}. Venha ouvir e partilhar.")],
        "it": [("Jam session acustica", "Porta il tuo strumento o vieni solo ad ascoltare: jam aperta a {city}.")],
        "es": [("Noche de música en vivo", "Bandas locales y buen ambiente en {city}. ¡Te esperamos!")],
        "fr": [("Soirée jazz", "Concert de jazz dans un petit club chaleureux de {city}.")],
        "de": [("Offene Jam-Session", "Bring dein Instrument mit oder hör einfach zu – offene Jam in {city}.")],
        "en": [("Open Mic & Jam Night", "Bring your instrument or just come to listen. Friendly open jam in {city}."),
               ("Live Jazz Evening", "A cozy evening of live jazz in {city}. Great music, great people.")],
    },
    "outdoor": {
        "pt_BR": [("Trilha de fim de semana", "Trilha leve com vista incrível perto de {city}. Leve água, protetor e disposição!")],
        "pt_PT": [("Caminhada pela serra", "Caminhada de nível moderado perto de {city}, com piquenique no fim.")],
        "it": [("Escursione in collina", "Facile trekking vicino a {city} con pranzo al sacco e panorama mozzafiato.")],
        "es": [("Senderismo de domingo", "Ruta sencilla cerca de {city} con vistas espectaculares. ¡Trae agua y buen calzado!")],
        "fr": [("Randonnée du week-end", "Randonnée facile près de {city}, pique-nique au sommet.")],
        "de": [("Wanderung am Wochenende", "Gemütliche Wanderung in der Nähe von {city} mit Picknick.")],
        "en": [("Weekend Hike", "An easy, scenic hike near {city}. Bring water, sunscreen and good shoes!"),
               ("Sunrise Walk in the Park", "Early morning walk and coffee as the city wakes up in {city}.")],
    },
    "culture": {
        "pt_BR": [("Visita guiada ao centro histórico", "Conheça a história de {city} com um guia local apaixonado pela cidade.")],
        "pt_PT": [("Passeio pelos bairros históricos", "Descubra as histórias escondidas dos bairros antigos de {city}.")],
        "it": [("Visita guidata al centro storico", "Scopriamo insieme le meraviglie nascoste di {city} con una guida del posto."),
               ("Serata al museo", "Visita serale al museo e poi un aperitivo tutti insieme a {city}.")],
        "es": [("Visita guiada por el casco antiguo", "Descubre la historia de {city} con un guía local.")],
        "fr": [("Visite du vieux quartier", "Découvrez l'histoire de {city} avec un guide passionné.")],
        "de": [("Altstadtführung", "Entdecke die Geschichte von {city} mit einem lokalen Guide.")],
        "en": [("Old Town Walking Tour", "Discover the hidden stories of {city} with a passionate local guide."),
               ("Museum Night Out", "An evening at the museum followed by drinks together in {city}.")],
    },
    "social": {
        "pt_BR": [("Happy hour de boas-vindas", "Novo em {city}? Venha conhecer gente legal num happy hour descontraído.")],
        "pt_PT": [("Convívio de boas-vindas", "Acabou de chegar a {city}? Venha conhecer locais e outros viajantes.")],
        "it": [("Aperitivo di benvenuto", "Nuovo a {city}? Vieni a conoscere gente simpatica davanti a uno spritz.")],
        "es": [("Afterwork internacional", "¿Nuevo en {city}? Ven a conocer gente de todo el mundo.")],
        "fr": [("Apéro international", "Nouveau à {city} ? Viens rencontrer des gens sympas autour d'un verre.")],
        "de": [("Internationaler Stammtisch", "Neu in {city}? Komm vorbei und lerne nette Leute kennen.")],
        "en": [("Newcomers Social", "New in {city}? Come meet friendly locals and fellow travellers."),
               ("Rooftop Meetup", "Sunset, music and new friends on a rooftop in {city}.")],
    },
    "sports": {
        "pt_BR": [("Futebol society de quinta", "Pelada amistosa, todos os níveis! Times mistos em {city}."),
                  ("Corrida no parque", "5 km em ritmo leve e café depois. Encontro no parque em {city}.")],
        "pt_PT": [("Corrida à beira-rio", "Corrida leve de 5 km junto ao rio em {city}, seguida de pequeno-almoço.")],
        "it": [("Corsa al parco", "5 km a ritmo tranquillo e colazione insieme a {city}.")],
        "es": [("Fútbol entre amigos", "Partido amistoso para todos los niveles en {city}.")],
        "fr": [("Footing du dimanche", "5 km tranquilles puis café ensemble à {city}.")],
        "de": [("Lauftreff im Park", "5 km in entspanntem Tempo, danach Kaffee in {city}.")],
        "en": [("Sunday Fun Run", "A relaxed 5 km run followed by coffee in {city}. All paces welcome."),
               ("Beach Volleyball Meetup", "Friendly beach volleyball games, mixed teams, in {city}.")],
    },
    "wellness": {
        "pt_BR": [("Yoga no parque", "Aula de yoga ao ar livre para todos os níveis em {city}. Traga seu tapete!")],
        "pt_PT": [("Yoga ao pôr do sol", "Aula de yoga ao ar livre em {city}, para todos os níveis.")],
        "it": [("Yoga all'alba", "Lezione di yoga all'aperto per tutti i livelli a {city}.")],
        "es": [("Yoga al aire libre", "Clase de yoga para todos los niveles en {city}. ¡Trae tu esterilla!")],
        "fr": [("Yoga en plein air", "Cours de yoga tous niveaux au parc à {city}.")],
        "de": [("Yoga im Park", "Yoga für alle Levels unter freiem Himmel in {city}.")],
        "en": [("Yoga in the Park", "Outdoor yoga for every level in {city}. Bring your mat!"),
               ("Mindful Morning Meditation", "Start the day calm and centred with a guided meditation in {city}.")],
    },
    "art": {
        "pt_BR": [("Oficina de cerâmica", "Aprenda o básico da cerâmica e leve sua peça para casa. {city}.")],
        "pt_PT": [("Workshop de azulejos", "Pinte o seu próprio azulejo com uma artista local em {city}.")],
        "it": [("Laboratorio di acquerello", "Dipingiamo insieme gli scorci più belli di {city}. Materiale incluso.")],
        "es": [("Taller de pintura", "Pinta y conoce gente en un taller relajado en {city}.")],
        "fr": [("Atelier dessin urbain", "Croquis en plein air dans les rues de {city}.")],
        "de": [("Urban-Sketching-Treffen", "Gemeinsam zeichnen in den Straßen von {city}.")],
        "en": [("Pottery Workshop", "Learn the basics of pottery and take your piece home. {city}."),
               ("Urban Sketching Meetup", "Sketch the streets of {city} together. All levels welcome.")],
    },
    "tech": {
        "pt_BR": [("Meetup de tecnologia e startups", "Palestras curtas e networking com a comunidade tech de {city}.")],
        "pt_PT": [("Encontro de nómadas digitais", "Coworking e networking para nómadas digitais em {city}.")],
        "it": [("Meetup startup e tecnologia", "Talk brevi e networking con la community tech di {city}.")],
        "es": [("Meetup de nómadas digitales", "Coworking y networking para nómadas digitales en {city}.")],
        "fr": [("Afterwork tech & startups", "Pitchs et networking avec la communauté tech de {city}.")],
        "de": [("Tech & Startup Meetup", "Kurze Talks und Networking mit der Tech-Szene in {city}.")],
        "en": [("Digital Nomads Coworking Day", "Work together, share tips and grab lunch with other remote workers in {city}."),
               ("Tech & Startups Meetup", "Lightning talks and networking with the {city} tech community.")],
    },
    "photo": {
        "pt_BR": [("Passeio fotográfico", "Vamos fotografar os cantos mais bonitos de {city} na hora dourada.")],
        "pt_PT": [("Passeio fotográfico", "Fotografar {city} ao fim da tarde, com dicas de composição.")],
        "it": [("Photo walk al tramonto", "Fotografiamo {city} nell'ora d'oro. Va bene anche lo smartphone!")],
        "es": [("Paseo fotográfico", "Fotografiamos {city} en la hora dorada. ¡Vale el móvil!")],
        "fr": [("Balade photo", "Photographier {city} à l'heure dorée, smartphone bienvenu.")],
        "de": [("Fotowalk zur goldenen Stunde", "Gemeinsam {city} fotografieren – Smartphone reicht!")],
        "en": [("Golden Hour Photo Walk", "Capture {city} at golden hour. Phones are perfectly fine!")],
    },
    "travel": {
        "pt_BR": [("Encontro de viajantes", "Troque dicas de viagem e planeje roteiros com outros viajantes em {city}.")],
        "pt_PT": [("Encontro de viajantes", "Partilhe dicas e histórias de viagem em {city}.")],
        "it": [("Serata viaggiatori", "Racconti, consigli e itinerari tra viaggiatori a {city}.")],
        "es": [("Quedada de viajeros", "Comparte consejos y rutas con otros viajeros en {city}.")],
        "fr": [("Rencontre de voyageurs", "Partage tes bons plans et récits de voyage à {city}.")],
        "de": [("Reisende-Treffen", "Tipps und Geschichten austauschen mit anderen Reisenden in {city}.")],
        "en": [("Travellers Meetup", "Swap travel tips, stories and itineraries with fellow travellers in {city}.")],
    },
    "coffee": {
        "pt_BR": [("Café e conversa", "Um café especial e boas conversas numa cafeteria charmosa de {city}.")],
        "pt_PT": [("Café e conversa", "Um café e dois dedos de conversa numa pastelaria de {city}.")],
        "it": [("Colazione insieme", "Cornetto e cappuccino in compagnia a {city}.")],
        "es": [("Café y charla", "Café de especialidad y buena conversación en {city}.")],
        "fr": [("Café-rencontre", "Un café et de belles rencontres dans un café de {city}.")],
        "de": [("Kaffeeklatsch", "Guter Kaffee und nette Gespräche in einem Café in {city}.")],
        "en": [("Coffee & Conversation", "Specialty coffee and great conversation at a cozy café in {city}.")],
    },
    "wine": {
        "pt_BR": [("Degustação de vinhos", "Prove vinhos nacionais e aprenda com um sommelier em {city}.")],
        "pt_PT": [("Prova de vinhos portugueses", "Vinho verde, Douro e Alentejo numa prova descontraída em {city}.")],
        "it": [("Degustazione di vini", "Un viaggio tra i vini italiani con un sommelier a {city}.")],
        "es": [("Cata de vinos", "Descubre vinos locales con un sumiller en {city}.")],
        "fr": [("Dégustation de vins", "Découverte des vins régionaux avec un sommelier à {city}.")],
        "de": [("Weinprobe", "Regionale Weine probieren und Leute kennenlernen in {city}.")],
        "en": [("Wine Tasting Evening", "Taste local wines and learn from a sommelier in {city}.")],
    },
    "volunteer": {
        "pt_BR": [("Mutirão de limpeza da praia", "Vamos deixar {city} mais bonita! Luvas e sacos fornecidos.")],
        "pt_PT": [("Limpeza de praia", "Ajude a limpar a costa de {city}. Material fornecido.")],
        "it": [("Pulizia del parco", "Diamo una mano al verde di {city}! Guanti e sacchi forniti.")],
        "es": [("Limpieza de playa", "¡Dejemos {city} más bonita! Guantes y bolsas incluidos.")],
        "fr": [("Nettoyage citoyen", "Rendons {city} plus belle ! Gants et sacs fournis.")],
        "de": [("Park-Aufräumaktion", "Gemeinsam für ein sauberes {city}! Handschuhe gestellt.")],
        "en": [("Beach Clean-up", "Let's make {city} a little greener! Gloves and bags provided.")],
    },
}

# ---------------------------------------------------------------------------
# Communities: THEME -> lang -> [(name, description)]
# ---------------------------------------------------------------------------
COMMUNITIES = {
    "language": {
        "pt_BR": [("Troca de Idiomas {city}", "Grupo para praticar idiomas, marcar encontros e fazer amigos internacionais em {city}.")],
        "pt_PT": [("Línguas em {city}", "Pratique línguas com locais e estrangeiros em {city}.")],
        "it": [("Scambio Lingue {city}", "Pratichiamo le lingue insieme e organizziamo incontri a {city}.")],
        "es": [("Intercambio de Idiomas {city}", "Practica idiomas y conoce gente nueva en {city}.")],
        "fr": [("Échange Linguistique {city}", "Pratiquer les langues et rencontrer du monde à {city}.")],
        "de": [("Sprachtandem {city}", "Sprachen üben und neue Leute treffen in {city}.")],
        "en": [("{city} Language Exchange", "Practice languages, plan meetups and make international friends in {city}.")],
    },
    "food": {
        "pt_BR": [("Comida de Rua {city}", "Dicas dos melhores lugares para comer bem e barato em {city}.")],
        "pt_PT": [("Sabores de {city}", "Restaurantes, tascas e petiscos de {city} partilhados por quem conhece.")],
        "it": [("Buongustai di {city}", "Trattorie, pizzerie e gelaterie consigliate dai locali di {city}.")],
        "es": [("Foodies {city}", "Los mejores sitios para comer en {city}, recomendados por la comunidad.")],
        "fr": [("Gourmands de {city}", "Les meilleures adresses de {city}, partagées par la communauté.")],
        "de": [("Foodies {city}", "Die besten Restaurants und Streetfood-Tipps in {city}.")],
        "en": [("{city} Foodies", "The best places to eat in {city}, recommended by people who live here.")],
    },
    "outdoor": {
        "pt_BR": [("Trilhas e Natureza {city}", "Trilhas, cachoeiras e passeios ao ar livre perto de {city}.")],
        "pt_PT": [("Caminhadas {city}", "Percursos pedestres e natureza à volta de {city}.")],
        "it": [("Trekking {city}", "Escursioni e natura intorno a {city}.")],
        "es": [("Senderismo {city}", "Rutas y naturaleza cerca de {city}.")],
        "fr": [("Randos {city}", "Randonnées et sorties nature autour de {city}.")],
        "de": [("Wandern {city}", "Wanderungen und Natur rund um {city}.")],
        "en": [("{city} Hikers", "Trails, viewpoints and outdoor adventures around {city}.")],
    },
    "travel": {
        "pt_BR": [("Viajantes em {city}", "Para quem está chegando ou de passagem por {city}: dicas, encontros e amizades.")],
        "pt_PT": [("Viajantes em {city}", "Dicas e encontros para quem visita {city}.")],
        "it": [("Viaggiatori a {city}", "Consigli e incontri per chi è di passaggio a {city}.")],
        "es": [("Viajeros en {city}", "Consejos y quedadas para quienes visitan {city}.")],
        "fr": [("Voyageurs à {city}", "Bons plans et rencontres pour ceux qui visitent {city}.")],
        "de": [("Reisende in {city}", "Tipps und Treffen für alle, die {city} besuchen.")],
        "en": [("Travellers in {city}", "Tips, meetups and friendships for everyone visiting {city}.")],
    },
    "music": {
        "pt_BR": [("Música ao Vivo {city}", "Shows, rodas de samba e jams em {city}.")],
        "pt_PT": [("Música em {city}", "Concertos, fado e jams em {city}.")],
        "it": [("Musica dal Vivo {city}", "Concerti e jam session a {city}.")],
        "es": [("Música en Vivo {city}", "Conciertos y jams en {city}.")],
        "fr": [("Musique Live {city}", "Concerts et jams à {city}.")],
        "de": [("Live-Musik {city}", "Konzerte und Jams in {city}.")],
        "en": [("{city} Live Music", "Gigs, open mics and jam sessions in {city}.")],
    },
    "sports": {
        "pt_BR": [("Corredores de {city}", "Treinos coletivos e provas de corrida em {city}.")],
        "pt_PT": [("Corrida {city}", "Treinos em grupo e provas em {city}.")],
        "it": [("Runner {city}", "Allenamenti di gruppo e gare a {city}.")],
        "es": [("Runners {city}", "Entrenamientos en grupo y carreras en {city}.")],
        "fr": [("Coureurs de {city}", "Sorties running en groupe à {city}.")],
        "de": [("Lauftreff {city}", "Gemeinsam laufen in {city}.")],
        "en": [("{city} Runners", "Group runs, races and good company in {city}.")],
    },
    "tech": {
        "pt_BR": [("Nômades Digitais {city}", "Coworkings, cafés com wi-fi e networking em {city}.")],
        "pt_PT": [("Nómadas Digitais {city}", "Coworkings e networking em {city}.")],
        "it": [("Nomadi Digitali {city}", "Coworking e networking a {city}.")],
        "es": [("Nómadas Digitales {city}", "Coworkings y networking en {city}.")],
        "fr": [("Nomades Numériques {city}", "Coworkings et networking à {city}.")],
        "de": [("Digitale Nomaden {city}", "Coworking und Networking in {city}.")],
        "en": [("{city} Digital Nomads", "Coworking spots, wifi cafés and networking in {city}.")],
    },
    "culture": {
        "pt_BR": [("Cultura e Arte {city}", "Exposições, museus e agenda cultural de {city}.")],
        "pt_PT": [("Cultura em {city}", "Exposições, museus e agenda cultural de {city}.")],
        "it": [("Arte e Cultura {city}", "Mostre, musei e agenda culturale di {city}.")],
        "es": [("Cultura {city}", "Exposiciones, museos y agenda cultural de {city}.")],
        "fr": [("Culture {city}", "Expos, musées et agenda culturel de {city}.")],
        "de": [("Kultur {city}", "Ausstellungen, Museen und Kulturtipps in {city}.")],
        "en": [("{city} Culture Club", "Exhibitions, museums and the cultural agenda of {city}.")],
    },
    "wellness": {
        "pt_BR": [("Yoga e Bem-estar {city}", "Aulas, retiros e meditação em {city}.")],
        "pt_PT": [("Yoga {city}", "Aulas e meditação em {city}.")],
        "it": [("Yoga e Benessere {city}", "Lezioni e meditazione a {city}.")],
        "es": [("Yoga {city}", "Clases y meditación en {city}.")],
        "fr": [("Yoga {city}", "Cours et méditation à {city}.")],
        "de": [("Yoga {city}", "Kurse und Meditation in {city}.")],
        "en": [("{city} Yoga & Wellbeing", "Classes, retreats and meditation in {city}.")],
    },
    "photo": {
        "pt_BR": [("Fotografia {city}", "Passeios fotográficos e dicas de lugares para fotografar em {city}.")],
        "pt_PT": [("Fotografia {city}", "Passeios fotográficos em {city}.")],
        "it": [("Fotografi di {city}", "Photo walk e luoghi da fotografare a {city}.")],
        "es": [("Fotografía {city}", "Paseos fotográficos en {city}.")],
        "fr": [("Photo {city}", "Balades photo à {city}.")],
        "de": [("Fotografie {city}", "Fotowalks in {city}.")],
        "en": [("{city} Photographers", "Photo walks and the best spots to shoot in {city}.")],
    },
}

# ---------------------------------------------------------------------------
# Community chat messages, tips, announcements per language
# ---------------------------------------------------------------------------
CHAT = {
    "pt_BR": ["Oi pessoal! Acabei de entrar no grupo 😊", "Alguém topa um café no sábado?", "Que grupo incrível, obrigado por me adicionarem!",
              "Alguém conhece um bom lugar para praticar inglês?", "O encontro de ontem foi demais!", "Bem-vindos aos novos membros! 🎉",
              "Vou estar no parque domingo de manhã, quem quiser aparecer!", "Alguém recomenda um restaurante vegetariano?",
              "Fotos do último encontro ficaram lindas", "Estou chegando na cidade semana que vem, alguma dica?",
              "Bora marcar a próxima trilha?", "Adoro essa comunidade ❤️", "Obrigada pelas dicas, deu tudo certo!",
              "Alguém vai no show de sexta?", "Que dia lindo para passear!"],
    "pt_PT": ["Olá a todos! Acabei de me juntar ao grupo 😊", "Alguém para um café no sábado?", "Obrigado pelas dicas, foram ótimas!",
              "O encontro de ontem foi espetacular!", "Bem-vindos aos novos membros! 🎉", "Alguém recomenda uma tasca boa?",
              "Chego à cidade na próxima semana, alguma sugestão?", "Que dia bonito para passear à beira-rio!",
              "Vamos marcar a próxima caminhada?", "Adoro este grupo ❤️"],
    "it": ["Ciao a tutti! Sono nuovo nel gruppo 😊", "Qualcuno per un caffè sabato?", "Grazie per i consigli, siete fantastici!",
           "L'incontro di ieri è stato bellissimo!", "Benvenuti ai nuovi membri! 🎉", "Qualcuno conosce una buona trattoria?",
           "Arrivo in città la prossima settimana, consigli?", "Che bella giornata per una passeggiata!",
           "Organizziamo la prossima uscita?", "Adoro questa community ❤️", "Le foto dell'ultima volta sono stupende"],
    "es": ["¡Hola a todos! Acabo de unirme 😊", "¿Alguien para un café el sábado?", "¡Gracias por los consejos!",
           "¡La quedada de ayer estuvo genial!", "¡Bienvenidos a los nuevos miembros! 🎉", "¿Alguien recomienda un buen bar de tapas?",
           "Llego a la ciudad la próxima semana, ¿algún consejo?", "¡Qué día tan bonito para pasear!",
           "¿Organizamos la próxima salida?", "Me encanta este grupo ❤️"],
    "fr": ["Salut tout le monde ! Je viens de rejoindre le groupe 😊", "Quelqu'un pour un café samedi ?", "Merci pour les conseils !",
           "La rencontre d'hier était top !", "Bienvenue aux nouveaux membres ! 🎉", "Quelqu'un connaît un bon bistrot ?",
           "J'arrive en ville la semaine prochaine, des conseils ?", "Quelle belle journée pour se balader !",
           "On organise la prochaine sortie ?", "J'adore ce groupe ❤️"],
    "de": ["Hallo zusammen! Bin neu in der Gruppe 😊", "Hat jemand Lust auf Kaffee am Samstag?", "Danke für die Tipps!",
           "Das Treffen gestern war super!", "Willkommen an alle Neuen! 🎉", "Kennt jemand ein gutes Restaurant?",
           "Ich komme nächste Woche in die Stadt, habt ihr Tipps?", "Was für ein schöner Tag für einen Spaziergang!",
           "Planen wir das nächste Treffen?", "Ich liebe diese Gruppe ❤️"],
    "en": ["Hi everyone! Just joined the group 😊", "Anyone up for coffee on Saturday?", "Thanks for the tips, you're all amazing!",
           "Yesterday's meetup was so much fun!", "Welcome to all the new members! 🎉", "Can anyone recommend a good vegetarian place?",
           "I'm arriving in town next week, any tips?", "What a beautiful day for a walk!", "Shall we plan the next outing?",
           "Love this community ❤️", "The photos from last time turned out great", "Who's going to the concert on Friday?",
           "Just tried the place you recommended, absolutely loved it!", "Count me in for the next one!"],
}

TIPS = {
    "pt_BR": [("Melhor horário para visitar", "Vá cedo de manhã nos fins de semana: menos fila e luz linda para fotos."),
              ("Transporte", "O metrô é a forma mais rápida de circular. Use o cartão recarregável para economizar."),
              ("Comida barata e boa", "Os mercados municipais têm lanches deliciosos por preços justos."),
              ("Segurança", "Prefira aplicativos de transporte à noite e mantenha o celular guardado em lugares movimentados.")],
    "pt_PT": [("Transportes", "O passe navegante compensa muito se ficar mais de três dias."),
              ("Miradouros", "Os miradouros ao pôr do sol são imperdíveis. Leve um casaco, fica fresco!"),
              ("Comer bem", "Prove o prato do dia nas tascas: bom, farto e barato.")],
    "it": [("Orari", "Molti negozi chiudono nel primo pomeriggio: organizza le visite di conseguenza."),
           ("Acqua gratis", "Le fontanelle offrono acqua potabile fresca gratis: porta una borraccia!"),
           ("Mangiare bene", "Evita i ristoranti con il menù turistico vicino ai monumenti: due vie più in là si mangia meglio.")],
    "es": [("Horarios", "Aquí se cena tarde: los restaurantes se llenan a partir de las 21h."),
           ("Transporte", "La tarjeta de transporte recargable ahorra mucho dinero."),
           ("Tapas", "En muchos bares la tapa viene gratis con la bebida.")],
    "fr": [("Transports", "Le carnet de tickets ou la carte rechargeable reviennent moins cher."),
           ("Musées", "Beaucoup de musées sont gratuits le premier dimanche du mois.")],
    "de": [("Öffis", "Das Tagesticket lohnt sich ab drei Fahrten."),
           ("Sonntag", "Sonntags sind die meisten Geschäfte geschlossen – vorher einkaufen!")],
    "en": [("Getting around", "Get a reloadable transit card on day one, it's cheaper and faster."),
           ("Best time to visit", "Go early on weekend mornings: fewer crowds and beautiful light for photos."),
           ("Eat like a local", "Skip the places right next to the landmarks; two streets away is better and cheaper."),
           ("Stay safe", "Use ride apps at night and keep your phone away in crowded spots.")],
}

ANNOUNCEMENTS = {
    "pt_BR": [("Bem-vindos à comunidade!", "Leiam as regras: respeito sempre, sem spam e muita troca cultural. Aproveitem! 💚"),
              ("Próximo encontro confirmado", "Nosso próximo encontro já está na aba de eventos. Confirme presença!")],
    "pt_PT": [("Bem-vindos!", "Regras simples: respeito, nada de spam e muita partilha. Divirtam-se! 💚"),
              ("Novo encontro", "O próximo encontro já está nos eventos. Confirmem presença!")],
    "it": [("Benvenuti nella community!", "Regole semplici: rispetto, niente spam e tanta condivisione. Buon divertimento! 💚"),
           ("Prossimo incontro", "Il prossimo incontro è già nella sezione eventi. Confermate la presenza!")],
    "es": [("¡Bienvenidos a la comunidad!", "Reglas: respeto, nada de spam y mucho intercambio cultural. ¡Disfrutad! 💚"),
           ("Próxima quedada", "La próxima quedada ya está en eventos. ¡Confirmad asistencia!")],
    "fr": [("Bienvenue dans la communauté !", "Règles : respect, pas de spam et beaucoup de partage. Amusez-vous ! 💚"),
           ("Prochaine rencontre", "La prochaine rencontre est dans l'onglet événements. Inscrivez-vous !")],
    "de": [("Willkommen in der Community!", "Regeln: Respekt, kein Spam und viel Austausch. Viel Spaß! 💚"),
           ("Nächstes Treffen", "Das nächste Treffen steht im Event-Tab. Meldet euch an!")],
    "en": [("Welcome to the community!", "House rules: be kind, no spam, lots of cultural exchange. Enjoy! 💚"),
           ("Next meetup confirmed", "Our next meetup is up in the events tab. RSVP so we can plan!")],
}

# ---------------------------------------------------------------------------
# Experiences: THEME -> lang -> [(title, description)]
# ---------------------------------------------------------------------------
EXPERIENCES = {
    "food": {
        "pt_BR": [("Aula de culinária brasileira na minha casa", "Vamos preparar moqueca, farofa e brigadeiro juntos. Depois a gente come tudo! Ingredientes inclusos.")],
        "pt_PT": [("Aula de pastéis de nata", "Aprenda a fazer pastéis de nata como os da pastelaria, na minha cozinha em {city}.")],
        "it": [("Corso di pasta fresca con la nonna", "Impariamo a fare tagliatelle e ravioli a mano, poi pranziamo insieme a {city}.")],
        "es": [("Clase de paella casera", "Cocinamos una paella auténtica y la disfrutamos juntos en {city}.")],
        "fr": [("Atelier croissants", "Apprenez à faire des croissants maison dans ma cuisine à {city}.")],
        "de": [("Backkurs: Brezeln & Strudel", "Wir backen gemeinsam Brezeln und Apfelstrudel in {city}.")],
        "en": [("Home Cooking Class with a Local", "Cook a traditional meal with me at home in {city}, then we sit down and eat together.")],
    },
    "culture": {
        "pt_BR": [("Passeio a pé pelo centro histórico", "Histórias, curiosidades e os melhores cantinhos de {city}, com um guia local.")],
        "pt_PT": [("Passeio pelos bairros antigos", "Descubra as ruelas e histórias de {city} a pé.")],
        "it": [("Passeggiata tra i vicoli nascosti", "Ti porto nei posti che i turisti non vedono a {city}.")],
        "es": [("Paseo por el barrio antiguo", "Historias y rincones secretos de {city} con un local.")],
        "fr": [("Balade dans le vieux quartier", "Les secrets de {city} racontés par un habitant.")],
        "de": [("Altstadtspaziergang", "Die versteckten Ecken von {city} mit einem Einheimischen.")],
        "en": [("Hidden Gems Walking Tour", "I'll show you the corners of {city} that tourists never see.")],
    },
    "music": {
        "pt_BR": [("Aula de samba para iniciantes", "Aprenda os passos básicos do samba numa aula divertida em {city}.")],
        "pt_PT": [("Noite de fado com um local", "Vamos juntos a uma casa de fado autêntica em {city}.")],
        "it": [("Lezione di mandolino", "Prime note di mandolino in una lezione rilassata a {city}.")],
        "es": [("Clase de salsa", "Aprende salsa desde cero en {city}.")],
        "fr": [("Initiation au jazz manouche", "Découverte de la guitare manouche à {city}.")],
        "de": [("Trommel-Workshop", "Rhythmus und Spaß beim Trommeln in {city}.")],
        "en": [("Beginner Dance Class", "Learn the basic steps in a fun, relaxed class in {city}.")],
    },
    "outdoor": {
        "pt_BR": [("Trilha guiada com vista panorâmica", "Trilha de nível fácil perto de {city}, com lanche no topo.")],
        "pt_PT": [("Caminhada costeira", "Percurso pela costa perto de {city} com paragem para petiscos.")],
        "it": [("Trekking panoramico", "Escursione facile vicino a {city} con pranzo al sacco.")],
        "es": [("Ruta de senderismo guiada", "Ruta fácil cerca de {city} con picnic.")],
        "fr": [("Randonnée guidée", "Randonnée facile près de {city} avec pique-nique.")],
        "de": [("Geführte Wanderung", "Leichte Tour bei {city} mit Picknick.")],
        "en": [("Guided Scenic Hike", "An easy guided hike near {city} with a picnic at the viewpoint.")],
    },
    "art": {
        "pt_BR": [("Oficina de grafite", "Conheça a arte de rua de {city} e faça seu próprio grafite.")],
        "pt_PT": [("Pintura de azulejos", "Pinte o seu azulejo e leve-o para casa. {city}.")],
        "it": [("Laboratorio di ceramica", "Modella la tua tazza in un laboratorio artigiano a {city}.")],
        "es": [("Taller de cerámica", "Crea tu propia pieza en un taller de {city}.")],
        "fr": [("Atelier aquarelle", "Peindre {city} à l'aquarelle, matériel fourni.")],
        "de": [("Keramik-Workshop", "Töpfere deine eigene Tasse in {city}.")],
        "en": [("Pottery Session", "Make your own mug in a friendly local studio in {city}.")],
    },
    "language": {
        "pt_BR": [("Conversação em português com café", "Pratique português de forma leve tomando um café em {city}.")],
        "pt_PT": [("Português para viajantes", "Frases úteis e conversa num café de {city}.")],
        "it": [("Italiano al bar", "Conversazione in italiano davanti a un caffè a {city}.")],
        "es": [("Español con tapas", "Practica español mientras probamos tapas en {city}.")],
        "fr": [("Français autour d'un café", "Conversation en français dans un café de {city}.")],
        "de": [("Deutsch beim Kaffee", "Deutsch üben bei Kaffee und Kuchen in {city}.")],
        "en": [("English Conversation over Coffee", "Practice English in a relaxed chat over coffee in {city}.")],
    },
    "photo": {
        "pt_BR": [("Ensaio de fotografia urbana", "Dicas de fotografia de celular pelos lugares mais bonitos de {city}.")],
        "pt_PT": [("Fotografia ao pôr do sol", "Os melhores miradouros de {city} para fotografar.")],
        "it": [("Fotografia all'ora d'oro", "I punti più fotogenici di {city} con consigli pratici.")],
        "es": [("Fotografía urbana", "Los rincones más fotogénicos de {city}.")],
        "fr": [("Photo à l'heure dorée", "Les plus beaux spots photo de {city}.")],
        "de": [("Fotokurs in der Stadt", "Die schönsten Fotospots in {city}.")],
        "en": [("Golden Hour Photo Session", "The most photogenic spots in {city} plus phone photography tips.")],
    },
    "wine": {
        "pt_BR": [("Degustação de cachaças artesanais", "Conheça a história da cachaça e prove rótulos artesanais em {city}.")],
        "pt_PT": [("Prova de vinho do Porto", "Prove diferentes estilos de vinho do Porto em {city}.")],
        "it": [("Degustazione in enoteca", "Vini locali e taglieri in un'enoteca di {city}.")],
        "es": [("Cata de vinos y quesos", "Vinos y quesos locales en {city}.")],
        "fr": [("Dégustation vins et fromages", "Accords mets-vins à {city}.")],
        "de": [("Weinverkostung", "Regionale Weine mit kleinen Snacks in {city}.")],
        "en": [("Wine & Cheese Tasting", "Local wines and cheeses with a friendly host in {city}.")],
    },
    "wellness": {
        "pt_BR": [("Yoga ao nascer do sol", "Aula de yoga ao ar livre em {city} para todos os níveis.")],
        "pt_PT": [("Yoga na praia", "Yoga ao amanhecer perto de {city}.")],
        "it": [("Yoga al parco", "Yoga all'aperto a {city} per tutti i livelli.")],
        "es": [("Yoga al amanecer", "Yoga al aire libre en {city}.")],
        "fr": [("Yoga au lever du soleil", "Yoga en plein air à {city}.")],
        "de": [("Sonnenaufgangs-Yoga", "Yoga im Freien in {city}.")],
        "en": [("Sunrise Yoga", "Outdoor yoga for every level in {city}.")],
    },
}

REVIEWS = {
    "pt_BR": ["Experiência incrível, super recomendo!", "Anfitrião muito simpático e atencioso.", "Foi o ponto alto da minha viagem!",
              "Aprendi muito e me diverti demais.", "Tudo muito bem organizado, voltarei com certeza."],
    "pt_PT": ["Experiência fantástica, recomendo!", "Anfitriã muito simpática.", "Foi o melhor da viagem!"],
    "it": ["Esperienza fantastica, consigliatissima!", "Host gentilissimo e preparato.", "Il momento più bello del viaggio!",
           "Ho imparato tanto e mi sono divertito."],
    "es": ["¡Experiencia increíble, muy recomendable!", "Anfitrión muy amable.", "¡Lo mejor del viaje!", "Aprendí muchísimo."],
    "fr": ["Expérience géniale, je recommande !", "Hôte adorable et passionné.", "Le meilleur moment de mon voyage !"],
    "de": ["Tolles Erlebnis, sehr zu empfehlen!", "Sehr netter Gastgeber.", "Das Highlight meiner Reise!"],
    "en": ["Amazing experience, highly recommend!", "Such a warm and knowledgeable host.", "The highlight of my trip!",
           "Learned so much and had a great time.", "Really well organised, would do it again."],
}
