import {
  _resetState,
  _setDeps,
  checkRateLimit,
  googleComponents,
  handleResolvePlace,
  handleReverseGeocode,
  handleSearchAddress,
  HttpResult,
  normalizeLang,
  normalizeQuery,
  parseSearchInput,
  PER_MINUTE_LIMIT,
  photonFeatureToSuggestion,
  USER_AGENT,
} from '../../src/location/placeSearch';

const req = (data: any, uid: string | null = 'u1') => ({ auth: uid ? { uid } : undefined, data });

const photonBody = {
  features: [
    {
      properties: {
        osm_type: 'W', osm_id: 1, name: 'Piazza Navona', city: 'Rome', state: 'Lazio',
        country: 'Italy', countrycode: 'it', postcode: '00186',
      },
      geometry: { coordinates: [12.4731, 41.8992] },
    },
    {
      properties: { osm_type: 'N', osm_id: 2, street: 'Via del Corso', housenumber: '1', city: 'Rome', country: 'Italy', countrycode: 'IT' },
      geometry: { coordinates: [12.48, 41.9] },
    },
    // Exact duplicate text → dropped.
    {
      properties: {
        osm_type: 'W', osm_id: 3, name: 'Piazza Navona', city: 'Rome', state: 'Lazio',
        country: 'Italy', countrycode: 'it', postcode: '00186',
      },
      geometry: { coordinates: [12.4732, 41.8993] },
    },
    // No coordinates → dropped.
    { properties: { name: 'Broken' }, geometry: {} },
  ],
};

let calls: { url: string; init?: any }[] = [];
function stub(opts: { places?: string | null; geocoding?: string | null; respond: (url: string, init?: any) => HttpResult }) {
  calls = [];
  const quota = jest.fn(async () => undefined);
  _setDeps({
    fetchJson: async (url, init) => {
      calls.push({ url, init });
      return opts.respond(url, init);
    },
    placesKey: async () => opts.places ?? null,
    geocodingKey: async () => opts.geocoding ?? null,
    quota,
    now: () => 1_000_000,
  });
  return quota;
}

beforeEach(() => _resetState());
afterAll(() => _setDeps());

describe('validation helpers', () => {
  it('normalizes queries and languages', () => {
    expect(normalizeQuery('  Via   DEL  Corso ')).toBe('via del corso');
    expect(normalizeLang('pt_BR')).toBe('pt-BR');
    expect(normalizeLang('IT')).toBe('it');
    expect(normalizeLang('<script>')).toBe('en');
    expect(normalizeLang(undefined)).toBe('en');
  });

  it('rejects short, long and missing queries', () => {
    expect(() => parseSearchInput({ query: 'a' })).toThrow(/characters/);
    expect(() => parseSearchInput({ query: 'x'.repeat(121) })).toThrow(/characters/);
    expect(() => parseSearchInput({})).toThrow(/characters/);
  });

  it('coarsens the bias point and drops bad session tokens', () => {
    const i = parseSearchInput({ query: 'rome', lat: 41.89921, lng: 12.47312, sessionToken: 'bad token!' });
    expect(i.biasLat).toBe(41.9);
    expect(i.biasLng).toBe(12.5);
    expect(i.sessionToken).toBeUndefined();
    expect(i.mode).toBe('address');
    const j = parseSearchInput({ query: 'rome', lat: 999, lng: 0, sessionToken: 'abcdefgh1234', mode: 'city' });
    expect(j.biasLat).toBeUndefined();
    expect(j.sessionToken).toBe('abcdefgh1234');
    expect(j.mode).toBe('city');
  });
});

