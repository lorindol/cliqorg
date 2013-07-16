
    
# thanks to http://mindreframer.github.io/posts/2013/01-25-the-perfect-puppet-setup-for-vagrant.html

# puppet group
group { "puppet":
  ensure => "present",
}

# the default path for puppet to look for executables
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

# the default file attributes
File { owner => 0, group => 0, mode => 0644 }

# we define run-stages, so we can prepare the system
# to have basic requirements installed
# http://docs.puppetlabs.com/puppet/2.7/reference/lang_run_stages.html

# first stage should do general OS updating/upgrading
stage { 'first': }

# last stage should cleanup/ do something unusual
stage { 'last': }

# declare dependancies
Stage['first'] -> Stage['main'] -> Stage['last']

class apt_get_update{
  exec{'apt-get update': }
}

class apt_get_update_cyclic{
  exec{'apt-get  update': }
}

class apt_ppa(
  $ppa
) {
  $release = $::lsbdistcodename

  include apt::params

  $sources_list_d = $apt::params::sources_list_d

  if ! $release {
    fail('lsbdistcodename fact not available: release parameter required')
  }

  $filename_without_slashes = regsubst($name, '/', '-', G)
  $filename_without_dots    = regsubst($filename_without_slashes, '\.', '_', G)
  $filename_without_ppa     = regsubst($filename_without_dots, '^ppa:', '', G)
  $sources_list_d_filename  = "${filename_without_ppa}-${release}.list"

  $package = $::lsbdistrelease ? {
    /^[1-9]\..*|1[01]\..*|12.04$/ => 'python-software-properties',
    default  => 'software-properties-common',
  }

  if ! defined(Package[$package]) {
    package { $package:
      require => Class['apt_get_update']
    }
  }

  exec { "add-apt-repository-${ppa}":
    command   => "/usr/bin/add-apt-repository ${ppa}",
    creates   => "${sources_list_d}/${sources_list_d_filename}",
    logoutput => 'on_failure',
    require   => [
      Package["${package}"],
    ],
    notify    => Class['apt_get_update_cyclic']
  }

  file { "${sources_list_d}/${sources_list_d_filename}":
    ensure  => file,
    require => Exec["add-apt-repository-${ppa}"],
  }
}

# run apt-get update before anything else runs
class {'apt_get_update':
  stage => first
}

class {'apt_get_update_cyclic': }

class {'apt_ppa':
  stage  => first,
  ppa    => 'ppa:ondrej/php5'
}

if ! defined(Package['python-software-properties']) {
  package { ['python-software-properties']:
    ensure  => 'installed'
  }
}

file { '/home/vagrant/.bash_aliases':
  ensure => 'present',
  source => 'puppet:///modules/puphpet/dot/.bash_aliases',
}

package { [
    'build-essential',
    'vim',
    'curl',
    'screen',
    'bash-completion'
  ]:
  ensure  => 'installed',
}

class { 'apache': }

apache::dotconf { 'custom':
  content => 'EnableSendfile Off',
}

apache::module { 'rewrite': }

apache::vhost { 'cliqorg.local':
  server_name   => 'cliqorg.local',
  serveraliases => [
],
  docroot       => '/srv/cliqorg.local/web/',
  port          => '80',
  env_variables => [
],
  priority      => '1',
}

class { 'php':
  service       => 'apache',
  module_prefix => '',
  require       => Package['apache'],
}

php::module { 'php5-cli': }
php::module { 'php5-common': }
php::module { 'php5-curl': }
php::module { 'php5-imagick': }
php::module { 'php5-intl': }
php::module { 'php5-mcrypt': }
php::module { 'php5-mysqlnd': }
php::module { 'php5-xcache': }

class { 'php::devel':
  require => Class['php'],
}

class { 'php::pear':
  require => Class['php'],
}



php::pecl::module { 'xhprof':
  use_package     => false,
  preferred_state => 'beta',
}

apache::vhost { 'xhprof':
  server_name => 'xhprof',
  docroot     => '/var/www/xhprof/xhprof_html',
  port        => 80,
  priority    => '1',
  require     => Php::Pecl::Module['xhprof']
}


class { 'xdebug':
  service => 'apache',
}

class { 'composer':
  require => Package['php5', 'curl'],
}

puphpet::ini { 'xdebug':
  value   => [
    'xdebug.default_enable = 1',
    'xdebug.remote_autostart = 0',
    'xdebug.remote_connect_back = 1',
    'xdebug.remote_enable = 1',
    'xdebug.remote_handler = "dbgp"',
    'xdebug.remote_port = 9000',
    'xdebug.max_nesting_level = 512',
    'xdebug.var_display_max_data = -1',
    'xdebug.var_display_max_depth = -1',
    'xdebug.var_display_max_children = -1'
  ],
  ini     => '/etc/php5/conf.d/zzz_xdebug.ini',
  notify  => Service['apache'],
  require => Class['php'],
}

puphpet::ini { 'php':
  value   => [
    'date.timezone = "Europe/Berlin"'
  ],
  ini     => '/etc/php5/conf.d/zzz_php.ini',
  notify  => Service['apache'],
  require => Class['php'],
}

puphpet::ini { 'custom':
  value   => [
    'display_errors = On',
    'html_errors = On',
    'error_reporting = "E_ALL | E_STRICT"',
    'error_log = "/var/log/apache2/php_error.log"',
    'log_errors = On',
    'short_open_tag = Off'
  ],
  ini     => '/etc/php5/conf.d/zzz_custom.ini',
  notify  => Service['apache'],
  require => Class['php'],
}



