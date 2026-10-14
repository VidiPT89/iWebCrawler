const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
function setup(urls,customize=()=>{}){
 let frame; const messages=[];
 const links=urls.map((href,i)=>({href,textContent:'Reference '+i,getAttribute:()=>null,querySelector:()=>null,style:{},getClientRects:()=>[{}],getBoundingClientRect:()=>({x:40,y:100+i*40,width:150,height:20}),scrollIntoView(){}}));
 customize(links);
 const ctx=new Proxy({},{get:()=>()=>{},set:()=>true});
 const scope={URL,Set,Math,innerWidth:800,innerHeight:600,devicePixelRatio:1,matchMedia:()=>({matches:true}),cancelAnimationFrame:()=>{},requestAnimationFrame:f=>{frame=f;return 1},document:{title:'Test',querySelectorAll:()=>links,createElement:()=>({style:{},setAttribute(){},getContext:()=>ctx}),documentElement:{appendChild(){},dataset:{}}},window:{webkit:{messageHandlers:{crawler:{postMessage:m=>messages.push(m)}}}}};
 vm.runInNewContext(fs.readFileSync('iWebCrawler/Resources/Spider.js','utf8'),scope);
 return {api:scope.window.__crawler,messages,tick:t=>frame(t)};
}
test('reports links, excludes unsafe protocols and emits unique references',()=>{const s=setup(['https://doi.org/10.1234/example','javascript:alert(1)','https://doi.org/10.1234/example']);assert.equal(s.messages[0].count,2);s.api.start();s.tick(2000);s.tick(4000);s.tick(6000);assert.equal(s.messages.filter(m=>m.kind==='link').length,1);assert.equal(s.messages.find(m=>m.kind==='link').type,'DOI');assert.equal(s.messages.at(-1).kind,'complete')});
test('pause stops discoveries and resume continues',()=>{const s=setup(['https://example.com/a','https://example.com/b']);s.api.start();s.tick(2000);s.api.pause();s.tick(4000);assert.equal(s.messages.filter(m=>m.kind==='link').length,1);s.api.start();s.tick(6000);assert.equal(s.messages.filter(m=>m.kind==='link').length,2)});
test('empty documents finish safely',()=>{const s=setup([]);s.api.start();s.tick(2000);assert.equal(s.messages.at(-1).kind,'complete')});
test('completed exploration can be restarted',()=>{const s=setup(['https://example.com']);s.api.start();s.tick(2000);s.tick(4000);s.api.start();s.tick(6000);assert.equal(s.messages.filter(m=>m.kind==='link').length,2)});
test('classifies ISBN, PMID and Bibcode references',()=>{const s=setup(['https://en.wikipedia.org/wiki/Special:BookSources/9780199734825','https://pubmed.ncbi.nlm.nih.gov/33270151/','https://ui.adsabs.harvard.edu/abs/2021SciNa.108....1Z/abstract']);s.api.start();s.tick(2000);s.tick(4000);s.tick(6000);assert.deepEqual(s.messages.filter(m=>m.kind==='link').map(m=>m.type),['ISBN','PMID','Bibcode'])});
test('emits progress for duplicate links as well as unique discoveries',()=>{const s=setup(['https://example.com/a','https://example.com/a']);s.api.start();s.tick(2000);s.tick(4000);assert.deepEqual(s.messages.filter(m=>m.kind==='progress').map(m=>m.scanned),[1,2])});
test('speed configuration changes scan interval',()=>{const s=setup(['https://example.com/a','https://example.com/b']);s.api.configure({speed:4});s.api.start();s.tick(300);s.tick(600);assert.equal(s.messages.filter(m=>m.kind==='link').length,2)});
test('names image and icon links from their accessible label and skips unnamed ones',()=>{const s=setup(['https://example.com/logo','https://example.com/icon','https://example.com/empty'],([img,icon,empty])=>{img.textContent='';img.querySelector=()=>({alt:'Example logo'});icon.textContent='  ';icon.getAttribute=n=>n==='aria-label'?'Open menu':null;empty.textContent=''});assert.equal(s.messages[0].count,2);s.api.start();s.tick(2000);s.tick(4000);assert.deepEqual(s.messages.filter(m=>m.kind==='link').map(m=>m.title),['Example logo','Open menu'])});
