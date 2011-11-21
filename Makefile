
all:
	python setup.py build_ext --inplace

clean:
	rm -rf build
	rm openni/*.so

install:
	python setup.py install