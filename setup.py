from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext


test = Extension("opennipyx.test",
              sources=["opennipyx/test.pyx", 'cpp_rect.cpp'],
              include_dirs=["."],
              language="c++")

setup(
  name = 'test',
  packages=['opennipyx'],
  ext_modules=[test
    # Extension("opennipyx",
    #           sources=["opennipyx/xn.pyx", 'cpp_rect.cpp'],
    #           include_dirs=[".", '/usr/include/openni'],
    #           language="c++"),
    ],
  cmdclass = {'build_ext': build_ext},
)
