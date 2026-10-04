// Масата, сгъната на квадрат: горната повърхност е навътре, 4 стави са
// сгънати на 90°. Краката, вложката, обувчиците, скобите и заключващите
// тръби са прибрани вътре. Само за изглед - не се печата.

use <chain_link.scad>
use <legs.scad>

$fn = 48;

/* [Изглед] */
show_contents = true;   // краката и останалото вътре
cutaway = false;        // разрязано наполовина, за да се види вътре
check = -1;             // 0..3 - проверка за удар в ъгъл №check (празно = няма удар)

// стойности от chain_link.scad / legs.scad
pitch = 20; n = 26; tube_d = 10; slat_len = 700;
sock = 6;                     // лайсната влиза 6 мм в плочка A
z_inner = -6.1 + (6.1 - 5.4)/2;   // мястото на синята плочка в процепа

// Квадрат 7 x 7 стъпки (140 x 140 мм по осите на лайсните): 28 позиции,
// 26 лайсни + 3 стъпки шев между крайните звена (51 мм с вилките + 9 мм луфт).
side = 7;
half = side * pitch / 2;
corners_slat = [2, 9, 16, 23];        // лайсните, на които се сгъва на 90°
function pos(j) = (j + 26) % 28;      // лайсна 0 е на позиция 26 (шевът е на лявата страна)
function Pp(p) =
    p <= side     ? [-half + p * pitch, -half] :
    p <= 2*side   ? [ half, -half + (p - side) * pitch] :
    p <= 3*side   ? [ half - (p - 2*side) * pitch,  half] :
                    [-half,  half - (p - 3*side) * pitch];
function P(j) = Pp(pos(j));
function ang(j) = let(d = P(j + 1) - P(j)) atan2(d[1], d[0]);

// Звено, което започва от лайсна j; локално +y сочи навътре в кутията
module at_link(j) translate([P(j)[0], P(j)[1], 0]) rotate([0, 0, ang(j)]) children();

module link(i) at_link(i)
    if (i % 2 == 1)      color("steelblue") translate([0, 0, z_inner]) inner_link();
    else if (i == 0)     color("yellowgreen") end_link();
    else if (i == n - 2) color("yellowgreen") end_link_r();
    else                 color("orange") outer_link();

module chain() for (i = [0 : n - 2]) link(i);

module slat(j) color("silver") translate([P(j)[0], P(j)[1], sock - slat_len]) cylinder(d = tube_d, h = slat_len);

module folded_table() {
    chain();
    translate([0, 0, 2*sock - slat_len]) mirror([0, 0, 1]) chain();
    for (j = [0 : n - 1]) slat(j);
}

// Всичко, което се прибира вътре
module contents() {
    z0 = sock - slat_len + 15;
    c = half - 5 - 1 - 7.5 - 1.5;     // крака в 4-те вътрешни ъгъла
    for (sx = [-1, 1], sy = [-1, 1]) color("lightgray")
        translate([sx * c, sy * c, z0]) cylinder(d = 15, h = 650);
    // вложката в единия край
    color("darkorange") translate([0, 0, z0 + 25]) hub();
    // заключващите тръби по долната стена
    for (x = [-22, 22]) color("dimgray") translate([x, -c - 2, z0 + 75]) cylinder(d = 10, h = 547);
    // 4 обувчици една след друга
    for (k = [0 : 3]) color("yellowgreen")
        translate([20, 4, z0 + 60 + k * 125]) rotate([0, -90, 0]) translate([75, 0, 0]) shoe();
    // 4 скоби в другия край
    for (k = [0 : 3]) color("royalblue")
        translate([(k % 2) * 34 - 17, floor(k / 2) * 34 - 17, z0 + 560]) mount_print();
}

module scene() {
    folded_table();
    if (show_contents) contents();
}

// Проверка: всичко около ъгъла k (звената и лайсните от двете страни) не се пресича
module corner_check(k) {
    c = corners_slat[k];
    intersection() {
        union() { link(c - 2); link(c - 1); slat(c - 1); slat(c - 2); }
        union() { link(c); link(c + 1); slat(c + 1); slat(c + 2); }
    }
}

if (check == -2) echo(); else if (check >= 0) corner_check(check);
else rotate([0, 90, 0]) translate([0, 0, slat_len/2 - sock])
    if (cutaway) difference() { scene(); translate([-500, 0, -1000]) cube([1000, 500, 2000]); }
    else scene();
