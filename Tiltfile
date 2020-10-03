docker_compose("./docker-compose.yml")
docker_build('letfn/kuma', 'b/kuma')
docker_build('letfn/init', 'b/init')

local_resource('cfg init',
  cmd='cat config.tgz | docker-compose run --rm  -T init tar xvfz -',
  deps=['init-done'])

local_resource('cfg kuma-global',
  cmd='sleep 60; bash -x libexec/cfg-global',
  deps=['kuma-global-done'])

local_resource('cfg kuma-remote',
  cmd='sleep 60; bash -x libexec/cfg-remote; bash -x libexec/cfg-app',
  deps=['kuma-done'])

local_resource('test app',
  cmd='sleep 60; bash -x libexec/test-app',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('save-config',
  cmd='docker-compose run --rm -T init tar cvfz - /config /zerotier /zerotier0 /zerotier1 /zerotier2 > config.tgz',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

