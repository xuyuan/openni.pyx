
from openni import test
from openni import xn

import cv

cvimage = cv.CreateImageHeader( (640, 480), cv.IPL_DEPTH_8U, 3 )

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
        image = imageGenerator.GetRGB24ImageMap()
        # print image
        cv.SetData(cvimage, image.tostring())
        cv.ShowImage( "Image Stream", cvimage )
        cv.WaitKey(5)  # for showing image 
finally:
    context.Release()
