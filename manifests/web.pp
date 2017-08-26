# = Class: icinga2::web
#
# Sets up an apache instance for icinga web interface,
# protected with ldap authentication
class icinga2::web(
    $icingaweb_db_host = hiera('icingaweb_db_host'),
    $icingaweb_db_name = hiera('icingaweb_db_name'),
    $icingaweb_user_name = hiera('icingaweb_user_name'),
    $icingaweb_password = hiera('icingaweb_password'),
    $icinga_ido_db_host = hiera('icinga_ido_db_host'),
    $icinga_ido_db_name = hiera('icinga_ido_db_name'),
    $icinga_ido_user_name = hiera('icinga_ido_user_name'),
    $icinga_ido_password = hiera('icinga_ido_password'),
    $director_db_host = hiera('director_db_host'),
    $director_db_name = hiera('director_db_name'),
    $director_user_name = hiera('director_user_name'),
    $director_password = hiera('director_password'),
    $icinga_api_password = hiera('icinga_api_password'),
) {
    include ::icinga2

    package { [ 'icingaweb2', 'icingaweb2-module-monitoring',
                'icingaweb2-module-doc', 'icingacli' ] :
        ensure => present,
        require => Apt::Repository['icinga2'],
    }

    include ::apache

    if os_version('debian == jessie') {
        include ::apache::mod::php5
    }

    if os_version('debian >= stretch') {
        include ::apache::mod::php7
    }

    include ::apache::mod::ssl
    include ::apache::mod::headers
    include ::apache::mod::cgi

    ferm::service { 'icinga2-https':
      proto => 'tcp',
      port  => 443,
    }

    ferm::service { 'icinga2-http':
      proto => 'tcp',
      port  => 80,
    }

    if os_version('debian >= stretch') {
        require_package('php7.0')
        require_package('php-dev')
        require_package('php-curl')
        require_package('php-imagick')
        require_package('php-gd')
        require_package('php-json')
        require_package('php-mbstring')
        require_package('php-common')
        require_package('php-mysql')
        require_package('php-ldap')
    } else {
        require_package('php5')
        require_package('php5-curl')
        require_package('php5-dev')
        require_package('php5-imagick')
        require_package('php5-gd')
        require_package('php5-json')
        require_package('php5-mbstring')
        require_package('php5-common')
        require_package('php5-mysql')
        require_package('php5-ldap')
    }

    file { '/etc/icingaweb2':
        ensure => 'directory',
        owner  => 'www-data',
        group  => 'icingaweb2',
        mode   => '2755',
    }

    file { '/etc/icingaweb2/authentication.ini':
        ensure => present,
        content => template('icinga2/authentication.ini.erb'),
        owner  => 'www-data',
        group  => 'icingaweb2',
    }

    file { '/etc/icingaweb2/groups.ini':
        ensure => present,
        content => template('icinga2/groups.ini.erb'),
        owner  => 'www-data',
        group  => 'icingaweb2',
    }

    file { '/etc/icingaweb2/resources.ini':
        ensure => present,
        content => template('icinga2/resources.ini.erb'),
        owner  => 'www-data',
        group  => 'icingaweb2',
    }

    file { '/etc/icingaweb2/modules/director':
        ensure => 'directory',
        owner  => 'www-data',
        group  => 'icingaweb2',
    }

    file { '/etc/icingaweb2/modules/director/config.ini':
        ensure => present,
        content => template('icinga2/config.ini.erb'),
        owner  => 'www-data',
        group  => 'icingaweb2',
        require => File['/etc/icingaweb2/modules/director'],
    }

    file { '/etc/icingaweb2/modules/director/kickstart.ini':
        ensure => present,
        content => template('icinga2/kickstart.ini.erb'),
        owner  => 'www-data',
        group  => 'icingaweb2',
        require => File['/etc/icingaweb2/modules/director'],
    }

    file { '/etc/icingaweb2/modules/monitoring/backends.ini':
        ensure => present,
        content => template('icinga2/backends.ini.erb'),
        owner  => 'www-data',
        group  => 'icingaweb2',
    }

    file { '/etc/icingaweb2/modules/monitoring/commandtransports.ini':
        ensure => present,
        content => template('icinga2/commandtransports.ini.erb'),
        owner  => 'www-data',
        group  => 'icingaweb2',
    }

    file { '/etc/icingaweb2/modules/monitoring/roles.ini':
        ensure => present,
        content => template('icinga2/roles.ini.erb'),
        owner  => 'www-data',
        group  => 'icingaweb2',
    }

    #git::clone { 'beta-mediawiki-core':
    #    directory => "${stage_dir}/php-master",
    #    origin    => 'https://gerrit.wikimedia.org/r/p/mediawiki/core.git',
    #    branch    => 'master',
    #    owner     => 'root',
    #    group     => 'root',
    #    require   => Package['icingaweb2'],
    #}

    # install the Icinga Apache site
    include ::apache::mod::rewrite
    include ::apache::mod::authnz_ldap
    include ::apache::mod::rewrite

    include ::apache::mod::proxy

    include ::apache::mod::proxy_http

    include ::apache::mod::headers


    #letsencrypt::cert::integrated { 'gerrit-icinga':
    #     subjects   => 'gerrit-icinga.wmflabs.org',
    #     puppet_svc => 'apache2',
    #     system_svc => 'apache2',
    #}

    $ssl_settings = ssl_ciphersuite('apache', 'mid', true)
    # letsencrypt::cert::integrated { 'icinga2':
    #    subjects   => hiera('icinga2_apache_host', 'icinga.wmflabs.org'),
    #    puppet_svc => 'apache2',
    #    system_svc => 'apache2',
    #    require    => Class['apache::mod::ssl'],
    #}

    apache::site { 'gerrit-icinga.wmflabs.org':
        content => template('icinga2/gerrit-icinga.wmflabs.org.erb'),
    }
}
