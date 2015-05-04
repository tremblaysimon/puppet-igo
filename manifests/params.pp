# params.pp

class igo::params {

  $igoRootPath  = '/var/igoroot'
  $databaseName = 'postgres'
  $appUser      = 'vagrant'
  $appGroup     = 'vagrant'
}
