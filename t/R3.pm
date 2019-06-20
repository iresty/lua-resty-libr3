package t::R3;

use lib 'lib';

use Test::Nginx::Socket::Lua::Stream -Base;

repeat_each(2);
log_level('info');
no_long_string();
no_shuffle();

add_block_preprocessor(sub {
    my ($block) = @_;

    my $http_config = $block->http_config // <<_EOC_;
    lua_package_path 'lib/?.lua;;';
    lua_package_cpath './?.so;;';
_EOC_

    $block->set_value("http_config", $http_config);
});

1;