describe('Photon adapter', () => {
  it('maps a feature to primary/secondary lines', () => {
    const s = photonFeatureToSuggestion(photonBody.features[0])!;
    expect(s.primary).toBe('Piazza Navona');
    expect(s.secondary).toBe('00186 Rome, Lazio, Italy');
    expect(s.city).toBe('Rome');
    expect(s.countryCode).toBe('IT');
    expect(s.lat).toBeCloseTo(41.8992);
  });

  it('uses street + number when the feature has no name; a city is its own city', () => {
    expect(photonFeatureToSuggestion(photonBody.features[1])!.primary).toBe('Via del Corso 1');
    const city = photonFeatureToSuggestion({
      properties: { type: 'city', name: 'Ulm', state: 'Baden-Württemberg', country: 'Germany', countrycode: 'DE', osm_type: 'R', osm_id: 9 },
      geometry: { coordinates: [9.99, 48.39] },
    })!;
    expect(city.city).toBe('Ulm');
    expect(city.secondary).toBe('Baden-Württemberg, Germany');
  });

  it('searches with a User-Agent, English structured fields, bias and dedupe', async () => {
    const quota = stub({ respond: () => ({ ok: true, status: 200, body: photonBody }) });
    const r = await handleSearchAddress(req({ query: 'piazza navona', lat: 41.9, lng: 12.5, lang: 'it' }));
    expect(r.provider).toBe('photon');
    expect(r.suggestions.map((s) => s.primary)).toEqual(['Piazza Navona', 'Via del Corso 1']);
    expect(calls[0].url).toContain('photon.komoot.io/api/');
    expect(calls[0].url).toContain('lang=en');
    expect(calls[0].url).toContain('lat=41.9');
    expect(calls[0].url).not.toContain('nominatim');
    expect(calls[0].init.headers['User-Agent']).toBe(USER_AGENT);
    expect(quota).toHaveBeenCalledTimes(1);
  });

  it('restricts to cities in city mode', async () => {
    stub({ respond: () => ({ ok: true, status: 200, body: { features: [] } }) });
    await handleSearchAddress(req({ query: 'ulm', mode: 'city' }));
    expect(calls[0].url).toContain('layer=city');
  });

  it('reverse geocodes a dropped pin, keeping the pin coordinates', async () => {
    stub({ respond: () => ({ ok: true, status: 200, body: { features: [photonBody.features[0]] } }) });
    const r = await handleReverseGeocode(req({ lat: 41.8991234, lng: 12.4730987, lang: 'de' }));
    expect(r.place).toMatchObject({ lat: 41.89912, lng: 12.4731, city: 'Rome', country: 'Italy' });
    expect(r.place!.address).toContain('Piazza Navona');
    expect(calls[0].url).toContain('/reverse?');
    expect(calls[0].url).toContain('lang=de');
  });
});

