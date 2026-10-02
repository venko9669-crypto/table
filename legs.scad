// Краката на масата: 4 тръби Ø15 x 650, кръстосани в центъра на масата
// по средата на височината.
//
// Всеки крак тръгва от стъпало (обувчица) на пода, минава през центъра на
// масата и стига под противоположния ъгъл на плота. В центъра 4-те крака
// минават през вложка (hub) с 4 наклонени отвора.
//
// Четири оси не могат да минат през една и съща точка, без тръбите да се
// пресекат. Затова всеки крак е изместен встрани от центъра с hub_e, а
// посоката на изместването се върти в една и съща посока (като стол с
// усукани крака). Така краката се разминават в центъра, а горе и долу
// все още гледат към ъглите (отклонението е само hub_e).
//
//   Отгоре:                  Отстрани (по диагонала):
//
//    ъгъл .         . ъгъл          плот ____________
//           \     /                      \        /
//            [hub]                         \    /
//           /     \                         [hub]   <- средата на височината
//    стъпало        стъпало                /    \
//                                   стъпало      стъпало
//
// Части:
//   shoe    - обувчица на долния край на крака (плоско дъно, наклонено гнездо)
//   hub     - вложката в центъра с 4 отвора
//   mount   - скоба, надяната на лайсна от плота, със сляпо наклонено гнездо
//             за горния край на крака. mount_r е огледалната (по 2 от всяка).
//
// Горните краища не стигат до звената на ръба (половин крак е 325 мм, а ръбът
// е на 350 мм от центъра), затова скобите хващат лайсни на ~170-220 мм от центъра.
// hub_e и mount_drop са избрани така, че продължението на оста на всеки крак
// да минава точно през оста на лайсна - тогава кракът не усуква лайсната.
// Печат: shoe - на плоското дъно; hub - на плоската долна страна;
//        mount - на устието на гнездото (то е плоско). Без подпори.

$fn = 96;

/* [Маса] */
table_w = 700;    // плот по X
table_d = 500;    // плот по Y
table_h = 415;    // височина до горната повърхност на плота (= горната страна на лайсните)
slat_d  = 10;     // лайсни на плота
slat_pitch = 20;
n_slats = 26;

/* [Крака] */
leg_d   = 15;     // диаметър на крака
leg_len = 650;    // дължина на крака
tol     = 0.4;    // хлабина на отворите за крака

/* [Обувчица] */
shoe_z     = 12;  // височина на оста на крака в края му над пода
shoe_sock  = 30;  // дълбочина на гнездото по оста
shoe_wall  = 4;   // стена около крака
shoe_pad_d = 44;  // диаметър на стъпката
shoe_pad_h = 3;   // дебелина на стъпката
pad_recess = 0.8; // вдлъбнатина отдолу за гумено/филцово лепенче (0 = без)
shoe_toe   = 70;  // колко навън (към ъгъла) продължава стъпката - разширява базата

/* [Скоба на лайсна] */
mount_drop = 20;  // колко под оста на лайсната е горният край на оста на крака
                  // (20 мм дава ос на крака, която минава точно през оста на лайсната)
mount_sock = 30;  // дълбочина на гнездото за крака
mount_floor = 3;  // дъно на гнездото
mount_wall = 4;   // стена около крака
collar_len = 30;  // дължина на яката по лайсната
collar_wall = 3.5; // стена около лайсната
tol_slat   = 0.3; // хлабина на яката (плъзга се по лайсната до мястото си)
screw_d    = 2.8; // отвор за винт M3 (самонарезен), фиксира скобата на лайсната
nb_clr     = 1.5; // хлабина до съседните лайсни

/* [Вложка в центъра] */
hub_e = slat_pitch / cos(atan2(table_d/2, table_w/2));  // изместване (разминаване); така горните краища падат под лайсни
hub_r = 50;       // радиус на сферата, от която е изрязана вложката
hub_h = 44;       // височина на вложката (плоска отгоре и отдолу)

/* [Изглед] */
part = "assembly"; // [shoe, hub, mount, mount_r, assembly]

