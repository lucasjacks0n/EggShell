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

all: ios macos iospro