describe('Google adapter', () => {
  const autocomplete = {
    suggestions: [
      { placePrediction: { placeId: 'ChIJ_navona_000', text: { text: 'Piazza Navona, Roma' }, structuredFormat: { mainText: { text: 'Piazza Navona' }, secondaryText: { text: 'Roma, RM, Italia' } } } },
      { queryPrediction: { text: { text: 'piazza' } } },
    ],
  };
  const details = {
    formattedAddress: 'Piazza Navona, 00186 Roma RM, Italy',
    location: { latitude: 41.8992, longitude: 12.4731 },
    addressComponents: [
      { longText: 'Rome', shortText: 'Rome', types: ['locality', 'political'] },
      { longText: 'Lazio', shortText: 'Lazio', types: ['administrative_area_level_1'] },
      { longText: 'Italy', shortText: 'IT', types: ['country', 'political'] },
    ],
  };

  it('uses Places Autocomplete (New) with the session token and location bias', async () => {
    stub({ places: 'KEY', respond: () => ({ ok: true, status: 200, body: autocomplete }) });
    const r = await handleSearchAddress(req({ query: 'piazza nav', lang: 'it', lat: 41.9, lng: 12.5, sessionToken: 'sess-token-1234' }));
    expect(r.provider).toBe('google');
    expect(r.suggestions).toEqual([expect.objectContaining({ placeId: 'ChIJ_navona_000', primary: 'Piazza Navona', secondary: 'Roma, RM, Italia' })]);
    expect(r.suggestions[0].lat).toBeUndefined();
    expect(calls[0].url).toBe('https://places.googleapis.com/v1/places:autocomplete');
    expect(calls[0].init.headers['X-Goog-Api-Key']).toBe('KEY');
    const body = JSON.parse(calls[0].init.body);
    expect(body).toMatchObject({ input: 'piazza nav', languageCode: 'it', sessionToken: 'sess-token-1234' });
    expect(body.locationBias.circle.center).toEqual({ latitude: 41.9, longitude: 12.5 });
  });

  it('restricts to (cities) in city mode', async () => {
    stub({ places: 'KEY', respond: () => ({ ok: true, status: 200, body: { suggestions: [] } }) });
    await handleSearchAddress(req({ query: 'ulm', mode: 'city' }));
    expect(JSON.parse(calls[0].init.body).includedPrimaryTypes).toEqual(['(cities)']);
  });

  it('resolves a place with details in English and the same session token', async () => {
    stub({ places: 'KEY', respond: () => ({ ok: true, status: 200, body: details }) });
    const r = await handleResolvePlace(req({ placeId: 'ChIJ_navona_000', sessionToken: 'sess-token-1234' }));
    expect(r.place).toEqual({
      address: 'Piazza Navona, 00186 Roma RM, Italy', lat: 41.8992, lng: 12.4731,
      city: 'Rome', country: 'Italy', countryCode: 'IT', placeId: 'ChIJ_navona_000',
    });
    expect(calls[0].url).toContain('/v1/places/ChIJ_navona_000?');
    expect(calls[0].url).toContain('sessionToken=sess-token-1234');
    expect(calls[0].url).toContain('languageCode=en');
    expect(calls[0].init.headers['X-Goog-FieldMask']).toContain('location');
  });

  it('resolvePlace fails cleanly without a key or with a bad id', async () => {
    stub({ respond: () => ({ ok: true, status: 200, body: details }) });
    await expect(handleResolvePlace(req({ placeId: 'ChIJ_navona_000' }))).rejects.toMatchObject({ statusCode: 503 });
    await expect(handleResolvePlace(req({ placeId: '../etc' }))).rejects.toMatchObject({ code: 'INVALID_ARGUMENT' });
  });

  it('reverse geocodes with the Geocoding API when that key is set', async () => {
    stub({
      geocoding: 'GKEY',
      respond: () => ({ ok: true, status: 200, body: { status: 'OK', results: [{ formatted_address: 'Piazza Navona, Roma', place_id: 'pid', address_components: [{ long_name: 'Rome', short_name: 'Rome', types: ['locality'] }, { long_name: 'Italy', short_name: 'IT', types: ['country'] }] }] } }),
    });
    const r = await handleReverseGeocode(req({ lat: 41.8992, lng: 12.4731, lang: 'pt-BR' }));
    expect(r.place).toMatchObject({ address: 'Piazza Navona, Roma', city: 'Rome', countryCode: 'IT', placeId: 'pid' });
    expect(calls[0].url).toContain('maps.googleapis.com/maps/api/geocode/json');
    expect(calls[0].url).toContain('language=pt-BR');
  });

  it('reads both address component shapes', () => {
    expect(googleComponents([{ long_name: 'Lazio', types: ['administrative_area_level_1'] }, { long_name: 'Italy', short_name: 'it', types: ['country'] }]))
      .toEqual({ city: 'Lazio', country: 'Italy', countryCode: 'IT' });
    expect(googleComponents(undefined as any)).toEqual({ city: '', country: '', countryCode: '' });
  });
});

