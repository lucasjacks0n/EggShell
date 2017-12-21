cd src/esplmacos
rm mv build/Release/esplmacos
xcodebuild -target esplmacos -configuration Release
echo updating binary...
rm ../../resources/esplmacos
echo "updating binary"
mv build/Release/esplmacos ../../resources/esplmacos
