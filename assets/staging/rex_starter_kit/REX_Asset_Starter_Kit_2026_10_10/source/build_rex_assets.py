#!/usr/bin/env python3
"""REX procedural 3D engineering starter assets + fidelity-preserving source sprites.
No claim of photorealistic/rigged game ready human characters.
Requires trimesh, numpy, Pillow (with scipy optional).
"""
from pathlib import Path
import math, json, zipfile, shutil, random
import numpy as np
import trimesh as tm
from PIL import Image, ImageDraw, ImageFont, ImageOps, ImageFilter

ROOT=Path('/mnt/data/REX_Asset_Starter_Kit_2026_10_10')
MESH=ROOT/'3d'/'glb'; SCRIPTS=ROOT/'source'; SPRITES=ROOT/'2d'/'extracted_verified'; CARDS=ROOT/'2d'/'playing_cards'; PREVIEW=ROOT/'preview'; REFS=ROOT/'references'
for p in (MESH,SCRIPTS,SPRITES,CARDS,PREVIEW,REFS):p.mkdir(parents=True,exist_ok=True)
GOLD=(232,163,35,255); LIGHT_GOLD=(252,207,87,255); DARK_GOLD=(148,85,18,255)
BLACK=(19,17,21,255); NAVY=(17,27,57,255); TAN=(174,124,83,255); SKIN_A=(196,137,95,255); SKIN_B=(221,176,130,255)
THEMES={
 'emerald':(13,87,62,255),
 'sapphire':(14,54,134,255),
 'ruby':(128,18,35,255),
 'obsidian':(25,26,31,255),
 'ivory':(218,199,165,255),
 'amethyst':(80,30,116,255),
}

def mesh_color(m,c):
 m.visual.vertex_colors=np.tile(np.array(c,dtype=np.uint8),(len(m.vertices),1))
 return m

def box(extents,pos,c):
 m=tm.creation.box(extents=extents)
 m.apply_translation(pos)
 return mesh_color(m,c)

def sphere(scale,pos,c,sub=2):
 m=tm.creation.icosphere(subdivisions=sub)
 m.apply_scale(scale)
 m.apply_translation(pos)
 return mesh_color(m,c)

def tube(start,end,r,c,sections=10):
 st=np.asarray(start,dtype=float); en=np.asarray(end,dtype=float); delta=en-st
 l=np.linalg.norm(delta)
 if l<1e-6:return sphere([r]*3,st,c,1)
 m=tm.creation.cylinder(radius=r,height=l,sections=sections)
 m.apply_transform(tm.geometry.align_vectors(np.array([0.,0.,1.]),delta/l))
 m.apply_translation((st+en)/2)
 return mesh_color(m,c)

def polytube(points,r,c,sections=8):
 return [tube(points[i],points[i+1],r,c,sections) for i in range(len(points)-1)]

def ell_ring(rx,ry,z,r,c,segments=96,cross=9,center=(0.,0.)):
 # elliptical tubular ring
 V=[];F=[]
 for i in range(segments):
  t=2*math.pi*i/segments; ct,st=math.cos(t),math.sin(t)
  cx=center[0]+rx*ct; cy=center[1]+ry*st
  n=np.array([ct/rx,st/ry,0.]);n=n/np.linalg.norm(n)
  for j in range(cross):
   p=2*math.pi*j/cross
   V.append([cx+r*math.cos(p)*n[0],cy+r*math.cos(p)*n[1],z+r*math.sin(p)])
 for i in range(segments):
  ni=(i+1)%segments
  for j in range(cross):
   nj=(j+1)%cross
   a=i*cross+j;b=ni*cross+j;cc=ni*cross+nj;d=i*cross+nj
   F.append([a,b,cc]);F.append([a,cc,d])
 return mesh_color(tm.Trimesh(vertices=V,faces=F,process=False),c)

def flat_disc(rx,ry,z,thick,color,n=96):
 # elliptical extruded solid top, smooth material via vertex colors
 vertices=[[0.,0.,z+thick/2],[0.,0.,z-thick/2]]
 for at_z in [z+thick/2,z-thick/2]:
  for i in range(n):
   a=2*math.pi*i/n
   vertices.append([rx*math.cos(a),ry*math.sin(a),at_z])
 faces=[]
 for i in range(n):
  k=(i+1)%n
  faces.extend([[0,2+i,2+k],[1,2+n+k,2+n+i], [2+i,2+n+i,2+n+k], [2+i,2+n+k,2+k]])
 return mesh_color(tm.Trimesh(vertices=vertices,faces=faces,process=False),color)

