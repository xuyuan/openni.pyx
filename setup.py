from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

xn = Extension("openni.xn",
               sources=['openni/xn.pyx'],
               include_dirs=[".", '/usr/include/openni'],
               libraries=["OpenNI"],
               language="c++")

setup(
  name = 'openni',
  packages=['openni'],
  ext_modules=[xn],
  cmdclass = {'build_ext': build_ext},
)
