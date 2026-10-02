// Звено "осмица" - свързва краищата на тънките тръби като верига на колело.
// Тръбите са нитовете, плочките са звената.
//
// Две части:
//   outer (жълта) - едно цяло: външна плочка A (сляпо гнездо, капаче) + вътрешна
//                   плочка B + "ботуш" отдолу, който ги свързва и носи полуотворения
//                   канал за заключващата тръба. Стяга тръбите (пресова сглобка).
//   inner (синя)  - влиза в процепа между A и B, върти се свободно около тръбата.
//   end   (зелена)- крайно звено в началото и в края на веригата: като жълтото, но
//                   с удължение - вилка с пин. В началото пинът минава през дупка
//                   в заключващата тръба и тя се върти около него като рамо.
//                   В края втори пин минава през другата дупка и я заключва.
//                   end_r е огледалното за другия край.
//
//   Изглед отстрани (ос на тръбите е към теб), плотът е отгоре:
//
//   тръби:                0     1     2     3     4     5
//   звена:               [0===1][1===2][2===3][3===4][4===5]
//   ботуши:          [end=======]   [outer]     [=======end_r]
//   заключваща тръба:   o=============================o
//                       ^ пин (ос, рамото се върти)   ^ пин (заключва)
//
//   Отгоре (плотът е нагоре по екрана):  рамото се завърта около първия пин
//   и щраква последователно в каналите, като ципа; накрая вторият пин.
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
// Печат: outer и end - изправени на тесния край (каналът и процепът са
//        вертикални), inner - плоско. Без подпори.

include <print_helpers.scad>

$fn = 64;

/* [Тръби] */
tube_d = 10;       // диаметър на тънката тръба
pitch  = 20;       // стъпка център-в-център

/* [Звено] */
t          = 5;    // дебелина на една плочка (B и inner)
wall       = 4.5;  // стена около тръбата (ухо Ø19 при стъпка 20)
waist      = 12;   // ширина на "талията" между двата отвора
gap        = 1;    // хлабина между съседни звена в един слой
tol_press  = 0.15; // хлабина на отворите при outer (стяга тръбата)
tol_free   = 0.4;  // хлабина на отвора при inner (върти се)
spacer     = 0.4;  // шайбичка около отвора на inner (от горната страна)
slot_clr   = 0.3;  // хлабина на inner в процепа на outer (общо)

/* [Заключване] */
lock_d     = 10;   // диаметър на заключващата тръба
tol_lock   = 0.3;  // хлабина на канала (диаметър)
snap_open  = 8.6;  // ширина на отвора на канала (< lock_d, за да щраква)
lead_in    = 1;    // скосяване на входа на канала
sock       = 6;    // дълбочина на слепото гнездо за тръбата в плочка A
cap_t      = 2;    // капаче над гнездото (външната страна)
clr        = 0.5;  // хлабина между ботуша и ушите на inner/B
ch_wall    = 2.4;  // стена над канала (носи натиска от заключващата тръба)
lip_wall   = 2;    // стена под канала (устната, която щраква)

/* [Крайно звено (рамо)] */
ext        = 16;   // удължение на ботуша навън от веригата (вилката)
pin_d      = 4;    // пин (стоманен щифт или болт M4); същата дупка в заключващата тръба
tol_pin    = 0.2;  // хлабина на отвора за пина
stub       = 6;    // колко стърчи заключващата тръба зад пина
fork_extra = 3;    // удебеляване на долната стена на вилката

/* [Печат] */
edge_r     = 2;    // заобляне на ъглите
cham_out   = 1;    // фаска на външната страна (капачето)
cham_in    = 0.6;  // фаска на вътрешната страна и по ръбовете
hole_cham  = 0.5;  // фаска на входа на отворите

/* [Изглед] */
part    = "assembly"; // [outer, inner, end, end_r, assembly]
n_tubes = 6;          // за assembly
arm_angle = 0;        // за assembly: ъгъл на отвореното рамо (0 = заключено)

lobe_d = min(tube_d + 2*wall, pitch - gap);   // външен диаметър на "ухото"
ch_d   = lock_d + tol_lock;                   // диаметър на канала
layer_inner = t + 2*spacer;                   // място за inner слоя (плочка + шайбичка + луфт)
t_A    = sock + cap_t;                        // дебелина на плочката A
slot   = layer_inner + slot_clr;              // процеп между A и B
boot_in = slot + t;                           // колко навътре стига outer (до края на B)
z_B    = -boot_in;                            // B: от z_B до z_B + t
y_top  = -lobe_d/2 - clr;                     // горен ръб на ботуша (под ушите)
ch_cy  = y_top - ch_wall - ch_d/2;            // ос на канала (височина)
ch_o   = sqrt((ch_d/2)^2 - (snap_open/2)^2);  // колко навътре в ботуша е оста на канала
ch_cz  = -boot_in + ch_o;                     // ос на канала (по оста на тръбите)
y_bot  = ch_cy - ch_d/2 - lip_wall;           // долен ръб на ботуша

