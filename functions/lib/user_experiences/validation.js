"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.LIMITS = exports.PAYMENT_TYPES = exports.CATEGORIES = exports.EXPERIENCE_LIMITS = void 0;
exports.maxExperiencesFor = maxExperiencesFor;
exports.canCreateExperience = canCreateExperience;
exports.buildSearchKeywords = buildSearchKeywords;
exports.validateExperiencePayload = validateExperiencePayload;
exports.EXPERIENCE_LIMITS = {
    FREE: 0,
    SILVER: 1,
    GOLD: 5,
    PLATINUM: null,
    TEST: null,
};
/** Max experiences for [tier] (null = unlimited). Admins are unlimited. */
function maxExperiencesFor(tier, isAdmin = false) {
    if (isAdmin)
        return null;
    // `in` (not `??`): null means UNLIMITED and must not fall back to 0.
    return tier in exports.EXPERIENCE_LIMITS ? exports.EXPERIENCE_LIMITS[tier] : 0;
}
/** Whether a host with [count] experiences may create one more. */
function canCreateExperience(tier, count, isAdmin = false) {
    const max = maxExperiencesFor(tier, isAdmin);
    return max === null || count < max;
}
exports.CATEGORIES = [
    'foodDrink', 'cultureHistory', 'natureOutdoors', 'nightlife',
    'sportsAdventure', 'wellness', 'languageLearning', 'toursWalks',
    'workshopsClasses', 'other',
];
exports.PAYMENT_TYPES = ['pix', 'paypal', 'venmo', 'stripe', 'other'];
exports.LIMITS = {
    titleMin: 5,
    titleMax: 80,
    descriptionMin: 30,
    descriptionMax: 2000,
    maxPhotos: 8,
    includedMax: 20,
    notIncludedMax: 20,
    itemMax: 120,
    durationMin: 15,
    durationMax: 60 * 24 * 14, // two weeks
    groupMax: 500,
    priceMax: 1000000,
    shortTextMax: 500,
    locationMax: 200,
    paymentValueMax: 300,
    languagesMax: 10,
};
function str(v) {
    return typeof v === 'string' ? v.trim() : '';
}
function optStr(v, max) {
    const s = str(v);
    return s.length === 0 ? null : s.slice(0, max);
}
function isHttpUrl(v) {
    return /^https?:\/\/[^\s/$.?#][^\s]*$/i.test(v);
}
function strList(v) {
    if (!Array.isArray(v))
        return [];
    return v.map((x) => str(x)).filter((x) => x.length > 0);
}
function finiteNum(v) {
    return typeof v === 'number' && Number.isFinite(v) ? v : null;
}
/** Lower-cased search tokens (title, city, country, category), like events. */
function buildSearchKeywords(parts) {
    const out = new Set();
    for (const p of parts) {
        if (!p)
            continue;
        // Split on whitespace + ASCII punctuation (keeps accented letters / CJK
        // inside tokens; mirrors the client's keyword builder).
        for (const t of p.toLowerCase().split(/[\s!-/:-@[-`{-~]+/)) {
            if (t.length >= 2)
                out.add(t);
            if (out.size >= 40)
                break;
        }
    }
    return Array.from(out);
}
/**
 * Validates the payload of `createUserExperience`. Only client-owned fields
 * are read; anything server-owned in the payload (ratings, status 'hidden',
 * hostId of someone else, …) is ignored, never copied.
 */
function validateExperiencePayload(p) {
    const errors = [];
    const d = p !== null && p !== void 0 ? p : {};
    const title = str(d.title);
    if (title.length < exports.LIMITS.titleMin || title.length > exports.LIMITS.titleMax)
        errors.push('title');
    const description = str(d.description);
    if (description.length < exports.LIMITS.descriptionMin || description.length > exports.LIMITS.descriptionMax) {
        errors.push('description');
    }
    const category = str(d.category);
    if (!exports.CATEGORIES.includes(category))
        errors.push('category');
    const mainPhotoUrl = str(d.mainPhotoUrl);
    if (!isHttpUrl(mainPhotoUrl))
        errors.push('mainPhotoUrl');
    const photoUrls = strList(d.photoUrls);
    if (photoUrls.length > exports.LIMITS.maxPhotos || photoUrls.some((u) => !isHttpUrl(u))) {
        errors.push('photoUrls');
    }
    const included = strList(d.included);
    if (included.length < 1 || included.length > exports.LIMITS.includedMax ||
        included.some((i) => i.length > exports.LIMITS.itemMax)) {
        errors.push('included');
    }
    const notIncluded = strList(d.notIncluded);
    if (notIncluded.length > exports.LIMITS.notIncludedMax ||
        notIncluded.some((i) => i.length > exports.LIMITS.itemMax)) {
        errors.push('notIncluded');
    }
    const locationName = str(d.locationName);
    if (locationName.length === 0 || locationName.length > exports.LIMITS.locationMax) {
        errors.push('locationName');
    }
    const lat = finiteNum(d.lat);
    const lng = finiteNum(d.lng);
    const hasCoords = lat !== null && lng !== null &&
        Math.abs(lat) <= 90 && Math.abs(lng) <= 180;
    const geohash = str(d.geohash);
    const durationMinutes = finiteNum(d.durationMinutes);
    if (durationMinutes === null || !Number.isInteger(durationMinutes) ||
        durationMinutes < exports.LIMITS.durationMin || durationMinutes > exports.LIMITS.durationMax) {
        errors.push('durationMinutes');
    }
    const languages = strList(d.languages).slice(0, exports.LIMITS.languagesMax);
    if (languages.length < 1)
        errors.push('languages');
    const maxGroupSize = finiteNum(d.maxGroupSize);
    if (maxGroupSize === null || !Number.isInteger(maxGroupSize) ||
        maxGroupSize < 1 || maxGroupSize > exports.LIMITS.groupMax) {
        errors.push('maxGroupSize');
    }
    const minRaw = d.minGroupSize === null || d.minGroupSize === undefined
        ? null
        : finiteNum(d.minGroupSize);
    if (d.minGroupSize !== null && d.minGroupSize !== undefined &&
        (minRaw === null || !Number.isInteger(minRaw) || minRaw < 1 ||
            (maxGroupSize !== null && minRaw > maxGroupSize))) {
        errors.push('minGroupSize');
    }
    const isFree = d.isFree === true;
    const price = isFree ? 0 : finiteNum(d.price);
    if (price === null || price < 0 || price > exports.LIMITS.priceMax)
        errors.push('price');
    const currency = optStr(d.currency, 8);
    let paymentLink = null;
    const pl = (d.paymentLink && typeof d.paymentLink === 'object')
        ? d.paymentLink
        : null;
    if (pl) {
        const type = str(pl.type);
        const value = str(pl.value);
        const typeOk = exports.PAYMENT_TYPES.includes(type);
        const valueOk = value.length > 0 && value.length <= exports.LIMITS.paymentValueMax &&
            (type === 'pix' || isHttpUrl(value));
        if (typeOk && valueOk)
            paymentLink = { type, value };
        else if (!isFree)
            errors.push('paymentLink');
    }
    if (!isFree && !paymentLink && !errors.includes('paymentLink'))
        errors.push('paymentLink');
    const status = str(d.status) === 'published' ? 'published' : 'draft';
    const city = optStr(d.city, 120);
    const country = optStr(d.country, 120);
    const data = {
        title,
        description,
        category,
        mainPhotoUrl,
        photoUrls,
        included,
        notIncluded,
        locationName,
        city,
        country,
        lat: hasCoords ? lat : null,
        lng: hasCoords ? lng : null,
        geohash: hasCoords && /^[0-9b-hjkmnp-z]{1,12}$/.test(geohash) ? geohash : null,
        meetingPoint: optStr(d.meetingPoint, exports.LIMITS.shortTextMax),
        durationMinutes,
        languages,
        minGroupSize: minRaw,
        maxGroupSize,
        price: price !== null && price !== void 0 ? price : 0,
        currency: isFree ? null : currency,
        isFree,
        paymentLink,
        availability: optStr(d.availability, exports.LIMITS.shortTextMax),
        cancellationPolicy: optStr(d.cancellationPolicy, exports.LIMITS.shortTextMax),
        status,
        hostName: optStr(d.hostName, 120),
        hostPhotoUrl: optStr(d.hostPhotoUrl, 1000),
        searchKeywords: buildSearchKeywords([title, city, country, category, locationName]),
    };
    return { ok: errors.length === 0, errors, data };
}
//# sourceMappingURL=validation.js.map