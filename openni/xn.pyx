from cpython cimport bool  # or from libcpp cimport bool

ctypedef int XnUInt8
ctypedef int XnUInt16
ctypedef int XnUInt32
ctypedef char XnChar
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

    ##### Context #####
    cdef cppclass CContext "xn::Context":
        XnStatus Init()
        XnStatus InitFromXmlFile(XnChar* strFileName, CScriptNode& scriptNode)

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

cdef class Context:
    cdef CContext *_this

    def __cinit__(self):
        self._this = newContext()

    def __dealloc__(self):
        delContext(self._this)

    def Init(self):
        return self._this.Init()

    def InitFromXmlFile(self, strFileName, ScriptNode scriptNode):
        cdef char* s = strFileName
        return self._this.InitFromXmlFile(s, scriptNode._this[0])
