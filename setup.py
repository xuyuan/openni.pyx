from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext


test = Extension("opennipyx.test",
              sources=["opennipyx/test.pyx", 'opennipyx/cpp_rect.cpp'],
              include_dirs=["."],
              language="c++")

xn = Extension("opennipyx.xn",
              sources=['opennipyx/xn.pyx'],
              include_dirs=[".", '/usr/include/openni'],
              language="c++")

setup(
  name = 'test',
  packages=['opennipyx'],
  ext_modules=[test, xn],
  cmdclass = {'build_ext': build_ext},
)
