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
- https://medium.com/codex/run-your-docker-containers-for-free-in-the-cloud-and-for-unlimited-time-361515cb0876
- https://www.analyticsvidhya.com/blog/2023/03/top-4-cloud-platforms-to-host-or-run-docker-containers-for-free/#Render
- https://docs.snowflake.com/en/user-guide/intro-key-concepts
- https://docs.mindsdb.com/setup/self-hosted/docker

## Docs

gh release create v0.1.0 --title "v0.1.0 (beta)" --notes "this is a beta release" --prerelease

docker run --rm -d -p 8080:8080 --name metatrader -v metatrader:/data metatrader:5

```sql
    DROP DATABASE IF EXISTS wisefinance_db;
```

### Start MindsDB

Run the command below to start MindsDB in Docker.

```bash
   docker run -p 47334:47334 -p 47335:47335 mindsdb/mindsdb
```

If you wish to simply spin up the container without the logs, run the following command:
```bash
   docker run -d -p 47334:47334 -p 47335:47335 mindsdb/mindsdb
```