assert(lobe_d - tube_d >= 3, "Стената е твърде тънка - увеличи pitch или намали tube_d");
assert(waist <= lobe_d, "waist трябва да е <= lobe_d");
echo(str("Заключваща тръба при 26 тръби на плота: дупки през ", 25*pitch - 2*x_pin,
          " мм (център-център), обща дължина ", 25*pitch - 2*x_pin + 2*stub, " мм"));
assert(snap_open < lock_d, "snap_open трябва да е по-малко от lock_d, иначе няма щракване");
x_pin  = -lobe_d/2 - ext/2;                   // ос на пина (в началния край)
R_stub = sqrt(stub^2 + (ch_d/2)^2) + 0.5;     // радиус, който описва опашката на рамото
assert(stub <= ext/2 - 1, "stub е твърде дълъг за ext");
assert(ch_cz + R_stub + 1.6 <= t_A, "Опашката на рамото пробива задната стена - намали stub");
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

// Контур (по XY) на жълтото/крайното звено: горе ушите, долу ботушът.
// ext_l > 0 добавя удължение навън за вилката на крайното звено.
module link_profile(ext_l = 0) {
    L = pitch + lobe_d;
    round2d(edge_r, edge_r) {
        stadium_2d();
        translate([-lobe_d/2, y_bot]) square([L, -y_bot]);
        if (ext_l > 0) {
            yb = y_bot - fork_extra;
            translate([-lobe_d/2 - ext_l, yb]) square([ext_l + 1, lobe_d/2 - yb]);
        }
    }
}

// Общото тяло на жълтото и крайното звено.
// z=0 е вътрешната страна на A, тръбите идват от -z.
// A: z 0..t_A (сляпо гнездо + капаче навън); процеп за inner; B: z_B..z_B+t.
module link_body(ext_l = 0) {
    L = pitch + lobe_d;
    difference() {
        translate([0, 0, z_B]) cext(boot_in + t_A, cb = cham_in, ct = cham_out) link_profile(ext_l);
        // процеп за синята плочка (над ботуша)
        translate([-lobe_d/2 - (ext_l > 0 ? 0 : 1), y_top, -slot]) cube([L + 2, 50, slot]);
        // гнезда в A (с фаска на входа откъм процепа)
        for (x = [0, pitch]) translate([x, 0, 0]) {
            translate([0, 0, -1]) cylinder(d = tube_d + tol_press, h = sock + 1);
            hole_chamfer(tube_d + tol_press, hole_cham);
        }
        // отвори в B (с фаски от двете страни)
        for (x = [0, pitch]) translate([x, 0, z_B]) {
            translate([0, 0, -1]) cylinder(d = tube_d + tol_press, h = t + 2);
            hole_chamfer(tube_d + tol_press, hole_cham);
            translate([0, 0, t]) mirror([0, 0, 1]) hole_chamfer(tube_d + tol_press, hole_cham);
        }
        // полуотворен канал по дължина на веригата, отворът гледа към плота (-z)
        translate([-lobe_d/2 - ext_l - 1, ch_cy, ch_cz]) rotate([0, 90, 0])
            cylinder(d = ch_d, h = L + ext_l + 2);
        // фаски на канала в двата края (по тях звеното ляга на принтера)
        for (x = [-lobe_d/2, pitch + lobe_d/2]) if (!(ext_l > 0 && x < 0))
            translate([x, ch_cy, ch_cz]) rotate([0, x < 0 ? 90 : -90, 0]) hole_chamfer(ch_d, hole_cham);
        // скосен вход, за да се щраква по-лесно
        translate([-lobe_d/2 - ext_l - 1, ch_cy, -boot_in]) rotate([90, 0, 90])
            linear_extrude(L + ext_l + 2) polygon([
                [-snap_open/2 - lead_in, -0.01], [snap_open/2 + lead_in, -0.01],
                [snap_open/2, lead_in], [-snap_open/2, lead_in]]);
    }
}

// Жълтото звено
module outer_link() link_body(0);