// --- изчислени ---
slat_z = table_h - slat_d/2;                        // ос на лайсните
leg_top_z = slat_z - mount_drop;
alpha = asin((leg_top_z - shoe_z) / leg_len);       // ъгъл на крака спрямо пода
cross_z = (leg_top_z + shoe_z) / 2;                 // височина на кръстосването
phi0 = atan2(table_d/2, table_w/2);                 // посока към ъгъла
phis = [phi0, 180 - phi0, 180 + phi0, -phi0];       // посоки към 4-те ъгъла (горния край)
half_h = leg_len/2 * cos(alpha);                    // хоризонтално от центъра до края

// Посока на крака (нагоре към ъгъла)
function leg_dir(phi) = [cos(alpha)*cos(phi), cos(alpha)*sin(phi), sin(alpha)];
// Горният край на крака с ъгъл phi
function leg_top(phi) = [-hub_e*sin(phi) + half_h*cos(phi), hub_e*cos(phi) + half_h*sin(phi), leg_top_z];
// Продължението на оста на крака пресича височината на лайсните тук.
// Скобата се поставя там, така силата от крака минава през оста на лайсната
// и не я усуква.
k_top = mount_drop / sin(alpha);
function leg_at_slat(phi) = leg_top(phi) + k_top * leg_dir(phi);
// Най-близката лайсна (лайсните са центрирани около y = 0)
y0_slat = -(n_slats - 1) * slat_pitch / 2;
function slat_y(y) = y0_slat + round((y - y0_slat) / slat_pitch) * slat_pitch;
S0 = leg_at_slat(phis[0]);
S1 = leg_at_slat(phis[1]);
mount_dy = S0[1] - slat_y(S0[1]);                   // остатъчно разминаване с лайсната
assert(abs((S1[1] - slat_y(S1[1])) - mount_dy) < 0.01,
       "Краката не падат симетрично под лайсни - провери hub_e");
assert(abs(mount_dy) < 2, "Оста на крака не попада на лайсна - нагласи mount_drop");

echo(str("Скоби: на лайсни y = ", slat_y(S0[1]), " и ", slat_y(S1[1]),
         ", на x = ±", S0[0], " и ±", -S1[0], " мм от центъра; dy = ", mount_dy));
echo(str("Ъгъл на краката: ", alpha, "°; кръстосване на ", cross_z, " мм; ",
         "краищата на ", half_h, " мм от центъра (хоризонтално)"));

// Ориентира оста z по крака, който отива нагоре към ъгъл phi
module along_leg(phi) rotate([0, 90 - alpha, phi]) children();

// Ос на крак i: минава през (hub_e * нормалата, cross_z) с посока нагоре към ъгъла
module leg_frame(phi) {
    translate([-hub_e * sin(phi), hub_e * cos(phi), cross_z]) along_leg(phi) children();
}

// ---------------- Обувчица ----------------
// Локално: оста на крака се издига към +x, долният ѝ край е в (0, 0, shoe_z).
module shoe() {
    sock_d = leg_d + tol;
    body_d = sock_d + 2*shoe_wall;
    // къде оста на крака стига пода - там центрираме стъпката
    x_floor = -shoe_z / tan(alpha);
    difference() {
        intersection() {
            hull() {
                translate([x_floor + shoe_pad_d/4, 0, 0]) cylinder(d = shoe_pad_d, h = shoe_pad_h);
                // "пета" навън - разширява опорната база
                translate([-shoe_toe, 0, 0]) cylinder(d = shoe_pad_d * 0.7, h = shoe_pad_h);
                translate([0, 0, shoe_z]) rotate([0, 90 - alpha, 0])
                    translate([0, 0, -body_d/2]) cylinder(d = body_d, h = shoe_sock + body_d/2);
            }
            translate([-200, -200, 0]) cube([400, 400, 200]);   // плоско дъно
        }
        // гнездо за крака
        translate([0, 0, shoe_z]) rotate([0, 90 - alpha, 0]) cylinder(d = sock_d, h = shoe_sock + 50);
        // вдлъбнатина за лепенче
        if (pad_recess > 0) for (x = [x_floor + shoe_pad_d/4, -shoe_toe])
            translate([x, 0, -1]) cylinder(d = shoe_pad_d * 0.7 - 8, h = pad_recess + 1);
    }
}

