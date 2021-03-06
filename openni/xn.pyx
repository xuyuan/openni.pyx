"""
Python binding of namespace xn in OpenNI
========================================
"""

__license__ = "MIT"
__author__ =  "Xu, Yuan"
__email__ = "xuyuan.cn@gmail.com"

import numpy as np
cimport numpy as np
np.import_array()

CODEC_NULL = XN_CODEC_NULL
CODEC_UNCOMPRESSED = XN_CODEC_UNCOMPRESSED
CODEC_JPEG = XN_CODEC_JPEG
CODEC_16Z = XN_CODEC_16Z
CODEC_16Z_EMB_TABLES = XN_CODEC_16Z_EMB_TABLES
CODEC_8Z = XN_CODEC_8Z

cdef _raw2array(void* data, int ndim, np.npy_intp* shape, dtype):
    # Use the PyArray_SimpleNewFromData function from numpy to create a
    # new Python object pointing to the existing data
    ndarray = np.PyArray_SimpleNewFromData(ndim, shape, dtype, data)

    # copy the data, since this data belongs to OpenNI interally
    return np.PyArray_NewCopy(ndarray, np.NPY_ANYORDER)

cdef class Version:
    cdef CVersion *_this

    def __cinit__(self, int nMajor, int nMinor, int nMaintenance, int nBuild):
        self._this = newVersion(nMajor, nMinor, nMaintenance, nBuild)

    def __dealloc__(self):
        delVersion(self._this)

    def __richcmp__(Version self, Version other, int op):
        if op == 2:
            return self._this[0] == other._this[0]
        else:
            raise NotImplemented

cdef class MapMetaData:
    """
    Represents a MetaData object for generators producing
    pixel-map-based outputs 
    """
    cdef CMapMetaData* _this

    def __init__(self):
        """meant to be used by inheriting classes."""
        raise NotImplemented

    def __dealloc__(self):
        delMapMetaData(self._this)

    def Res(self):
        """
        Gets the actual resolution of columns in the frame (after
        cropping)
        """
        return (self._this.XRes(), self._this.YRes())

    def FPS(self):
        """Gets the FPS in which frame was generated. """
        return self._this.FPS()

cdef class DepthMetaData(MapMetaData):
    def __init__(self):
        self._this = newDepthMetaData()

    def Data(self):
        """
        .. warning: this is the data pointing to OpenNI interal data
        """
        this = <CDepthMetaData*>(self._this)
        cdef np.npy_intp shape[2]
        shape[0] = <np.npy_intp>(this.XRes())
        shape[1] = <np.npy_intp>(this.YRes())
        data = this.Data()

        return np.PyArray_SimpleNewFromData(2, shape,
                                            np.NPY_UINT16, <void*>data)

cdef class ImageMetaData(MapMetaData):
    def __init__(self):
        self._this = newImageMetaData()

    def RGB24Data(self):
        """
        .. warning: this is the data pointing to OpenNI interal data
        """
        this = <CImageMetaData*>(self._this)
        cdef np.npy_intp shape[3]
        shape[0] = <np.npy_intp>(this.XRes())
        shape[1] = <np.npy_intp>(this.YRes())
        shape[2] = <np.npy_intp>(3)
        data = this.RGB24Data()

        return np.PyArray_SimpleNewFromData(3, shape,
                                            np.NPY_UINT8, <void*>data)

cdef class SceneMetaData(MapMetaData):
    def __init__(self):
        self._this = newSceneMetaData()

    def Data(self):
        """
        .. warning: this is the data pointing to OpenNI interal data
        """
        this = <CSceneMetaData*>(self._this)
        cdef np.npy_intp shape[2]
        shape[0] = <np.npy_intp>(this.XRes())
        shape[1] = <np.npy_intp>(this.YRes())
        data = this.Data()

        return np.PyArray_SimpleNewFromData(2, shape,
                                            np.NPY_UINT16, <void*>data)

cdef class Node:
    """Base class for all node"""
    TYPE_IMAGE = XN_NODE_TYPE_IMAGE
    TYPE_DEPTH = XN_NODE_TYPE_DEPTH
    TYPE_SCENE = XN_NODE_TYPE_SCENE
    TYPE_RECORDER = XN_NODE_TYPE_RECORDER

    cdef CNodeWrapper* _this

    def __init__(self):
        raise NotImplemented

    def __dealloc__(self):
        delNodeWrapper(self._this)

    def GetName(self):
        cdef char* s = <char*>(self._this.GetName())
        cdef bytes name
        name = s
        return name

cdef class ProductionNode(Node):

    def __init__(self):
        self._this = newProductionNode()


cdef class ScriptNode(ProductionNode):

    def __init__(self):
        self._this = newScriptNode()

