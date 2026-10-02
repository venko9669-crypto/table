#!/usr/bin/env python3
"""Проверка на размерите на масата: дали всичко пасва, здравина и навиване.

Стойностите са копирани от chain_link.scad и legs.scad - ако ги смениш там,
смени ги и тук. Пуска се с: python3 check_fit.py
"""
import math

# ---------------- материали (на склад) ----------------
STOCK_THIN = (10, 700, 29)    # Ø, дължина, брой
STOCK_THICK = (15, 650, 4)

# ---------------- плот / верига (chain_link.scad) ----------------
W, D_TOP, H = 700, 500, 415     # плот X, Y, височина
slat_d, pitch, n_slats = 10, 20, 26
lobe_d = 19                     # ухо на звената
t, spacer, slot_clr = 5, 0.4, 0.3
sock, cap_t = 6, 2
y_top, y_bot = -10, -24.7       # ботуш спрямо оста на лайсната (отрицателно = под плота)
ext, stub, pin_d, fork_extra = 16, 6, 4, 3
lock_d = 10

# ---------------- крака (legs.scad) ----------------
leg_d, leg_len = 15, 650
shoe_z = 12
shoe_toe, shoe_pad_d = 70, 44
mount_drop = 20
hub_r, hub_h = 50, 44
mount_reach = 55                # най-далечната точка на скобата от оста на лайсната

# ---------------- приблизителни маси ----------------
# Тръбите: приемам алуминий с 1 мм стена (тънки) и 1.5 мм (дебели).
ALU = 2.7e-3                    # g/mm^3
def tube_mass(d, wall, length):
    return math.pi / 4 * (d**2 - (d - 2 * wall)**2) * length * ALU / 1000  # kg

ok_all = True
def check(cond, text):
    global ok_all
    ok_all &= cond
    print(("  OK   " if cond else "  !!   ") + text)

print("=" * 70)
print("1. ТРЪБИ - дължини и бройки")
print("=" * 70)
slat_len = W
x_pin = -lobe_d / 2 - ext / 2
lock_holes = (n_slats - 1) * pitch - 2 * x_pin
lock_len = lock_holes + 2 * stub
thin_needed = [("лайсни", slat_len, n_slats), ("заключващи тръби", lock_len, 2)]
thick_needed = [("крака", leg_len, 4)]
n_thin = sum(n for _, _, n in thin_needed)
for name, L, n in thin_needed:
    check(L <= STOCK_THIN[1], f"{name}: {n} x Ø{STOCK_THIN[0]} x {L:.0f} мм (от {STOCK_THIN[1]} мм, остатък {STOCK_THIN[1] - L:.0f})")
check(n_thin <= STOCK_THIN[2], f"тънки: трябват {n_thin}, имаш {STOCK_THIN[2]} (резерва {STOCK_THIN[2] - n_thin})")
for name, L, n in thick_needed:
    check(L <= STOCK_THICK[1] and n <= STOCK_THICK[2], f"{name}: {n} x Ø{STOCK_THICK[0]} x {L} мм (от {STOCK_THICK[1]} мм)")
print(f"       заключващи тръби: дупки Ø{pin_d} на {lock_holes:.0f} мм център-център, на {stub} мм от краищата")

print()
print("=" * 70)
print("2. ВИСОЧИНИ И КРАКА")
print("=" * 70)
slat_z = H - slat_d / 2
leg_top_z = slat_z - mount_drop
alpha = math.asin((leg_top_z - shoe_z) / leg_len)
cross_z = (leg_top_z + shoe_z) / 2
phi0 = math.atan2(D_TOP / 2, W / 2)
hub_e = pitch / math.cos(phi0)
half_h = leg_len / 2 * math.cos(alpha)
print(f"       ъгъл на краката {math.degrees(alpha):.1f}°, кръстосване на {cross_z:.0f} мм (средата е {H/2:.0f})")
print(f"       изместване във вложката hub_e = {hub_e:.1f} мм")

def leg(phi):
    u = (math.cos(phi), math.sin(phi))
    n = (-math.sin(phi), math.cos(phi))
    d = (math.cos(alpha) * u[0], math.cos(alpha) * u[1], math.sin(alpha))
    p0 = (hub_e * n[0], hub_e * n[1], cross_z)
    return p0, d

phis = [phi0, math.pi - phi0, math.pi + phi0, -phi0]
legs = [leg(p) for p in phis]

def pt(p0, d, s):
    return tuple(p0[i] + s * d[i] for i in range(3))

