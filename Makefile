
all:
	python setup.py build_ext --inplace

clean:
	rm -rf build
	rm openni/*.so
	rm openni/*.cpp

install:
	python setup.py install
