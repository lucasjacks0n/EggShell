ios:
	@echo "Compiling iOS Sources (tool)..."
	@cd src/esplios;\
		rm -rf packages;\
		make clean;\
		make package;\
		dpkg -x packages/* new;\
		mv new/usr/bin/esplios ../../resources/esplios

ios-debug:
	@echo "Compiling iOS Sources (debug-tool)..."
	@cd src/esplios;\
		rm -rf packages;\
		make clean;\
		make package install;\
		dpkg -x packages/* new;\
		mv new/usr/bin/esplios ../../resources/esplios

iospro:
	@echo "Compiling iOS Sources (tweak)..."
	@cd src/espro;\
		rm -rf packages;\
		make clean;\
		make package;\
		dpkg -x packages/* new;\
		mv new/Library/MobileSubstrate/DynamicLibraries/* ../../resources/;\
		rm -rf new

macos:
	@echo "Compiling macOS Sources..."
	@cd src/esplmacos;\
	rm build/Release/esplmacos 2>/dev/null;\
	xcodebuild -target esplmacos -configuration Release;\
	rm ../../resources/esplmacos;\
	mv build/Release/esplmacos ../../resources/esplmacos

cydia-package:
	@echo "Packing Cydia Package..."
	@rm -rf .cydia-package
	@mkdir .cydia-package
	@mkdir .cydia-package/DEBIAN
	@mkdir .cydia-package/usr
	@mkdir .cydia-package/usr/local
	@mkdir .cydia-package/usr/local/EggShell
	@mkdir .cydia-package/usr/local/bin
	@echo "#!/bin/bash" >> .cydia-package/usr/local/bin/eggshell
	@echo "cd /usr/local/EggShell" >> .cydia-package/usr/local/bin/eggshell
	@echo "python eggshell.py" >> .cydia-package/usr/local/bin/eggshell
	@chmod +x .cydia-package/usr/local/bin/eggshell
	@cp eggshell.py .cydia-package/usr/local/EggShell
	@cp -R modules .cydia-package/usr/local/EggShell
	@cp -R resources .cydia-package/usr/local/EggShell
	@echo "Name: eggshell-community-edition" >> .cydia-package/DEBIAN/control
	@echo "Package: com.rpwnage.eggshell" >> .cydia-package/DEBIAN/control
	@echo "Version: 3.4.0" >> .cydia-package/DEBIAN/control
	@echo "Description: iOS/macOS/Linux pentest tool" >> .cydia-package/DEBIAN/control
	@echo "Architecture: iphoneos-arm" >> .cydia-package/DEBIAN/control
	@echo "Author: Community Edition <rpwnage@protonmail.com>" >> .cydia-package/DEBIAN/control
	@echo "Maintainer: Lucas Jackson <rpwnage@protonmail.com>" >> .cydia-package/DEBIAN/control
	@echo "Depends: python (>=3.0), com.lucasjackson.pysslfix (>=1.0)" >> .cydia-package/DEBIAN/control
	@echo "#!/bin/bash" >> .cydia-package/DEBIAN/postinst
	@echo "ldid -S /usr/bin/python" >> .cydia-package/DEBIAN/postinst
	@chmod +x .cydia-package/DEBIAN/postinst
	@dpkg -b .cydia-package eggshell.deb

all: ios macos iospro
.PHONY: ios macos iospro