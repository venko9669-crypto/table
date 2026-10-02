// Звено "осмица" - свързва краищата на тънките тръби като верига на колело.
// Тръбите са нитовете, плочките са звената.
//
// Две части:
//   outer (жълта) - едно цяло: външна плочка A (сляпо гнездо, капаче) + вътрешна
//                   плочка B + "ботуш" отдолу, който ги свързва и носи полуотворения
//                   канал за заключващата тръба. Стяга тръбите (пресова сглобка).
//   inner (синя)  - влиза в процепа между A и B, върти се свободно около тръбата.
//
//   Изглед отстрани (ос на тръбите е към теб), плотът е отгоре:
//
//   тръби:             0     1     2     3     4     5
//   звена:            [0===1][1===2][2===3][3===4][4===5]
//   ботуши на outer:  [=====]       [=====]       [=====]
//   заключваща тръба: ====================================================
//
// Сглобяване: синята плочка се пъха в процепа на две съседни жълти, после
// тръбата се вкарва отвътре през B и синята до дъното на гнездото в A.
// След като масата се разпъне, заключващата тръба се щраква странично (откъм
// вътрешността на масата) в каналите на всички outer звена - тя изправя
// веригата в права линия и плотът не се огъва.
//
//   Сечение на outer (гледа се по дължината на веригата):
//
//     навън               навътре (към плота)
//       |‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾|
//       | ///// |inner| B |  <- тръба на плота
//       |‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
//       |            __
//       |           (     <- заключваща тръба, щраква отдясно
//       |____________‾‾      (отворът е по-тесен от тръбата)
//
// По двата ръба на плота - огледално.
// Плотът се сгъва нагоре (горната повърхност навътре); надолу го спират ботушите.
// Печат: outer - изправен на тесния край (каналът и процепът са вертикални),
//        inner - плоско. Без подпори.

$fn = 64;

/* [Тръби] */
tube_d = 10;       // диаметър на тънката тръба
pitch  = 20;       // стъпка център-в-център

/* [Звено] */
t          = 4;    // дебелина на една плочка
wall       = 4;    // стена около тръбата
waist      = 10;   // ширина на "талията" между двата отвора
gap        = 1;    // хлабина между съседни звена в един слой
tol_press  = 0.15; // хлабина на отворите при outer (стяга тръбата)
tol_free   = 0.4;  // хлабина на отвора при inner (върти се)
spacer     = 0.4;  // шайбичка около отвора на inner от двете страни
slot_clr   = 0.3;  // хлабина на inner в процепа на outer (общо)

/* [Заключване] */
lock_d     = 10;   // диаметър на заключващата тръба
tol_lock   = 0.3;  // хлабина на канала (диаметър)
snap_open  = 8.6;  // ширина на отвора на канала (< lock_d, за да щраква)
lead_in    = 1;    // скосяване на входа на канала
sock       = 5;    // дълбочина на слепото гнездо за тръбата в плочка A
cap_t      = 1.6;  // капаче над гнездото (външната страна)
clr        = 0.5;  // хлабина между ботуша и ушите на inner/B
ch_wall    = 1.6;  // стена над и под канала

/* [Изглед] */
part    = "assembly"; // [outer, inner, assembly]
n_tubes = 6;          // за assembly

lobe_d = min(tube_d + 2*wall, pitch - gap);   // външен диаметър на "ухото"
ch_d   = lock_d + tol_lock;                   // диаметър на канала
layer_inner = t + 2*spacer;                   // дебелина на inner слоя
t_A    = sock + cap_t;                        // дебелина на плочката A
slot   = layer_inner + slot_clr;              // процеп между A и B
boot_in = slot + t;                           // колко навътре стига outer (до края на B)
z_B    = -boot_in;                            // B: от z_B до z_B + t
y_top  = -lobe_d/2 - clr;                     // горен ръб на ботуша (под ушите)
ch_cy  = y_top - ch_wall - ch_d/2;            // ос на канала (височина)
ch_o   = sqrt((ch_d/2)^2 - (snap_open/2)^2);  // колко навътре в ботуша е оста на канала
ch_cz  = -boot_in + ch_o;                     // ос на канала (по оста на тръбите)
y_bot  = ch_cy - ch_d/2 - ch_wall;            // долен ръб на ботуша