cdef class DepthGenerator(ProductionNode):

    def __init__(self):
        self._this = newDepthGenerator()

    def GetMetaData(self):
        """Gets the current depth-map meta data."""
        metaData = DepthMetaData()
        metaDataPtr = <CDepthMetaData*>(metaData._this)
        this = <CDepthGenerator*>(self._this)
        this.GetMetaData(metaDataPtr[0])
        return metaData

    def GetDepthMap(self):
        """
        Gets the current depth-map. This map is updated after a call
        to xnWaitAndUpdateData().
        """
        this = <CDepthGenerator*>(self._this)
        cdef XnDepthPixelConstPtr pixel
        pixel = this.GetDepthMap()
        w, h = self.GetMetaData().Res()

        cdef np.npy_intp shape[2]
        shape[0] = <np.npy_intp>(h)
        shape[1] = <np.npy_intp>(w)

        return _raw2array(<void*>pixel, 2, shape, np.NPY_UINT16)

    def ConvertDepthMapToProjective(self, np.ndarray[np.uint16_t, ndim=2] pixel not None):
        """
        coverts depth map to projective coodrinates
        """
        cdef int h = pixel.shape[0]
        cdef int w = pixel.shape[1]
        cdef np.npy_intp shape[3]
        shape[0] = h
        shape[1] = w
        shape[2] = <np.npy_intp>(3)
        cdef np.ndarray[np.npy_float, ndim=3] aProjective = np.PyArray_SimpleNew(3, shape, np.NPY_FLOAT)
        np.PyArray_UpdateFlags(aProjective, aProjective.flags.num | np.NPY_OWNDATA)

        for y in range(h):
            for x in range(w):
                aProjective[y, x, 0] = x
                aProjective[y, x, 1] = y
                aProjective[y, x, 2] = pixel[y, x]
        return aProjective

    def ConvertProjectiveToRealWorld(self, aProjective):
        """
        Converts a list of points from projective coordinates to real
        world coordinates.
        """
        cdef XnPoint3D* aProjectiveData = <XnPoint3D*>np.PyArray_DATA(aProjective)
        cdef np.npy_intp* shape = np.PyArray_DIMS(aProjective)
        cdef int ndim = np.PyArray_NDIM(aProjective)

        aRealWorld = np.PyArray_SimpleNew(ndim, shape, np.NPY_FLOAT)
        np.PyArray_UpdateFlags(aRealWorld, aRealWorld.flags.num | np.NPY_OWNDATA)
        cdef XnPoint3D* aRealWorldData =  <XnPoint3D*>np.PyArray_DATA(aRealWorld)
        cdef int nCount = 1
        for i in range(ndim - 1):
            nCount *= shape[i]

        this = <CDepthGenerator*>(self._this)
        this.ConvertProjectiveToRealWorld(nCount,
                                          aProjectiveData, 
                                          aRealWorldData)
        return aRealWorld

cdef class ImageGenerator(ProductionNode):

    def __init__(self):
            self._this = newImageGenerator()

    def GetMetaData(self):
        metaData = ImageMetaData()
        metaDataPtr = <CImageMetaData*>(metaData._this)
        this = <CImageGenerator*>(self._this)
        this.GetMetaData(metaDataPtr[0])
        return metaData

    def GetRGB24ImageMap(self):
        _this = <CImageGenerator*>(self._this)
        cdef XnRGB24PixelConstPtr pixel
        pixel = _this.GetRGB24ImageMap()
        w, h = self.GetMetaData().Res()

        # Create a C array to describe the shape of the ndarray
        cdef np.npy_intp shape[3]
        shape[0] = <np.npy_intp>(h)
        shape[1] = <np.npy_intp>(w)
        shape[2] = <np.npy_intp>(3)

        return _raw2array(<void*>pixel, 3, shape, np.NPY_UINT8)

cdef class SceneAnalyzer(ProductionNode):
    """
    A map generator that gets raw sensory data and generates a map
    with labels that clarify the scene.
    """
    def __init__(self):
            self._this = newSceneAnalyzer()

    def GetMetaData(self):
        metaData = SceneMetaData()
        metaDataPtr = <CSceneMetaData*>(metaData._this)
        this = <CSceneAnalyzer*>(self._this)
        this.GetMetaData(metaDataPtr[0])
        return metaData

    def GetLabelMap(self):
        this = <CSceneAnalyzer*>(self._this)
        cdef XnLabelConstPtr pixel
        pixel = this.GetLabelMap()
        w, h = self.GetMetaData().Res()

        # Create a C array to describe the shape of the ndarray
        cdef np.npy_intp shape[2]
        shape[0] = <np.npy_intp>(h)
        shape[1] = <np.npy_intp>(w)

        return _raw2array(<void*>pixel, 2, shape, np.NPY_UINT16)

    def GetFloor(self):
        cdef XnPlane3D plane
        this = <CSceneAnalyzer*>(self._this)
        this.GetFloor(plane)
        return ([plane.ptPoint.X, plane.ptPoint.Y, plane.ptPoint.Z],
                [plane.vNormal.X, plane.vNormal.Y, plane.vNormal.Z])

