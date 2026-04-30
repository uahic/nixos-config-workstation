# Install
1.  ```sudo  ln -s ~/nixos-config /etc/nixos```
2.  ```sudo nixos-rebuild switch --flake```
3.  ```nix-shell -p pre-commit --run "pre-commit install"```
4.  ```pre-commit install```



For games like SWG (enable borderless window) + this as launch options
SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0 PROTON_NO_GRAB=1 %command%
