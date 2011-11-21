from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext


test = Extension("openni.test",
              sources=["openni/test.pyx", 'openni/cpp_rect.cpp'],
              include_dirs=["."],
              language="c++")

xn = Extension("openni.xn",
               sources=['openni/xn.pyx'],
               include_dirs=[".", '/usr/include/openni'],
               libraries=["OpenNI"],
               language="c++")

setup(
  name = 'openni',
  packages=['openni'],
  ext_modules=[test, xn],
  cmdclass = {'build_ext': build_ext},
)
