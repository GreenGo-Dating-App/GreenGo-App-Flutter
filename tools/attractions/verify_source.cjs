process.env.NODE_TLS_REJECT_UNAUTHORIZED='0';
const admin=require('firebase-admin'); const XLSX=require('xlsx');
admin.initializeApp({credential:admin.credential.cert(require('D:/Projects/GreenGo/firebase/greengo-chat-firebase-adminsdk.json'))});
const db=admin.firestore();
(async()=>{
  const wb=XLSX.readFile('C:/Users/Software Engineering/Desktop/Travel-Attractions-Dataset/master.xlsx');
  const rows=XLSX.utils.sheet_to_json(wb.Sheets[wb.SheetNames[0]],{defval:null});
  const score=new Map(), ids=new Set();
  for(const r of rows){ ids.add(Number(r.AttractionID)); score.set(Number(r.AttractionID), Number(r.PopularityScore)); }
  console.log('xlsx rows:',rows.length);

  const s=await db.collection('attractions_index').get();
  let n=0, notInXlsx=0, mismatch=0;
  for(const d of s.docs){
    if(d.id.endsWith('_meta'))continue;
    for(const a of (d.data().items||[])){
      n++;
      if(!ids.has(a.i)){ notInXlsx++; console.log('  NOT IN XLSX:',a.i,a.n); }
      else if(score.get(a.i)!==a.sc){ mismatch++; console.log('  SCORE MISMATCH:',a.i,a.n,'xlsx',score.get(a.i),'firestore',a.sc); }
    }
  }
  console.log('published records          :',n);
  console.log('NOT present in master.xlsx :',notInXlsx);
  console.log('score != PopularityScore   :',mismatch);

  // Anything else that could still surface as an "attraction"?
  const geo=await db.collection('external_events').where('source','==','geoapify').count().get();
  console.log('\nleftover geoapify docs in external_events:',geo.data().count,'(tab no longer reads them)');
  process.exit(0);
})().catch(e=>{console.error('FAIL',e.message);process.exit(1);});
