process.env.NODE_TLS_REJECT_UNAUTHORIZED='0';
const admin=require('firebase-admin');
admin.initializeApp({credential:admin.credential.cert(require('D:/Projects/GreenGo/firebase/greengo-chat-firebase-adminsdk.json'))});
const db=admin.firestore(), auth=admin.auth();
(async()=>{
  const email='mauro.tommasi.work@gmail.com';
  let uid=null;
  try{ const u=await auth.getUserByEmail(email); uid=u.uid;
    console.log('USER  :',email,'\n  uid :',uid,'\n  disabled:',u.disabled);
  }catch(e){ console.log('USER LOOKUP FAILED:',e.message); }

  const ev=await db.collection('events')
    .where('title','>=','GreenGo').where('title','<=','GreenGo\uf8ff').limit(5).get();
  console.log('\nEVENTS matching "GreenGo":',ev.size);
  for(const d of ev.docs){
    const e=d.data();
    console.log(`  ${d.id}  "${e.title}"`);
    console.log(`     organizer=${e.organizerId} attendeeCount=${e.attendeeCount} max=${e.maxAttendees} status=${e.status||'-'}`);
    if(uid){
      const a=await db.collection('events').doc(d.id).collection('attendees').doc(uid).get();
      console.log(`     your attendee doc exists: ${a.exists}${a.exists?' status='+a.data().status:''}`);
    }
    const n=await db.collection('events').doc(d.id).collection('attendees').count().get();
    console.log(`     attendees subcollection: ${n.data().count}`);
  }
  process.exit(0);
})().catch(e=>{console.error('FAIL',e.message);process.exit(1);});
