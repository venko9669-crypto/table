// Звено "осмица" - свързва краищата на тънките тръби като верига на колело.
// Тръбите са нитовете, плочките са звената.
//
// Както при веригата на колело, има два вида плочки в три слоя по оста на тръбата:
//   lock  (A) - крайна плочка: сляпо гнездо за тръбата + "ботуш" отдолу с канал
//               за заключващата тръба (под тръбите, от вътрешната страна)
//   outer (B) - вътрешна стягаща плочка (пресова сглобка), не се върти спрямо тръбата
//   inner     - плочка между A и B, върти се свободно около тръбата (шарнир)
//
//   Изглед отстрани (ос на тръбите е към теб), плотът е отгоре:
//
//   тръби:             0     1     2     3     4     5
//   звена:            [0===1][1===2][2===3][3===4][4===5]
//   ботуши на A:      [=====]       [=====]       [=====]
//   заключваща тръба: ====================================================
//
// Всяка тръба минава през A + inner + B. Inner е заклещена между A и B.
// След като масата се разпъне, през каналите на всички A плочки се пъха
// една тръба по дължина - тя изправя веригата в права линия и плотът не се огъва.
// По двата ръба на плота - огледално.
// Ботушът стои под звената B и inner (откъм вътрешността на масата), така че
// отвън се вижда само капачето на A, а заключващата тръба е под плота.
// Плотът се сгъва нагоре (горната повърхност навътре); надолу го спират ботушите.
// Печат: плоско, без подпори (lock - с външната страна към масата на принтера).

$fn = 64;

/* [Тръби] */
tube_d = 10;       // диаметър на тънката тръба
pitch  = 20;       // стъпка център-в-център

/* [Звено] */
t          = 4;    // дебелина на една плочка
wall       = 4;    // стена около тръбата
waist      = 10;   // ширина на "талията" между двата отвора
gap        = 1;    // хлабина между съседни звена в един слой
tol_press  = 0.15; // хлабина на отвора при outer/lock (стяга тръбата)
tol_free   = 0.4;  // хлабина на отвора при inner (върти се)
spacer     = 0.4;  // шайбичка около отвора на inner от двете страни

/* [Заключване] */
lock_d     = 10;   // диаметър на заключващата тръба
tol_lock   = 0.5;  // хлабина на канала (тръбата трябва да се плъзга ~500 мм)
sock       = 5;    // дълбочина на слепото гнездо за тръбата в lock плочката
cap_t      = 1.6;  // капаче над гнездото (външната страна)
clr        = 0.5;  // хлабина между ботуша и ушите на inner/B
ch_wall    = 1.6;  // стена над и под канала

/* [Изглед] */
part    = "assembly"; // [lock, outer, inner, assembly]
n_tubes = 6;          // за assembly

lobe_d = min(tube_d + 2*wall, pitch - gap);   // външен диаметър на "ухото"
ch_d   = lock_d + tol_lock;                   // диаметър на канала
layer_inner = t + 2*spacer;                   // дебелина на inner слоя
t_A    = sock + cap_t;                        // дебелина на плочката A
boot_in = layer_inner + t;                    // колко навътре стига ботушът (под inner и B)
y_top  = -lobe_d/2 - clr;                     // горен ръб на ботуша (под ушите)
ch_cy  = y_top - ch_wall - ch_d/2;            // ос на канала (височина)
ch_cz  = (t_A - boot_in)/2;                   // ос на канала (по оста на тръбите)
y_bot  = ch_cy - ch_d/2 - ch_wall;            // долен ръб на ботуша

assert(lobe_d - tube_d >= 3, "Стената е твърде тънка - увеличи pitch или намали tube_d");
assert(waist <= lobe_d, "waist трябва да е <= lobe_d");
assert(t_A + boot_in - ch_d >= 3, "Каналът е по-широк от ботуша - увеличи t или sock");

// Плосък контур на осмицата (без отвори)
module eight_2d() {
    circle(d = lobe_d);
    translate([pitch, 0]) circle(d = lobe_d);
    translate([0, -waist/2]) square([pitch, waist]);
}

// Плосък контур "стадион" - за lock плочката, за да побере канала
module stadium_2d() {
    hull() { circle(d = lobe_d); translate([pitch, 0]) circle(d = lobe_d); }
}

// Капка с отрязан връх - печата се без подпори, върхът сочи надолу (-y)
module teardrop_2d(d) {
    r = d/2;
    intersection() {
        hull() {
            circle(d = d);
            polygon([[-r*cos(45), -r*sin(45)], [0, -r*sqrt(2)], [r*cos(45), -r*sin(45)]]);
        }
        square(d, center = true);
    }
}

module holes(hole_d, z0, h) {
    for (x = [0, pitch]) translate([x, 0, z0]) cylinder(d = hole_d, h = h);
}

// Вътрешна стягаща плочка (B)
module outer_link() {
    difference() {
        linear_extrude(t) eight_2d();
        holes(tube_d + tol_press, -1, t + 2);
    }
}

// Крайна плочка (A): z=0 е към плота, гнездата отдолу (към -z), капачето навън (+z).
// Ботушът виси под ушите (-y) и стига навътре под inner и B.
module lock_link() {
    L = pitch + lobe_d;
    difference() {
        union() {
            linear_extrude(t_A) stadium_2d();
            // ботуш под inner и B
            translate([-lobe_d/2, y_bot, -boot_in]) cube([L, y_top - y_bot, boot_in + t_A]);
            // връзка ботуш - плочка
            translate([-lobe_d/2, y_bot, 0]) cube([L, -y_bot, t_A]);
        }
        holes(tube_d + tol_press, -1, sock + 1);
        // канал по дължина на веригата; профил x->Y, y->Z (върхът към плота), екструзия -> X
        translate([-lobe_d/2 - 1, ch_cy, ch_cz]) rotate([90, 0, 90])
            linear_extrude(L + 2) teardrop_2d(ch_d);
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
    z_A     = 0;   // вътрешната страна на A, тръбите идват от -z
    z_inner = -layer_inner;
    z_B     = -layer_inner - t;
    tube_end = z_A + sock;

    for (i = [0 : n_tubes - 1])
        color("silver") translate([i*pitch, 0, z_B - 10])
            cylinder(d = tube_d, h = tube_end - z_B + 10);

    for (i = [0 : 2 : n_tubes - 2]) translate([i*pitch, 0, 0]) {
        color("orange") translate([0, 0, z_A]) lock_link();
        color("orange") translate([0, 0, z_B]) outer_link();
    }
    for (i = [1 : 2 : n_tubes - 2])
        color("steelblue") translate([i*pitch, 0, z_inner]) inner_link();

    // заключващата тръба
    color("dimgray") translate([-lobe_d/2 - 15, ch_cy, z_A + ch_cz])
        rotate([0, 90, 0]) cylinder(d = lock_d, h = (n_tubes - 1)*pitch + lobe_d + 30);
}

if      (part == "lock")  translate([0, 0, t_A]) mirror([0, 0, 1]) lock_link(); // капачето на масата
else if (part == "outer") outer_link();
else if (part == "inner") inner_link();
else assembly();