assert(lobe_d - tube_d >= 3, "Стената е твърде тънка - увеличи pitch или намали tube_d");
assert(waist <= lobe_d, "waist трябва да е <= lobe_d");
assert(snap_open < lock_d, "snap_open трябва да е по-малко от lock_d, иначе няма щракване");
assert(ch_cz + ch_d/2 + 1.6 <= t_A, "Ботушът е твърде тесен за канала - увеличи t или sock");

// Плосък контур на осмицата (без отвори)
module eight_2d() {
    circle(d = lobe_d);
    translate([pitch, 0]) circle(d = lobe_d);
    translate([0, -waist/2]) square([pitch, waist]);
}

// Плосък контур "стадион" - за плочките на outer
module stadium_2d() {
    hull() { circle(d = lobe_d); translate([pitch, 0]) circle(d = lobe_d); }
}

module holes(hole_d, z0, h) {
    for (x = [0, pitch]) translate([x, 0, z0]) cylinder(d = hole_d, h = h);
}

// Жълтото звено (едно цяло): z=0 е вътрешната страна на A, тръбите идват от -z.
// A: z 0..t_A (сляпо гнездо + капаче навън); процеп за inner; B: z_B..z_B+t.
// Ботушът виси под ушите (-y) и свързва A и B.
module outer_link() {
    L = pitch + lobe_d;
    difference() {
        union() {
            linear_extrude(t_A) stadium_2d();                         // A
            translate([0, 0, z_B]) linear_extrude(t) stadium_2d();    // B
            // ботуш под процепа
            translate([-lobe_d/2, y_bot, z_B]) cube([L, y_top - y_bot, boot_in + t_A]);
            // връзка ботуш - A и ботуш - B (под ушите, извън процепа)
            translate([-lobe_d/2, y_bot, 0])   cube([L, -y_bot, t_A]);
            translate([-lobe_d/2, y_bot, z_B]) cube([L, -y_bot, t]);
        }
        holes(tube_d + tol_press, -1, sock + 1);           // гнезда в A
        holes(tube_d + tol_press, z_B - 1, t + 2);         // отвори в B
        // полуотворен канал по дължина на веригата, отворът гледа към плота (-z)
        translate([-lobe_d/2 - 1, ch_cy, ch_cz]) rotate([0, 90, 0])
            cylinder(d = ch_d, h = L + 2);
        // скосен вход, за да се щраква по-лесно
        translate([-lobe_d/2 - 1, ch_cy, -boot_in]) rotate([90, 0, 90])
            linear_extrude(L + 2) polygon([
                [-snap_open/2 - lead_in, -0.01], [snap_open/2 + lead_in, -0.01],
                [snap_open/2, lead_in], [-snap_open/2, lead_in]]);
    }
}

// Въртяща се плочка, с шайбички от двете страни
module inner_link() {
    hole_d = tube_d + tol_free;
    difference() {
        union() {
            translate([0, 0, spacer]) linear_extrude(t) eight_2d();
            for (x = [0, pitch]) translate([x, 0, 0])
                cylinder(d = hole_d + 3, h = t + 2*spacer);
        }
        holes(hole_d, -1, t + 2*spacer + 2);
    }
}

module assembly() {
    z_inner = -slot + slot_clr/2;
    tube_end = sock;

    for (i = [0 : n_tubes - 1])
        color("silver") translate([i*pitch, 0, z_B - 10])
            cylinder(d = tube_d, h = tube_end - z_B + 10);

    for (i = [0 : 2 : n_tubes - 2])
        color("orange") translate([i*pitch, 0, 0]) outer_link();
    for (i = [1 : 2 : n_tubes - 2])
        color("steelblue") translate([i*pitch, 0, z_inner]) inner_link();

    // заключващата тръба
    color("dimgray") translate([-lobe_d/2 - 15, ch_cy, ch_cz])
        rotate([0, 90, 0]) cylinder(d = lock_d, h = (n_tubes - 1)*pitch + lobe_d + 30);
}

// outer се печата изправен на тесния край (x = -lobe_d/2 на масата на принтера)
if      (part == "outer") translate([0, 0, lobe_d/2]) rotate([0, -90, 0]) outer_link();
else if (part == "inner") inner_link();
else assembly();
