import random, sys
# Labyrinthe parfait (parcours en profondeur), puis quelques murs retirés
# (boucles, comme dans le jeu). Cellules de C px sur 3840 x 2160.
#
# --salle : salle au centre (10 x 3 cases, comme la maison des fantômes du
# jeu) pour le texte « Packarch Linux » : sans murs ni pastilles dedans,
# cadre à double trait aux coins arrondis, ouverte à gauche et à droite.
# Sans l'option, le labyrinthe est le même qu'avant (fond SDDM).
salle = "--salle" in sys.argv[1:]
random.seed(7)
C=96; W,H=3840,2160
nx,ny=W//C,H//C+1
ox=(W-nx*C)//2; oy=(H-ny*C)//2
# Salle : cases [sx0, sx1) x [sy0, sy1), centrée sur l'image
sx0,sx1,sy0,sy1=15,25,10,13
porte=11
def dans(x,y): return salle and sx0<=x<sx1 and sy0<=y<sy1
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
pts=" ".join(f"M{ox+x*C+C/2-5} {oy+y*C+C/2}a5 5 0 1 0 10 0a5 5 0 1 0-10 0" for x in range(nx) for y in range(ny) if not dans(x,y))
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
print(f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}">
<path d="{d}" stroke="#26336b" stroke-width="10" stroke-linecap="round" fill="none"/>
<path d="{pts}" fill="#2a2a33"/>{cadre}
</svg>''')
