class rt {
}

class rt::server {

  if $operatingsystem == Debian {

    # This is added to get the backports repo available
    file {"/etc/apt/sources.list.d/rt.backports.list":
      ensure => present,
      owner  => "root",
      group  => "root",
      alias  => "backports",
      source => "puppet:///modules/rt/rt.backports.list",
      notify => Exec["apt-get-update"]
    }

    # Make the packages in new repos available
    exec {"/usr/bin/apt-get update":
      refreshonly => true,
      alias       => "apt-get-update"
    }

    # Pin the perl modules that have to come from backports
    # repo so that they always come from that repo.
    file {"/etc/apt/preferences.d/rt":
      ensure => present,
      owner  => "root",
      group  => "root",
      alias  => "rt-prefs",
      source => "puppet:///modules/rt/rt"
    }

    # Overide the package type to require the backports config
    Package {
      require => [
        Exec["apt-get-update"],
        File["backports"],
        File["rt-prefs"]
      ]
    }

  }

  package {"mysql-server":
    ensure => installed
  }

  package {"rt4-apache2":
    ensure => installed
  }

  package {"rt4-clients":
    ensure  => installed
  }

  package {"rt4-db-mysql":
    ensure  => installed,
    require => [
      Package["mysql-server"]
    ]
  }

  package {"request-tracker4":
    ensure  => installed,
    require => [
      Package["mysql-server"],
      Package["rt4-apache2"],
      Package["rt4-clients"],
      Package["rt4-db-mysql"]
    ]
  }

  service {"mysql":
    ensure  => running,
    enable  => true,
    require => Package["mysql-server"]
  }

# This is a useful starting point when you want to do customization,
# like SSL etc.
#  file {"/etc/request-tracker4/apache2-modperl2.conf":
#    ensure  => present,
#    owner   => "root",
#    group   => "root",
#    mode    => 600,
#    source  => "puppet:///modules/rt/apache2-modperl2.conf",
#    require => Package["request-tracker4"],
#    notify  => Service["apache2"]
#  }

  file {"/etc/apache2/sites-enabled/001-rt4":
    ensure  => "/etc/request-tracker4/apache2-modperl2.conf",
    notify  => Service["apache2"],
    require => [
      File["/etc/apache2/mods-enabled/actions.conf"],
      File["/etc/apache2/mods-enabled/actions.load"]
    ]
  }

  file {"/etc/apache2/mods-enabled/actions.conf":
    ensure => "/etc/apache2/mods-available/actions.conf",
    notify  => Service["apache2"],
    require => Package["request-tracker4"]
  }

  file {"/etc/apache2/mods-enabled/actions.load":
    ensure  => "/etc/apache2/mods-available/actions.load",
    notify  => Service["apache2"],
    require => Package["request-tracker4"]
  }

  service {"apache2":
    ensure  => running,
    enable  => true,
    require => [
      Package["rt4-apache2"],
      File["/etc/apache2/sites-enabled/001-rt4"],
      Exec["/usr/sbin/update-rt-siteconfig-4"]
    ]
  }

  file {"/etc/request-tracker4/RT_SiteConfig.d/50-debconf":
    ensure => absent,
    require => Package["request-tracker4"]
  }

  file {"/etc/request-tracker4/RT_SiteConfig.d/50-rtconf":
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 600,
    source  => "puppet:///modules/rt/50-rtconf",
    require => File["/etc/request-tracker4/RT_SiteConfig.d/50-debconf"],
    notify  => Exec["/usr/sbin/update-rt-siteconfig-4"]
  }

  exec {"/usr/sbin/update-rt-siteconfig-4":
    refreshonly => true,
    require => File["/etc/request-tracker4/RT_SiteConfig.d/50-debconf"]
  }

  package {"postfix":
    ensure => installed
  }

  file {"/etc/postfix/main.cf":
    owner   => "root",
    group   => "root",
    source  => "puppet:///modules/rt/main.cf",
    require => Package["postfix"],
    notify  => Service["postfix"]
  }

  file {"/etc/mailname":
    owner   => "root",
    group   => "root",
    content => "rt.foo.com",
    require => Package["postfix"],
    notify  => Service["postfix"]
  }

  service {"postfix":
    ensure  => running,
    enable  => true,
    require => [
      File["/etc/postfix/main.cf"],
      File["/etc/mailname"]
    ]
  }

}

class rt::server::aliases {

  define queue($ensure = "present") {

    mailalias {$name:
      ensure    => $ensure,
      recipient => "|/usr/bin/rt-mailgate-4 --queue ${name} --action correspond --url http://localhost/rt"
    }

    mailalias {"${name}-comment":
      ensure    => $ensure,
      recipient => "|/usr/bin/rt-mailgate-4 --queue ${name} --action comment --url http://localhost/rt"
    }

  }

  Mailalias {
    notify => Exec["/usr/bin/newaliases"]
  }

  exec {"/usr/bin/newaliases":
    refreshonly => true
  }

  queue {"rt":
    ensure => "present"
  }

  queue {"general":
    ensure => "present"
  }

}
