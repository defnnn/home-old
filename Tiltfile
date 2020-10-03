docker_compose("./docker-compose.yml")

docker_build('letfn/kuma', 'b/kuma')
docker_build('letfn/init', 'b/init')

local_resource('cfg init',
  cmd='cat config.tgz | docker-compose run --rm  -T init tar xvfz -',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('cfg kuma-ingress-app',
  cmd='bash -x libexec/cfg-ingress; bash -x libexec/cfg-app',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('cfg kuma-control',
  cmd='bash -x libexec/cfg-control',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('cfg kuma-dataplane-tokens',
  cmd='bash -x libexec/cfg-dataplane-tokens',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('test app',
  cmd='bash -x libexec/test-app',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('save-config',
  cmd='docker-compose run --rm -T init tar cvfz - /config /zerotier /nginx1 /nginx2 /zerotier0 /zerotier1 /zerotier2 > config.tgz',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

