# Wise Finance Metatrader Interface

Metatrader application interface

## Execution

**For MT5:**

```bash
cd MT5
make run

```

**For MT4:**

```bash
cd MT4
make run

```

Goto http://localhost:8080/

## Note

- MT4 is not fully supported yet

## TODOs

- Limit the number of desktop windows to just 1, currently it is about 4 by default
- Add encryption to the novnc connection
- Add a proxy server like caddy to proxy the connection instead
- noVNC does not seem to fully support copy and paste (find a solution)
- Disable Metaeditor and any other graphical tool apart from MetaTrader
- Disable the noVNC control bar

## Resources

- https://github.com/ConSol/docker-headless-vnc-container
- https://github.com/novnc/noVNC#quick-start
- https://hub.docker.com/r/fredblgr/ubuntu-novnc
- https://askubuntu.com/questions/229989/how-to-setup-x11vnc-to-access-with-graphical-login-screen
- https://github.com/theasp/docker-novnc
- https://hub.docker.com/r/engineervix/pyinstaller-windows
- https://stackoverflow.com/questions/64173592/how-can-i-correctly-install-run-pip-in-a-wine-emulated-python-version-inside
- https://hub.docker.com/r/x11docker/xfce-wine-playonlinux
- https://github.com/mviereck/x11docker#installation-from-distribution-repositories
- https://github.com/fcwu/docker-ubuntu-vnc-desktop
- https://github.com/hdavid0510/docker-ubuntu-lxde-novnc
- https://hub.docker.com/r/dorowu/ubuntu-desktop-lxde-vnc
- https://github.com/novnc/noVNC
- https://github.com/TurboVNC/tightvnc
- https://github.com/pgaskin/easy-novnc
- https://faun.pub/how-to-push-docker-image-using-github-actions-694397c4f557
- https://blog.derlin.ch/github-actions-reusable-workflow-docker-images
- https://stackoverflow.com/questions/5480258/how-can-i-delete-a-remote-tag
