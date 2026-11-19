import random, sys
# Labyrinthe parfait (parcours en profondeur), puis quelques murs retirés
# (boucles, comme dans le jeu). Cellules de C px sur 3840 x 2160.
random.seed(7)
C=96; W,H=3840,2160
nx,ny=W//C,H//C+1
ox=(W-nx*C)//2; oy=(H-ny*C)//2
# murs : droite[x][y], bas[x][y]
droite=[[True]*ny for _ in range(nx)]; bas=[[True]*ny for _ in range(nx)]
vu=[[False]*ny for _ in range(nx)]
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
    if random.random()<.5: droite[x][y]=False
    else: bas[x][y]=False
segs=[]
for x in range(nx):
    for y in range(ny):
        X,Y=ox+x*C,oy+y*C
        if droite[x][y] and x<nx-1: segs.append((X+C,Y,X+C,Y+C))
        if bas[x][y] and y<ny-1: segs.append((X,Y+C,X+C,Y+C))
d=" ".join(f"M{a} {b}L{c} {e}" for a,b,c,e in segs)
pts=" ".join(f"M{ox+x*C+C/2-5} {oy+y*C+C/2}a5 5 0 1 0 10 0a5 5 0 1 0-10 0" for x in range(nx) for y in range(ny))
print(f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}">
<path d="{d}" stroke="#26336b" stroke-width="10" stroke-linecap="round" fill="none"/>
<path d="{pts}" fill="#2a2a33"/>
</svg>''')
