
all:
	python setup.py build_ext --inplace

clean:
	rm -rf build
	rm opennipyx/*.so

test:
	python test.py
