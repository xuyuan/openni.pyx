
from openni import test
from openni import xn

# r = test.Rectangle(1, 2, 3, 4)
# print r
# print "Original area:", r.getArea()
# r.move(1,2)
# print r
# print "Area is invariante under rigid motions:", r.getArea()
# r += test.Rectangle(0,0,1,1)
# print r
# print "Now the aread is:", r.getArea()


v1 = xn.Version(0, 1, 1, 1)
# v2 = xn.Version(0, 1, 1, 1)
# print v1 == v2

context = xn.Context()
ret = context.Init()
assert ret

scriptNode = context.InitFromXmlFile('BasicColorAndDepth.xml')
assert scriptNode

imageGenerator = context.FindExistingNode(xn.NODE_TYPE_IMAGE)
print imageGenerator

while context.WaitAndUpdateAll():
    print 'update'
