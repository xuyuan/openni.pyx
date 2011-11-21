

ctypedef int XnUInt8
ctypedef int XnUInt16
ctypedef int XnUInt32

cdef extern from "XnCppWrapper.h" namespace "xn":
    cdef cppclass cVersion "Version":
        Version(XnUInt8 nMajor, XnUInt8 nMinor, XnUInt16 nMaintenance, XnUInt32 nBuild)


cdef class Version:
    pass

