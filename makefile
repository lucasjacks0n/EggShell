ios:
	cd src/esplios;\
	rm -rf packages;\
	make clean;\
	make package;\
	dpkg -x packages/* new;\
	mv new/usr/bin/esplios ../../resources/esplios

iospro:
	cd src/espro;\
	rm -rf packages;\
	make clean;\
	make package;\
	dpkg -x packages/* new;\
	mv new/Library/MobileSubstrate/DynamicLibraries/* ../../resources/;\
	rm -rf new

macos:
	cd src/esplmacos;\
	rm build/Release/esplmacos 2>/dev/null;\
	xcodebuild -target esplmacos -configuration Release;\
	rm ../../resources/esplmacos;\
	mv build/Release/esplmacos ../../resources/esplmacos

cydia-package:
	rm -rf .cydia-package
	# directory stucture
	mkdir .cydia-package
	mkdir .cydia-package/DEBIAN
	mkdir .cydia-package/usr
	mkdir .cydia-package/usr/local
	mkdir .cydia-package/usr/local/EggShell
	mkdir .cydia-package/usr/local/bin
	echo "#!/bin/bash" >> .cydia-package/usr/local/bin/eggshell
	echo "cd /usr/local/EggShell" >> .cydia-package/usr/local/bin/eggshell
	echo "python eggshell.py" >> .cydia-package/usr/local/bin/eggshell
	chmod +x .cydia-package/usr/local/bin/eggshell
	# copy files
	cp eggshell.py .cydia-package/usr/local/EggShell
	cp -R modules .cydia-package/usr/local/EggShell
	cp -R resources .cydia-package/usr/local/EggShell
	# control file
	echo "Name: EggShell" >> .cydia-package/DEBIAN/control
	echo "Package: com.lucasjackson.eggshell" >> .cydia-package/DEBIAN/control
	echo "Version: 3.0.0" >> .cydia-package/DEBIAN/control
	echo "Description: iOS/macOS/Linux pentest tool" >> .cydia-package/DEBIAN/control
	echo "Architecture: iphoneos-arm" >> .cydia-package/DEBIAN/control
	echo "Author: Lucas Jackson <lucas@lucasjackson5815@gmail.com>" >> .cydia-package/DEBIAN/control
	echo "Maintainer: Lucas Jackson <lucas@lucasjackson5815@gmail.com>" >> .cydia-package/DEBIAN/control
	echo "Depends: python (>=2.7.8-1), com.lucasjackson.pysslfix (>=1.0)" >> .cydia-package/DEBIAN/control
	#postinst
	echo "#!/bin/bash" >> .cydia-package/DEBIAN/postinst
	echo "ldid -S /usr/bin/python" >> .cydia-package/DEBIAN/postinst
	chmod +x .cydia-package/DEBIAN/postinst
	dpkg -b .cydia-package eggshell.deb

all: ios macos iospro cydia-package
