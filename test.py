
from openni import xn

import cv

cvimage = cv.CreateImageHeader( (640, 480), cv.IPL_DEPTH_8U, 3 )
cvdepth = cv.CreateImageHeader( (640, 480), cv.IPL_DEPTH_16U, 1 )

# v1 = xn.Version(0, 1, 1, 1)
# v2 = xn.Version(0, 1, 1, 1)
# print v1 == v2

context = xn.Context()
ret = context.Init()
assert ret

scriptNode = context.InitFromXmlFile('BasicColorAndDepth.xml')
assert scriptNode

depthGenerator = context.FindExistingNode(xn.NODE_TYPE_DEPTH)
imageGenerator = context.FindExistingNode(xn.NODE_TYPE_IMAGE)

try:
    while context.WaitAndUpdateAll():
        depth = depthGenerator.GetDepthMap()
        image = imageGenerator.GetRGB24ImageMap()

        # for showing image
        cv.SetData(cvdepth, depth.tostring())
        cv.SetData(cvimage, image.tostring())
        cv.CvtColor(cvimage, cvimage, cv.CV_RGB2BGR)
        cv.ShowImage("Depth Stream", cvdepth)
        cv.ShowImage("Image Stream", cvimage)
        key = cv.WaitKey(5)  
        if key == 27:
            break
finally:
    context.Release()
