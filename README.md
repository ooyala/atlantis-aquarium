atlantis-aquarium
=================

Atlantis in a Vagrant VM!  Excellent for testing.

Control is primarily through the controller, bin/atlantis-aquarium (which should probably become a gem or
other easily-installable package at some point).  Initial bootstrap can also be done via the makeitso script,
until its functionality is fully subsumed in an elegant way into the main script.

```
Usage:
  atlantis-aquarium build   [<component>...] [options] [-C | --compile] [-I | --image]
  atlantis-aquarium start   [<component>...] [options]
  atlantis-aquarium restart  <component>...  [options]
  atlantis-aquarium stop     <component>...  [options]
  atlantis-aquarium ssh     [<component>]    [options]
  atlantis-aquarium atlantis [--] [<argument>...]
  atlantis-aquarium provision
  atlantis-aquarium register-components
  atlantis-aquarium base-cluster
  atlantis-aquarium build-layers  [--base] [--builder]
  atlantis-aquarium nuke-system

Options:
  -C, --compile  Only compile; don't build image or deploy
  -I, --image    Only compile and build Docker image; don't deploy
  -i, --instance Which instance of the component to act on [default: all]
  -h, --help     Show usage
```

### Common options

The most common options take components - one of base-aquarium-image, builder, manager, registry, router,
supervisor, and zookeeper (or "all", which is also the default when component is optional).  All but
base-aquarium-image are services run in docker containers; base-aquarium-image is a special target to build
the base image that other components run inside.

These options can also take an instance in the case of supervisor or router; valid supervisor instances are 1,
2, and 3, and valid router instances are internal and external.

- build: Compile, build the container, and (re)start the given component.  With -C, only compiles, and with
  -I, compiles and builds container but doesn't restart.  If an instance is given, only that instance will be
  restarted.  

- start: Ensure that the component is running.  If it is already running, it won't be restarted.

- restart: Restart the container.  If it is running, it will be stopped and then started; if not, it will just
  be started.  Note that this restarts the container, so any data stored within it will be lost.  (E.g.,
  restarting Zookeeper will destroy all metadata about the cluster.

- stop: Ensure that the component is not running.  If it is already stopped, no action is taking.

- ssh: ssh into the container for the given component/instance.  If no instance is given for supervisor or
  router, each instance will be ssh'd into in turn.  If no component is given, ssh into the Vagrant VM
  instead.

### Convenience wrapper for atlantis command

The atlantis subcommand will pass remaining arguments to the atlantis command run within the VM; this is
a convenience, e.g., for `atlantis ssh \[container\]`

### Setup options

The remaining options are useful primarily for setting up the system:

- provision: provision the container: install go, setup docker, etc.  Should be done with a fresh VM.

- register-components: Register the supervisors, routers, etc. with the manager.  Should be done once after
  all components are started, or after zookeeper is restarted.

- base-cluster: Set up some sample hello-* apps and deploy them.  Useful as a test to ensure everything is
  working.

- build-layers [--base] [--builder]: Build the layers required for deploying.  Only needed for the simple
  builder.  --base builds only the base image; --builder builds only the language-specific layers (e.g.,
  ruby1.9.3, go1.2).  Should be done when layers are modifed or the builder is restarted.

- nuke-system: Tear down everything!  Currently unimplemented.
