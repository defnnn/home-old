docker_compose("./docker-compose.yml")

docker_build('letfn/kuma', 'b/kuma')
docker_build('letfn/init', 'b/init')

custom_build('defn/home:jojomomojo', 'make build-jojomomojo', ['b'])

local_resource('cfg init',
  cmd='cat config.tgz | docker-compose run --rm  -T init tar xvfz -',
  resource_deps=['done'])

local_resource('cfg kuma-ingress-app',
  cmd='bash -x libexec/cfg-ingress; bash -x libexec/cfg-app',
  resource_deps=['done'])

local_resource('cfg kuma-control',
  cmd='bash -x libexec/cfg-control',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('cfg kuma-data',
  cmd='bash -x libexec/cfg-data',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('test app',
  cmd='bash -x libexec/test-app',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('save-config',
  cmd='docker-compose run --rm -T init tar cvfz - /config /zerotier /zerotier0 /zerotier1 /zerotier2 > config.tgz',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

