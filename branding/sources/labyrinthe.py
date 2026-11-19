import random, sys
# Labyrinthe parfait (parcours en profondeur), puis quelques murs retirés
# (boucles, comme dans le jeu). Cellules de C px sur 3840 x 2160.
#
# --salle : salle au centre (10 x 3 cases, comme la maison des fantômes du
# jeu) pour le texte « Packarch Linux » : sans murs ni pastilles dedans,
# cadre à double trait aux coins arrondis, ouverte à gauche et à droite.
# --salle-y=N : rangée du haut de la salle (10 par défaut : centrée) ;
# --salle-l=N, --salle-h=N : largeur et hauteur en cases (10 et 3 par
# défaut), salle centrée en largeur, portes au milieu des côtés.
# --cadre-seul : seulement le cadre de la salle (dessiné sans fondu sur le
# fond SDDM) ; --sans-cadre : le labyrinthe sans le cadre.
# --fantomes=N : N fantômes de couleur dans des couloirs (graine 11 : toujours
# les mêmes ; un par zone de l'écran), hors de la salle, de la zone de l'heure et du bas de l'écran ;
# pas de pastille sur leur case. --fantomes-seuls : seulement eux (calque à
# part, en pleines couleurs).
# Sans --salle, le labyrinthe est le même qu'avant.
args = sys.argv[1:]
salle = "--salle" in args
cadre_seul = "--cadre-seul" in args
fantomes_seuls = "--fantomes-seuls" in args
sans_cadre = "--sans-cadre" in args
def opt(nom, defaut):
    return next((int(a.split("=")[1]) for a in args if a.startswith(nom + "=")), defaut)
haut = opt("--salle-y", 10)
larg = opt("--salle-l", 10)
haute = opt("--salle-h", 3)
nb_fantomes = opt("--fantomes", 0)
random.seed(7)
C=96; W,H=3840,2160
nx,ny=W//C,H//C+1
ox=(W-nx*C)//2; oy=(H-ny*C)//2
# Salle : cases [sx0, sx1) x [sy0, sy1), centrée sur l'image
sx0=(nx-larg)//2
sx1,sy0,sy1=sx0+larg,haut,haut+haute
porte=haut+haute//2
def dans(x,y): return salle and sx0<=x<sx1 and sy0<=y<sy1
# Fantômes : cases choisies avec leur propre graine (le labyrinthe ne change
# pas), loin de la salle, de l'heure (en haut au centre) et du bas
COULEURS=[("#ff6b81","#e8364f"),("#8ff0b4","#22c55e"),("#ffb3df","#f472b6"),("#8fb4ff","#3b6fe0"),
          ("#ffc46b","#f59e0b"),("#d2b8ff","#8b5cf6"),("#7ff0f5","#22b8c9"),("#7ff5d8","#14b8a6")]
