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
//   shoe - обувчица на долния край на крака (плоско дъно, наклонено гнездо)
//   hub  - вложката в центъра с 4 отвора
// Печат: shoe - на плоското дъно; hub - на плоската долна страна. Без подпори.

$fn = 96;

/* [Маса] */
table_w = 700;    // плот по X
table_d = 500;    // плот по Y
table_h = 415;    // височина до горната повърхност на плота
top_drop = 20;    // колко под горната повърхност свършва оста на крака (уточнява се с горната част)

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

/* [Вложка в центъра] */
hub_e = 24;       // изместване на всеки крак от центъра (разминаване)
hub_r = 50;       // радиус на сферата, от която е изрязана вложката
hub_h = 44;       // височина на вложката (плоска отгоре и отдолу)

/* [Изглед] */
part = "assembly"; // [shoe, hub, assembly]

// --- изчислени ---
leg_top_z = table_h - top_drop;
alpha = asin((leg_top_z - shoe_z) / leg_len);       // ъгъл на крака спрямо пода
cross_z = (leg_top_z + shoe_z) / 2;                 // височина на кръстосването
phi0 = atan2(table_d/2, table_w/2);                 // посока към ъгъла
phis = [phi0, 180 - phi0, 180 + phi0, -phi0];       // посоки към 4-те ъгъла (горния край)
half_h = leg_len/2 * cos(alpha);                    // хоризонтално от центъра до края

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
                translate([0, 0, shoe_z]) rotate([0, 90 - alpha, 0])
                    translate([0, 0, -body_d/2]) cylinder(d = body_d, h = shoe_sock + body_d/2);
            }
            translate([-200, -200, 0]) cube([400, 400, 200]);   // плоско дъно
        }
        // гнездо за крака
        translate([0, 0, shoe_z]) rotate([0, 90 - alpha, 0]) cylinder(d = sock_d, h = shoe_sock + 50);
        // вдлъбнатина за лепенче
        if (pad_recess > 0)
            translate([x_floor + shoe_pad_d/4, 0, -1]) cylinder(d = shoe_pad_d - 8, h = pad_recess + 1);
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

// ---------------- Сглобка ----------------
module assembly() {
    // плотът (само контур)
    color("tan", 0.3) translate([-table_w/2, -table_d/2, table_h - 12]) cube([table_w, table_d, 12]);
    for (phi = phis) {
        // крак
        color("silver") leg_frame(phi) cylinder(d = leg_d, h = leg_len, center = true);
        // обувчица: долният край е от противоположната страна на ъгъла
        color("yellowgreen")
            translate([-hub_e * sin(phi), hub_e * cos(phi), 0])
            rotate([0, 0, phi]) translate([-half_h, 0, 0]) shoe();
    }
    color("orange") translate([0, 0, cross_z]) hub();
}

if      (part == "shoe") shoe();
else if (part == "hub")  translate([0, 0, hub_h/2]) hub();
else assembly();
