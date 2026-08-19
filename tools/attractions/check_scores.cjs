process.env.NODE_TLS_REJECT_UNAUTHORIZED='0';
const admin=require('firebase-admin');
admin.initializeApp({credential:admin.credential.cert(require('D:/Projects/GreenGo/firebase/greengo-chat-firebase-adminsdk.json'))});
const db=admin.firestore();
(async()=>{
  const s=await db.collection('attractions_index').get();
  let n=0,zero=0,noTier=0,min=999,max=0;
  const tiers={};
  for(const d of s.docs){
    if(d.id.endsWith('_meta'))continue;
    for(const a of (d.data().items||[])){
      n++;
      const sc=a.sc;
      if(sc==null||sc===0){zero++;console.log('  ZERO SCORE:',a.i,a.n);}
      if(!a.st)noTier++;
      if(sc<min)min=sc; if(sc>max)max=sc;
      tiers[a.st]=(tiers[a.st]||0)+1;
    }
  }
  console.log('index records          :',n);
  console.log('missing/zero score     :',zero);
  console.log('missing tier           :',noTier);
  console.log('score range            :',min,'-',max);
  console.log('tiers                  :',JSON.stringify(tiers));
  const f=await db.collection('attractions').where('greengoScore','==',0).limit(5).get();
  console.log('full docs with score 0 :',f.size);
  process.exit(0);
})().catch(e=>{console.error('FAIL',e.message);process.exit(1);});
