// Звено "осмица" - свързва краищата на тънките тръби като верига на колело.
// Тръбите са нитовете, плочките са звената.
//
// Както при веригата на колело, има два вида плочки в три слоя по оста на тръбата:
//   outer (A, B) - външни плочки, стягат тръбата (пресова сглобка), не се въртят спрямо нея
//   inner        - вътрешна плочка между A и B, върти се свободно около тръбата (шарнир)
//
//   слой A (края, с капаче):  [0===1]       [2===3]       [4===5]
//   слой inner:                     [1===2]       [3===4]
//   слой B:                   [0===1]       [2===3]       [4===5]
//   тръби:                     0     1     2     3     4     5
//
// Всяка тръба минава през A + inner + B. Inner е заклещена между A и B,
// затова не може да се изхлузи. По двата ръба на плота - огледално.
// Печат: плоско на масата, без подпори.

$fn = 64;

/* [Тръби] */
tube_d = 10;       // диаметър на тънката тръба
pitch  = 20;       // стъпка център-в-център

/* [Звено] */
t          = 4;    // дебелина на една плочка
wall       = 4;    // стена около тръбата
waist      = 10;   // ширина на "талията" между двата отвора
gap        = 1;    // хлабина между съседни звена в един слой
tol_press  = 0.15; // хлабина на отвора при outer (стяга тръбата)
tol_free   = 0.4;  // хлабина на отвора при inner (върти се)
spacer     = 0.4;  // шайбичка около отвора на inner от двете страни
cap        = true; // плочка A със сляп отвор (скрива края на тръбата)
cap_floor  = 1.2;  // дебелина на дъното при cap

/* [Изглед] */
part    = "assembly"; // [outer, outer_cap, inner, assembly]
n_tubes = 6;          // за assembly

lobe_d = min(tube_d + 2*wall, pitch - gap);   // външен диаметър на "ухото"

assert(lobe_d - tube_d >= 3, "Стената е твърде тънка - увеличи pitch или намали tube_d");
assert(waist <= lobe_d, "waist трябва да е <= lobe_d");

// Плосък контур на осмицата (без отвори)
module eight_2d() {
    circle(d = lobe_d);
    translate([pitch, 0]) circle(d = lobe_d);
    translate([0, -waist/2]) square([pitch, waist]);
}

module holes(hole_d, z0, h) {
    for (x = [0, pitch]) translate([x, 0, z0]) cylinder(d = hole_d, h = h);
}

// Външна плочка - стяга тръбата
module outer_link(blind = false) {
    hole_d = tube_d + tol_press;
    difference() {
        linear_extrude(t) eight_2d();
        if (blind) holes(hole_d, cap_floor, t);   // отворът е отдолу нагоре, дъното е навън
        else       holes(hole_d, -1, t + 2);
    }
}

// Вътрешна плочка - върти се, с шайбички от двете страни
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

layer_inner = t + 2*spacer;  // дебелина на inner слоя

module assembly() {
    z_A     = 0;                      // края на тръбата
    z_inner = -layer_inner;
    z_B     = -layer_inner - t;
    tube_end = cap ? z_A + t - cap_floor : z_A + t;

    for (i = [0 : n_tubes - 1])
        color("silver") translate([i*pitch, 0, z_B - 10])
            cylinder(d = tube_d, h = tube_end - z_B + 10);

    for (i = [0 : 2 : n_tubes - 2]) translate([i*pitch, 0, 0]) {
        // A: отворът гледа към плота, дъното навън
        color("orange") translate([0, 0, z_A + t]) mirror([0, 0, 1]) outer_link(blind = cap);
        color("orange") translate([0, 0, z_B]) outer_link();
    }
    for (i = [1 : 2 : n_tubes - 2])
        color("steelblue") translate([i*pitch, 0, z_inner]) inner_link();
}

if      (part == "outer")     outer_link();
else if (part == "outer_cap") outer_link(blind = true);
else if (part == "inner")     inner_link();
else assembly();
