
# from opennipyx import test
from opennipyx import test
# from opennipyx.test import Rectangle
from opennipyx import xn

r = test.Rectangle(1, 2, 3, 4)
print r
print "Original area:", r.getArea()
r.move(1,2)
print r
print "Area is invariante under rigid motions:", r.getArea()
r += test.Rectangle(0,0,1,1)
print r
print "Now the aread is:", r.getArea()


version = xn.Version()
print version
