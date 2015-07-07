class phpmyadmin ($root_password, $phpmyadmin_password) {
	ensure_resource('package', 'phpmyadmin', {'ensure' => 'present'})

	ensure_resource(
		'package', 
		'php5-mcrypt',
		{ 'ensure' => 'installed', 'notify' => Exec["enable-mcrypt"]}
	)

	exec { 'enable-mcrypt':
		command => 'php5enmod mcrypt',
		notify => Class['Apache::Service'],
		refreshonly => true,
	}

	# Set up phpMyAdmin
	exec { 'unpack-pma-tables':
		command => 'gunzip create_tables.sql.gz',
		cwd => '/usr/share/doc/phpmyadmin/examples/',
		creates => '/usr/share/doc/phpmyadmin/examples/create_tables.sql',
		require => Package['phpmyadmin'],
	}

	mysql::db { 'phpmyadmin':
		user => 'phpmyadmin',
		password => $phpmyadmin_password,
		host => 'localhost',
		grant    => ['ALL'],
		sql      => '/usr/share/doc/phpmyadmin/examples/create_tables.sql',
		require => Exec['unpack-pma-tables'],
	}

	# Set phpMyAdmin defaults
	file { '/root/pma.debconf.sh':
		ensure => file,
		mode => 0755,
		content => template('phpmyadmin/debconf.sh.erb'),
		notify => Exec["/root/pma.debconf.sh"],
	}

	exec { '/root/pma.debconf.sh':
		refreshonly => true,
	}

	file {'/etc/phpmyadmin':
		ensure => 'directory',
	}

	file {'/etc/phpmyadmin/config.inc.php':
		ensure => file,
		owner => 'root',
		group => 'root',
		source => 'puppet:///modules/phpmyadmin/config.inc.php',
		notify => Class['Apache::Service'],
		require => File['/etc/phpmyadmin'],
		mode => 0644,
	}

	file { '/etc/apache2/conf-enabled/phpmyadmin.conf':
		ensure => link,
		target => '/etc/phpmyadmin/apache.conf',
		notify => Class['Apache::Service'],
		require => Package['phpmyadmin'],
	}

}