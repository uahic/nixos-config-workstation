{
  pkgs,
  unstable,
}: {
  buildInputs = with pkgs; [
    python312
    unstable.uv
    tmux
    unstable.stdenv.cc.cc.lib
    unstable.ollama-cuda
    cudaPackages.cudatoolkit
    unstable.cudaPackages.nsight_systems
    linuxPackages.nvidia_x11
  ];

  shellHook = ''
    export LD_LIBRARY_PATH="${unstable.stdenv.cc.cc.lib}/lib:/run/opengl-driver/lib:$LD_LIBRARY_PATH"
    export CUDA_PATH=${pkgs.cudaPackages.cudatoolkit}
    export TRITON_LIBCUDA_PATH=/run/opengl-driver/lib

    if [ ! -d .venv ]; then
      uv venv
    fi
    source .venv/bin/activate

    echo "Entered $(basename $PWD) environment"
  '';
}
