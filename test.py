
from openni import test
from openni import xn


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

try:
    while context.WaitAndUpdateAll():
        imd = imageGenerator.GetMetaData()
        print imd.Res(), imd.FPS()
finally:
    context.Release()
