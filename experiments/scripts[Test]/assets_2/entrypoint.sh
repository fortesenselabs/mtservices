#!/bin/bash
set -ex

HOME='/root'
RUN_FLUXBOX=${RUN_FLUXBOX:-yes}
RUN_XTERM=${RUN_XTERM:-yes}

case $RUN_FLUXBOX in
    false|no|n|0)
        rm -f ${HOME}/vnc/conf.d/fluxbox.conf
    ;;
esac

case $RUN_XTERM in
    false|no|n|0)
        rm -f ${HOME}/vnc/conf.d/xterm.conf
    ;;
esac

exec supervisord -c ${HOME}/vnc/supervisord.conf