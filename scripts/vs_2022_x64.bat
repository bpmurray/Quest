pushd ..
if exist "build\" rd /q /s "build"
mkdir build
pushd build
cmake .\.. -G "Visual Studio 17 2022" -A x64
popd
popd
