process.env.NODE_TLS_REJECT_UNAUTHORIZED='0';
const admin=require('firebase-admin');
admin.initializeApp({credential:admin.credential.cert(require('D:/Projects/GreenGo/firebase/greengo-chat-firebase-adminsdk.json'))});
const db=admin.firestore();
(async()=>{
  for(const id of ['253','251']){
    const d=await db.collection('attractions').doc(id).get();
    const m=d.data();
    console.log(`\n--- ${id} ${m.name} ---`);
    console.log('img field:', JSON.stringify(m.img));
    const B='greengo-chat.firebasestorage.app';
    for(const v of ['micro','thumb','card','hero']){
      const p=encodeURIComponent(`${m.img.base}/${v}-${m.img.hash}.webp`);
      const url=`https://firebasestorage.googleapis.com/v0/b/${B}/o/${p}?alt=media&token=${m.img.token}`;
      const r=await fetch(url,{method:'GET'});
      console.log(`  ${v.padEnd(6)} HTTP ${r.status}  ${r.headers.get('content-type')}  ${r.headers.get('content-length')||'?'} bytes`);
    }
  }
  process.exit(0);
})().catch(e=>{console.error('FAIL',e.message);process.exit(1);});
