cd src/esplios
rm -rf packages
echo "cleaning..."
make clean
echo "building..."
make package
dpkg -x packages/* new
echo "updating binary"
mv new/usr/bin/esplios ../../resources/esplios
