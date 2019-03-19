# ================================================================
# Compile ONNXRuntime
# ================================================================

[ -e $STAGE/ort ] && ( set -xe
    cd $SCRATCH

    "$ROOT_DIR/pkgs/utils/pip_install_from_git.sh" numpy/numpy,v

    # ------------------------------------------------------------

    . "$ROOT_DIR/pkgs/utils/git/version.sh" Microsoft/onnxruntime,v
    until git clone --single-branch -b "$GIT_TAG" "$GIT_REPO"; do echo 'Retrying'; done
    cd onnxruntime

    git remote add patch https://github.com/xkszltl/onnxruntime.git

    PATCHES=""

    for i in $PATCHES; do
        git pull --no-edit --rebase patch "$i"
    done

    . "$ROOT_DIR/pkgs/utils/git/submodule.sh"

    (
        set -xe

        cd cmake/external

        rm -rf googletest protobuf
        cp -rf /usr/local/src/{gtest,protobuf} ./
        mv gtest googletest

        for i in ./*.cmake; do
            sed -i "s/$(sed 's/\([\/\.]\)/\\\1/g' <<< "$GIT_MIRROR_GITHUB")\(\/..*\/.*\.git\)/$(sed 's/\([\/\.]\)/\\\1/g' <<< "$GIT_MIRROR")\1/" "$i"
        done
    )

    # ------------------------------------------------------------

    . "$ROOT_DIR/pkgs/utils/fpm/pre_build.sh"

    (
        set +xe
        . scl_source enable devtoolset-8 rh-python36
        . "/opt/intel/mkl/bin/mklvars.sh" intel64
        set -xe

        . "$ROOT_DIR/pkgs/utils/fpm/toolchain.sh"

        mkdir -p build
        cd $_

        cmake                                               \
            -DCMAKE_BUILD_TYPE=Release                      \
            -DCMAKE_C_COMPILER=gcc                          \
            -DCMAKE_CXX_COMPILER=g++                        \
            -DCMAKE_{C,CXX,CUDA}_COMPILER_LAUNCHER=ccache   \
            -DCMAKE_C{,XX}_FLAGS="-fdebug-prefix-map='$SCRATCH'='$INSTALL_PREFIX/src' -g"   \
            -DCMAKE_INSTALL_PREFIX="$INSTALL_ABS"           \
            -DCMAKE_POLICY_DEFAULT_CMP0003=NEW              \
            -DCMAKE_POLICY_DEFAULT_CMP0060=NEW              \
            -DCMAKE_VERBOSE_MAKEFILE=ON                     \
            -DONNX_CUSTOM_PROTOC_EXECUTABLE="/usr/local/bin/protoc" \
            -Deigen_SOURCE_PATH="/usr/local/include/eigen3" \
            -Donnxruntime_BUILD_SHARED_LIB=ON               \
            -Donnxruntime_CUDNN_HOME='/usr/local/cuda'      \
            -Donnxruntime_ENABLE_PYTHON=ON                  \
            -Donnxruntime_RUN_ONNX_TESTS=ON                 \
            -Donnxruntime_USE_CUDA=ON                       \
            -Donnxruntime_USE_JEMALLOC=OFF                  \
            -Donnxruntime_USE_LLVM=ON                       \
            -Donnxruntime_USE_MKLDNN=ON                     \
            -Donnxruntime_USE_MKLML=ON                      \
            -Donnxruntime_USE_OPENMP=ON                     \
            -Donnxruntime_USE_PREBUILT_PB=ON                \
            -Donnxruntime_USE_PREINSTALLED_EIGEN=ON         \
            -Donnxruntime_USE_TVM=OFF                       \
            -G"Ninja"                                       \
            ../cmake

        time cmake --build .
        time cmake --build . --target install

        if [ "_$GIT_MIRROR" == "_$GIT_MIRROR_CODINGCAFE" ]; then
            curl -sSL 'https://repo.codingcafe.org/microsoft/onnxruntime/20181210.zip' > 'models.zip'
        else
            axel -n200 -o 'models.zip' 'https://onnxruntimetestdata.blob.core.windows.net/models/20181210.zip'
        fi

        md5sum -c <<< 'a966def7447f4ff04f5665bca235b3f3 models.zip'
        unzip -o models.zip -d ../models
        rm -rf models.zip

        time cmake --build . --target test || ! nvidia-smi

        python ../setup.py bdist_wheel --use_cuda
        pushd dist
        ../../rename_manylinux.sh
        sudo python -m pip install -IU ./*-manylinux1_*.whl
        popd

        # Exclude MKL-DNN/ONNX files.
        pushd "$INSTALL_ROOT"
        rpm -ql codingcafe-mkl-dnn | sed -n 's/^\//\.\//p' | xargs rm -rf
        rpm -ql codingcafe-onnx | sed -n 's/^\//\.\//p' | xargs rm -rf
        popd
    )

    "$ROOT_DIR/pkgs/utils/fpm/install_from_git.sh"
    
    # ------------------------------------------------------------

    cd
    rm -rf $SCRATCH/onnxruntime
)
sudo rm -vf $STAGE/ort
sync || true
