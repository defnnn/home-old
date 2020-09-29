docker_compose("./docker-compose.yml")
docker_build('letfn/kuma', 'b/kuma')
local_resource('--------------:',
  cmd='true',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)
local_resource('global-cp',
  cmd='bash -x libexec/meh-global-cp',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)
local_resource('farcast1-cp',
  cmd='bash -x libexec/meh-farcast1',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)
local_resource('farcast2-cp',
  cmd='bash -x libexec/meh-farcast2',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)
local_resource('farcast1-app',
  cmd='bash -x libexec/meh-app1',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)
local_resource('farcast2-app',
  cmd='bash -x libexec/meh-app2',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)
local_resource('-------------:-',
  cmd='true',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)
local_resource('save-config',
  cmd='docker-compose run --rm -T init tar cvfz - /config /zerotier0 /zerotier1 /zerotier2 > config.tgz',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)
local_resource('apply-config',
  cmd='cat config.tgz | docker-compose run --rm  -T init tar xvfz -; docker-compose exec -T init touch /tmp/done.txt',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)