def seg_dist(a, b, n=2000):
    best = 1e9
    for i in range(n + 1):
        s = -leg_len / 2 + leg_len * i / n
        q = pt(*a, s)
        p0, d = b
        tt = max(-leg_len / 2, min(leg_len / 2, sum((q[k] - p0[k]) * d[k] for k in range(3))))
        r = pt(p0, d, tt)
        best = min(best, math.dist(q, r))
    return best

dmin = min(seg_dist(legs[i], legs[j]) for i in range(4) for j in range(i + 1, 4))
check(dmin - leg_d >= 2, f"краката се разминават във вложката: най-малко {dmin - leg_d:.1f} мм между тях")

k_top = mount_drop / math.sin(alpha)
for i, (p0, d) in enumerate(legs):
    top = pt(p0, d, leg_len / 2)
    at_slat = pt(p0, d, leg_len / 2 + k_top)
    y_s = round((at_slat[1] + (n_slats - 1) * pitch / 2) / pitch) * pitch - (n_slats - 1) * pitch / 2
    idx = round((y_s + (n_slats - 1) * pitch / 2) / pitch) + 1
    check(abs(at_slat[1] - y_s) < 1, f"крак {i+1}: оста минава през лайсна №{idx} (y={y_s:.0f}) при x={at_slat[0]:+.0f}, разминаване {at_slat[1]-y_s:+.2f} мм")
    check(top[2] + leg_d / 2 < slat_z - slat_d / 2, f"крак {i+1}: горният край не опира в лайсните ({slat_z - slat_d/2 - top[2] - leg_d/2:.1f} мм хлабина)")

def foot(p0, d):
    f = pt(p0, d, -leg_len / 2)
    u = (d[0] / math.cos(alpha), d[1] / math.cos(alpha))
    reach = shoe_toe + shoe_pad_d * 0.7 / 2      # петата на обувчицата навън
    return (f[0] - reach * u[0], f[1] - reach * u[1])
feet = [foot(p0, d) for p0, d in legs]
xs = sorted(abs(f[0]) for f in feet)
ys = sorted(abs(f[1]) for f in feet)
print(f"       опорни точки (петите на обувчиците): |x| = {xs[0]:.0f}..{xs[-1]:.0f}, |y| = {ys[0]:.0f}..{ys[-1]:.0f} мм от центъра")

print()
print("=" * 70)
print("3. СТАБИЛНОСТ")
print("=" * 70)
m_slats = n_slats * tube_mass(10, 1, slat_len)
m_lock = 2 * tube_mass(10, 1, lock_len)
m_legs = 4 * tube_mass(15, 1.5, leg_len)
m_print = 0.75                  # всички печатни части, приблизително
m_total = m_slats + m_lock + m_legs + m_print
print(f"       маса (алуминиеви тръби + PETG): ~{m_total:.1f} кг")
# опорният многоъгълник е четириъгълникът на стъпалата; най-близкият ръб по y и по x
sup_y = min(abs(f[1]) for f in feet)   # консервативно
sup_x = min(abs(f[0]) for f in feet)
over_y = D_TOP / 2 - sup_y
over_x = W / 2 - sup_x
for name, sup, over in [("дългата страна", sup_y, over_y), ("късата страна", sup_x, over_x)]:
    p_tip = m_total * sup / over
    print(f"       натиск по ръба на {name}: стъпалата са на {sup:.0f} мм, ръбът стърчи {over:.0f} мм")
    print(f"         -> масата се накланя при ~{p_tip:.1f} кг натиск върху самия ръб (без товар отгоре)")
    p_tip10 = (m_total + 10) * sup / over
    print(f"         -> с 10 кг товар в средата: при ~{p_tip10:.1f} кг")

print()
print("=" * 70)
print("4. ЗДРАВИНА (приблизително, алуминий 6063 ~145 МПа, PETG ~45 МПа)")
print("=" * 70)
I = math.pi / 64 * (10**4 - 8**4)
Wb = I / 5
P_alu = 4 * 145 * Wb / slat_len / 9.81
P_st = 4 * 235 * Wb / slat_len / 9.81
print(f"       една лайсна Ø10x1, отвор 700 мм, точков товар в средата:")
print(f"         алуминий: до ~{P_alu:.1f} кг, стомана: до ~{P_st:.1f} кг (лайсните не си делят точков товар)")
check(10 / n_slats < P_alu, f"10 кг разпределени по целия плот: {10/n_slats:.2f} кг на лайсна")
chain_load = (m_slats + 10) / 2 * 9.81       # на всеки край на плота, Н
cant = W / 2 - 252                            # най-дълго конзолно рамо от скоба до веригата (по-късото е 98)
cant = max(W / 2 - 223.6, W / 2 - 252.2)
M = chain_load / 2 * cant
check(M / Wb < 145, f"лайсна със скоба, конзола {cant:.0f} мм до веригата: {M/Wb:.0f} МПа (алуминий 145)")
# звено: натискът в стената над канала
M_chain = chain_load / 500 * 340**2 / 8      # Н*мм, приблизително
F_wall = M_chain / (abs(y_top) + 7.5) / 4     # двойка сили, поделена на ~4 звена
A_wall = 2.4 * (pitch + lobe_d)
check(F_wall / A_wall < 45 / 3, f"стена над канала в звеното: ~{F_wall:.0f} Н -> {F_wall/A_wall:.1f} МПа (PETG 45, х3 запас)")

