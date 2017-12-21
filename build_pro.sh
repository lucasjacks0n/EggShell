cd src/espro
rm -rf packages
echo "cleaning..."
make clean
echo "building..."
make package
dpkg -x packages/* new
echo "updating binary"
mv new/Library/MobileSubstrate/DynamicLibraries/* ../../resources/
rm -rf new
