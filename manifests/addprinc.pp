# === Type: kerberos::addprinc
#
# Adds a kerberos principal to the KDC database. Supports use of kadmin.local
# or kadmin. The latter supports use of a ticket cache or a keytab file.
#
# === Authors
#
# Author Name <greg.1.anderson@greenknowe.org>
# Additions by Michael Weiser <michael.weiser@gmx.de>
#
# === Copyright
#
# Copyright 2014 Jason Edgecombe (Copyright assigned by original author)
#
define kerberos::addprinc($principal_name = $title,
  $password = undef, $flags = '',
  $local = true, $kadmin_ccache = undef, $keytab = undef,
  $tries = undef, $try_sleep = undef,
  $kadmin_server_package = $kerberos::kadmin_server_package,
  $client_packages = $kerberos::client_packages,
  $krb5_conf_path = $kerberos::krb5_conf_path,
) {
  if $local {
    # if we're gonna run kadmin.local we better make sure it's
    # installed
    include kerberos::server::kadmind_kprop
    $kadmin = 'kadmin.local'

    $addprinc_exec_require = [
      Package[$kadmin_server_package],
      Exec['create_krb5kdc_principal']
    ]
    $ccache_par = $kadmin_ccache ? {
      undef => '',
      default => "-c '${kadmin_ccache}'"
    }

    $keytab_par = $keytab ? {
      undef => '',
      default => "-k -t '${keytab}'"
    }

  } else {
    # if we're gonna run kadmin we better make sure it's installed
    # and configured
    include kerberos::client
    $kadmin = 'kadmin'

    $ccache_par = $kadmin_ccache ? {
      undef => '',
      default => "-c '${kadmin_ccache}'"
    }

    $keytab_par = $keytab ? {
      undef => '',
      default => "-k -t '${keytab}'"
    }

    $addprinc_exec_require = [
      Package[$client_packages],
      File['krb5.conf']
    ]
  }

  if !('-randkey' in $flags) {
    $password_par = $password ? {

      undef => '-nokey',
      default => "-pw ${password}"
    }
  }

  $cmd = "addprinc ${flags} ${password_par} ${principal_name}"
  exec { "add_principal_${principal_name}":
    command     => "${kadmin} ${ccache_par} ${keytab_par} -q '${cmd}'",
    path        => [ '/usr/sbin', '/usr/bin' ],
    environment => "KRB5_CONFIG=${krb5_conf_path}",
    require     => $addprinc_exec_require,
    tries       => $tries,
    try_sleep   => $try_sleep,
  }
}
