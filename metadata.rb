name 'whats-fresh'
maintainer 'Oregon State University'
maintainer_email 'systems@osuosl.org'
license 'Apache 2.0'
description "Installs/Configures What's Fresh dependencies"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.11'

depends 'application'
depends 'application_nginx'
depends 'application_python'
depends 'build-essential'
depends 'database'
depends 'geos'
depends 'git'
depends 'magic_shell'
depends 'monitoring'
depends 'osl-munin'
depends 'osl-nginx'
depends 'postgis'
depends 'postgresql'
depends 'python'
depends 'selinux_policy'
depends 'working-waterfronts'
depends 'yum'
depends 'yum-epel'
depends 'yum-ius'
depends 'yum-osuosl'
