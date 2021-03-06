#!/bin/bash
set -e
export MODULE_PREFIX="$HOME/Installed_Package"

echo "Updating all packages"
sudo apt update
sudo apt --yes upgrade
sudo apt install --yes ntpdate nginx ifupdown virtualenv sshfs tcl tk tcl-dev tk-dev build-essential wget cmake libboost-all-dev libprotoc-dev libprotoc-dev libbz2-dev protobuf-compiler rsync
echo "Completed"

echo "Creating Host-Only-Network"
echo -e "#Host only network\nauto enp0s8\niface enp0s8 inet static\n\t\taddress 192.168.56.106\n\t\tnetmask 255.255.255.0\n\t\tnetwork 192.168.56.0\n\t\tbroadcast 192.168.56.255" | sudo tee /etc/network/interfaces
sudo ifup enp0s8
echo "Completed"

# echo "Setting Time"
# timedatectl set-timezone 'Asia/Kolkata'
# timedatectl set-time '14:14:43'
# timedatectl set-ntp yes
# echo "Completed"

echo "Downloading Anaconda 3 Edition 2021-05"
wget https://repo.anaconda.com/archive/Anaconda3-2021.05-Linux-x86_64.sh
chmod +x Anaconda3-2021.05-Linux-x86_64.sh
./Anaconda3-2021.05-Linux-x86_64.sh -b -p $MODULE_PREFIX/anaconda3
rm -rf Anaconda3-2021.05-Linux-x86_64.sh
echo "Completed"

echo "Downloading Environment Module"
wget https://github.com/cea-hpc/modules/archive/refs/tags/v4.7.1.tar.gz
tar -xvf v4.7.1.tar.gz
cd modules-4.7.1
./configure --prefix=$MODULE_PREFIX/environment_modules --modulefilesdir=$MODULE_PREFIX/modules
make -j 20 && make install
cd ..
rm -rf v4.7.1.tar.gz modules-4.7.1 $MODULE_PREFIX/modules
cd $MODULE_PREFIX
echo "Completed"

echo "Downloading all required modules"
git clone --recursive https://github.com/animesh-server-dot-files/modules.git modules_source
mkdir -p modules/python
mkdir -p modules/golang
mkdir -p modules/nextstrain
mkdir -p modules/usher
mkdir -p modules/anaconda
ln modules_source/python/3.9.5 modules/python/3.9.5
ln modules_source/python/2.7.18 modules/python/2.7.18
ln modules_source/golang/1.16.4 modules/golang/1.16.4
ln modules_source/nextstrain/1.0.0_a9 modules/nextstrain/1.0.0_a9
ln modules_source/usher/0.3 modules/usher/0.3
ln modules_source/anaconda/3-2021.05 modules/anaconda/3-2021.05
. $MODULE_PREFIX/environment_modules/init/bash
echo "Completed"

echo "Downloading and Building required go packages"
module load golang/1.16.4
go get -u -ldflags="-s -w" github.com/gokcehan/lf
go get github.com/cov-ert/gofasta
echo "Completed"

echo "Building UShER"
cd modules_source/usher/v0.3/source
mkdir -p usher_build && cd usher_build
cmake -DTBB_DIR=${PWD}/../oneTBB-2019_U9  -DCMAKE_PREFIX_PATH=${PWD}/../oneTBB-2019_U9/cmake ..
make -j 20
mkdir -p ../../package
cp parsimony.pb.h parsimony.pb.cc matOptimize usher matUtils ../../package/
cd ../..
rm -rf source/usher_build source/oneTBB-2019_U9/cmake/TBBConfig.cmake source/oneTBB-2019_U9/cmake/TBBConfigVersion.cmake
echo "Completed"

echo "Configuring Anaconda and Installing required packages"
module load anaconda/3-2021.05
conda create --yes -n python_3.9 python=3.9
conda create --yes -n python_2.7 python=2.7
conda config --add channels conda-forge
conda config --add channels bioconda
conda activate python_3.9
conda install --yes mafft iqtree minimap2
conda deactivate
module unload anaconda/3-2021.05
echo "Completed"

echo "Installing required python packages"
module load python/3.9.5
pip install nextstrain-augur snakemake==6.3.0 tqdm bpytop cython arrow pendulum biopython pytools openpyxl
pip install git+https://github.com/cov-lineages/pangolin.git fuzzyset
pip install git+https://github.com/cov-lineages/pangoLEARN.git 
pip install git+https://github.com/cov-lineages/scorpio.git 
pip install git+https://github.com/cov-lineages/constellations.git
echo "Completed"

echo "Installing Rclone"
curl https://rclone.org/install.sh | sudo bash
echo "Completed"

echo "Appending lines to bashrc"
echo 'export MODULE_PREFIX="$HOME/Installed_Package"' >> ~/.bash_profile
echo '. $MODULE_PREFIX/environment_modules/init/bash' >> ~/.bash_profile
echo "module load python/3.9.5 golang/1.16.4 nextstrain/1.0.0_a9 usher/0.3" >> $MODULE_PREFIX/environment_modules/init/modulerc
echo "Completed"