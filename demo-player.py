#!/usr/bin/env python
import sys
from openni import xn

import cv

cvimage = cv.CreateImageHeader( (640, 480), cv.IPL_DEPTH_8U, 3 )
cvdepth = cv.CreateImageHeader( (640, 480), cv.IPL_DEPTH_16U, 1 )
cvlabel = cv.CreateImageHeader( (640, 480), cv.IPL_DEPTH_16U, 1 )

context = xn.Context()

player = context.OpenFileRecording(sys.argv[1])
assert player
assert isinstance(player, xn.Player)

depthGenerator = context.FindExistingNode(xn.Node.TYPE_DEPTH)
imageGenerator = context.FindExistingNode(xn.Node.TYPE_IMAGE)
sceneAnalyzer = context.FindExistingNode(xn.Node.TYPE_SCENE)

# create a recorder
# recorder = xn.Recorder(context)
# recorder.SetDestination(recorder.MEDIUM_FILE, "test.oni")
# recorder.AddNodeToRecording(depthGenerator)
# recorder.AddNodeToRecording(imageGenerator)

# set player
player.SetRepeat(False)
player.SetPlaybackSpeed(0)


print '-'*10, 'Player', '-'*10
print 'Playback speed:', player.GetPlaybackSpeed()
if depthGenerator:
    depthName = depthGenerator.GetName()
    print depthName, 'num frames:', player.GetNumFrames(depthName)
if imageGenerator:
    imageName = imageGenerator.GetName()
    print imageName, 'num frames:', player.GetNumFrames(imageName)
print '-' * 30

singleStep = False

try:
    while not player.IsEOF():
        if not context.WaitAndUpdateAll():
            break

        # print 'timestamp:', player.TellTimestamp()

        if depthGenerator:
            depth = depthGenerator.GetDepthMap()
            cv.SetData(cvdepth, depth.tostring())
            cv.ShowImage("Depth Stream", cvdepth)
            # print 'depth frame:', player.TellFrame(depthGenerator.GetName())

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

        if singleStep:
            key = cv.WaitKey(0)
        else:
            key = cv.WaitKey(10)

        if key == 27:
            break
        elif key == 44:
            print 'one frame back'
            player.SeekToFrame(imageGenerator.GetName(), -1, xn.Player.SEEK_CUR)
        elif key == 98:
            print 'jump to begining'
            player.SeekToFrame(imageGenerator.GetName(), 0, xn.Player.SEEK_SET)
        elif key == 115:
            singleStep = not singleStep
            print 'set singleStep to', singleStep
        elif key != -1:
            print key, 'pressed'
finally:
    # release all rescourses
    del context
    del player
    del depthGenerator
    del imageGenerator
    del sceneAnalyzer


