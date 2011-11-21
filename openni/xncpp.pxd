from cpython cimport bool  # or from libcpp cimport bool
cimport numpy as np
np.import_array()

ctypedef np.uint8_t XnUInt8
ctypedef np.uint16_t XnUInt16
ctypedef np.uint32_t XnUInt32
ctypedef np.int32_t XnInt32
ctypedef char XnChar

ctypedef XnInt32 XnProductionNodeType
cdef extern from 'XnTypes.h':
    cdef struct XnRGB24Pixel:
        XnUInt8 nRed
        XnUInt8 nGreen
        XnUInt8 nBlue

    # define const pointer
    ctypedef char* XnRGB24PixelConstPtr "const XnRGB24Pixel*"

    enum XnPredefinedProductionNodeType:
        XN_NODE_TYPE_INVALID
        XN_NODE_TYPE_DEVICE
        XN_NODE_TYPE_DEPTH
        XN_NODE_TYPE_IMAGE
        XN_NODE_TYPE_AUDIO
        XN_NODE_TYPE_IR
        XN_NODE_TYPE_USER
        XN_NODE_TYPE_RECORDER
        XN_NODE_TYPE_PLAYER
        XN_NODE_TYPE_GESTURE
        XN_NODE_TYPE_SCENE
        XN_NODE_TYPE_HANDS
        XN_NODE_TYPE_CODEC
        XN_NODE_TYPE_PRODUCTION_NODE
        XN_NODE_TYPE_GENERATOR
        XN_NODE_TYPE_MAP_GENERATOR
        XN_NODE_TYPE_SCRIPT
        XN_NODE_TYPE_FIRST_EXTENSION

ctypedef XnUInt32 XnStatus

cdef extern from 'XnStatus.h':
    enum:
        XN_STATUS_OK

cdef extern from "XnCppWrapper.h" namespace "xn":
    ##### Version #####
    cdef cppclass CVersion "xn::Version":
        bool operator==(CVersion right)

    CVersion *newVersion "new xn::Version" (XnUInt8, XnUInt8, XnUInt16, XnUInt32)
    void delVersion "delete" (CVersion *rect)

    ##### MapMetaData ####
    cdef cppclass CMapMetaData "xn::MapMetaData":
        XnUInt32 XRes()
        XnUInt32 YRes()
        XnUInt32 FPS()

    void delMapMetaData "delete" (CMapMetaData* data)

    ##### ImageMetaData ####
    cdef cppclass CImageMetaData "xn::ImageMetaData" (CMapMetaData):
        pass

    CImageMetaData *newImageMetaData "new xn::ImageMetaData" ()

    ##### ScriptNode #####
    cdef cppclass CScriptNode "xn::ScriptNode":
        pass

    CScriptNode *newScriptNode "new xn::ScriptNode" ()

    void delScriptNode "delete" (CScriptNode *node)

    ##### ProductionNode #####
    cdef cppclass CProductionNode "xn::ProductionNode":
        pass

    CProductionNode *newProductionNode "new xn::ProductionNode" ()

    void delProductionNode "delete" (CProductionNode *node)

    ##### ImageGenerator ######
    cdef cppclass CImageGenerator "xn::ImageGenerator" (CProductionNode):
        void GetMetaData(CImageMetaData& metaData)
        XnRGB24PixelConstPtr GetRGB24ImageMap()

    CImageGenerator *newImageGenerator "new xn::ImageGenerator" ()

    ##### Context #####
    cdef cppclass CContext "xn::Context":
        XnStatus Init()
        XnStatus InitFromXmlFile(XnChar* strFileName, CScriptNode& scriptNode)
        void Release()
        XnStatus FindExistingNode(XnProductionNodeType nodeType, CProductionNode& node)
        XnStatus WaitAndUpdateAll()
    CContext *newContext "new xn::Context" ()

    void delContext "delete" (CContext *context)
