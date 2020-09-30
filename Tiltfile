docker_compose("./docker-compose.yml")
docker_build('letfn/kuma', 'b/kuma')

local_resource('-- config -----',
  cmd='true',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('global-cp',
  cmd='bash -x libexec/global-cp',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('farcast1-cp',
  cmd='bash -x libexec/farcast1; bash -x libexec/app1',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('farcast2-cp',
  cmd='bash -x libexec/farcast2; bash -x libexec/app2',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('-- tests ------',
  cmd='true',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('test',
  cmd='bash libexec/test',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('-- configs ----',
  cmd='true',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('save-config',
  cmd='docker-compose run --rm -T init tar cvfz - /config /zerotier0 /zerotier1 /zerotier2 > config.tgz',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('apply-config',
  cmd='cat config.tgz | docker-compose run --rm  -T init tar xvfz -; docker-compose exec -T init touch /tmp/done.txt',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)