def ornament(coordinate,scale=1.):
 x,y,z=coordinate;v=[]
 # An original diamond stud composed of two elongated golden pyramids (baroque motif)
 for direction in (-1,1):
  m=tm.creation.cone(radius=0.035*scale,height=0.09*scale,sections=4)
  if direction==-1:m.apply_transform(tm.transformations.rotation_matrix(math.pi,[1,0,0]))
  m.apply_translation((x,y,z+direction*0.045*scale))
  v.append(mesh_color(m,LIGHT_GOLD))
 return v

def table_parts(cloth):
 out=[]
 # actual 3d: concentric top planes, ornate rims, table side and 4 feet
 out.append(flat_disc(1.40,1.02,1.03,.13,BLACK))
 out.append(flat_disc(1.30,.92,1.13,.03,GOLD))
 out.append(flat_disc(1.18,.81,1.166,.02,cloth))
 out.append(ell_ring(1.36,.98,1.11,.064,LIGHT_GOLD))
 out.append(ell_ring(1.265,.875,1.15,.022,DARK_GOLD))
 out.append(ell_ring(1.20,.825,1.185,.018,LIGHT_GOLD))
 out.append(ell_ring(1.38,.995,.991,.023,DARK_GOLD))
 out.append(ell_ring(1.37,.982,.932,.035,GOLD))
 # ribbing motifs decorating side wall of table
 for i in range(48):
  t=2*math.pi*i/48
  x,y=1.387*math.cos(t),1.015*math.sin(t)
  out.append(sphere([.027,.027,.020],[x,y,1.028],LIGHT_GOLD,1))
 for i in range(32):
  t=2*math.pi*i/32
  x,y=1.350*math.cos(t),.965*math.sin(t)
  out.extend(ornament((x,y,.94),.7))
 # pedestal + tapered carved arches
 out.append(tube([0,0,.25],[0,0,.95],.49,BLACK,32))
 for h,r in [(.26,.56),(.31,.51),(.52,.45),(.71,.50),(.89,.56)]:
  out.append(ell_ring(r,r*.78,h,.028,GOLD,64,8))
 for i in range(16):
  t=2*math.pi*i/16;x,y=.515*math.cos(t),.40*math.sin(t)
  out.extend(polytube([(x*.74,y*.74,.35),(x,y,.49),(x*.80,y*.80,.70)],.015,DARK_GOLD))
 for t in (0,math.pi/2,math.pi,3*math.pi/2):
  x,y=.93*math.cos(t),.75*math.sin(t)
  out.append(box([.23,.26,.23],[x,y,.19],BLACK))
  out.append(box([.26,.29,.055],[x,y,.08],GOLD))
  out.append(box([.24,.28,.046],[x,y,.32],LIGHT_GOLD))
 # corner badges along surface border
 for t in (math.pi/4,3*math.pi/4,5*math.pi/4,7*math.pi/4):
  x,y=1.30*math.cos(t),.93*math.sin(t)
  out.extend(ornament((x,y,1.16),1.2))
 # central emblem kept small / don't interfere with cards
 out.append(sphere([.22,.13,.004],[0,0,1.185],DARK_GOLD,2))
 return out

def chair_parts(upholstery):
 out=[]
 # Chair local front faces negative Y, Z is up. Plush seat.
 out.append(box([.72,.65,.11],[0,-.02,.59],GOLD))
 out.append(sphere([.337,.287,.095],[0,-.06,.675],upholstery,2))
 out.append(sphere([.31,.07,.55],[0,.245,1.13],upholstery,3))
 # arched carved chair back
 out.extend(polytube([(-.40,.28,.68),(-.43,.28,1.32),(-.37,.29,1.69),(-.17,.29,1.78),(0,.28,1.83),(.17,.29,1.78),(.37,.29,1.69),(.43,.28,1.32),(.40,.28,.68)],.043,LIGHT_GOLD,12))
 # gold spade-shaped chair crest
 out.extend(ornament((0,.28,1.84),2.2))
 # legs: dark core with bright gold bevels and feet
 for x in (-.32,.32):
  for y in (-.25,.24):
   out.append(tube([x,y,.06],[x,y,.59],.056,GOLD,12))
   out.append(box([.16,.16,.075],[x,y,.065],DARK_GOLD))
  # armrests at left/right
  out.extend(polytube([(x*1.20,-.32,.81),(x*1.2,-.12,.87),(x*1.19,.22,.89)],.058,GOLD,12))
  out.append(sphere([.076,.075,.078],[x*1.20,-.32,.82],LIGHT_GOLD,2))
  out.append(tube([x*1.20,-.21,.86],[x*1.20,-.17,.56],.031,DARK_GOLD,10))
 # gold studs tuft buttons x-z grid on the back face
 for row in range(3):
  for i in range(3-(row%2)):
   x=(i-(2-(row%2))/2)*.21
   z=1.00+row*.19
   out.append(sphere([.016,.013,.018],[x,.172,z],LIGHT_GOLD,1))
 return out

