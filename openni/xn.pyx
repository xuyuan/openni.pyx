"""
Cython wrapper for namespace xn of OpenNI
=========================================
"""

__license__ = "MIT"
__author__ =  "Xu, Yuan"
__email__ = "xuyuan.cn@gmail.com"

import numpy as np
cimport numpy as np
np.import_array()

NODE_TYPE_IMAGE = XN_NODE_TYPE_IMAGE
NODE_TYPE_DEPTH = XN_NODE_TYPE_DEPTH
NODE_TYPE_SCENE = XN_NODE_TYPE_SCENE
NODE_TYPE_RECORDER = XN_NODE_TYPE_RECORDER

RECORD_MEDIUM_FILE = XN_RECORD_MEDIUM_FILE

CODEC_NULL = XN_CODEC_NULL
CODEC_UNCOMPRESSED = XN_CODEC_UNCOMPRESSED
CODEC_JPEG = XN_CODEC_JPEG
CODEC_16Z = XN_CODEC_16Z
CODEC_16Z_EMB_TABLES = XN_CODEC_16Z_EMB_TABLES
CODEC_8Z = XN_CODEC_8Z

cdef raw2array(void* data, int ndim, np.npy_intp* shape, dtype):
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

cdef class ScriptNode:
    cdef CScriptNode* _this

    def __cinit__(self):
        self._this = newScriptNode()

    def __dealloc__(self):
        delScriptNode(self._this)

cdef class ProductionNode:
    cdef CProductionNode* _this

    def __init__(self):
        self._this = newProductionNode()

    def __dealloc__(self):
        delProductionNode(self._this)


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

        return raw2array(<void*>pixel, 2, shape, np.NPY_UINT16)

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
                aProjective[y, x, 0] = y
                aProjective[y, x, 1] = x
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

        return raw2array(<void*>pixel, 3, shape, np.NPY_UINT8)

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

        return raw2array(<void*>pixel, 2, shape, np.NPY_UINT16)

    def GetFloor(self):
        cdef XnPlane3D plane
        this = <CSceneAnalyzer*>(self._this)
        this.GetFloor(plane)
        return ([plane.ptPoint.X, plane.ptPoint.Y, plane.ptPoint.Z],
                [plane.vNormal.X, plane.vNormal.Y, plane.vNormal.Z])

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
    def __init__(self):
        self._this = newRecorder()

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
        default compression will be chosen according to the node type.
        """
        this = <CRecorder*>(self._this)
        status = this.AddNodeToRecording(node._this[0], compression)
        assert status == XN_STATUS_OK

    def RemoveNodeFromRecording(self, ProductionNode node):
        """
        Removes node from recording and stop recording it.
        """
        this = <CRecorder*>(self._this)
        status = this.RemoveNodeFromRecording(node._this[0])
        assert status == XN_STATUS_OK

    def Record(self):
        """
        Records one frame of data from each node that was added to the
        recorder with xnAddNodeToRecording.
        """
        this = <CRecorder*>(self._this)
        status = this.Record()
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
        status = self._this.InitFromXmlFile(s, scriptNode._this[0])
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

        status = self._this.FindExistingNode(nodeType, node._this[0])
        if status == XN_STATUS_OK:
            return node

    def OpenFileRecording(self, strFileName):
        """
        Opens a recording file, adding all nodes in it to the context.
        """
        cdef char* s = strFileName
        playerNode = ProductionNode()
        status = self._this.OpenFileRecording(s, playerNode._this[0])
        if status == XN_STATUS_OK:
            return playerNode

    def WaitAndUpdateAll(self):
        """
        Updates all generators nodes in the context, waiting for all
        to have new data.
        """
        status = self._this.WaitAndUpdateAll()
        return status == XN_STATUS_OK
