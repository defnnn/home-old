def test_tmux_is_installed(host):
    tmux = host.package("tmux")
    assert tmux.is_installed
