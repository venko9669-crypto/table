#!/usr/bin/env python3
"""Подрежда STL частите на плочи за принтер с маса 220x220 (Creality) и
записва всяка плоча като .3mf (отделни обекти - слайсърът може да ги мести)
и като .stl. Пуска се от папката на проекта: python3 tools/make_plates.py
"""
import os, zipfile

BED = 220          # размер на масата
MARGIN = 6         # от ръба на масата
GAP = 5            # между частите

PLATES = [
    # име, [(stl, брой)], запълване (за бележката)
    ("plate1_links_outer", [("link_outer", 22), ("link_end", 2), ("link_end_r", 2)], "40% gyroid"),
    ("plate2_links_inner", [("link_inner", 24)], "40%"),
    ("plate3_shoes",       [("leg_shoe", 4)], "25% gyroid"),
    ("plate4_hub",         [("leg_hub", 1)], "15% gyroid"),
    ("plate5_mounts",      [("leg_mount", 2), ("leg_mount_r", 2)], "50% gyroid"),
]

def read_stl(path):
    tris, cur = [], []
    for line in open(path):
        p = line.split()
        if p and p[0] == "vertex":
            cur.append(tuple(float(v) for v in p[1:4]))
            if len(cur) == 3:
                tris.append(cur); cur = []
    return tris

def bbox(tris):
    pts = [v for t in tris for v in t]
    return [min(p[i] for p in pts) for i in range(3)], [max(p[i] for p in pts) for i in range(3)]

def normalized(tris):
    lo, hi = bbox(tris)
    t2 = [[(v[0] - lo[0], v[1] - lo[1], v[2] - lo[2]) for v in t] for t in tris]
    return t2, [hi[i] - lo[i] for i in range(3)]

def rotate90(tris):
    return [[(-v[1], v[0], v[2]) for v in t] for t in tris]

def arrange(items):
    """Редове по ширина; връща [(обект, x, y)] или None, ако не се събират."""
    x, y, row_h, out = MARGIN, MARGIN, 0, []
    for name, size in items:
        w, d = size[0], size[1]
        if x + w > BED - MARGIN:
            x, y, row_h = MARGIN, y + row_h + GAP, 0
        if y + d > BED - MARGIN:
            return None
        out.append((name, x, y))
        x += w + GAP
        row_h = max(row_h, d)
    # центриране на цялата група
    maxx = max(px + dict(items)[n][0] for n, px, py in out) if False else None
    return out

def write_3mf(path, objects, placements):
    verts_xml = []
    res = []
    for oid, (name, tris) in enumerate(objects, start=1):
        idx, vs, tri_idx = {}, [], []
        for t in tris:
            ids = []
            for v in t:
                k = (round(v[0], 4), round(v[1], 4), round(v[2], 4))
                if k not in idx:
                    idx[k] = len(vs); vs.append(k)
                ids.append(idx[k])
            if len(set(ids)) == 3:
                tri_idx.append(ids)
        v_xml = "".join(f'<vertex x="{a}" y="{b}" z="{c}"/>' for a, b, c in vs)
        t_xml = "".join(f'<triangle v1="{a}" v2="{b}" v3="{c}"/>' for a, b, c in tri_idx)
        res.append(f'<object id="{oid}" name="{name}" type="model"><mesh><vertices>{v_xml}</vertices>'
                   f'<triangles>{t_xml}</triangles></mesh></object>')
    build = "".join(f'<item objectid="{oid}" transform="1 0 0 0 1 0 0 0 1 {x:.3f} {y:.3f} 0"/>'
                    for oid, (x, y) in enumerate(placements, start=1))
    model = ('<?xml version="1.0" encoding="UTF-8"?>\n'
             '<model unit="millimeter" xml:lang="en-US" '
             'xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">'
             f'<resources>{"".join(res)}</resources><build>{build}</build></model>')
    ctypes = ('<?xml version="1.0" encoding="UTF-8"?>\n'
              '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
              '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
              '<Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>'
              '</Types>')
    rels = ('<?xml version="1.0" encoding="UTF-8"?>\n'
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Target="/3D/3dmodel.model" Id="rel0" '
            'Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/></Relationships>')
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", ctypes)
        z.writestr("_rels/.rels", rels)
        z.writestr("3D/3dmodel.model", model)

def write_stl(path, objects, placements):
    with open(path, "w") as f:
        f.write("solid plate\n")
        for (name, tris), (x, y) in zip(objects, placements):
            for t in tris:
                f.write(" facet normal 0 0 0\n  outer loop\n")
                for v in t:
                    f.write(f"   vertex {v[0]+x:.4f} {v[1]+y:.4f} {v[2]:.4f}\n")
                f.write("  endloop\n endfacet\n")
        f.write("endsolid plate\n")

os.makedirs("creality", exist_ok=True)
summary = []
for plate, parts, infill in PLATES:
    objects, sizes = [], []
    for stl, n in parts:
        tris, size = normalized(read_stl(f"stl/{stl}.stl"))
        # по-дългата страна по X, за да се редят по-плътно
        if size[1] > size[0]:
            tris, size = normalized(rotate90(tris))
        for k in range(n):
            objects.append((f"{stl}_{k+1}", tris))
            sizes.append(size)
    # проба с двете ориентации на всички части - избира тази, която се събира
    placed = None
    for rot in (False, True):
        objs, szs = objects, sizes
        if rot:
            objs, szs = [], []
            for (nm, t), s in zip(objects, sizes):
                t2, s2 = normalized(rotate90(t)); objs.append((nm, t2)); szs.append(s2)
        items = list(zip(range(len(objs)), szs))
        x, y, row_h, pl, ok = MARGIN, MARGIN, 0, [], True
        for i, s in items:
            if x + s[0] > BED - MARGIN:
                x, y, row_h = MARGIN, y + row_h + GAP, 0
            if y + s[1] > BED - MARGIN:
                ok = False; break
            pl.append((x, y)); x += s[0] + GAP; row_h = max(row_h, s[1])
        if ok:
            # центриране на групата на масата
            w = max(p[0] + s[0] for p, s in zip(pl, szs)); d = max(p[1] + s[1] for p, s in zip(pl, szs))
            dx, dy = (BED - w - MARGIN) / 2, (BED - d - MARGIN) / 2
            placed = (objs, [(p[0] + dx - MARGIN/2, p[1] + dy - MARGIN/2) for p in pl], szs)
            break
    if placed is None:
        raise SystemExit(f"{plate}: частите не се събират на {BED}x{BED}")
    objs, pl, szs = placed
    write_3mf(f"creality/{plate}.3mf", objs, pl)
    write_stl(f"creality/{plate}.stl", objs, pl)
    h = max(s[2] for s in szs)
    summary.append((plate, len(objs), infill, h))
    print(f"{plate}: {len(objs)} части, височина до {h:.0f} мм, запълване {infill}")
