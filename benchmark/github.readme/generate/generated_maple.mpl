with(Groebner):
with(PolynomialIdeals):


J := PolynomialIdeal({z1 + z2 + z3 + z4 + z5 + z6 + z7, z1*z2 + z1*z7 + z2*z3 + z3*z4 + z4*z5 + z5*z6 + z6*z7, z1*z2*z3 + z1*z2*z7 + z1*z6*z7 + z2*z3*z4 + z3*z4*z5 + z4*z5*z6 + z5*z6*z7, z1*z2*z3*z4 + z1*z2*z3*z7 + z1*z2*z6*z7 + z1*z5*z6*z7 + z2*z3*z4*z5 + z3*z4*z5*z6 + z4*z5*z6*z7, z1*z2*z3*z4*z5 + z1*z2*z3*z4*z7 + z1*z2*z3*z6*z7 + z1*z2*z5*z6*z7 + z1*z4*z5*z6*z7 + z2*z3*z4*z5*z6 + z3*z4*z5*z6*z7, z1*z2*z3*z4*z5*z6 + z1*z2*z3*z4*z5*z7 + z1*z2*z3*z4*z6*z7 + z1*z2*z3*z5*z6*z7 + z1*z2*z4*z5*z6*z7 + z1*z3*z4*z5*z6*z7 + z2*z3*z4*z5*z6*z7, z1*z2*z3*z4*z5*z6*z7 + 2147483646}, charactesistic=2147483647):
print("Running cylic7");
st := time[real]():
Groebner[Basis](J, tdeg(z1, z2, z3, z4, z5, z6, z7), method=direct):
print("cylic7: ", time[real]() - st);

J := PolynomialIdeal({z1 + z2 + z3 + z4 + z5 + z6 + z7 + z8, z1*z2 + z1*z8 + z2*z3 + z3*z4 + z4*z5 + z5*z6 + z6*z7 + z7*z8, z1*z2*z3 + z1*z2*z8 + z1*z7*z8 + z2*z3*z4 + z3*z4*z5 + z4*z5*z6 + z5*z6*z7 + z6*z7*z8, z1*z2*z3*z4 + z1*z2*z3*z8 + z1*z2*z7*z8 + z1*z6*z7*z8 + z2*z3*z4*z5 + z3*z4*z5*z6 + z4*z5*z6*z7 + z5*z6*z7*z8, z1*z2*z3*z4*z5 + z1*z2*z3*z4*z8 + z1*z2*z3*z7*z8 + z1*z2*z6*z7*z8 + z1*z5*z6*z7*z8 + z2*z3*z4*z5*z6 + z3*z4*z5*z6*z7 + z4*z5*z6*z7*z8, z1*z2*z3*z4*z5*z6 + z1*z2*z3*z4*z5*z8 + z1*z2*z3*z4*z7*z8 + z1*z2*z3*z6*z7*z8 + z1*z2*z5*z6*z7*z8 + z1*z4*z5*z6*z7*z8 + z2*z3*z4*z5*z6*z7 + z3*z4*z5*z6*z7*z8, z1*z2*z3*z4*z5*z6*z7 + z1*z2*z3*z4*z5*z6*z8 + z1*z2*z3*z4*z5*z7*z8 + z1*z2*z3*z4*z6*z7*z8 + z1*z2*z3*z5*z6*z7*z8 + z1*z2*z4*z5*z6*z7*z8 + z1*z3*z4*z5*z6*z7*z8 + z2*z3*z4*z5*z6*z7*z8, z1*z2*z3*z4*z5*z6*z7*z8 + 2147483646}, charactesistic=2147483647):
print("Running cylic8");
st := time[real]():
Groebner[Basis](J, tdeg(z1, z2, z3, z4, z5, z6, z7, z8), method=direct):
print("cylic8: ", time[real]() - st);

