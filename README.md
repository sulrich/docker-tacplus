# tac_plus container 

minimal build and implementation of the tac_plus server from [marc
huber](https://www.pro-bono-publico.de/projects/). 

uses a container for bulding the binaries and then copies these to a target
container with the misc. additional elements.

## notable files

the `tac_plus.cfg` has the barest of configuration elements in here but does
specify some log files to be placed within `/var/log/tac_plus`. the
`docker-entry.sh` script within the container will generate this for you.  i
find it useful to overlay `/var/log` with a volume mounting of my specification
so i can see these logs.  

additionally, i stick my personal `tac_plus.cfg` file in a personal location
and override this with a binding mount. attempting to redirect tac_plus logs to
STDOUT to facilitate grokking them via `docker logs -f <container_name>` has
been a rabbit hole i haven't really gone down.  it looks like tac_plus seeks or
pays attention to logfile location if you're not using syslog.

#### sample binding mounts

```shell
  -v ${HOME}/clab/etc/tac_plus:/etc/tac_plus
  -v ${HOME}/clab/var/tac_plus:/var/log/tac_plus
```
