// Масата навита: плотът е навит с горната повърхност навътре, а краката,
// вложката, обувчиците и заключващите тръби са прибрани вътре в рулото.
// Само за изглед - не се печата.

use <chain_link.scad>
use <legs.scad>

$fn = 48;

/* [Изглед] */
show_contents = true;   // краката и останалото вътре
cutaway = false;        // разрязано наполовина, за да се види вътре

// стойности от chain_link.scad / legs.scad
pitch = 20; n = 26; tube_d = 10; slat_len = 700;
sock = 6;                     // лайсната влиза 6 мм в плочка A
z_inner = -6.1 + (6.1 - 5.4)/2;   // мястото на синята плочка в процепа
seam = 52;                    // крайните звена с вилките се срещат на шева
alpha = 35.56; phi0 = atan2(250, 350);

// Радиус на рулото: 25 стави по 20 мм + шев 52 мм обикалят точно 360°
function f(R) = (n - 1) * 2 * asin(pitch/2 / R) + 2 * asin(seam/2 / R) - 360;
function solve(lo, hi, k) = k == 0 ? (lo + hi)/2 :
    let(m = (lo + hi)/2) f(m) > 0 ? solve(m, hi, k - 1) : solve(lo, m, k - 1);
R = solve(60, 200, 50);
dth = 2 * asin(pitch/2 / R);
echo(str("Рулото: Ø", 2*R, " мм по осите на лайсните"));

// Лайсна j лежи на окръжността; локално +y сочи към центъра на рулото
function th(j) = (j - (n - 1)/2) * dth;            // симетрично около дъното
function P(j) = [R * sin(th(j)), -R * cos(th(j))];

// Рамка на звеното, което започва от лайсна j (оста x към лайсна j+1)
module at_link(j) translate([P(j)[0], P(j)[1], 0]) rotate([0, 0, th(j) + dth/2]) children();
// Рамка на самата лайсна j (за скобите)
module at_slat(j) translate([P(j)[0], P(j)[1], 0]) rotate([0, 0, th(j)]) children();

// Едната верига (z = 0 е вътрешната страна на плочка A)
module chain() {
    for (i = [0 : 2 : n - 2]) at_link(i)
        if (i == 0)          color("yellowgreen") end_link();
        else if (i == n - 2) color("yellowgreen") end_link_r();
        else                 color("orange") outer_link();
    for (i = [1 : 2 : n - 3]) at_link(i)
        color("steelblue") translate([0, 0, z_inner]) inner_link();
}

// Краката: оста X (по лайсната) -> z на рулото, Y (напречно) -> x, Z (нагоре) -> y
module legs_to_roll() multmatrix([[0, 1, 0, 0], [0, 0, 1, 0], [1, 0, 0, 0], [0, 0, 0, 1]]) children();

module rolled_table() {
    z_mid = sock - slat_len/2;          // средата на лайсните
    // двете вериги
    chain();
    translate([0, 0, 2*sock - slat_len]) mirror([0, 0, 1]) chain();
    // лайсните
    for (j = [0 : n - 1]) color("silver")
        translate([P(j)[0], P(j)[1], sock - slat_len]) cylinder(d = tube_d, h = slat_len);
    // скобите на краката остават на лайсни №4, 6, 21, 23 (отвън на рулото)
    for (m = [[22, 223.6, 0, false], [3, -223.6, 180, false],
              [20, -252.2, 0, true], [5, 252.2, 180, true]])
        at_slat(m[0]) translate([0, 0, z_mid]) legs_to_roll()
            translate([m[1], 0, 0]) rotate([0, 0, m[2]])
                color("royalblue") if (m[3]) mount_r(); else mount();
}

module contents() {
    z0 = sock - slat_len;
    // вложката
    color("darkorange") translate([0, 25, z0 + 40]) hub();
    // 4 крака
    for (p = [[-25, -58], [0, -62], [25, -58], [50, -44]])
        color("lightgray") translate([p[0], p[1], z0 + 25]) cylinder(d = 15, h = 650);
    // 2 заключващи тръби
    for (p = [[-50, -44], [-62, -24]])
        color("dimgray") translate([p[0], p[1], z0 + 90]) cylinder(d = 10, h = 547);
    // 4 обувчици, легнали по дължина една след друга
    for (k = [0 : 3]) color("yellowgreen")
        translate([18, 2, z0 + 150 + k * 135]) rotate([0, -90, 0]) translate([75, 0, 0]) shoe();
}

module scene() {
    rolled_table();
    if (show_contents) contents();
}

// рулото легнало, с центъра в началото на координатите
rotate([0, 90, 0]) translate([0, 0, slat_len/2 - sock])
    if (cutaway) difference() { scene(); translate([-500, 0, -1000]) cube([1000, 500, 2000]); }
    else scene();
