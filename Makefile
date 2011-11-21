
all:
	python setup.py build_ext --inplace

clean:
	rm -rf build
	rm openni/*.so

test: all
	python test.py
