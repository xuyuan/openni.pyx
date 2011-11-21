from cpython cimport bool  # or from libcpp cimport bool

ctypedef int XnUInt8
ctypedef int XnUInt16
ctypedef int XnUInt32
ctypedef int XnInt32
ctypedef char XnChar

ctypedef XnInt32 XnProductionNodeType
# XnPredefinedProductionNodeType
XN_NODE_TYPE_INVALID = -1
XN_NODE_TYPE_DEVICE = 1
XN_NODE_TYPE_DEPTH = 2
XN_NODE_TYPE_IMAGE = 3
XN_NODE_TYPE_AUDIO = 4
XN_NODE_TYPE_IR = 5
XN_NODE_TYPE_USER = 6
XN_NODE_TYPE_RECORDER = 7
XN_NODE_TYPE_PLAYER = 8
XN_NODE_TYPE_GESTURE = 9
XN_NODE_TYPE_SCENE = 10
XN_NODE_TYPE_HANDS = 11
XN_NODE_TYPE_CODEC = 12
XN_NODE_TYPE_PRODUCTION_NODE = 13
XN_NODE_TYPE_GENERATOR = 14
XN_NODE_TYPE_MAP_GENERATOR = 15
XN_NODE_TYPE_SCRIPT = 16
XN_NODE_TYPE_FIRST_EXTENSION = 17

ctypedef XnUInt32 XnStatus
XN_STATUS_OK = 0

cdef extern from "XnCppWrapper.h" namespace "xn":
    ##### Version #####
    cdef cppclass CVersion "xn::Version":
        bool operator==(CVersion right)

    CVersion *newVersion "new xn::Version" (XnUInt8, XnUInt8, XnUInt16, XnUInt32)
    void delVersion "delete" (CVersion *rect)

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
        pass

    CImageGenerator *newImageGenerator "new xn::ImageGenerator" ()

    void delImageGenerator "delete" (CImageGenerator *node)

    ##### Context #####
    cdef cppclass CContext "xn::Context":
        XnStatus Init()
        XnStatus InitFromXmlFile(XnChar* strFileName, CScriptNode& scriptNode)
        XnStatus FindExistingNode(XnProductionNodeType nodeType, CProductionNode& node)
    CContext *newContext "new xn::Context" ()

    void delContext "delete" (CContext *context)


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

cdef class ImageGenerator(ProductionNode):

    def __init__(self):
        self._this = newImageGenerator()

cdef class Context:
    cdef CContext *_this

    def __cinit__(self):
        self._this = newContext()

    def __dealloc__(self):
        delContext(self._this)

    def Init(self):
        status = self._this.Init()
        return status == XN_STATUS_OK

    def InitFromXmlFile(self, strFileName):
        cdef char* s = strFileName
        scriptNode = ScriptNode()
        status = self._this.InitFromXmlFile(s, scriptNode._this[0])
        if status == XN_STATUS_OK:
            return scriptNode

    def FindExistingNode(self, XnProductionNodeType nodeType):
        if nodeType == XN_NODE_TYPE_IMAGE:
            node = ImageGenerator()
        else:
            node = ProductionNode()

        status = self._this.FindExistingNode(nodeType, node._this[0])
        if status == XN_STATUS_OK:
            return node
