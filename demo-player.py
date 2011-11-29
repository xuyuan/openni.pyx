#!/usr/bin/env python

from openni import xn

import cv

cvimage = cv.CreateImageHeader( (640, 480), cv.IPL_DEPTH_8U, 3 )
cvdepth = cv.CreateImageHeader( (640, 480), cv.IPL_DEPTH_16U, 1 )
cvlabel = cv.CreateImageHeader( (640, 480), cv.IPL_DEPTH_16U, 1 )

context = xn.Context()

player = context.OpenFileRecording('capture.oni')
assert player
assert isinstance(player, xn.Player)

depthGenerator = context.FindExistingNode(xn.NODE_TYPE_DEPTH)
imageGenerator = context.FindExistingNode(xn.NODE_TYPE_IMAGE)
# recorder = context.FindExistingNode(xn.NODE_TYPE_RECORDER)
sceneAnalyzer = context.FindExistingNode(xn.NODE_TYPE_SCENE)


# set player
player.SetRepeat(True)
player.SetPlaybackSpeed(0)


print '-'*10, 'Player', '-'*10
if depthGenerator:
    depthName = depthGenerator.GetName()
    print depthName, 'num frames:', player.GetNumFrames(depthName)
if imageGenerator:
    imageName = imageGenerator.GetName()
    print imageName, 'num frames:', player.GetNumFrames(imageName)
print '-' * 30

try:
    while True:
        # if not player.ReadNext():
            # break

        if not context.WaitAndUpdateAll():
            break

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
    del player
    del depthGenerator
    del imageGenerator
    del sceneAnalyzer

