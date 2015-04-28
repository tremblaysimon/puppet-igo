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
  
  $databaseName = 'postgres'

  $pgsqlScriptPath = '/usr/share/postgresql/9.3/contrib/postgis-2.1'


  class { 'apache': 
    mpm_module => 'prefork',
    default_vhost => false,
    user         => 'vagrant',
    group        => 'vagrant'
  }
  class {'::apache::mod::php': }
  class {'::apache::mod::rewrite': }
  class {'::apache::mod::cgi': }

  apache::vhost { 'igo':
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
  
  class { 'postgresql::server':
    postgres_password => 'postgres'
  }
  
  class {'postgresql::server::postgis':}


  #TODO: Not the cleaniest way to do that (should avoid sequence of exec resources).
  exec { "createlang-plpgsql":
    command => "createlang plpgsql ${databaseName}",
    path => "/usr/bin",
    require => Class['postgresql::server::postgis'],
    returns => [0, 2]
  }

  exec { "psql-postgis":
    command => "psql -d ${databaseName} -f ${pgsqlScriptPath}/postgis.sql",
    path => "/usr/bin",
    require => Exec['createlang-plpgsql']
  }

  exec { "psql-postgis_comments":
    command => "psql -d ${databaseName} -f ${pgsqlScriptPath}/postgis_comments.sql",
    path => "/usr/bin",
    require => Exec['psql-postgis']
  }

  exec { "psql-spatial_ref_sys":
    command => "psql -d ${databaseName} -f ${pgsqlScriptPath}/spatial_ref_sys.sql",
    path => "/usr/bin",
    require => Exec['psql-postgis_comments']
  }
  
  vcsrepo { '/var/tmp/cphalcon':
    ensure   => present,
    provider => git,
    source   => 'git://github.com/phalcon/cphalcon.git',
    depth    => 1
  }
  
  exec { 'installAndBuild-cphalcon':
    command => "./install",
    cwd => '/var/tmp/cphalcon/build'
    path => "/usr/bin",
    require => Vcsrepo['/var/tmp/cphalcon']    
  }

  php::config { 'extension=phalcon.so':
    file => '/etc/php5/apache2/conf.d/30-phalcon.ini'
  }

  # TODO: Change to official librairie git depot when it will be available.
  vcsrepo { '/vagrant/librairie':
    ensure   => present,
    provider => git,
    source   => 'https://gitlab.forge.gouv.qc.ca/simon.tremblay/librairie.git',
    depth    => 1
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

#
#Configurer le fichier igo/config/config.php
#
#Modifier les deux valeurs de l'array uri suivantes:
#
#'navigateur' => "/navigateur/" 'librairie' => "/librairie/"

}
