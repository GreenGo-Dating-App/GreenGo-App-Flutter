/** Compute a bounding box per country from its published attraction coordinates
 *  and store it on attraction_countries/{ISO2}. Used by the app to resolve which
 *  country a user is standing in without a reverse-geocode call. */
process.env.NODE_TLS_REJECT_UNAUTHORIZED='0';
const admin=require('firebase-admin');
admin.initializeApp({credential:admin.credential.cert(require('D:/Projects/GreenGo/firebase/greengo-chat-firebase-adminsdk.json'))});
const db=admin.firestore();
const PAD=1.5; // degrees of padding so users outside our city set still match
(async()=>{
  const snap=await db.collection('attractions_index').get();
  const box={};
  for(const d of snap.docs){
    if(d.id.endsWith('_meta'))continue;
    const iso=d.data().iso2;
    for(const a of (d.data().items||[])){
      if(typeof a.la!=='number'||typeof a.ln!=='number')continue;
      const b=box[iso]||(box[iso]={s:90,w:180,n:-90,e:-180});
      b.s=Math.min(b.s,a.la); b.n=Math.max(b.n,a.la);
      b.w=Math.min(b.w,a.ln); b.e=Math.max(b.e,a.ln);
    }
  }
  let batch=db.batch(),n=0;
  for(const [iso,b] of Object.entries(box)){
    batch.set(db.collection('attraction_countries').doc(iso),
      { bbox:[ +(b.s-PAD).toFixed(4), +(b.w-PAD).toFixed(4),
               +(b.n+PAD).toFixed(4), +(b.e+PAD).toFixed(4) ] },{merge:true});
    n++;
  }
  await batch.commit();
  console.log('bbox written for',n,'countries');
  const us=(await db.collection('attraction_countries').doc('US').get()).data();
  console.log('US bbox [S,W,N,E]:',us.bbox);
  // sanity: Denver + Seattle + Dallas must fall inside the US box
  const inBox=(p,b)=>p[0]>=b[0]&&p[0]<=b[2]&&p[1]>=b[1]&&p[1]<=b[3];
  for(const [name,p] of [['Denver',[39.74,-104.99]],['Seattle',[47.61,-122.33]],['Dallas',[32.78,-96.80]],['Los Angeles',[34.05,-118.24]]])
    console.log(`  ${name.padEnd(12)} inside US bbox: ${inBox(p,us.bbox)}`);
  process.exit(0);
})().catch(e=>{console.error('FAIL',e.message);process.exit(1);});