cdef class Player(ProductionNode):
    """Reads data from a recording and plays it"""
    SEEK_SET = XN_PLAYER_SEEK_SET
    SEEK_CUR = XN_PLAYER_SEEK_CUR
    SEEK_END = XN_PLAYER_SEEK_END
    def __init__(self):
        self._this = newPlayer()

    def GetNumFrames(self, strNodeName):
        """
        Retrieves the number of frames of a specific node played by a
        player.

        :param strNodeName: The name of the node for which to retrieve
            the number of frames.
        """
        this = <CPlayer*>(self._this)
        cdef char* s = strNodeName
        cdef XnUInt32 pnFrames
        status = this.GetNumFrames(s, pnFrames)
        assert status == XN_STATUS_OK
        return pnFrames

    def SetRepeat(self, bRepeat):
        """
        Determines whether the player will automatically rewind to the
        beginning of the recording when reaching the end.
        """
        this = <CPlayer*>(self._this)
        status = this.SetRepeat(bRepeat)
        assert status == XN_STATUS_OK

    def SetPlaybackSpeed(self, dSpeed):
        """
        Sets the playback speed, as a ratio of the time passed in the
        recording. A value of 1.0 means the player will try to output
        frames in the rate they were recorded (according to their
        timestamps). A value bigger than 1.0 means fast-forward, and a
        value between 0.0 and 1.0 means slow-motion. The special value
        of 0.0 means there will be no delay, and that frames will be
        returned as soon as asked for.
        """
        this = <CPlayer*>(self._this)
        status = this.SetPlaybackSpeed(dSpeed)
        return status == XN_STATUS_OK

    def GetPlaybackSpeed(self):
        """
        Gets the playback speed. see :func:`SetPlaybackSpeed` for more
        details.
        """
        this = <CPlayer*>(self._this)
        return this.GetPlaybackSpeed()

    def TellFrame(self, strNodeName):
        """
        Reports the current frame number of a specific node played by
        a player.
        """
        this = <CPlayer*>(self._this)
        cdef char* s = strNodeName
        cdef XnUInt32 nFrame
        status = this.TellFrame(s, nFrame)
        assert status == XN_STATUS_OK
        return nFrame

    def TellTimestamp(self):
        """
        Reports the current timestamp of a player, i.e. the amount of
        time passed since the beginning of the recording.

        :return: timestamp in microseconds.
        """
        this = <CPlayer*>(self._this)
        cdef XnUInt64 nTimestamp
        status = this.TellTimestamp(nTimestamp)
        assert status == XN_STATUS_OK
        return nTimestamp

    def IsEOF(self):
        """Checks whether the player is at the end-of-file marker.

        .. note::

            In the built-in ONI player, this function will never
            return TRUE for a player that is in repeat mode
        """
        this = <CPlayer*>(self._this)
        return this.IsEOF() != 0

    def SeekToFrame(self, strNodeName, nFrameOffset, origin):
        """
        Seeks the player to a specific frame of a specific played
        node, so that playing will continue from that frame onwards.

        :param strNodeName: The name of the node whose frame is to be
            sought.

        :param nFrameOffset: The number of frames to move, relative to
            the specified origin. See the remark below.

        :param origin: The origin to seek from. See the note below.

        .. note::

            The meaning of the nTimeOffset parameter changes according
            to the origin parameter:

            +----------+---------------------------------------------+
            | origin   | Meaning of the nFrameOffset parameter       |
            +==========+=============================================+
            |          | nFrameOffset specifies the total number of  |
            | SEEK_SET | frames since the beginning of the node's    |
            |          | recording.                                  |
            +----------+---------------------------------------------+
            |          | nFrameOffset specifies the number of frames |
            |          | to move, relative to the current frame of   |
            | SEEK_CUR | the specifies node. A positive value means  |
            |          | move forward, and a negative value means    |
            |          | move backwards.                             |
            +----------+---------------------------------------------+
            |          | nFrameOffset specifies the number of frames |
            | SEEK_END | to move, relative to the end of the node's  |
            |          | recording. This must be a negative value.   |
            +----------+---------------------------------------------+
        """
        this = <CPlayer*>(self._this)
        cdef char* s = strNodeName
        status = this.SeekToFrame(s, nFrameOffset, origin)
        assert status == XN_STATUS_OK

