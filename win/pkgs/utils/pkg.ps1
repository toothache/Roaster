
function GetNugetVersion()
{
    $versionPrefix = 'v'

    pushd $PSScriptRoot
    $rawVersion = git describe --long --match ($versionPrefix+'*')
    popd

    $time    = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmssfffffff")
    $iter    = $rawVersion.split('-')[-2]
    $hash    = $rawVersion.split('-')[-1]
    $tag     = $rawVersion.split('-')[0].split('/')[-1]

    # NuGet drops some trailing zero.
    $nullable_iter = '.' + $iter
    if ($iter -eq '0')
    {
        $nullable_iter = ''
    }
    $nullable_iter = ''

    $version = $tag.TrimStart($versionPrefix) + $nullable_iter + '-T' + $time + $hash

    return $version, $tag, $iter, $hash
}


function GetLowerCaseSemanticVersion()
{
    $versionPrefix = 'v'

    pushd $PSScriptRoot
    $rawVersion = git describe --long --match ($versionPrefix+'*')
    popd

    $time    = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmssfffffff")
    $iter    = $rawVersion.split('-')[-2]
    $hash    = $rawVersion.split('-')[-1]
    $tag     = $rawVersion.split('-')[0].split('/')[-1]

    $version = $tag.TrimStart($versionPrefix) + '-' + $time + $hash

    return $version
}


function GetPackageName()
{
    Param(
        [Parameter(Mandatory = $True)]
        [string] $pkg,
        [string] $msvc_ver = 'v142'
    )

    return "Roaster.$pkg.$msvc_ver.dyn.x64"
}


function GetPackageDescription()
{
    Param(
        [Parameter(Mandatory = $True)]
        [string] $pkg
    )

    $nuspec_dir = "$PSScriptRoot/../../nuget/$pkg"
    if (-Not (Test-Path $nuspec_dir))
    {
        Write-Host "Unable to find package description for `"$pkg`"."
        exit 1
    }

    $nuspec_path = "$nuspec_dir/$(GetPackageName $pkg v141).nuspec"
    [XML]$spec = Get-Content $nuspec_path
    $metadata = $spec.package.metadata
    return "$($metadata.summary)`n`n$($metadata.description)"
}


function GetPackagePrefix()
{
    Param(
        [Parameter(Mandatory = $True)]
        [string] $pkg
    )

    if ($pkg -eq "cuda" -or $pkg -eq "cublas" -or $pkg -eq "cufft" -or $pkg -eq "cusolver" -or $pkg -eq "cusparse")
    {
        $prefix = "${Env:ProgramFiles}/NVIDIA GPU Computing Toolkit/CUDA/v11.1"
    }
    elseif ($pkg -eq "cudnn" -or $pkg -eq "cudnn_adv" -or $pkg -eq "cudnn_cnn" -or $pkg -eq "cudnn_ops")
    {
        $prefix = "${Env:ProgramFiles}/NVIDIA GPU Computing Toolkit/CUDA/v11.1"
    }
    elseif ($pkg -eq "eigen")
    {
        $prefix = "${Env:ProgramFiles}/Eigen3"
    }
    elseif ($pkg -eq "jsoncpp" -or $pkg -eq "jsoncpp-dev")
    {
        $prefix = "${Env:ProgramFiles}/jsoncpp"
    }
    elseif ($pkg -eq "mkldnn" -or $pkg -eq "mkldnn-dev")
    {
        $prefix = "${Env:ProgramFiles}/oneDNN"
    }
    elseif ($pkg -eq "onnx" -or $pkg -eq "onnx-dev")
    {
        $prefix = "${Env:ProgramFiles}/ONNX"
    }
    elseif ($pkg -eq "opencv" -or $pkg -eq "opencv-dev")
    {
        $prefix = "${Env:ProgramFiles}/opencv"
    }
    elseif ($pkg -eq "protobuf" -or $pkg -eq "protobuf-dev")
    {
        $prefix = "${Env:ProgramFiles}/protobuf"
    }
    elseif ($pkg -eq "rocksdb" -or $pkg -eq "rocksdb-dev")
    {
        $prefix = "${Env:ProgramFiles}/rocksdb"
    }
    elseif ($pkg -eq "caffe2" -or $pkg -eq "caffe2-dev" -or $pkg -eq "caffe2-debuginfo")
    {
        $prefix = "${Env:ProgramFiles}/Caffe2"
    }
    elseif ($pkg -eq "pytorch" -or $pkg -eq "pytorch-dev" -or $pkg -eq "pytorch-debuginfo")
    {
        $prefix = "${Env:ProgramFiles}/Caffe2"
    }
    elseif ($pkg -eq "cream" -or $pkg -eq "cream-dev")
    {
        $prefix = "${Env:ProgramFiles}/Cream"
    }
    elseif ($pkg -eq "ort" -or $pkg -eq "ort-dev")
    {
        $prefix = "${Env:ProgramFiles}/onnxruntime"
    }
    elseif ($pkg -eq "mkl" -or $pkg -eq "mkl-vml" -or $pkg -eq "mkl-dev")
    {
        $prefix = "${Env:ProgramFiles(x86)}/IntelSWTools"
    }
    elseif ($pkg -eq "daal" -or $pkg -eq "daal-dev" -or $pkg -eq "iomp" -or $pkg -eq "ipp" -or $pkg -eq "ipp-dev" -or $pkg -eq "mpi" -or $pkg -eq "tbb")
    {
        $prefix = "${Env:ProgramFiles(x86)}/IntelSWTools"
    }
    elseif ($pkg -eq "c-ares")
    {
        $prefix = "${Env:ProgramFiles(x86)}/c-ares"
    }
    elseif ($pkg -eq "grpc")
    {
        $prefix = "${Env:ProgramFiles(x86)}/grpc"
    }
    elseif ($pkg -eq "benchmark")
    {
        $prefix = "${Env:ProgramFiles(x86)}/benchmark"
    }
    else
    {
        $prefix = "${Env:ProgramFiles}/$pkg"
    }

    return $prefix
}

function PreparePackageData()
{
    Param(
        [Parameter(Mandatory = $True)]
        [string] $pkg,
        [Parameter(Mandatory = $True)]
        [string] $dest_dir
    )

    $prefix = GetPackagePrefix $pkg
    
}

