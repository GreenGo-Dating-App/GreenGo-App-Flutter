process.env.NODE_TLS_REJECT_UNAUTHORIZED='0';
const fs=require('fs');
const admin=require('firebase-admin');
admin.initializeApp({credential:admin.credential.cert(require('D:/Projects/GreenGo/firebase/greengo-chat-firebase-adminsdk.json'))});
const db=admin.firestore();
const NAME={IT:'Italy',ES:'Spain',US:'United States',BR:'Brazil'};
(async()=>{
  const out={};
  for(const iso of ['IT','ES','US','BR']){
    const s=await db.collection('attractions_index').where('iso2','==',iso).get();
    let items=[];
    for(const d of s.docs){ if(d.id.endsWith('_meta'))continue; items=items.concat(d.data().items||[]); }
    const byCity={};
    for(const a of items){ (byCity[a.c]=byCity[a.c]||[]).push(a); }
    for(const c of Object.keys(byCity)) byCity[c].sort((x,y)=>y.sc-x.sc);
    out[iso]={total:items.length,byCity};
  }
  let md='# Attractions live in GreenGo — Events > Attractions\n\n';
  let txt='';
  for(const iso of ['IT','ES','US','BR']){
    const {total,byCity}=out[iso];
    md+=`\n## ${NAME[iso]} (${iso}) — ${total}\n\n`;
    txt+=`\n===== ${NAME[iso]} (${iso}) — ${total} =====\n`;
    const cities=Object.keys(byCity).sort((a,b)=>byCity[b].length-byCity[a].length);
    for(const city of cities){
      md+=`\n### ${city} (${byCity[city].length})\n\n| # | Attraction | Category | Score | Tier | Importance |\n|---|---|---|---|---|---|\n`;
      txt+=`\n-- ${city} (${byCity[city].length}) --\n`;
      byCity[city].forEach((a,i)=>{
        md+=`| ${a.i} | ${a.n} | ${a.cat} | ${a.sc} | ${a.st} | ${a.imp} |\n`;
        txt+=`${String(a.i).padEnd(5)} ${String(a.n).slice(0,42).padEnd(44)} ${String(a.cat).padEnd(17)} ${String(a.sc).padStart(3)} ${a.st}\n`;
      });
    }
  }
  fs.writeFileSync('C:/Users/Software Engineering/Desktop/GreenGo-Attractions-Live-List.md',md,'utf8');
  fs.writeFileSync('published_list.txt',txt,'utf8');
  console.log(txt);
  process.exit(0);
})().catch(e=>{console.error('FAIL',e.message);process.exit(1);});
