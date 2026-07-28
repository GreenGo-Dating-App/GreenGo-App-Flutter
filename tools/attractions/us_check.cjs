process.env.NODE_TLS_REJECT_UNAUTHORIZED='0';
const admin=require('firebase-admin'); const XLSX=require('xlsx');
admin.initializeApp({credential:admin.credential.cert(require('D:/Projects/GreenGo/firebase/greengo-chat-firebase-adminsdk.json'))});
const db=admin.firestore();
(async()=>{
  const wb=XLSX.readFile('C:/Users/Software Engineering/Desktop/Travel-Attractions-Dataset/master.xlsx');
  const rows=XLSX.utils.sheet_to_json(wb.Sheets[wb.SheetNames[0]],{defval:null}).filter(r=>r.CountryISO2==='US');
  console.log('US rows in master.xlsx        :',rows.length);
  console.log('US AttractionID range         :',Math.min(...rows.map(r=>+r.AttractionID)),'-',Math.max(...rows.map(r=>+r.AttractionID)));
  const cities={}; rows.forEach(r=>cities[r.CityName]=(cities[r.CityName]||0)+1);
  console.log('US cities in sheet            :',Object.keys(cities).length);
  console.log(' ',Object.entries(cities).map(([k,v])=>`${k} ${v}`).join(' | '));

  const s=await db.collection('attractions_index').where('iso2','==','US').get();
  let items=[]; for(const d of s.docs){ if(d.id.endsWith('_meta'))continue; items=items.concat(d.data().items||[]); }
  console.log('\nUS PUBLISHED in Firestore     :',items.length);
  const pc={}; items.forEach(a=>pc[a.c]=(pc[a.c]||0)+1);
  console.log(' by city:',Object.entries(pc).map(([k,v])=>`${k} ${v}`).join(' | '));
  const la=items.filter(a=>a.c==='Los Angeles');
  console.log('\nLos Angeles published         :',la.length);
  la.sort((a,b)=>b.sc-a.sc).forEach(a=>console.log('   %s  %s (%s)',String(a.sc).padStart(3),a.n,a.cat));
  process.exit(0);
})().catch(e=>{console.error('FAIL',e.message);process.exit(1);});