// Крайно звено: жълтото + удължение навън (-x) с вилка за пина.
// В удължението каналът е отворен навътре изцяло, за да може рамото да се завърта.
module end_link() {
    L0 = -lobe_d/2;                 // края на обикновеното звено
    yb = y_bot - fork_extra;
    difference() {
        link_body(ext);
        // процеп за рамото в удължението: лентата на канала, отворена към -z
        translate([L0 - ext - 1, ch_cy - ch_d/2, z_B - 1])
            cube([ext + 1.01, ch_d, ch_cz - z_B + 1]);
        // място за опашката на рамото зад пина
        translate([x_pin, ch_cy - ch_d/2, ch_cz]) rotate([-90, 0, 0])
            cylinder(r = R_stub, h = ch_d);
        // отвор за пина, по височина (y), с фаски
        translate([x_pin, yb - 1, ch_cz]) rotate([-90, 0, 0])
            cylinder(d = pin_d + tol_pin, h = lobe_d/2 - yb + 2);
        for (y = [yb, lobe_d/2]) translate([x_pin, y, ch_cz])
            rotate([y < 0 ? -90 : 90, 0, 0]) hole_chamfer(pin_d + tol_pin, 0.4);
    }
}

// Огледалното крайно звено за другия край на веригата
module end_link_r() translate([pitch, 0, 0]) mirror([1, 0, 0]) end_link();

// Въртяща се плочка: плоска отдолу (ляга цялата на принтера), шайбички отгоре.
// Вътрешните ъгли между ушите и талията са заоблени.
module inner_link() {
    hole_d = tube_d + tol_free;
    difference() {
        union() {
            cext(t, cb = 0.4, ct = 0.4) round2d(0.01, 3) eight_2d();
            for (x = [0, pitch]) translate([x, 0, t - 0.01])
                cylinder(d = hole_d + 3, h = spacer + 0.01);
        }
        for (x = [0, pitch]) translate([x, 0, 0]) {
            translate([0, 0, -1]) cylinder(d = hole_d, h = t + spacer + 2);
            hole_chamfer(hole_d, 0.4);
            translate([0, 0, t + spacer]) mirror([0, 0, 1]) hole_chamfer(hole_d, 0.4);
        }
    }
}

module assembly() {
    z_inner = -slot + (slot - t - spacer)/2;
    tube_end = sock;

    for (i = [0 : n_tubes - 1])
        color("silver") translate([i*pitch, 0, z_B - 10])
            cylinder(d = tube_d, h = tube_end - z_B + 10);

    last = n_tubes - 2;  // началото на последното жълто/крайно звено
    for (i = [0 : 2 : last]) translate([i*pitch, 0, 0])
        if (i == 0)         color("yellowgreen") end_link();
        else if (i == last) color("yellowgreen") end_link_r();
        else                color("orange") outer_link();
    for (i = [1 : 2 : n_tubes - 2])
        color("steelblue") translate([i*pitch, 0, z_inner]) inner_link();

    // заключващата тръба с двете дупки за пиновете
    x_pin_r = (n_tubes - 1)*pitch - x_pin;
    color("dimgray") translate([x_pin, 0, ch_cz]) rotate([0, arm_angle, 0])
        translate([-x_pin, 0, -ch_cz]) difference() {
        translate([x_pin - stub, ch_cy, ch_cz]) rotate([0, 90, 0])
            cylinder(d = lock_d, h = x_pin_r - x_pin + 2*stub);
        for (x = [x_pin, x_pin_r]) translate([x, ch_cy - lock_d, ch_cz]) rotate([-90, 0, 0])
            cylinder(d = pin_d, h = 2*lock_d);
    }
    // пиновете
    for (x = arm_angle == 0 ? [x_pin, x_pin_r] : [x_pin]) color("red") translate([x, y_bot - fork_extra - 2, ch_cz])
        rotate([-90, 0, 0]) cylinder(d = pin_d, h = lobe_d/2 - y_bot + fork_extra + 4);
}

// outer се печата изправен на тесния край (x = -lobe_d/2 на масата на принтера)
if      (part == "outer") translate([0, 0, lobe_d/2]) rotate([0, -90, 0]) outer_link();
else if (part == "end")   translate([0, 0, lobe_d/2 + ext]) rotate([0, -90, 0]) end_link();
else if (part == "end_r") mirror([1, 0, 0]) translate([0, 0, lobe_d/2 + ext]) rotate([0, -90, 0]) end_link();
else if (part == "inner") inner_link();
else if (part != "none") assembly();
