// Помощни модули за по-добър FDM печат: заоблени ъгли и фаски.
//
// Препоръки от ръководствата за FDM:
//  - фаска ~45° по ръбовете, които лягат на масата на принтера - премахва
//    "слонския крак" и не изисква подпори;
//  - заоблени вътрешни ъгли - по-малка концентрация на напрежение;
//  - фаска на входа на отворите - тръбата влиза по-лесно, а първият слой
//    не стеснява отвора.

// Заобля 2D контур: ro - външни ъгли, ri - вътрешни (вдлъбнати) ъгли.
module round2d(ro = 1, ri = 1) {
    offset(r = ro) offset(delta = -ro)
        offset(r = -ri) offset(delta = ri)
            children();
}

// linear_extrude с фаски 45° отдолу (cb) и отгоре (ct).
// Фаската е на стъпала по step мм - на принтер с такъв слой е точно като права.
module cext(h, cb = 0, ct = 0, step = 0.2) {
    nb = round(cb / step);
    nt = round(ct / step);
    if (nb > 0) for (i = [0 : nb - 1])
        translate([0, 0, i * step]) linear_extrude(step + 0.01)
            offset(delta = -(nb - i) * step) children();
    translate([0, 0, nb * step]) linear_extrude(h - (nb + nt) * step) children();
    if (nt > 0) for (i = [0 : nt - 1])
        translate([0, 0, h - (nt - i) * step - 0.01]) linear_extrude(step + 0.01)
            offset(delta = -(i + 1) * step) children();
}

// Конус за фаска на входа на отвор с диаметър d (по оста +z от z = 0).
module hole_chamfer(d, c = 0.5) {
    translate([0, 0, -0.01]) cylinder(d1 = d + 2*c + 0.02, d2 = d, h = c + 0.01);
}