cdef class Context:
    """
    The context is the main object in OpenNI. A context is an object
    that holds the complete state of applications using OpenNI,
    including all the production chains used by the application. The
    same application can create more than one context, but the
    contexts cannot share information. For example, a middleware node
    cannot use a device node from another context. The context must be
    initialized once, prior to its initial use. At this point, all
    plugged-in modules are loaded and analyzed.
    """
    cdef CContext *_this

    def __cinit__(self):
        self._this = newContext()

    def __dealloc__(self):
        delContext(self._this)

    def __init__(self):
        """Initializes the OpenNI library.
        """
        status = self._this.Init()
        assert status == XN_STATUS_OK

    def InitFromXmlFile(self, strFileName):
        """
        Initializes OpenNI context, and then configures it using the
        given file.
        """
        cdef char* s = strFileName
        scriptNode = ScriptNode()
        scriptnodeptr = <CScriptNode*>(scriptNode._this)
        status = self._this.InitFromXmlFile(s, scriptnodeptr[0])
        if status == XN_STATUS_OK:
            return scriptNode

    def FindExistingNode(self, XnProductionNodeType nodeType):
        """
        Returns the first found existing node of the specified type. 
        """
        if nodeType == XN_NODE_TYPE_DEPTH:
            node = DepthGenerator()
        elif nodeType == XN_NODE_TYPE_IMAGE:
            node = ImageGenerator()
        elif nodeType == XN_NODE_TYPE_SCENE:
            node = SceneAnalyzer()
        elif nodeType == XN_NODE_TYPE_RECORDER:
            node = Recorder()
        else:
            node = ProductionNode()
        nodePtr = <CProductionNode*>(node._this)
        status = self._this.FindExistingNode(nodeType, nodePtr[0])
        if status == XN_STATUS_OK:
            return node

    def OpenFileRecording(self, strFileName):
        """
        Opens a recording file, adding all nodes in it to the context.
        """
        cdef char* s = strFileName
        player = Player()
        playerPtr = <CPlayer*>(player._this)
        status = self._this.OpenFileRecording(s, playerPtr[0])
        if status == XN_STATUS_OK:
            return player

    def WaitAndUpdateAll(self):
        """
        Updates all generators nodes in the context, waiting for all
        to have new data.
        """
        status = self._this.WaitAndUpdateAll()
        return status == XN_STATUS_OK

cdef class Recorder(ProductionNode):
    """
    To record, an application should create a Recorder node, and set
    its destination (the file name to which it should write). The
    application should then add to the recorder node, every node it
    wants to record. When adding a node to the recorder, the recorder
    reads its configuration and records it. It also registers to every
    possible event of the node, so that when any configuration change
    takes place, it is also recorded.

    Once all required nodes are added, the application can read data
    from the nodes and record it. Recording of data can be achieved
    either by explicitly calling the xn::Recorder::Record() function,
    or by using one of the UpdateAll functions (see Reading Data).

    Applications that initialize OpenNI using an XML file can easily
    record their session without any change to the code. All that is
    required is that they create an additional node in the XML file
    for the recorder, add nodes to it, and when the application calls
    one of the UpdateAll functions, recording will occur.
    """
    MEDIUM_FILE = XN_RECORD_MEDIUM_FILE
    def __init__(self, Context context=None):
        this = newRecorder()
        if context:
            contextPtr = <CContext*>(context._this)
            this.Create(contextPtr[0])
        self._this = this

    def SetDestination(self, destType, strDest):
        """
        Tells the recorder where to record.

        :param destType: The type of medium to record to. Currently
            only RECORD_MEDIUM_FILE is supported

        :param strDest: Recording destination. If destType is
            RECORD_MEDIUM_FILE, this specifies a file name.
        """
        this = <CRecorder*>(self._this)
        cdef char* s = strDest
        status = this.SetDestination(destType, s)
        assert status == XN_STATUS_OK
        

    def AddNodeToRecording(self, ProductionNode node, compression=CODEC_NULL):
        """
        Adds a node to recording and start recording it. This function
        must be called on each node that is to be recorded with this
        recorder.

        :param node: The node to add to the recording.

        :param compression: The type of compression that will be used
            to encode the node's data. If CODEC_NULL is specified, a
            default compression will be chosen according to the node
            type.
        """
        this = <CRecorder*>(self._this)
        nodePtr = <CProductionNode*>(node._this)
        status = this.AddNodeToRecording(nodePtr[0], compression)
        assert status == XN_STATUS_OK

    def RemoveNodeFromRecording(self, ProductionNode node):
        """
        Removes node from recording and stop recording it.
        """
        this = <CRecorder*>(self._this)
        nodePtr = <CProductionNode*>(node._this)
        status = this.RemoveNodeFromRecording(nodePtr[0])
        assert status == XN_STATUS_OK

    def Record(self):
        """
        Records one frame of data from each node that was added to the
        recorder with xnAddNodeToRecording.
        """
        this = <CRecorder*>(self._this)
        status = this.Record()
        assert status == XN_STATUS_OK
