#!/usr/bin/env python

from openni import xn

import cv

cvimage = cv.CreateImageHeader( (640, 480), cv.IPL_DEPTH_8U, 3 )
cvdepth = cv.CreateImageHeader( (640, 480), cv.IPL_DEPTH_16U, 1 )
cvlabel = cv.CreateImageHeader( (640, 480), cv.IPL_DEPTH_16U, 1 )

# v1 = xn.Version(0, 1, 1, 1)
# v2 = xn.Version(0, 1, 1, 1)
# print v1 == v2

context = xn.Context()

node = context.InitFromXmlFile('demo.xml')
# node = context.OpenFileRecording('test.oni')
assert node

depthGenerator = context.FindExistingNode(xn.Node.TYPE_DEPTH)
imageGenerator = context.FindExistingNode(xn.Node.TYPE_IMAGE)
# recorder = context.FindExistingNode(xn.NODE_TYPE_RECORDER)
sceneAnalyzer = context.FindExistingNode(xn.Node.TYPE_SCENE)


try:
    while context.WaitAndUpdateAll():

        if depthGenerator:
            depth = depthGenerator.GetDepthMap()
            cv.SetData(cvdepth, depth.tostring())
            cv.ShowImage("Depth Stream", cvdepth)

        if imageGenerator:
            image = imageGenerator.GetRGB24ImageMap()
            cv.SetData(cvimage, image.tostring())
            cv.CvtColor(cvimage, cvimage, cv.CV_RGB2BGR)
            cv.ShowImage("Image Stream", cvimage)

        if sceneAnalyzer:
            label = sceneAnalyzer.GetLabelMap()
            label[label.nonzero()] = 2 ** 15
            cv.SetData(cvlabel, label.tostring())
            cv.ShowImage("Label", cvlabel)

        key = cv.WaitKey(10)  
        if key == 27:
            break
finally:
    # release all rescourses
    del context
    del node
    del depthGenerator
    del imageGenerator
    del sceneAnalyzer


