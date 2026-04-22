# Install
1.  ```sudo  ln -s ~/nixos-config /etc/nixos```
2.  ```sudo nixos-rebuild switch --flake```
3.  ```nix-shell -p pre-commit --run "pre-commit install"```
4.  ```pre-commit install```