def seated_character_parts(gender='male',fabric=NAVY,skin=SKIN_B,hair=BLACK):
 # explicit engineering guide, not final realistic human model and not rigged
 o=[]
 # seated body chest, collar, lapel, lower half legs
 o.append(sphere([.24,.14,.30],[0,-.10,1.07],fabric,2))
 o.append(sphere([.22,.15,.105],[0,-.16,.78],fabric,2))
 for sx in (-1,1):
  o.append(sphere([.11,.14,.16],[sx*.145,-.19,.69],fabric,2))
  o.append(tube([sx*.145,-.18,.69],[sx*.145,-.47,.64],.079,fabric,10))
  o.append(sphere([.11,.15,.057],[sx*.145,-.49,.57],BLACK,2))
 # neck and head
 o.append(tube([0,-.11,1.285],[0,-.11,1.39],.067,skin,12))
 o.append(sphere([.132,.110,.168],[0,-.125,1.495],skin,3))
 o.append(sphere([.145,.095,.078],[0,-.13,1.620],hair,2))
 # face directed negativeY, eyes eyebrows nose
 for sx in (-1,1):
  o.append(sphere([.021,.017,.011],[sx*.052,-.226,1.515],BLACK,1))
  o.append(tube([sx*.036,-.221,1.538],[sx*.078,-.210,1.537],.007,BLACK,5))
 o.append(sphere([.020,.027,.027],[0,-.233,1.467],skin,1))
 o.append(tube([-.025,-.232,1.417],[.025,-.232,1.417],.005,DARK_GOLD,8))
 # arms around cards towards table center; shoulders -> elbows -> hands
 for sx in (-1,1):
  o.append(sphere([.105,.12,.12],[sx*.24,-.11,1.215],fabric,2))
  o.append(tube([sx*.23,-.09,1.19],[sx*.28,-.34,.97],.075,fabric,12))
  o.append(tube([sx*.28,-.34,.97],[sx*.13,-.49,1.06],.060,fabric,12))
  o.append(sphere([.065,.042,.04],[sx*.13,-.49,1.06],skin,2))
  o.extend(ornament((sx*.265,-.05,1.28),.6))
 # buttons on chest + necktie edge
 for z in (1.02,1.12,1.22):
  o.append(sphere([.01,.009,.015],[0,-.254,z],GOLD,1))
 if gender=='female':
  o.append(sphere([.15,.088,.07],[0,-.08,1.611],hair,2))
 return o

def rotate_z(meshes,angle):
 T=tm.transformations.rotation_matrix(angle,[0,0,1]);out=[]
 for m in meshes:
  n=m.copy();n.apply_transform(T);out.append(n)
 return out

def translate(meshes,vec):
 out=[]
 for m in meshes:
  n=m.copy();n.apply_translation(vec);out.append(n)
 return out

def export_mesh(meshes,path):
 merged=tm.util.concatenate(meshes)
 merged.export(path,file_type='glb')
 return {'vertices':len(merged.vertices),'faces':len(merged.faces),'bytes':path.stat().st_size}

manifest=[]
def record(path,asset_id,kind,status,description,details=None):
 manifest.append({'path':str(path.relative_to(ROOT)).replace('\\','/'),'id':asset_id,'kind':kind,'status':status,'description':description, **(details or {})})

