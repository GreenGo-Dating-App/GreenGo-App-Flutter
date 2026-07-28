process.env.NODE_TLS_REJECT_UNAUTHORIZED='0';
const admin=require('firebase-admin');
admin.initializeApp({credential:admin.credential.cert(require('D:/Projects/GreenGo/firebase/greengo-chat-firebase-adminsdk.json'))});
const db=admin.firestore();
(async()=>{
  const c=await db.collection('attraction_countries').where('published','==',true).get();
  const rows=c.docs.map(d=>({iso:d.id,n:d.data().name,t:d.data().publishedCount})).sort((a,b)=>b.t-a.t);
  console.log('PUBLISHED COUNTRIES:',rows.length);
  let line='';
  rows.forEach((r,i)=>{ line+=`${r.iso} ${String(r.t).padStart(3)}   `; if((i+1)%8===0){console.log('  '+line);line='';} });
  if(line) console.log('  '+line);
  const tot=rows.reduce((s,r)=>s+r.t,0);
  console.log('TOTAL ATTRACTIONS:',tot);
  const idx=await db.collection('attractions_index').get();
  console.log('index docs:',idx.size,'(shards + meta)');
  const cities=await db.collection('attraction_cities').count().get();
  console.log('cities:',cities.data().count);
  // integrity: score + image on every index record
  let n=0,bad=0;
  for(const d of idx.docs){ if(d.id.endsWith('_meta'))continue;
    for(const a of (d.data().items||[])){ n++; if(!a.sc||!a.b||!a.h||!a.tk) bad++; } }
  console.log('index records:',n,'| missing score/image:',bad);
  process.exit(0);
})().catch(e=>{console.error('FAIL',e.message);process.exit(1);});
