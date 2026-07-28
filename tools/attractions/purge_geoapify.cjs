process.env.NODE_TLS_REJECT_UNAUTHORIZED='0';
const admin=require('firebase-admin');
admin.initializeApp({credential:admin.credential.cert(require('D:/Projects/GreenGo/firebase/greengo-chat-firebase-adminsdk.json'))});
const db=admin.firestore();

async function purgeBySource(coll, source){
  let total=0, cursor;
  for(;;){
    let q=db.collection(coll).where('source','==',source).orderBy('__name__').limit(400);
    if(cursor) q=q.startAfter(cursor);
    const snap=await q.get();
    if(snap.empty) break;
    const b=db.batch();
    snap.docs.forEach(d=>b.delete(d.ref));
    await b.commit();
    total+=snap.size;
    cursor=snap.docs[snap.docs.length-1];
    if(total%2000===0) console.log(`  ${coll}: ${total} deleted...`);
    if(snap.size<400) break;
  }
  return total;
}
async function purgeByPrefix(coll, prefix){
  let total=0;
  for(;;){
    const snap=await db.collection(coll).orderBy('__name__')
      .startAt(prefix).endAt(prefix+'\uf8ff').limit(400).get();
    if(snap.empty) break;
    const b=db.batch();
    snap.docs.forEach(d=>b.delete(d.ref));
    await b.commit();
    total+=snap.size;
    if(snap.size<400) break;
  }
  return total;
}
(async()=>{
  console.log('purging external_events (source=geoapify)...');
  const a=await purgeBySource('external_events','geoapify');
  console.log('purging external_events_index/geoapify_*...');
  const b=await purgeByPrefix('external_events_index','geoapify_');
  console.log('purging external_country_stats/geoapify_*...');
  const c=await purgeByPrefix('external_country_stats','geoapify_');
  console.log('\n=== PURGE DONE ===');
  console.log('external_events        :',a);
  console.log('external_events_index  :',b);
  console.log('external_country_stats :',c);
  const left=await db.collection('external_events').where('source','==','geoapify').count().get();
  console.log('remaining geoapify docs:',left.data().count);
  // confirm other sources untouched
  for(const s of ['viator','ticketmaster','tiqets']){
    const n=await db.collection('external_events').where('source','==',s).count().get();
    console.log(`  ${s} preserved: ${n.data().count}`);
  }
  process.exit(0);
})().catch(e=>{console.error('FAIL',e.message);process.exit(1);});
