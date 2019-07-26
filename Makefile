#
#
#
pack-manager:
	cd manager; \
	mkdir build; \
	cp main.py build/; \
	mkdir build/lib; \
	pip3 install -r requirements.txt -t build/lib/.; \
	cd build; zip -9qr build.zip .; \

pack-worker:
	cd worker; \
	mkdir build; \
	cp main.py build/; \
	mkdir build/lib; \
	pip3 install -r requirements.txt -t build/lib/.; \
	cd build; zip -9qr build.zip .; \

pack: pack-manager pack-worker
	echo "Done packing."