// ---------------- Вложка ----------------
// Локално: центърът на кръстосването е в (0, 0, 0).
module hub() {
    difference() {
        intersection() {
            sphere(r = hub_r);
            cube([3*hub_r, 3*hub_r, hub_h], center = true);
        }
        for (phi = phis) translate([0, 0, -cross_z]) leg_frame(phi)
            cylinder(d = leg_d + tol, h = 3*hub_r, center = true);
    }
}

// ---------------- Скоба на лайсна ----------------
// Локално: оста на лайсната е по X през (0, 0, 0). Кракът отива нагоре към
// ъгъл phis[0]; продължението на оста му минава през (0, mount_dy, 0), а
// горният му край е mount_drop под лайсната.
mount_T = [0, mount_dy, 0] - k_top * leg_dir(phis[0]);
module mount() {
    D = leg_dir(phis[0]);
    T = mount_T;
    mouth = T - mount_sock * D;                       // устието на гнездото
    boss_d = leg_d + tol + 2*mount_wall;
    collar_d = slat_d + tol_slat + 2*collar_wall;
    difference() {
        intersection() {
            hull() {
                rotate([0, 90, 0]) cylinder(d = collar_d, h = collar_len, center = true);
                translate(mouth) along_leg(phis[0]) cylinder(d = boss_d, h = mount_sock + mount_floor);
            }
            // отрязано плоско на устието (на това се печата)
            translate(mouth) along_leg(phis[0]) translate([-100, -100, 0]) cube(200);
        }
        // лайсната
        rotate([0, 90, 0]) cylinder(d = slat_d + tol_slat, h = collar_len + 2, center = true);
        // гнездото за крака
        translate(mouth) along_leg(phis[0]) translate([0, 0, -1]) cylinder(d = leg_d + tol, h = mount_sock + 1);
        // място за съседните лайсни
        for (y = [-slat_pitch, slat_pitch]) translate([0, y, 0]) rotate([0, 90, 0])
            cylinder(d = slat_d + 2*nb_clr, h = 300, center = true);
        // винт M3 отстрани в яката
        for (x = [-collar_len/2 + 6, collar_len/2 - 6]) translate([x, 0, 0])
            rotate([90, 0, 0]) cylinder(d = screw_d, h = collar_d);
    }
}
module mount_r() mirror([1, 0, 0]) mount();

// ---------------- Сглобка ----------------
module assembly() {
    // плотът (само контур)
    color("tan", 0.25) translate([-table_w/2, -table_d/2, table_h - slat_d]) cube([table_w, table_d, slat_d]);
    for (phi = phis) {
        // крак
        color("silver") leg_frame(phi) cylinder(d = leg_d, h = leg_len, center = true);
        // обувчица: долният край е от противоположната страна на ъгъла
        color("yellowgreen")
            translate([-hub_e * sin(phi), hub_e * cos(phi), 0])
            rotate([0, 0, phi]) translate([-half_h, 0, 0]) shoe();
    }
    color("orange") translate([0, 0, cross_z]) hub();
    // лайсните, на които стоят скобите, и скобите
    for (k = [0 : 3]) {
        phi = phis[k];
        Tk = leg_at_slat(phi);
        rot = (k >= 2) ? 180 : 0;
        color("silver") translate([0, slat_y(Tk[1]), slat_z]) rotate([0, 90, 0])
            cylinder(d = slat_d, h = table_w, center = true);
        color("royalblue") translate([Tk[0], slat_y(Tk[1]), slat_z])
            if (k == 0 || k == 2) rotate([0, 0, rot]) mount(); else rotate([0, 0, rot]) mount_r();
    }
}

if      (part == "shoe") shoe();
else if (part == "hub")  translate([0, 0, hub_h/2]) hub();
else if (part == "mount" || part == "mount_r") {
    // устието на гнездото на масата на принтера
    mouth = mount_T - mount_sock * leg_dir(phis[0]);
    mirror([part == "mount_r" ? 1 : 0, 0, 0])
        rotate([0, -(90 - alpha), 0]) rotate([0, 0, -phis[0]]) translate(-mouth) mount();
}
else if (part != "none") assembly();