J := PolynomialIdeal({x0^2 + 2147483646*x0 + 2*x1^2 + 2*x2^2 + 2*x3^2 + 2*x4^2 + 2*x5^2 + 2*x6^2 + 2*x7^2 + 2*x8^2 + 2*x9^2 + 2*x10^2, 2*x0*x1 + 2*x1*x2 + 2147483646*x1 + 2*x2*x3 + 2*x3*x4 + 2*x4*x5 + 2*x5*x6 + 2*x6*x7 + 2*x7*x8 + 2*x8*x9 + 2*x9*x10, 2*x0*x2 + x1^2 + 2*x1*x3 + 2*x2*x4 + 2147483646*x2 + 2*x3*x5 + 2*x4*x6 + 2*x5*x7 + 2*x6*x8 + 2*x7*x9 + 2*x8*x10, 2*x0*x3 + 2*x1*x2 + 2*x1*x4 + 2*x2*x5 + 2*x3*x6 + 2147483646*x3 + 2*x4*x7 + 2*x5*x8 + 2*x6*x9 + 2*x7*x10, 2*x0*x4 + 2*x1*x3 + 2*x1*x5 + x2^2 + 2*x2*x6 + 2*x3*x7 + 2*x4*x8 + 2147483646*x4 + 2*x5*x9 + 2*x6*x10, 2*x0*x5 + 2*x1*x4 + 2*x1*x6 + 2*x2*x3 + 2*x2*x7 + 2*x3*x8 + 2*x4*x9 + 2*x5*x10 + 2147483646*x5, 2*x0*x6 + 2*x1*x5 + 2*x1*x7 + 2*x2*x4 + 2*x2*x8 + x3^2 + 2*x3*x9 + 2*x4*x10 + 2147483646*x6, 2*x0*x7 + 2*x1*x6 + 2*x1*x8 + 2*x2*x5 + 2*x2*x9 + 2*x3*x4 + 2*x3*x10 + 2147483646*x7, 2*x0*x8 + 2*x1*x7 + 2*x1*x9 + 2*x2*x6 + 2*x2*x10 + 2*x3*x5 + x4^2 + 2147483646*x8, 2*x0*x9 + 2*x1*x8 + 2*x1*x10 + 2*x2*x7 + 2*x3*x6 + 2*x4*x5 + 2147483646*x9, x0 + 2*x1 + 2*x2 + 2*x3 + 2*x4 + 2*x5 + 2*x6 + 2*x7 + 2*x8 + 2*x9 + 2*x10 + 2147483646}, charactesistic=2147483647):
print("Running katsura10");
st := time[real]():
Groebner[Basis](J, tdeg(x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10), method=direct):
print("katsura10: ", time[real]() - st);

J := PolynomialIdeal({x0^2 + 2147483646*x0 + 2*x1^2 + 2*x2^2 + 2*x3^2 + 2*x4^2 + 2*x5^2 + 2*x6^2 + 2*x7^2 + 2*x8^2 + 2*x9^2 + 2*x10^2 + 2*x11^2, 2*x0*x1 + 2*x1*x2 + 2147483646*x1 + 2*x2*x3 + 2*x3*x4 + 2*x4*x5 + 2*x5*x6 + 2*x6*x7 + 2*x7*x8 + 2*x8*x9 + 2*x9*x10 + 2*x10*x11, 2*x0*x2 + x1^2 + 2*x1*x3 + 2*x2*x4 + 2147483646*x2 + 2*x3*x5 + 2*x4*x6 + 2*x5*x7 + 2*x6*x8 + 2*x7*x9 + 2*x8*x10 + 2*x9*x11, 2*x0*x3 + 2*x1*x2 + 2*x1*x4 + 2*x2*x5 + 2*x3*x6 + 2147483646*x3 + 2*x4*x7 + 2*x5*x8 + 2*x6*x9 + 2*x7*x10 + 2*x8*x11, 2*x0*x4 + 2*x1*x3 + 2*x1*x5 + x2^2 + 2*x2*x6 + 2*x3*x7 + 2*x4*x8 + 2147483646*x4 + 2*x5*x9 + 2*x6*x10 + 2*x7*x11, 2*x0*x5 + 2*x1*x4 + 2*x1*x6 + 2*x2*x3 + 2*x2*x7 + 2*x3*x8 + 2*x4*x9 + 2*x5*x10 + 2147483646*x5 + 2*x6*x11, 2*x0*x6 + 2*x1*x5 + 2*x1*x7 + 2*x2*x4 + 2*x2*x8 + x3^2 + 2*x3*x9 + 2*x4*x10 + 2*x5*x11 + 2147483646*x6, 2*x0*x7 + 2*x1*x6 + 2*x1*x8 + 2*x2*x5 + 2*x2*x9 + 2*x3*x4 + 2*x3*x10 + 2*x4*x11 + 2147483646*x7, 2*x0*x8 + 2*x1*x7 + 2*x1*x9 + 2*x2*x6 + 2*x2*x10 + 2*x3*x5 + 2*x3*x11 + x4^2 + 2147483646*x8, 2*x0*x9 + 2*x1*x8 + 2*x1*x10 + 2*x2*x7 + 2*x2*x11 + 2*x3*x6 + 2*x4*x5 + 2147483646*x9, 2*x0*x10 + 2*x1*x9 + 2*x1*x11 + 2*x2*x8 + 2*x3*x7 + 2*x4*x6 + x5^2 + 2147483646*x10, x0 + 2*x1 + 2*x2 + 2*x3 + 2*x4 + 2*x5 + 2*x6 + 2*x7 + 2*x8 + 2*x9 + 2*x10 + 2*x11 + 2147483646}, charactesistic=2147483647):
print("Running katsura11");
st := time[real]():
Groebner[Basis](J, tdeg(x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11), method=direct):
print("katsura11: ", time[real]() - st);

