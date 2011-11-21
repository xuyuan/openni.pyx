from cpython cimport bool  # or from libcpp cimport bool

ctypedef int XnUInt8
ctypedef int XnUInt16
ctypedef int XnUInt32

cdef extern from "XnCppWrapper.h" namespace "xn":
    cdef cppclass CVersion "xn::Version":
        bool operator==(CVersion right)
    CVersion *new_Version "new xn::Version" (XnUInt8, XnUInt8, XnUInt16, XnUInt32)
    void del_Version "delete" (CVersion *rect)


cdef class Version:
    cdef CVersion *_this

    def __cinit__(self, int nMajor, int nMinor, int nMaintenance, int nBuild):
        self._this = new_Version(nMajor, nMinor, nMaintenance, nBuild)

    def __dealloc__(self):
        del_Version(self._this)

    def __richcmp__(Version self, Version other, int op):
        if op == 2:
            return self._this[0] == other._this[0]
        else:
            raise NotImplemented
