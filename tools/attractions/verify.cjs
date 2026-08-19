process.env.NODE_TLS_REJECT_UNAUTHORIZED='0';
const admin=require('firebase-admin');
admin.initializeApp({credential:admin.credential.cert(require('D:/Projects/GreenGo/firebase/greengo-chat-firebase-adminsdk.json'))});
const db=admin.firestore();
(async()=>{
  // 1. exactly what AttractionsDataSource.publishedCountries() runs
  const c=await db.collection('attraction_countries').where('published','==',true).get();
  console.log('publishedCountries ->', c.docs.map(d=>`${d.id}:${d.data().publishedCount}`).join('  '));

  // 2. exactly what forCountry('IT') runs
  const s=await db.collection('attractions_index').where('iso2','==','IT').get();
  let items=[];
  for(const d of s.docs){ if(d.id.endsWith('_meta'))continue; items=items.concat(d.data().items||[]); }
  console.log('forCountry(IT) -> docs:',s.size,' records:',items.length);
  const a=items[0];
  console.log('top record keys:',Object.keys(a).join(','));
  console.log('sample:',a.n,'|',a.c,'| score',a.sc,a.st,'| cat',a.cat,a.ci,'| imp',a.imp,a.ii,'| lat',a.la);
  const missing=items.filter(x=>!x.b||!x.h||!x.tk||x.la==null||x.ln==null);
  console.log('records missing image/coords:',missing.length);
  const withAttr=items.filter(x=>x.at).length;
  console.log('records requiring attribution:',withAttr,'/',items.length);

  // 3. detail doc
  const d=await db.collection('attractions').doc(String(a.i)).get();
  const m=d.data();
  console.log('detail doc ->',m.name,'| highlights',(m.topHighlights||[]).length,'| facts',(m.interestingFacts||[]).length,'| hours',m.openingHours);

  // 4. cities used for "you're here"
  const ct=await db.collection('attraction_cities').where('published','==',true).get();
  console.log('cities ->',ct.size);

  // 5. taxonomy
  const tx=await db.collection('attraction_taxonomy').get();
  console.log('taxonomy ->',tx.size,'docs; sample:',tx.docs.slice(0,3).map(x=>`${x.id}=${x.data().icon}`).join(' '));
  process.exit(0);
})().catch(e=>{console.error('FAIL',e.message);process.exit(1);});
