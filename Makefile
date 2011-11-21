
all:
	python setup.py build_ext --inplace

clean:
	rm -rf build
	rm openni/*.so

test:
	python test.py
