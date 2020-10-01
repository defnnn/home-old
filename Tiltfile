docker_compose("./docker-compose.yml")
docker_build('letfn/kuma', 'b/kuma')
docker_build('letfn/init', 'b/init')

local_resource('-- config -----',
  cmd='true',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('apply-config',
  cmd='cat config.tgz | docker-compose run --rm  -T init tar xvfz -',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('global-cp',
  cmd='bash -x libexec/global-cp',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('farcast1',
  cmd='bash -x libexec/remote-cp 1; bash -x libexec/app 1',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('farcast2',
  cmd='bash -x libexec/remote-cp 2; bash -x libexec/app 2',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('farcast3',
  cmd='bash -x libexec/remote-cp 3; bash -x libexec/app 3',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('-- tests ------',
  cmd='true',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('test',
  cmd='bash -x libexec/test',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('-- configs ----',
  cmd='true',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

local_resource('save-config',
  cmd='docker-compose run --rm -T init tar cvfz - /config /zerotier /zerotier0 /zerotier1 /zerotier2 > config.tgz',
  trigger_mode=TRIGGER_MODE_MANUAL, auto_init=False)