for name,color in THEMES.items():
 path=MESH/f'table_royal_{name}.glb'; data=export_mesh(table_parts(color),path)
 record(path,'TABLE-3D-'+name,'3d_mesh','PROCEDURAL_STAGING','Actual 3D royal table geometry, colored felt, ornamental rim and pedestal; not sculpted photorealistic asset',data)
 path=MESH/f'chair_royal_{name}.glb';data=export_mesh(chair_parts(color),path)
 record(path,'CHAIR-3D-'+name,'3d_mesh','PROCEDURAL_STAGING','Actual 3D upholstered royal chair; stylized ornament; no upholstery texture baking',data)

# Four character stand-ins: fully 3D but not high fidelity or animation-ready.
characters=[('north_female','female',(117,24,43,255),SKIN_B,(36,18,18,255)),('east_male','male',(20,30,48,255),SKIN_A,(22,15,15,255)),('west_male','male',(231,223,209,255),SKIN_B,(28,22,18,255)),('south_female','female',(16,84,66,255),SKIN_B,(43,25,20,255))]
for name,gen,cl,skin,hair in characters:
 path=MESH/f'player_{name}_GUIDE_ONLY.glb';data=export_mesh(seated_character_parts(gen,cl,skin,hair),path)
 record(path,'PLAYER-GUIDE-'+name,'3d_mesh','PLACEHOLDER_ONLY_NOT_GAME_ART','Fully 3D seated proportion/blocking mannequin. NOT photorealistic, NOT rigged, NOT ready for production use',data)
# Card solids with jewel-colored edge, separate asset gives physical thickness
for kind,shade in [('front',(242,238,222,255)),('back',NAVY)]:
 parts=[box([.15,.002,.23],[0,0,.0],shade),box([.156,.004,.237],[0,.003,0],GOLD)]
 path=MESH/f'card_single_{kind}.glb';data=export_mesh(parts,path)
 record(path,'CARD-MESH-'+kind,'3d_mesh','PROCEDURAL_STAGING','3D card rectangular geometry; artwork separately provided as 2D card face PNG',data)

# Scene guide for testing placements - not photorealistic
scene=table_parts(THEMES['emerald'])
positions=[('north',(0,1.55,0),0),('east',(1.96,0,0),math.pi/2),('south',(0,-1.55,0),math.pi),('west',(-1.96,0,0),-math.pi/2)]
for (seat,pos,ang),(name,gen,cl,skin,hair) in zip(positions,characters):
 scene+=translate(rotate_z(chair_parts(NAVY),ang),pos)
 scene+=translate(rotate_z(seated_character_parts(gen,cl,skin,hair),ang),pos)
path=MESH/'REX_four_seat_scene_GUIDE_ONLY.glb';data=export_mesh(scene,path)
record(path,'SCENE-3D-001','3d_scene','PLACEHOLDER_ONLY_NOT_GAME_ART','3D layout sample for seat placement and perspective tests, NOT image-quality production scene',data)

# Preserve actual alpha exactly; filenames understandable to Codex
with zipfile.ZipFile('/mnt/data/REX_Visual_Reference_Pack.zip') as z:
 tocopy={
  'references/REF_07_REX_LOGO_ALPHA.png':'REX_Logo_Original_Transparent.png',
  'references/ASSET_12_BLUE_CHAIR_ANGLED_ALPHA.png':'Chair_Blue_Gold_Angled_Original.png',
  'references/ASSET_13_BLUE_CHAIR_FRONT_ALPHA.png':'Chair_Blue_Gold_Front_Original.png',
  'references/ASSET_14_TABLE_FELT_ALPHA.png':'Table_Emerald_Felt_Original.png',
  'references/ASSET_15_TABLE_FRAME_ALPHA.png':'Table_Royal_Gold_Frame_Original.png',
 }
 for origin,dest in tocopy.items():
  data=z.read(origin);target=SPRITES/dest;target.write_bytes(data)
  im=Image.open(target)
  if im.mode!='RGBA':raise RuntimeError(f'{dest} not RGBA')
  alpha=im.getchannel('A');ext=alpha.getextrema();
  if ext[0]>=255:raise RuntimeError(f'No transparency on {dest}')
  record(target,'SOURCE-ALPHA-'+dest,'png_rgba','ACTUAL_ALPHA_REFERENCE','Exact original transparent PNG from uploaded user-supplied REX reference pack',{'dimensions':im.size,'alpha_minmax':ext,'bytes':len(data)})
 # optional include small thumbnail contact reference guide only
 for file in ['REF_06_GAME_TABLE_FOUR_PLAYERS.png','REF_09_MAIN_ROYAL_LOBBY.png','REF_02_ASSET_ATLAS_REFERENCE.png']:
  data=z.read('references/'+file)
  target=REFS/file
  target.write_bytes(data)
  record(target,'REF-'+file,'png_reference','REFERENCE_ONLY','Unmodified concept reference image; not a composable production layer')