describe('caching, auth, rate limit and errors', () => {
  it('serves a repeated query (other spelling) from cache without quota or HTTP', async () => {
    const quota = stub({ respond: () => ({ ok: true, status: 200, body: photonBody }) });
    await handleSearchAddress(req({ query: 'Piazza Navona' }));
    const again = await handleSearchAddress(req({ query: '  piazza   NAVONA ' }, 'u2'));
    expect(again.suggestions).toHaveLength(2);
    expect(calls).toHaveLength(1);
    expect(quota).toHaveBeenCalledTimes(1);
  });

  it('keys the cache by language and bias', async () => {
    stub({ places: 'KEY', respond: () => ({ ok: true, status: 200, body: { suggestions: [] } }) });
    await handleSearchAddress(req({ query: 'navona', lang: 'it' }));
    await handleSearchAddress(req({ query: 'navona', lang: 'de' }));
    await handleSearchAddress(req({ query: 'navona', lang: 'de', lat: 10, lng: 10 }));
    expect(calls).toHaveLength(3);
  });

  it('requires auth', async () => {
    stub({ respond: () => ({ ok: true, status: 200, body: photonBody }) });
    await expect(handleSearchAddress(req({ query: 'rome' }, null))).rejects.toMatchObject({ code: 'UNAUTHENTICATED' });
    await expect(handleReverseGeocode(req({ lat: 1, lng: 1 }, null))).rejects.toMatchObject({ code: 'UNAUTHENTICATED' });
  });

  it('validates reverse coordinates', async () => {
    stub({ respond: () => ({ ok: true, status: 200, body: photonBody }) });
    await expect(handleReverseGeocode(req({ lat: 91, lng: 0 }))).rejects.toMatchObject({ code: 'INVALID_ARGUMENT' });
    await expect(handleReverseGeocode(req({ lat: '1', lng: 0 }))).rejects.toMatchObject({ code: 'INVALID_ARGUMENT' });
  });

  it('limits each user to PER_MINUTE_LIMIT requests a minute', () => {
    for (let n = 0; n < PER_MINUTE_LIMIT; n++) checkRateLimit('fast', 5_000);
    expect(() => checkRateLimit('fast', 5_000)).toThrow(/Too many/);
    expect(() => checkRateLimit('other', 5_000)).not.toThrow();
    expect(() => checkRateLimit('fast', 65_001)).not.toThrow(); // new window
  });

  it('rate-limits even cached searches', async () => {
    stub({ respond: () => ({ ok: true, status: 200, body: photonBody }) });
    for (let n = 0; n < PER_MINUTE_LIMIT; n++) await handleSearchAddress(req({ query: 'rome' }));
    await expect(handleSearchAddress(req({ query: 'rome' }))).rejects.toMatchObject({ statusCode: 429 });
  });

  it('reports a provider failure as UNAVAILABLE and does not cache it', async () => {
    let fail = true;
    stub({ respond: () => (fail ? { ok: false, status: 502, body: null } : { ok: true, status: 200, body: photonBody }) });
    await expect(handleSearchAddress(req({ query: 'rome' }))).rejects.toMatchObject({ code: 'UNAVAILABLE', statusCode: 503 });
    fail = false;
    const r = await handleSearchAddress(req({ query: 'rome' }));
    expect(r.suggestions).toHaveLength(2);
  });

  it('a failed reverse lookup returns place: null (the pin is still usable)', async () => {
    stub({ respond: () => { throw new Error('timeout'); } });
    const r = await handleReverseGeocode(req({ lat: 41.9, lng: 12.5 }));
    expect(r).toEqual({ success: true, place: null });
  });

  it('propagates the daily quota error', async () => {
    _setDeps({
      fetchJson: async () => ({ ok: true, status: 200, body: photonBody }),
      placesKey: async () => null,
      quota: async () => { throw Object.assign(new Error('Daily limit'), { code: 'QUOTA_EXCEEDED' }); },
    });
    await expect(handleSearchAddress(req({ query: 'paris' }))).rejects.toMatchObject({ code: 'QUOTA_EXCEEDED' });
  });
});