J := PolynomialIdeal({x1*x2*x12 + x1*x12 + x2*x3*x12 + x3*x4*x12 + x4*x5*x12 + x5*x6*x12 + x6*x7*x12 + x7*x8*x12 + x8*x9*x12 + x9*x10*x12 + x10*x11*x12 + 2147483646, x1*x3*x12 + x2*x4*x12 + x2*x12 + x3*x5*x12 + x4*x6*x12 + x5*x7*x12 + x6*x8*x12 + x7*x9*x12 + x8*x10*x12 + x9*x11*x12 + 2147483645, x1*x4*x12 + x2*x5*x12 + x3*x6*x12 + x3*x12 + x4*x7*x12 + x5*x8*x12 + x6*x9*x12 + x7*x10*x12 + x8*x11*x12 + 2147483644, x1*x5*x12 + x2*x6*x12 + x3*x7*x12 + x4*x8*x12 + x4*x12 + x5*x9*x12 + x6*x10*x12 + x7*x11*x12 + 2147483643, x1*x6*x12 + x2*x7*x12 + x3*x8*x12 + x4*x9*x12 + x5*x10*x12 + x5*x12 + x6*x11*x12 + 2147483642, x1*x7*x12 + x2*x8*x12 + x3*x9*x12 + x4*x10*x12 + x5*x11*x12 + x6*x12 + 2147483641, x1*x8*x12 + x2*x9*x12 + x3*x10*x12 + x4*x11*x12 + x7*x12 + 2147483640, x1*x9*x12 + x2*x10*x12 + x3*x11*x12 + x8*x12 + 2147483639, x1*x10*x12 + x2*x11*x12 + x9*x12 + 2147483638, x1*x11*x12 + x10*x12 + 2147483637, x11*x12 + 2147483636, x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + x10 + x11 + 1}, charactesistic=2147483647):
print("Running eco12");
st := time[real]():
Groebner[Basis](J, tdeg(x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12), method=direct):
print("eco12: ", time[real]() - st);

J := PolynomialIdeal({x1*x2*x13 + x1*x13 + x2*x3*x13 + x3*x4*x13 + x4*x5*x13 + x5*x6*x13 + x6*x7*x13 + x7*x8*x13 + x8*x9*x13 + x9*x10*x13 + x10*x11*x13 + x11*x12*x13 + 2147483646, x1*x3*x13 + x2*x4*x13 + x2*x13 + x3*x5*x13 + x4*x6*x13 + x5*x7*x13 + x6*x8*x13 + x7*x9*x13 + x8*x10*x13 + x9*x11*x13 + x10*x12*x13 + 2147483645, x1*x4*x13 + x2*x5*x13 + x3*x6*x13 + x3*x13 + x4*x7*x13 + x5*x8*x13 + x6*x9*x13 + x7*x10*x13 + x8*x11*x13 + x9*x12*x13 + 2147483644, x1*x5*x13 + x2*x6*x13 + x3*x7*x13 + x4*x8*x13 + x4*x13 + x5*x9*x13 + x6*x10*x13 + x7*x11*x13 + x8*x12*x13 + 2147483643, x1*x6*x13 + x2*x7*x13 + x3*x8*x13 + x4*x9*x13 + x5*x10*x13 + x5*x13 + x6*x11*x13 + x7*x12*x13 + 2147483642, x1*x7*x13 + x2*x8*x13 + x3*x9*x13 + x4*x10*x13 + x5*x11*x13 + x6*x12*x13 + x6*x13 + 2147483641, x1*x8*x13 + x2*x9*x13 + x3*x10*x13 + x4*x11*x13 + x5*x12*x13 + x7*x13 + 2147483640, x1*x9*x13 + x2*x10*x13 + x3*x11*x13 + x4*x12*x13 + x8*x13 + 2147483639, x1*x10*x13 + x2*x11*x13 + x3*x12*x13 + x9*x13 + 2147483638, x1*x11*x13 + x2*x12*x13 + x10*x13 + 2147483637, x1*x12*x13 + x11*x13 + 2147483636, x12*x13 + 2147483635, x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + x10 + x11 + x12 + 1}, charactesistic=2147483647):
print("Running eco13");
st := time[real]():
Groebner[Basis](J, tdeg(x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13), method=direct):
print("eco13: ", time[real]() - st);

