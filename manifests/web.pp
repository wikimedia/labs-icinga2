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
    $director_password = hiera('director_password')
) {
    include ::icinga2

    apt::repository { 'icingaweb2':
        uri        => 'http://packages.icinga.com/debian',
        dist       => 'icinga-jessie',
        components => 'main',
        source     => false,
        keyfile    => 'puppet:///modules/icinga2/icingaweb2.gpg',
    }

    package { 'icingaweb2':
        ensure => present,
    }

    package { 'icinga2-doc':
        ensure => present,
    }

    include ::apache
    if os_version('debian == jessie') {
        include ::apache::mod::php5
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
        require_package('php7.0-dev')
        require_package('php7.0-gd')
    } else {
        require_package('php5')
        require_package('php5-dev')
        require_package('php5-gd')
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

    file { '/etc/icingaweb2/resources.ini':
        ensure => present,
        content => template('icinga2/resources.ini.erb'),
        owner  => 'www-data',
        group  => 'icingaweb2',
    }

    include ::passwords::ldap::wmf_cluster
    $proxypass = $passwords::ldap::wmf_cluster::proxypass

    # install the Icinga Apache site
    include ::apache::mod::rewrite
    include ::apache::mod::authnz_ldap
    include ::apache::mod::rewrite

    include ::apache::mod::proxy

    include ::apache::mod::proxy_http

    include ::apache::mod::headers


    letsencrypt::cert::integrated { 'gerrit-icinga':
         subjects   => 'gerrit-icinga.wmflabs.org',
         puppet_svc => 'apache2',
         system_svc => 'apache2',
    }

    $ssl_settings = ssl_ciphersuite('apache', 'mid', true)
    # letsencrypt::cert::integrated { 'icinga2':
    #    subjects   => hiera('icinga2_apache_host', 'icinga.wmflabs.org'),
    #    puppet_svc => 'apache2',
    #    system_svc => 'apache2',
    #    require    => Class['apache::mod::ssl'],
    #}

    apache::site { 'gerrit-icinga.wmflabs.org':
        content => template('icinga2/icinga.wmflabs.org.erb'),
    }

    file { '/etc/apache2/conf.d/icinga2.conf':
        ensure => absent,
    }

}