# 52 readable faces in 2D; suit color display suitable for game logic.
FONT_BASE='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
FONT_BOLD='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
font_44=ImageFont.truetype(FONT_BOLD,40);font_60=ImageFont.truetype(FONT_BASE,60);font_18=ImageFont.truetype(FONT_BASE,18)
for suit,color in [('spades',(20,23,30,255)),('hearts',(168,32,46,255)),('diamonds',(168,32,46,255)),('clubs',(20,23,30,255))]:
 char={'spades':'♠','hearts':'♥','diamonds':'♦','clubs':'♣'}[suit]
 for rank in ['A','2','3','4','5','6','7','8','9','10','J','Q','K']:
  sz=(180,260)
  im=Image.new('RGBA',sz,(0,0,0,0));d=ImageDraw.Draw(im)
  d.rounded_rectangle([3,3,176,256],radius=12,fill=(248,245,236,255),outline=GOLD,width=4)
  d.rounded_rectangle([8,8,171,251],radius=9,outline=(204,165,65,255),width=1)
  d.text((13,10),rank,font=font_44,fill=color)
  d.text((14,58),char,font=font_18,fill=color)
  bb=d.textbbox((0,0),char,font=font_60)
  d.text(((180-(bb[2]-bb[0]))/2,98),char,font=font_60,fill=color)
  # bottom inverse index, no glyph overlay obscuring legibility
  d.text((139,202),rank,font=ImageFont.truetype(FONT_BOLD,23),fill=color)
  p=CARDS/f'{suit}_{rank}.png';im.save(p,optimize=True)
  record(p,'CARD-2D-'+suit+'-'+rank,'png_rgba','GENERATED_PLAYABLE_VISUAL','Readable standard playing card face, independent PNG',{'dimensions':sz})
# back card
im=Image.new('RGBA',(180,260),(0,0,0,0));d=ImageDraw.Draw(im)
d.rounded_rectangle([3,3,176,256],radius=12,fill=(13,23,47,255),outline=GOLD,width=5)
for off in (10,18):d.rounded_rectangle([off,off,179-off,259-off],radius=8,outline=LIGHT_GOLD if off==10 else DARK_GOLD,width=2)
for t in range(20):
 a=math.pi*2*t/20
 x=90+51*math.cos(a);y=130+84*math.sin(a)
 d.ellipse([x-2,y-2,x+2,y+2],fill=GOLD)
d.text((90,123),'REX',font=ImageFont.truetype(FONT_BOLD,32),fill=GOLD,anchor='mm')
d.text((90,164),'♠',font=ImageFont.truetype(FONT_BASE,37),fill=GOLD,anchor='mm')
p=CARDS/'rex_card_back.png';im.save(p,optimize=True)
record(p,'CARD-2D-BACK','png_rgba','GENERATED_PLAYABLE_VISUAL','Reusable REX card back, consistent with gold/navy motif')

