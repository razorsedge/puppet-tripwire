# == Class: tripwire
#
# Full description of class tripwire here.
#
# === Parameters:
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables:
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if it
#   has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should not be used in preference to class parameters  as of
#   Puppet 2.6.)
#
# === Sample Usage:
#
#  class { 'tripwire': }
#
# === Authors:
#
# Mike Arnold <mike@razorsedge.org>
#
# === Copyright:
#
# Copyright (C) 2012 Mike Arnold, unless otherwise noted.
#
class tripwire inherits tripwire::params {
  package { 'tripwire':
    ensure => 'present',
  }

  file { 'site.key':
    ensure  => 'present',
    mode    => '600',
    owner   => 'root',
    group   => 'root',
    require => Package['tripwire'],
    path    => '/etc/tripwire/site.key',
    source  => 'puppet:///modules/tripwire/site.key',
  }

  file { 'twcfg.txt':
    ensure  => 'present',
    mode    => '640',
    owner   => 'root',
    group   => 'root',
    require => Package['tripwire'],
    path    => '/etc/tripwire/twcfg.txt',
    source  => 'puppet:///modules/tripwire/twcfg.txt',
  }

  file { 'twpol.txt':
    ensure  => 'present',
    mode    => '640',
    owner   => 'root',
    group   => 'root',
    require => [ Package['tripwire'], Class['lsb'], ],
    path    => '/etc/tripwire/twpol.txt',
    source  => [
      "puppet:///modules/tripwire/twpol.txt-${fqdn}",
      "puppet:///modules/tripwire/twpol.txt-${operatingsystem}-${lsbmajdistrelease}-${architecture}",
      "puppet:///modules/tripwire/twpol.txt-${operatingsystem}-${lsbmajdistrelease}",
      "puppet:///modules/tripwire/twpol.txt-${operatingsystem}",
      "puppet:///modules/tripwire/twpol.txt",
    ],
  }

  file { "${fqdn}.twd":
    ensure  => '/var/lib/tripwire/tripwire.twd',
    owner   => 'root',
    group   => 'root',
    require => Exec['tripwire-init'],
    path    => "/var/lib/tripwire/${fqdn}.twd",
  }

  file { '/etc/tripwire':
    ensure  => 'directory',
    mode    => '700',
    owner   => 'root',
    group   => 'root',
    require => Package['tripwire'],
    path    => '/etc/tripwire',
  }

  file { 'tripwire-setup-keyfiles':
    ensure  => 'present',
    mode    => '750',
    owner   => 'root',
    group   => 'root',
    require => Package['tripwire'],
    path    => '/etc/tripwire/tripwire-setup-keyfiles',
    source  => 'puppet:///modules/tripwire/tripwire-setup-keyfiles',
  }

  exec { 'tripwire-setup-keyfiles':
    command     => '/etc/tripwire/tripwire-setup-keyfiles',
    creates     => '/etc/tripwire/local.key',
    environment => [ "TWLOCALPASS=$tripwire_local", "TWSITEPASS=$tripwire_site", ],
    require     => [ File['tripwire-setup-keyfiles'], File['twpol.txt'], File['twcfg.txt'], File['site.key'], ],
  }

  exec { 'tripwire-init':
    command   => "/usr/sbin/tripwire --init --local-passphrase $tripwire_local --quiet",
    creates   => '/var/lib/tripwire/tripwire.twd',
   #path      => '/sbin:/usr/sbin:/usr/local/sbin',
    require   => Exec['tripwire-setup-keyfiles'],
    timeout   => 10000,
    logoutput => on_failure,
  }

#  exec { 'tripwire-update-policy':
#    command     => "/usr/sbin/tripwire --update-policy -Z low --local-passphrase $tripwire_local --site-passphrase $tripwire_site --quiet /etc/tripwire/twpol.txt",
#    cwd         => '/etc/tripwire',
#    refreshonly => 'true',
#    subscribe   => File['twpol.txt'],
#    timeout     => 10000,
#    logoutput   => on_failure,
#  }

}