J := PolynomialIdeal({10*x1*x2^2 + 10*x1*x3^2 + 10*x1*x4^2 + 10*x1*x5^2 + 10*x1*x6^2 + 10*x1*x7^2 + 2147483636*x1 + 10, 10*x1^2*x2 + 10*x2*x3^2 + 10*x2*x4^2 + 10*x2*x5^2 + 10*x2*x6^2 + 10*x2*x7^2 + 2147483636*x2 + 10, 10*x1^2*x3 + 10*x2^2*x3 + 10*x3*x4^2 + 10*x3*x5^2 + 10*x3*x6^2 + 10*x3*x7^2 + 2147483636*x3 + 10, 10*x1^2*x4 + 10*x2^2*x4 + 10*x3^2*x4 + 10*x4*x5^2 + 10*x4*x6^2 + 10*x4*x7^2 + 2147483636*x4 + 10, 10*x1^2*x5 + 10*x2^2*x5 + 10*x3^2*x5 + 10*x4^2*x5 + 10*x5*x6^2 + 10*x5*x7^2 + 2147483636*x5 + 10, 10*x1^2*x6 + 10*x2^2*x6 + 10*x3^2*x6 + 10*x4^2*x6 + 10*x5^2*x6 + 10*x6*x7^2 + 2147483636*x6 + 10, 10*x1^2*x7 + 10*x2^2*x7 + 10*x3^2*x7 + 10*x4^2*x7 + 10*x5^2*x7 + 10*x6^2*x7 + 2147483636*x7 + 10}, charactesistic=2147483647):
print("Running noon7");
st := time[real]():
Groebner[Basis](J, tdeg(x1, x2, x3, x4, x5, x6, x7), method=direct):
print("noon7: ", time[real]() - st);

J := PolynomialIdeal({10*x1*x2^2 + 10*x1*x3^2 + 10*x1*x4^2 + 10*x1*x5^2 + 10*x1*x6^2 + 10*x1*x7^2 + 10*x1*x8^2 + 2147483636*x1 + 10, 10*x1^2*x2 + 10*x2*x3^2 + 10*x2*x4^2 + 10*x2*x5^2 + 10*x2*x6^2 + 10*x2*x7^2 + 10*x2*x8^2 + 2147483636*x2 + 10, 10*x1^2*x3 + 10*x2^2*x3 + 10*x3*x4^2 + 10*x3*x5^2 + 10*x3*x6^2 + 10*x3*x7^2 + 10*x3*x8^2 + 2147483636*x3 + 10, 10*x1^2*x4 + 10*x2^2*x4 + 10*x3^2*x4 + 10*x4*x5^2 + 10*x4*x6^2 + 10*x4*x7^2 + 10*x4*x8^2 + 2147483636*x4 + 10, 10*x1^2*x5 + 10*x2^2*x5 + 10*x3^2*x5 + 10*x4^2*x5 + 10*x5*x6^2 + 10*x5*x7^2 + 10*x5*x8^2 + 2147483636*x5 + 10, 10*x1^2*x6 + 10*x2^2*x6 + 10*x3^2*x6 + 10*x4^2*x6 + 10*x5^2*x6 + 10*x6*x7^2 + 10*x6*x8^2 + 2147483636*x6 + 10, 10*x1^2*x7 + 10*x2^2*x7 + 10*x3^2*x7 + 10*x4^2*x7 + 10*x5^2*x7 + 10*x6^2*x7 + 10*x7*x8^2 + 2147483636*x7 + 10, 10*x1^2*x8 + 10*x2^2*x8 + 10*x3^2*x8 + 10*x4^2*x8 + 10*x5^2*x8 + 10*x6^2*x8 + 10*x7^2*x8 + 2147483636*x8 + 10}, charactesistic=2147483647):
print("Running noon8");
st := time[real]():
Groebner[Basis](J, tdeg(x1, x2, x3, x4, x5, x6, x7, x8), method=direct):
print("noon8: ", time[real]() - st);

