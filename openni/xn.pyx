"""
Cython wrapper for namespace xn of OpenNI
=========================================
"""

__license__ = "MIT"
__author__ =  "Xu, Yuan"
__email__ = "xuyuan.cn@gmail.com"

from xncpp cimport *
import numpy as np
cimport numpy as np
np.import_array()

NODE_TYPE_IMAGE = XN_NODE_TYPE_IMAGE
NODE_TYPE_DEPTH = XN_NODE_TYPE_DEPTH

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


cdef class ImageMetaData(MapMetaData):
    def __init__(self):
        self._this = newImageMetaData()    


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

        ndarray = np.PyArray_SimpleNewFromData(2, shape,
                                               np.NPY_UINT16,
                                               <void*> pixel)

        np.PyArray_UpdateFlags(ndarray, ndarray.flags.num | np.NPY_OWNDATA)
        return ndarray

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

        # Use the PyArray_SimpleNewFromData function from numpy to create a
        # new Python object pointing to the existing data
        ndarray = np.PyArray_SimpleNewFromData(3, shape,
                                               np.NPY_UINT8, <void *> pixel)

        # Tell Python that it can deallocate the memory when the ndarray
        # object gets garbage collected
        # As the OWNDATA flag of an array is read-only in Python, we need to
        # call the C function PyArray_UpdateFlags
        np.PyArray_UpdateFlags(ndarray, ndarray.flags.num | np.NPY_OWNDATA)
        return ndarray

cdef class Context:
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
        else:
            node = ProductionNode()

        status = self._this.FindExistingNode(nodeType, node._this[0])
        if status == XN_STATUS_OK:
            return node

    def WaitAndUpdateAll(self):
        """
        Updates all generators nodes in the context, waiting for all
        to have new data.
        """
        status = self._this.WaitAndUpdateAll()
        return status == XN_STATUS_OK