REGARDS=[(5,0),(-5,0),(0,4),(0,-4)]
hasard=random.Random(11)
fantomes=[]
# Un fantôme par zone (3 colonnes x 2 rangées d'écran), pour les répartir
zones=[(i,j) for j in range(2) for i in range(3)]
while len(fantomes)<nb_fantomes:
    zi,zj=zones[len(fantomes)%len(zones)]
    x=hasard.randrange(max(1,zi*nx//3),min(nx-1,(zi+1)*nx//3))
    y=hasard.randrange(max(1,zj*ny//2),min(ny-1,(zj+1)*ny//2))
    proche_salle=salle and sx0-2<=x<sx1+2 and sy0-2<=y<sy1+2
    heure=14<=x<26 and y<4
    bas_ecran=oy+y*C+C>H-380
    if proche_salle or heure or bas_ecran or any(abs(x-a)+abs(y-b)<6 for a,b,_,_ in fantomes): continue
    fantomes.append((x,y,COULEURS[len(fantomes)%len(COULEURS)],REGARDS[hasard.randrange(4)]))
def a_fantome(x,y): return any(a==x and b==y for a,b,_,_ in fantomes)
def dessin_fantomes():
    t=[]
    for i,(x,y,(c1,c2),(dx,dy)) in enumerate(fantomes):
        k=0.6  # 60 px de haut dans des couloirs de 96 px
        X=ox+x*C+C/2-50*k; Y=oy+y*C+C/2-54*k
        t.append(f'''<defs><linearGradient id="f{i}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{c1}"/><stop offset="1" stop-color="{c2}"/></linearGradient></defs>
<g transform="translate({X:.1f} {Y:.1f}) scale({k})"><path fill="url(#f{i})" d="M0 50 A50 50 0 0 1 100 50 V108 L83.3 92 L66.7 108 L50 92 L33.3 108 L16.7 92 L0 108 Z"/>
<ellipse cx="32" cy="46" rx="13" ry="16" fill="#fff"/><ellipse cx="68" cy="46" rx="13" ry="16" fill="#fff"/>
<circle cx="{32+dx}" cy="{46+dy}" r="7" fill="#2f5fd0"/><circle cx="{68+dx}" cy="{46+dy}" r="7" fill="#2f5fd0"/></g>''')
    return "\n".join(t)
# murs : droite[x][y], bas[x][y]
droite=[[True]*ny for _ in range(nx)]; bas=[[True]*ny for _ in range(nx)]
vu=[[dans(x,y) for y in range(ny)] for x in range(nx)]
pile=[(0,0)]; vu[0][0]=True
while pile:
    x,y=pile[-1]
    v=[(x+dx,y+dy) for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)) if 0<=x+dx<nx and 0<=y+dy<ny and not vu[x+dx][y+dy]]
    if not v: pile.pop(); continue
    a,b=random.choice(v)
    if a>x: droite[x][y]=False
    elif a<x: droite[a][b]=False
    elif b>y: bas[x][y]=False
    else: bas[a][b]=False
    vu[a][b]=True; pile.append((a,b))
for _ in range(nx*ny//6):
    x,y=random.randrange(nx-1),random.randrange(ny-1)
    r=random.random()
    # Les murs autour de la salle restent (le cadre les remplace)
    if salle and (dans(x,y) or dans(x+1,y) or dans(x,y+1)): continue
    if r<.5: droite[x][y]=False
    else: bas[x][y]=False
segs=[]
for x in range(nx):
    for y in range(ny):
        X,Y=ox+x*C,oy+y*C
        # Murs dedans et autour de la salle : dessinés par le cadre
        if droite[x][y] and x<nx-1 and not (dans(x,y) or dans(x+1,y)): segs.append((X+C,Y,X+C,Y+C))
        if bas[x][y] and y<ny-1 and not (dans(x,y) or dans(x,y+1)): segs.append((X,Y+C,X+C,Y+C))
d=" ".join(f"M{a} {b}L{c} {e}" for a,b,c,e in segs)
pts=" ".join(f"M{ox+x*C+C/2-5} {oy+y*C+C/2}a5 5 0 1 0 10 0a5 5 0 1 0-10 0" for x in range(nx) for y in range(ny) if not dans(x,y) and not a_fantome(x,y))
cadre=""
if salle:
    def rect(i, r):
        # Rectangle arrondi (marge i, rayon r), ouvert sur la case porte à
        # gauche et à droite
        x0,y0=ox+sx0*C+i, oy+sy0*C+i
        x1,y1=ox+sx1*C-i, oy+sy1*C-i
        p0,p1=oy+porte*C+18, oy+(porte+1)*C-18
        return (f"M{x0} {p0}V{y0+r}A{r} {r} 0 0 1 {x0+r} {y0}H{x1-r}A{r} {r} 0 0 1 {x1} {y0+r}V{p0}"
                f"M{x1} {p1}V{y1-r}A{r} {r} 0 0 1 {x1-r} {y1}H{x0+r}A{r} {r} 0 0 1 {x0} {y1-r}V{p1}")
    i=26
    x0,x1=ox+sx0*C, ox+sx1*C
    p0,p1=oy+porte*C+18, oy+(porte+1)*C-18
    # Les deux traits se rejoignent aux portes, comme dans le jeu
    jonctions=f"M{x0} {p0}H{x0+i}M{x0} {p1}H{x0+i}M{x1} {p0}H{x1-i}M{x1} {p1}H{x1-i}"
    cadre=f'\n<path d="{rect(0,40)} {rect(i,18)} {jonctions}" stroke="#2f3f85" stroke-width="10" stroke-linecap="round" stroke-linejoin="round" fill="none"/>'
if fantomes_seuls:
    print(f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}">
{dessin_fantomes()}
</svg>''')
    sys.exit()
if cadre_seul:
    print(f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}">{cadre}
</svg>''')
    sys.exit()
if sans_cadre: cadre=""
print(f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}">
<path d="{d}" stroke="#26336b" stroke-width="10" stroke-linecap="round" fill="none"/>
<path d="{pts}" fill="#2a2a33"/>{cadre}
</svg>''')
