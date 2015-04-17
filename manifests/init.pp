# Class: igo
#
# This module manages igo
#
# Parameters: none
#
# Actions:
#
# Requires: see metadata.json
#
# Sample Usage:
#
class igo {

  $apacheDocRootPath = '/var/www'

  class { 'apache': 
    mpm_module => 'prefork',
    default_vhost => false,
    user         => 'vagrant',
    group        => 'vagrant'
  }
  class {'::apache::mod::php': }
  class {'::apache::mod::rewrite': }
  class {'::apache::mod::cgi': }

apache::vhost { 'projeqtorquebec':
  vhost_name       => '*',
  port             => '80',
  docroot          => $apacheDocRootPath,
  docroot_owner    => 'vagrant',
  docroot_group    => 'vagrant',
  directories      => 
  [
    {
      'path'     => $apacheDocRootPath,
      'provider' => 'directory',
      'options'  => ['Indexes','FollowSymLinks','MultiViews'],
      'deny'     => 'from all',
      'allow_override' => 'All'
    },
  ],
}

# TODO: A confirmer.
file { '/var/www':
  ensure => 'link',
  target => '/vagrant',
  force  => true
}

  package {'cgi-mapserver':
    ensure => '6.4.1-2'
  }

  package {'mapserver-bin':
    ensure => '6.4.1-2'
  }

  package {'gdal-bin':
    ensure => '6.4.1-2'
  }

  package {'gcc': }
  package {'make': }
  package {'libpcre3-dev': }
  
  class { 'php': }
  class { 'php::dev': }

  class { 'php::extension::curl': }
  class { 'php::extension::intl': }
  class { 'php::extension::mapscript': }
  class { 'php::extension::pgsql': }  

}