print()
print("=" * 70)
print("5. НАВИВАНЕ (горната повърхност навътре)")
print("=" * 70)
seam = 2 * (lobe_d / 2 + ext) + 1        # крайните звена с вилките се срещат на шева
C = (n_slats - 1) * pitch + seam
D_axes = C / math.pi
print(f"       по осите на лайсните: Ø{D_axes:.0f} мм ({360/n_slats:.1f}° на всяка става)")
clear_end = D_axes - lobe_d - 1
clear_mid = D_axes - slat_d
print(f"       свободно вътре: Ø{clear_end:.0f} мм при звената, Ø{clear_mid:.0f} мм в средата")
outer_end = D_axes + 2 * (abs(y_bot) + fork_extra)
outer_mount = D_axes + 2 * mount_reach
print(f"       отвън: Ø~{outer_end:.0f} мм при ботушите, до ~{outer_mount + 0:.0f} мм при скобите на краката")
print(f"       дължина: ~{slat_len + 2*cap_t:.0f} мм")
check(2 * hub_r < clear_end, f"вложката Ø{2*hub_r} влиза (свободно Ø{clear_end:.0f})")
check(leg_len < slat_len, f"краката {leg_len} мм влизат по дължина ({slat_len} мм)")
check(lock_len < slat_len, f"заключващите тръби {lock_len:.0f} мм влизат по дължина")
# напречно сечение: вложката + 4 крака + 2 тръби + обувчици
R = clear_end / 2
ring = R - hub_r                         # ако вложката е опряна в стената
check(2 * ring >= leg_d + 1, f"до вложката остава полумесец {2*ring:.0f} мм за краката (Ø{leg_d})")

print()
print("=" * 70)
print("6. ТОВАРОНОСИМОСТ (разпределен товар по плота, до провлачване)")
print("=" * 70)
# Q - общ разпределен товар [Н]. За всяко място: колко Н момент/сила на 1 Н от Q.
def capacity(sig_thin, sig_thick):
    Wt = math.pi / 32 * (10**4 - 8**4) / 10         # Ø10x1, мм^3
    Wk = math.pi / 32 * (15**4 - 12**4) / 15        # Ø15x1.5
    res = {}
    # а) лайсна, свободно опряна на двете вериги, 1/26 от товара
    res["лайсна (отвор 700)"] = sig_thin * Wt / (slat_len / 8 / n_slats)
    # б) лайсна със скоба: конзола от скобата до веригата.
    #    Всяка верига носи Q/2; опорите ѝ са лайсните на y=150 и y=-190.
    a_, b_ = 150, -190
    ra = 0.5 * (0 - b_) / (a_ - b_)
    rb = 0.5 * (a_ - 0) / (a_ - b_)
    m_per_q = max(ra * (W / 2 - 252.2), rb * (W / 2 - 223.6))
    res["лайсна със скоба (конзола)"] = sig_thin * Wt / m_per_q
    # в) заключващата тръба носи огъването на веригата между опорите (340 мм)
    w = 0.5 / D_TOP
    m_rod = w * (a_ - b_)**2 / 8 - w * 80**2 / 2
    res["заключваща тръба"] = sig_thin * Wt / m_rod
    # г) крак: долната половина е конзола от вложката, напречната сила от пода
    m_leg = 0.25 * math.cos(alpha) * leg_len / 2
    res["крак (огъване при вложката)"] = sig_thick * Wk / m_leg
    return res
for name, st, sk in [("алуминий 6063 (145 МПа)", 145, 145), ("стомана S235 (235 МПа)", 235, 235)]:
    res = capacity(st, sk)
    print(f"       {name}:")
    for k, v in sorted(res.items(), key=lambda kv: kv[1]):
        print(f"         {k:30s} ~{v/9.81:5.0f} кг")
    worst = min(res.values()) / 9.81
    print(f"         -> най-слабото място: ~{worst:.0f} кг; с коефициент на сигурност 2: ~{worst/2:.0f} кг")
print("       точков товар върху една лайсна в средата - виж т.4")

print()
print("ВСИЧКО Е НАРЕД" if ok_all else "ИМА ПРОБЛЕМИ (виж !!)")
