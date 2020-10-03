docker_compose("./docker-compose.yml")
docker_build('letfn/kuma', 'b/kuma')
docker_build('letfn/init', 'b/init')

local_resource('cfg init',
  cmd='cat config.tgz | docker-compose run --rm  -T init tar xvfz -',
  resource_deps=['init-done'])

local_resource('cfg kuma-global',
  cmd='bash -x libexec/cfg-global',
  resource_deps=['kuma-global-done'])

local_resource('cfg kuma-remote',
  cmd='bash -x libexec/cfg-remote; bash -x libexec/cfg-app',
  resource_deps=['kuma-done'])

local_resource('test app',
  cmd='bash -x libexec/test-app',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('save-config',
  cmd='docker-compose run --rm -T init tar cvfz - /config /zerotier /zerotier0 /zerotier1 /zerotier2 > config.tgz',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

