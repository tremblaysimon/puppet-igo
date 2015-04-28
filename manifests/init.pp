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

  $apacheDocRootPath = '/var/www/html'

  $databaseName = 'postgres'

  $pgsqlScriptPath = '/usr/share/postgresql/9.3/contrib/postgis-2.1'


  include apache::mod::rewrite
  include apache::mod::cgi

  class { 'apache':
    mpm_module => 'prefork',
    default_vhost => false,
    user         => 'vagrant',
    group        => 'vagrant'
  }
  class { '::apache::mod::php': }

  apache::vhost { 'igo':
    vhost_name       => '*',
    port             => '80',
    docroot          => $apacheDocRootPath,
    docroot_owner    => 'vagrant',
    docroot_group    => 'vagrant',
    aliases => [
      { alias            => '/pilotage',
        path             => '/var/www/html/igo/pilotage/',
      },
      { alias            => '/navigateur/',
        path             => '/var/www/html/igo/interfaces/navigateur/',
      },
      { alias            => '/api/',
        path             => '/var/www/html/igo/interfaces/navigateur/api/',
      }
    ],
    directories      =>
    [
      {
        path      => '/var/www/html/igo/pilotage/',
        provider  => 'directory',
        php_value => 'max_input_vars 2000',
        rewrites => [
                      {
                        rewrite_rule => [ '^$ public/    [L]' ]
                      },
                      {
                        rewrite_rule => [ '(.*) public/$1 [L]' ]
                      }

                    ]
      },
      {
        path      => '/var/www/html/igo/pilotage/public/',
        provider  => 'directory',
        add_default_charset => 'UTF-8',
        rewrites => [
                      {
                        rewrite_cond => [ '%{REQUEST_FILENAME} !-d' ]
                      },
                      {
                        rewrite_cond => [ '%{REQUEST_FILENAME} !-f' ]
                      },
                      {
                        rewrite_rule => [ '^(.*)$ index.php?_url=/$1 [QSA,L]' ]
                      }
                    ]
      },
      {
        path      => '/var/www/html/igo/interfaces/navigateur/',
        provider  => 'directory',
        rewrites => [
                      {
                        rewrite_rule => [ '^$ public/    [L]' ]
                      },
                      {
                        rewrite_rule => [ '(.*) public/$1 [L]' ]
                      }
                    ]
      },
      {
        path      => '/var/www/html/igo/interfaces/navigateur/public/',
        provider  => 'directory',
        add_default_charset => 'UTF-8',
        rewrites => [
                      {
                        rewrite_cond => [ '%{REQUEST_FILENAME} !-d' ]
                      },
                      {
                        rewrite_cond => [ '%{REQUEST_FILENAME} !-f' ]
                      },
                      {
                        rewrite_rule => [ '^(.*)$ index.php?_url=/$1 [QSA,L]' ]
                      }
                    ]
      },
      {
        path      => '/var/www/html/igo/interfaces/navigateur/api/',
        provider  => 'directory',
        rewrites => [
                      {
                        rewrite_cond => [ '%{REQUEST_FILENAME} !-f' ]
                      },
                      {
                        rewrite_rule => [ '^(.*)$ index.php?_url=/$1 [QSA,L]' ]
                      }
                    ]
      },
    ],
  }

  file { '/var/www/html/igo':
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

  package {'gdal-bin': }

  package {'gcc': }
  package {'make': }
  package {'libpcre3-dev': }

  package {'git': }

  class { 'php': }
  class { 'php::dev': }

  class { 'php::extension::curl': }
  class { 'php::extension::intl': }
  class { 'php::extension::mapscript': }
  class { 'php::extension::pgsql': }

  class { 'postgresql::server':
    postgres_password => 'postgres'
  }

  class {'postgresql::server::postgis':}

  #TODO: Not the cleaniest way to do that (should avoid sequence of exec resources).
  exec { "createlang-plpgsql":
    command => "createlang plpgsql ${databaseName}",
    path => "/usr/bin",
    user => 'postgres',
    require => Class['postgresql::server::postgis'],
    returns => [0, 2]
  }

  exec { "psql-postgis":
    command => "psql -d ${databaseName} -f ${pgsqlScriptPath}/postgis.sql",
    path => "/usr/bin",
    user => 'postgres',
    require => Exec['createlang-plpgsql']
  }

  exec { "psql-postgis_comments":
    command => "psql -d ${databaseName} -f ${pgsqlScriptPath}/postgis_comments.sql",
    path => "/usr/bin",
    user => 'postgres',
    require => Exec['psql-postgis']
  }

  exec { "psql-spatial_ref_sys":
    command => "psql -d ${databaseName} -f ${pgsqlScriptPath}/spatial_ref_sys.sql",
    path => "/usr/bin",
    user => 'postgres',
    require => Exec['psql-postgis_comments']
  }

  vcsrepo { '/var/tmp/cphalcon':
    ensure   => present,
    provider => git,
    source   => 'git://github.com/phalcon/cphalcon.git',
    revision => 'phalcon-v1.3.1',
    require  => Package['git']
  }

  exec { 'installAndBuild-cphalcon':
    command => "./install",
    cwd => '/var/tmp/cphalcon/build',
    path => ['/usr/bin', '/bin'],
    require => [
                 Vcsrepo['/var/tmp/cphalcon'],
                 Class['php::dev']
               ]
  }

  file { '/etc/php5/apache2/conf.d/30-phalcon.ini':
    content => 'extension=phalcon.so',
    require => [
                 Class['php'],
                 Class['apache']
               ]
  }

  # TODO: Change to official librairie git depot when it will be available.
  vcsrepo { '/var/www/html/librairie':
    ensure   => present,
    provider => git,
    source   => 'https://gitlab.forge.gouv.qc.ca/simon.tremblay/librairie.git',
    depth    => 1,
    require => [
                 Package['git'],
                 Class['apache']
               ]
  }

  file { '/var/www/html/igo/interfaces/navigateur/app/cache':
    owner => 'vagrant',
    group => 'vagrant',
    mode => '0775'
  }

  file { '/var/www/html/igo/pilotage/app/cache':
    owner => 'vagrant',
    group => 'vagrant',
    mode => '0775'
  }

  file {'/vagrant/config/config.php':
    owner => 'vagrant',
    group => 'vagrant',
    source => '/vagrant/config/config.exemple.php'
  }

  file_line { 'config-navigateur':
    path => '/vagrant/config/config.php',
    line => '\'navigateur\'    => "/navigateur/",',
    match => '\'navigateur\'    => "\/igo_navigateur\/",',
    require => File['/vagrant/config/config.php']
  }

  file_line { 'config-librairie':
    path => '/vagrant/config/config.php',
    line => '\'librairies\'    => "/librairie/",',
    match => '\'librairies\'    => "\/igo\/librairie\/",',
    require => File['/vagrant/config/config.php']
  }

}