# visual contact sheet for actual deliverables (not a photorealistic preview)
actual=[SPRITES/'Table_Emerald_Felt_Original.png',SPRITES/'Table_Royal_Gold_Frame_Original.png',SPRITES/'Chair_Blue_Gold_Front_Original.png',SPRITES/'Chair_Blue_Gold_Angled_Original.png',SPRITES/'REX_Logo_Original_Transparent.png',CARDS/'spades_A.png',CARDS/'hearts_K.png',CARDS/'rex_card_back.png']
canvas=Image.new('RGB',(1440,990),(17,20,28));d=ImageDraw.Draw(canvas)
try:label_font=ImageFont.truetype(FONT_BOLD,22)
except:label_font=ImageFont.load_default()
labels=['Real alpha: felt','Real alpha: frame','Real alpha: front chair','Real alpha: angled chair','Real alpha: REX logo','Generated Ace','Generated King','Generated back']
for i,(source,label) in enumerate(zip(actual,labels)):
 col=i%4;row=i//4;x=col*360;y=row*485
 tile=Image.new('RGBA',(344,416),(30,35,44,255))
 td=ImageDraw.Draw(tile)
 for cy in range(0,416,28):
  for cx in range(0,344,28):
   if (cx//28+cy//28)%2==0:td.rectangle([cx,cy,cx+27,cy+27],fill=(47,51,59,255))
 src=Image.open(source).convert('RGBA');src.thumbnail((322,354),Image.Resampling.LANCZOS)
 tile.alpha_composite(src,((344-src.width)//2,(360-src.height)//2))
 canvas.paste(tile.convert('RGB'),(x+8,y+8))
 d.text((x+15,y+432),label,font=label_font,fill=(242,211,129))
canvas.save(PREVIEW/'REX_starter_asset_contact_sheet.jpg',quality=90)

# Documentation
README='''# REX asset starter kit — 2026-10-10

## What IS delivered
- 13 **real GLB geometry files**: six royal table color versions, six royal upholstered chair color versions, a four-seat layout scene, **plus** eight additional engineering GLBs (four seated human figure guides and two basic physical cards; total counts are calculated from actual files).
- 5 exact user-supplied transparent PNG assets: REX crest, two viewpoints of a chair, table felt, table frame.
- 53 independently generated 2D playing-card PNGs: 52 card faces and one back.
- Three original source concept references (reference only); a preview contact sheet.
- Full JSON manifest and the editable Python geometry-generation script.

## What is NOT delivered / MUST NOT be claimed
- NOT production-quality photorealistic characters. The four `PLAYER-GUIDE` meshes are simple geometry for seat blocking only. They are **not rigged, skinned, animated or fit as final human characters**.
- The procedural GLB tables and chairs are **real 3D geometry**, but do not match the ornate sculpting, PBR textures, lighting and realism of the supplied concept art exactly. They are staging models for engineering, camera and scale checks.
- No full photorealistic environment meshes, palaces, rigged outfits or animations. Images of places and interfaces supplied by the team remain flattened references, not independent environment textures.
- No ready-to-run Flutter 3D renderer. Flutter cannot display GLB by itself without a selected rendering pipeline; that choice must be reviewed by Abdulaziz.
- No independently extracted character PNGs from flattened screenshot collages. This would be misleading.
- No 100% visual fidelity claim. No copyright or commercial-rights verification independent of the team's source ownership.

## Folder guide
- `3d/glb/`: actual GLB meshes. Coordinates: **Z-up** authored locally, meters-ish; after import check engine axis conversion. Card designs are separately provided as 2D, not automatically texture mapped to GLB.
- `2d/extracted_verified/`: original assets with real alpha from user-uploaded files; pixels unaltered.
- `2d/playing_cards/`: generated single-card PNGs.
- `references/`: exact concept renders, **not production layers**.
- `source/build_rex_assets.py`: procedural Python generator; requires trimesh, Pillow and numpy.
- `ASSET_MANIFEST.json`: individual file status.

## Recommended implementation
1. For an immediately faithful *2D/2.5D* Android visual preview, use supplied alpha table + chair sprites, preserve dynamic Flutter cards, and acquire 4 independent character images. Do not put interactive buttons over flattened reference screenshots.
2. For production *true 3D*, commission/model real detailed chairs, tables, 4 rigged characters, calibrated cameras, light rigs and optimized material textures. These GLBs can be proportion/placement prototypes only.
3. Select Flutter rendering integration after hardware benchmark. Do not silently switch architecture.
4. Optimize PNGs, texture atlases and GLB meshes before mobile shipment.
5. Do not treat shop prices/coins/voice or any other visible mockup text as approved application requirements.
'''
(ROOT/'README.md').write_text(README,encoding='utf-8')
shutil.copy2(Path(__file__),SCRIPTS/'build_rex_assets.py')
(ROOT/'ASSET_MANIFEST.json').write_text(json.dumps({'project':'REX','status':'starter assets, not visual approval','source':'user-supplied original REX art directions and sprites','files':manifest},ensure_ascii=False,indent=2),encoding='utf-8')
counts={}
for item in manifest:counts[item['status']]=counts.get(item['status'],0)+1
print(json.dumps({'root':str(ROOT),'models':len(list(MESH.glob('*.glb'))),'card_images':len(list(CARDS.glob('*.png'))),'source_alpha':len(list(SPRITES.glob('*.png'))),'asset_counts':counts,'total_bytes':sum(p.stat().st_size for p in ROOT.rglob('*') if p.is_file())},indent=2))
